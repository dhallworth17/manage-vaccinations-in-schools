# frozen_string_literal: true

describe EmailDeliveryJob do
  subject(:perform) { described_class.new.perform(template_name, params) }

  before(:all) do
    Settings.govuk_notify.enabled = true
    Settings.govuk_notify.test_key = "abc"
  end

  after(:all) { Settings.govuk_notify.enabled = false }

  let(:response) do
    instance_double(
      Notifications::Client::ResponseNotification,
      id: SecureRandom.uuid
    )
  end

  let(:params) do
    {
      "academic_year" => academic_year,
      "consent_id" => consent&.id,
      "consent_form_id" => consent_form&.id,
      "disease_types" => disease_types,
      "parent_id" => parent&.id,
      "patient_id" => patient&.id,
      "programme_types" => programme_types,
      "sent_by_user_id" => sent_by&.id,
      "session_id" => session&.id,
      "team_id" => team&.id,
      "team_location_id" => team_location&.id,
      "vaccination_record_id" => vaccination_record&.id
    }.compact
  end

  let(:template_name) { :clinic_initial_invitation }
  let(:academic_year) { session.academic_year }
  let(:consent) { nil }
  let(:consent_form) { nil }
  let(:disease_types) { programmes.flat_map(&:disease_types) }
  let(:parent) { create(:parent, email: "test@example.com") }
  let(:patient) { create(:patient) }
  let(:programme_types) { programmes.map(&:type) }
  let(:programmes) { [Programme.sample] }
  let(:sent_by) { create(:user) }
  let(:session) { create(:session, programmes:, team:) }
  let(:team) do
    create(
      :team,
      reply_to_id: "54bf1d28-8851-43f2-893d-1853f43a50cd",
      programmes:
    )
  end
  let(:team_location) { session.team_location }
  let(:vaccination_record) { nil }
  let(:notifications_client) { instance_double(Notifications::Client) }

  before do
    allow(Notifications::Client).to receive(:new).with("abc").and_return(
      notifications_client
    )
    allow(notifications_client).to receive(:send_email).and_return(response)
  end

  after { described_class.instance_variable_set("@client", nil) }

  it "generates personalisation" do
    expect(GovukNotifyPersonalisation).to receive(:new).with(
      academic_year:,
      consent:,
      consent_form:,
      disease_types:,
      parent:,
      patient:,
      programme_types:,
      session:,
      team:,
      team_location:,
      vaccination_record:
    ).and_call_original
    perform
  end

  it "sends a text using GOV.UK Notify" do
    expect(notifications_client).to receive(:send_email).with(
      email_address: "test@example.com",
      email_reply_to_id: "54bf1d28-8851-43f2-893d-1853f43a50cd",
      personalisation: an_instance_of(Hash),
      template_id: EmailDeliveryJob::PASSTHROUGH_TEMPLATE_ID
    )
    perform
  end

  context "without a reply-to id" do
    let(:team) { create(:team, programmes:) }

    it "sends a text using GOV.UK Notify" do
      expect(notifications_client).to receive(:send_email).with(
        email_address: "test@example.com",
        personalisation: an_instance_of(Hash),
        template_id: EmailDeliveryJob::PASSTHROUGH_TEMPLATE_ID
      )
      perform
    end
  end

  it "creates a log entry" do
    expect { perform }.to change(NotifyLogEntry, :count).by(1)

    notify_log_entry = NotifyLogEntry.last
    expect(notify_log_entry).to be_email
    expect(notify_log_entry.delivery_id).to eq(response.id)
    expect(notify_log_entry.recipient).to eq("test@example.com")
    expect(notify_log_entry.template_id).to eq(
      NotifyTemplate.find(template_name, channel: :email).id
    )
    expect(notify_log_entry.parent).to eq(parent)
    expect(notify_log_entry.patient).to eq(patient)
    expect(notify_log_entry.programmes.map(&:type)).to eq(programme_types)
    expect(notify_log_entry.sent_by).to eq(sent_by)
    expect(notify_log_entry.subject).to include("has still not had their")
    expect(notify_log_entry.body).to include("Our records show that")
  end

  context "with a non-MMR programme" do
    let(:programmes) { [Programme.find("flu")] }

    it "creates a log entry programme record" do
      expect { perform }.to change(NotifyLogEntry::Programme, :count).by(1)

      notify_log_entry_programme =
        NotifyLogEntry.last.notify_log_entry_programmes.first

      expect(notify_log_entry_programme.programme_type).to eq("flu")
      expect(notify_log_entry_programme.disease_types).to eq(%w[influenza])
    end
  end

  context "with an MMR programme and disease types" do
    let(:programmes) { [Programme.find("mmr")] }
    let(:disease_types) { %w[measles mumps rubella] }

    it "creates a log entry programme record with variant disease types" do
      expect { perform }.to change(NotifyLogEntry::Programme, :count).by(1)

      notify_log_entry_programme =
        NotifyLogEntry.last.notify_log_entry_programmes.first

      expect(notify_log_entry_programme.programme_type).to eq("mmr")
      expect(notify_log_entry_programme.disease_types).to eq(
        %w[measles mumps rubella]
      )
    end
  end

  context "when the parent doesn't have an email address" do
    let(:parent) { create(:parent, email: nil) }

    it "doesn't send a text" do
      expect(notifications_client).not_to receive(:send_email)
      perform
    end

    it "writes a warning to the logs" do
      expect(Rails.logger).to receive(:warn).with(
        /Failed to find email address for template #{template_name}/
      )
      perform
    end
  end

  context "with a consent form" do
    let(:consent_form) do
      create(:consent_form, session:, parent_email: "test@example.com")
    end
    let(:parent) { nil }
    let(:patient) { nil }

    it "sends a text using GOV.UK Notify" do
      expect(notifications_client).to receive(:send_email).with(
        email_address: "test@example.com",
        email_reply_to_id: "54bf1d28-8851-43f2-893d-1853f43a50cd",
        personalisation: an_instance_of(Hash),
        template_id: EmailDeliveryJob::PASSTHROUGH_TEMPLATE_ID
      )
      perform
    end

    context "without a reply-to id" do
      let(:team) { create(:team, programmes:) }

      it "sends a text using GOV.UK Notify" do
        expect(notifications_client).to receive(:send_email).with(
          email_address: "test@example.com",
          personalisation: an_instance_of(Hash),
          template_id: EmailDeliveryJob::PASSTHROUGH_TEMPLATE_ID
        )
        perform
      end
    end

    it "creates a log entry" do
      expect { perform }.to change(NotifyLogEntry, :count).by(1)

      notify_log_entry = NotifyLogEntry.last
      expect(notify_log_entry).to be_email
      expect(notify_log_entry.delivery_id).to eq(response.id)
      expect(notify_log_entry.recipient).to eq("test@example.com")
      expect(notify_log_entry.template_id).to eq(
        NotifyTemplate.find(template_name, channel: :email).id
      )
      expect(notify_log_entry.consent_form).to eq(consent_form)
      expect(notify_log_entry.programmes.map(&:type)).to eq(programme_types)
    end

    context "when the consent form is matched to a patient" do
      let(:matched_patient) { create(:patient) }

      before do
        create(
          :consent,
          programme: session.programmes.first,
          consent_form:,
          patient: matched_patient
        )
      end

      it "sets patient on the log entry from the matched consent form" do
        perform
        expect(NotifyLogEntry.last.patient).to eq(matched_patient)
      end
    end

    context "when the parent doesn't have a phone number" do
      let(:consent_form) { create(:consent_form, session:, parent_email: nil) }

      it "doesn't send a text" do
        expect(notifications_client).not_to receive(:send_email)
        perform
      end
    end
  end
end
