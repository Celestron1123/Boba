import datetime
from firebase_functions import https_fn
from firebase_admin import initialize_app, firestore
from google.oauth2 import service_account
from googleapiclient.discovery import build

initialize_app()


def _require_auth(req):
    if req.auth is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="Must be logged in."
        )
    return req.auth.uid


def _profile(db, uid):
    snapshot = db.collection("users").document(uid).get()
    if not snapshot.exists:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.FAILED_PRECONDITION,
            message="User profile is not ready."
        )
    return snapshot.to_dict() or {}


def _require_therapist(db, uid):
    if _profile(db, uid).get("role") != "therapist":
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            message="Therapist access is required."
        )


@https_fn.on_call()
def createUserProfile(req: https_fn.CallableRequest) -> dict:
    """Create the server-owned identity portion of a user profile."""
    uid = _require_auth(req)
    data = req.data or {}
    role = data.get("role")
    first_name = str(data.get("firstName", "")).strip()
    last_name = str(data.get("lastName", "")).strip()

    if role not in ("patient", "therapist") or not first_name or not last_name:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="A valid role and name are required."
        )

    db = firestore.client()
    user_ref = db.collection("users").document(uid)
    existing = user_ref.get()
    if existing.exists and (existing.to_dict() or {}).get("role") not in (None, role):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.ALREADY_EXISTS,
            message="This account already has a different role."
        )

    email = (req.auth.token or {}).get("email", "")
    base_data = {
        "uid": uid,
        "email": email,
        "firstName": first_name,
        "lastName": last_name,
        "role": role,
        "emailVerified": bool((req.auth.token or {}).get("email_verified", False)),
        "updatedAt": firestore.SERVER_TIMESTAMP,
    }

    if role == "therapist":
        if not existing.exists:
            base_data["createdAt"] = firestore.SERVER_TIMESTAMP
        user_ref.set(base_data, merge=True)
        return {"uid": uid, "role": role}

    counter_ref = db.collection("counters").document("patients")

    @firestore.transactional
    def allocate(transaction):
        snapshot = transaction.get(counter_ref)
        current = int((snapshot.to_dict() or {}).get("lastNumber", 0)) if snapshot.exists else 0
        next_number = current + 1
        patient_data = dict(base_data)
        patient_data["patientNumber"] = next_number
        if not existing.exists:
            patient_data["createdAt"] = firestore.SERVER_TIMESTAMP
        transaction.set(counter_ref, {"lastNumber": next_number}, merge=True)
        transaction.set(user_ref, patient_data, merge=True)
        return next_number

    number = allocate(db.transaction())
    return {"uid": uid, "role": role, "patientNumber": number}


@https_fn.on_call()
def connectPatient(req: https_fn.CallableRequest) -> dict:
    uid = _require_auth(req)
    db = firestore.client()
    _require_therapist(db, uid)

    try:
        patient_number = int((req.data or {}).get("patientNumber"))
    except (TypeError, ValueError):
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="Enter a valid patient number."
        )

    matches = list(db.collection("users")
                   .where("patientNumber", "==", patient_number)
                   .limit(1)
                   .stream())
    if not matches or (matches[0].to_dict() or {}).get("role") != "patient":
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.NOT_FOUND,
            message="No patient was found with that number."
        )

    patient_ref = matches[0].reference
    patient = matches[0].to_dict() or {}
    connection_ref = db.collection("users").document(uid).collection("connections").document(patient_ref.id)
    if connection_ref.get().exists:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.ALREADY_EXISTS,
            message="This patient is already connected."
        )

    birth_date = patient.get("birthday")
    patient_age = None
    if birth_date:
        try:
            birth = birth_date.replace(tzinfo=datetime.timezone.utc) if birth_date.tzinfo is None else birth_date
            today = datetime.datetime.now(datetime.timezone.utc).date()
            patient_age = today.year - birth.date().year - ((today.month, today.day) < (birth.date().month, birth.date().day))
        except AttributeError:
            patient_age = None

    connection_ref.set({
        "patientId": patient_ref.id,
        "patientNumber": patient_number,
        "firstName": patient.get("firstName", ""),
        "lastName": patient.get("lastName", ""),
        "patientAge": patient_age,
        "wellnessGoals": patient.get("wellnessGoals", []),
        "status": "active",
        "createdBy": uid,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    })
    return {
        "patientId": patient_ref.id,
        "patientNumber": patient_number,
        "firstName": patient.get("firstName", ""),
        "lastName": patient.get("lastName", ""),
    }


@https_fn.on_call()
def disconnectPatient(req: https_fn.CallableRequest) -> dict:
    uid = _require_auth(req)
    db = firestore.client()
    _require_therapist(db, uid)
    patient_id = str((req.data or {}).get("patientId", "")).strip()
    if not patient_id:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="A patient ID is required."
        )

    connection_ref = db.collection("users").document(uid).collection("connections").document(patient_id)
    if not connection_ref.get().exists:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.NOT_FOUND,
            message="This patient is not connected."
        )
    connection_ref.delete()
    return {"patientId": patient_id, "status": "disconnected"}

SCOPES = ['https://www.googleapis.com/auth/calendar.events']
SERVICE_ACCOUNT_FILE = 'service-account.json'

@https_fn.on_call()
def bookAppointment(req: https_fn.CallableRequest) -> dict:
    # Ensure user is logged in via the iOS app
    if req.auth is None:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.UNAUTHENTICATED, message="Must be logged in.")

    data = req.data
    patient_id = req.auth.uid
    provider = data.get("provider", "Dr. Smith")
    start_time_str = data.get("time") # Expecting an ISO 8601 string from Swift

    try:
        start_at = datetime.datetime.fromisoformat(start_time_str.replace("Z", "+00:00"))
        end_at = start_at + datetime.timedelta(minutes=50)

        # Authenticate & Book on Google Calendar
        creds = service_account.Credentials.from_service_account_file(SERVICE_ACCOUNT_FILE, scopes=SCOPES)
        calendar_service = build('calendar', 'v3', credentials=creds)

        event_body = {
            'summary': f'Boba Appt: Patient {patient_id[-4:]}',
            'start': {'dateTime': start_time_str},
            'end': {'dateTime': end_at.isoformat()},
        }

        created_event = calendar_service.events().insert(calendarId='primary', body=event_body).execute()

        # Log to Firestore
        db = firestore.client()
        db.collection("appointments").add({
            "patientId": patient_id,
            "therapistId": data.get("therapistId"),
            "providerName": provider,
            "startAt": start_at,
            "gcalEventId": created_event.get('id'),
            "createdAt": firestore.SERVER_TIMESTAMP
        })

        return {"status": "success", "eventId": created_event.get('id')}

    except Exception as e:
        print(f"Error: {e}")
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INTERNAL, message="Booking failed.")
