# frozen_string_literal: true

class SendSchoolSessionRemindersJob < ApplicationJob
  sidekiq_options queue: :notifications

  def perform(session_id)
    session = Session.find(session_id)

    date = session.next_date(include_today: false)

    patients =
      session.patients.includes_statuses.where.not(
        SessionNotification
          .where(session:)
          .where(
            "session_notifications.patient_id = patient_locations.patient_id"
          )
          .where(session_date: date)
          .arel
          .exists
      )

    patients.find_each do |patient|
      patient.notifier.send_session_reminder(session, date, sent_by: nil)
    end
  end
end
