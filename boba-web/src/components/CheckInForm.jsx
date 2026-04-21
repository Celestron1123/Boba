import { useEffect, useState } from 'react'
import { MOOD_OPTIONS, createPatientLog, getMoodOption, updatePatientLog } from '../data/patientLogs'

export default function CheckInForm({
  patientId,
  date,
  existingLog,
  onSaved,
  submitLabel = 'Save today’s check-in',
  allowEditing = false,
}) {
  const defaultMood = existingLog?.mood ?? MOOD_OPTIONS[2].value
  const [emojiValue, setEmojiValue] = useState(defaultMood)
  const [notes, setNotes] = useState(existingLog?.notes ?? '')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [isEditing, setIsEditing] = useState(!existingLog)

  useEffect(() => {
    setEmojiValue(existingLog?.mood ?? MOOD_OPTIONS[2].value)
    setNotes(existingLog?.notes ?? '')
    setIsEditing(!existingLog)
    setError('')
  }, [existingLog])

  async function handleSubmit(event) {
    event.preventDefault()

    if (saving || (existingLog && !isEditing)) {
      return
    }

    const trimmedNotes = notes.trim()

    if (!trimmedNotes) {
      setError('Enter notes before submitting today’s check-in.')
      return
    }

    setSaving(true)
    setError('')

    try {
      const emojiOption = getMoodOption(emojiValue)
      const savedLog = existingLog
        ? await updatePatientLog({
            patientId,
            logId: existingLog.id,
            date,
            mood: emojiOption.value,
            notes: trimmedNotes,
          })
        : await createPatientLog({
            patientId,
            date,
            mood: emojiOption.value,
            notes: trimmedNotes,
          })

      onSaved(savedLog)
      setIsEditing(false)
    } catch (err) {
      console.error(err)
      setError(existingLog ? 'Unable to update this check-in.' : 'Unable to save today’s check-in.')
    } finally {
      setSaving(false)
    }
  }

  function handleEditClick() {
    setIsEditing(true)
    setError('')
  }

  function handleCancelClick() {
    setEmojiValue(existingLog?.mood ?? MOOD_OPTIONS[2].value)
    setNotes(existingLog?.notes ?? '')
    setIsEditing(false)
    setError('')
  }

  const isReadOnly = Boolean(existingLog) && !isEditing

  return (
    <form className="check-in-form" onSubmit={handleSubmit}>
      <fieldset className="check-in-fieldset" disabled={isReadOnly}>
        <legend>Mood</legend>
        <div className="check-in-mood-options">
          {MOOD_OPTIONS.map((option) => (
            <label
              key={option.value}
              className="check-in-mood-option"
              data-mood={option.value}
            >
              <input
                type="radio"
                name="emoji"
                value={option.value}
                checked={emojiValue === option.value}
                onChange={(event) => setEmojiValue(event.target.value)}
              />
              <span className="check-in-mood-emoji" aria-hidden="true">
                {option.emoji}
              </span>
              <span>{option.label}</span>
            </label>
          ))}
        </div>
      </fieldset>

      <div className="check-in-field">
        <label htmlFor="notes">Notes</label>
        <textarea
          id="notes"
          rows="5"
          value={notes}
          onChange={(event) => setNotes(event.target.value)}
          placeholder="Write a short journal entry for today."
          disabled={isReadOnly}
        />
      </div>

      {error ? <p className="check-in-error">{error}</p> : null}

      {isReadOnly ? (
        <div className="check-in-actions">
          <p className="check-in-status">This check-in has already been submitted.</p>
          {allowEditing ? (
            <button type="button" className="check-in-secondary-btn" onClick={handleEditClick}>
              Edit
            </button>
          ) : null}
        </div>
      ) : (
        <div className="check-in-actions">
          <button type="submit" className="check-in-submit-btn" disabled={saving}>
            {saving ? 'Saving...' : submitLabel}
          </button>
          {existingLog ? (
            <button
              type="button"
              className="check-in-secondary-btn"
              onClick={handleCancelClick}
              disabled={saving}
            >
              Cancel
            </button>
          ) : null}
        </div>
      )}
    </form>
  )
}
