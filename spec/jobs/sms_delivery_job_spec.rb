# frozen_string_literal: true

describe SMSDeliveryJob do
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

  let(:template_name) { :consent_school_request }
  let(:academic_year) { session.academic_year }
  let(:consent) { nil }
  let(:consent_form) { nil }
  let(:disease_types) { programmes.flat_map(&:disease_types) }
  let(:parent) { create(:parent, phone: "01234 567890") }
  let(:patient) { create(:patient) }
  let(:programme_types) { programmes.map(&:type) }
  let(:programmes) { [Programme.sample] }
  let(:sent_by) { create(:user) }
  let(:session) { create(:session, programmes:) }
  let(:team) { session.team }
  let(:team_location) { session.team_location }
  let(:vaccination_record) { nil }
  let(:notifications_client) { instance_double(Notifications::Client) }

  before do
    allow(Notifications::Client).to receive(:new).with("abc").and_return(
      notifications_client
    )
    allow(notifications_client).to receive(:send_sms).and_return(response)
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
    expect(notifications_client).to receive(:send_sms).with(
      phone_number: "01234 567890",
      template_id: SMSDeliveryJob::PASSTHROUGH_TEMPLATE_ID,
      personalisation: an_instance_of(Hash)
    )
    perform
  end

  it "creates a log entry" do
    expect { perform }.to change(NotifyLogEntry, :count).by(1)

    notify_log_entry = NotifyLogEntry.last
    expect(notify_log_entry).to be_sms
    expect(notify_log_entry.delivery_id).to eq(response.id)
    expect(notify_log_entry.recipient).to eq("01234 567890")
    expect(notify_log_entry.template_id).to eq(
      NotifyTemplate.find(template_name, channel: :sms).id
    )
    expect(notify_log_entry.purpose).to eq("consent_request")
    expect(notify_log_entry.parent).to eq(parent)
    expect(notify_log_entry.patient).to eq(patient)
    expect(notify_log_entry.programmes.map(&:type)).to eq(programme_types)
    expect(notify_log_entry.sent_by).to eq(sent_by)
    expect(notify_log_entry.body).to include("Give or refuse consent for")
  end

  context "when the parent doesn't have a phone number" do
    let(:parent) { create(:parent, phone: nil) }

    it "doesn't send a text" do
      expect(notifications_client).not_to receive(:send_sms)
      perform
    end
  end

  context "when the parent phone number is invalid" do
    before do
      allow(notifications_client).to receive(:send_sms).and_raise(
        Notifications::Client::BadRequestError.new(
          OpenStruct.new(
            code: 400,
            body: "InvalidPhoneError: Not a UK mobile number"
          )
        )
      )
    end

    it "creates a log entry for the failure" do
      expect { perform }.to change(NotifyLogEntry, :count).by(1)

      notify_log_entry = NotifyLogEntry.last
      expect(notify_log_entry).to be_sms
      expect(notify_log_entry).to be_not_uk_mobile_number_failure
      expect(notify_log_entry.delivery_id).to be_nil
      expect(notify_log_entry.recipient).to eq("01234 567890")
      expect(notify_log_entry.template_id).to eq(
        NotifyTemplate.find(template_name, channel: :sms).id
      )
      expect(notify_log_entry.purpose).to eq("consent_request")
      expect(notify_log_entry.parent).to eq(parent)
      expect(notify_log_entry.patient).to eq(patient)
      expect(notify_log_entry.programmes.map(&:type)).to eq(programme_types)
      expect(notify_log_entry.sent_by).to eq(sent_by)
    end
  end

  context "when the parent phone number is not part of the allow list" do
    before do
      allow(notifications_client).to receive(:send_sms).and_raise(
        Notifications::Client::BadRequestError.new(
          OpenStruct.new(
            code: 400,
            body: "Can’t send to this recipient using a team-only API key"
          )
        )
      )
    end

    it "creates a log entry for the failure" do
      expect { perform }.to change(NotifyLogEntry, :count).by(1)

      notify_log_entry = NotifyLogEntry.last
      expect(notify_log_entry).to be_sms
      expect(notify_log_entry).to be_technical_failure
      expect(notify_log_entry.delivery_id).to be_nil
      expect(notify_log_entry.recipient).to eq("01234 567890")
      expect(notify_log_entry.template_id).to eq(
        NotifyTemplate.find(template_name, channel: :sms).id
      )
      expect(notify_log_entry.purpose).to eq("consent_request")
      expect(notify_log_entry.parent).to eq(parent)
      expect(notify_log_entry.patient).to eq(patient)
      expect(notify_log_entry.programmes.map(&:type)).to eq(programme_types)
      expect(notify_log_entry.sent_by).to eq(sent_by)
    end
  end

  context "with a consent form" do
    let(:consent_form) do
      create(:consent_form, session:, parent_phone: "01234567890")
    end
    let(:parent) { nil }
    let(:patient) { nil }

    it "sends a text using GOV.UK Notify" do
      expect(notifications_client).to receive(:send_sms).with(
        phone_number: "01234 567890",
        template_id: SMSDeliveryJob::PASSTHROUGH_TEMPLATE_ID,
        personalisation: an_instance_of(Hash)
      )
      perform
    end

    it "creates a log entry" do
      expect { perform }.to change(NotifyLogEntry, :count).by(1)

      notify_log_entry = NotifyLogEntry.last
      expect(notify_log_entry).to be_sms
      expect(notify_log_entry.delivery_id).to eq(response.id)
      expect(notify_log_entry.recipient).to eq("01234 567890")
      expect(notify_log_entry.template_id).to eq(
        NotifyTemplate.find(template_name, channel: :sms).id
      )
      expect(notify_log_entry.purpose).to eq("consent_request")
      expect(notify_log_entry.consent_form).to eq(consent_form)
      expect(notify_log_entry.programmes.map(&:type)).to eq(programme_types)
    end

    it "creates a log entry programme record" do
      expect { perform }.to change(NotifyLogEntry::Programme, :count).by(1)

      notify_log_entry_programme = NotifyLogEntry::Programme.last

      expect(notify_log_entry_programme.programme_type).to eq(
        programmes.first.type
      )
      expect(notify_log_entry_programme.disease_types).to eq(
        programmes.first.disease_types
      )
    end

    context "when the parent doesn't have a phone number" do
      let(:consent_form) { create(:consent_form, session:, parent_phone: nil) }

      it "doesn't send a text" do
        expect(notifications_client).not_to receive(:send_sms)
        perform
      end
    end

    context "when the parent phone number is invalid" do
      before do
        allow(notifications_client).to receive(:send_sms).and_raise(
          Notifications::Client::BadRequestError.new(
            OpenStruct.new(
              code: 400,
              body: "InvalidPhoneError: Not a UK mobile number"
            )
          )
        )
      end

      it "creates a log entry for the failure" do
        expect { perform }.to change(NotifyLogEntry, :count).by(1)

        notify_log_entry = NotifyLogEntry.last
        expect(notify_log_entry).to be_sms
        expect(notify_log_entry).to be_not_uk_mobile_number_failure
        expect(notify_log_entry.delivery_id).to be_nil
        expect(notify_log_entry.recipient).to eq("01234 567890")
        expect(notify_log_entry.template_id).to eq(
          NotifyTemplate.find(template_name, channel: :sms).id
        )
        expect(notify_log_entry.purpose).to eq("consent_request")
        expect(notify_log_entry.consent_form).to eq(consent_form)
        expect(notify_log_entry.programmes.map(&:type)).to eq(programme_types)
        expect(notify_log_entry.sent_by).to eq(sent_by)
      end
    end
  end
end
