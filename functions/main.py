import datetime
from firebase_functions import https_fn
from firebase_admin import initialize_app, firestore
from google.oauth2 import service_account
from googleapiclient.discovery import build

initialize_app()

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
        # Authenticate & Book on Google Calendar
        creds = service_account.Credentials.from_service_account_file(SERVICE_ACCOUNT_FILE, scopes=SCOPES)
        calendar_service = build('calendar', 'v3', credentials=creds)

        event_body = {
            'summary': f'Boba Appt: Patient {patient_id[-4:]}',
            'start': {'dateTime': start_time_str},
            'end': {'dateTime': start_time_str}, # We will add 50 min math later
        }

        created_event = calendar_service.events().insert(calendarId='primary', body=event_body).execute()

        # Log to Firestore
        db = firestore.client()
        db.collection("appointments").add({
            "patientId": patient_id,
            "provider": provider,
            "startTime": start_time_str,
            "gcalEventId": created_event.get('id'),
            "createdAt": firestore.SERVER_TIMESTAMP
        })

        return {"status": "success", "eventId": created_event.get('id')}

    except Exception as e:
        print(f"Error: {e}")
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INTERNAL, message="Booking failed.")