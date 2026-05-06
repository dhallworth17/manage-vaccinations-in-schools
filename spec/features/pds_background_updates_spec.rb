# frozen_string_literal: true

describe "PDS background updates" do
  scenario "Patients are updated in the background from PDS" do
    given_pds_integration_is_enabled
    and_a_patient_without_an_nhs_number_exists

    when_the_background_jobs_run
    then_i_see_all_patients_updated
  end

  def given_pds_integration_is_enabled
    Flipper.enable(:pds)
    Flipper.enable(:pds_enqueue_bulk_updates)
    Flipper.enable(:pds_search_during_import)
  end

  def and_a_patient_without_an_nhs_number_exists
    @patient_without_nhs_number = create(:patient, nhs_number: nil)

    stub_pds_search_to_return_a_patient(
      "9000000009",
      "family" => @patient_without_nhs_number.family_name,
      "given" => @patient_without_nhs_number.given_name,
      "birthdate" => "eq#{@patient_without_nhs_number.date_of_birth.iso8601}",
      "address-postalcode" => @patient_without_nhs_number.address_postcode
    )

    stub_pds_get_nhs_number_to_return_a_patient("9000000009")
  end

  def when_the_background_jobs_run
    EnqueueUpdatePatientsFromPDSJob.perform_async

    2.times { Sidekiq::Job.drain_all }
  end

  def then_i_see_all_patients_updated
    expect(@patient_without_nhs_number.reload.nhs_number).to eq("9000000009")
  end
end
