# frozen_string_literal: true

describe SendSchoolSessionRemindersJob do
  subject(:perform) { described_class.new.perform(session.id) }

  let(:team) { create(:team, programmes:) }
  let(:notifier) { instance_double(Notifier::Patient) }
  let(:session) { create(:session, :tomorrow, programmes:, team:) }
  let(:programmes) { [Programme.hpv] }
  let(:parents) { create_list(:parent, 2) }
  let(:patient) do
    create(:patient, :consent_given_triage_not_needed, parents:, programmes:)
  end

  before do
    create(:patient_location, patient:, session:)
    allow(Notifier::Patient).to receive(:new).and_return(notifier)
    allow(notifier).to receive(:send_session_reminder)
  end

  it "sends a notification" do
    expect(notifier).to receive(:send_session_reminder).once.with(
      session,
      Date.tomorrow,
      sent_by: nil
    )
    perform
  end

  context "when triaged for vaccination" do
    let(:patient) do
      create(
        :patient,
        :consent_given_triage_safe_to_vaccinate,
        parents:,
        programmes:
      )
    end

    it "sends a notification" do
      expect(notifier).to receive(:send_session_reminder).once.with(
        session,
        Date.tomorrow,
        sent_by: nil
      )
      perform
    end
  end

  context "without consent or triage" do
    let(:patient) { create(:patient, parents:) }

    it "doesn't send any notifications" do
      expect { perform }.not_to change(SessionNotification, :count)
    end
  end

  context "when already sent" do
    before do
      create(:session_notification, :school_reminder, session:, patient:)
    end

    it "doesn't send any notifications" do
      expect { perform }.not_to change(SessionNotification, :count)
    end
  end

  context "when already vaccinated" do
    before do
      create(:vaccination_record, patient:, programme: programmes.first)
      PatientStatusUpdater.call(patient:)
    end

    it "doesn't send any notifications" do
      expect { perform }.not_to change(SessionNotification, :count)
    end
  end

  context "if the patient is deceased" do
    let(:patient) { create(:patient, :deceased, parents:) }

    it "doesn't send any notifications" do
      expect { perform }.not_to change(SessionNotification, :count)
    end
  end

  context "if the patient is invalid" do
    let(:patient) { create(:patient, :invalidated, parents:) }

    it "doesn't send any notifications" do
      expect { perform }.not_to change(SessionNotification, :count)
    end
  end

  context "if the patient is restricted" do
    let(:patient) { create(:patient, :restricted, parents:) }

    it "doesn't send any notifications" do
      expect { perform }.not_to change(SessionNotification, :count)
    end
  end

  context "if the patient is archived" do
    let(:patient) { create(:patient, :archived, parents:, team:) }

    it "doesn't send any notifications" do
      expect { perform }.not_to change(SessionNotification, :count)
    end
  end
end
