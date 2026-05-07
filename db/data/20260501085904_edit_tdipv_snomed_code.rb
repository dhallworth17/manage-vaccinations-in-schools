# frozen_string_literal: true

class EditTdipvSnomedCode < ActiveRecord::Migration[8.1]
  def up
    vaccine = Vaccine.find_by(upload_name: "Revaxis")
    Rails.logger.info "Editing vaccine #{vaccine.id}..."

    vaccine.update!(
      snomed_product_code: "7374311000001101",
      snomed_product_term: "Revaxis vaccine suspension for injection 0.5ml pre-filled syringes (Sanofi)"
    )

    Rails.logger.info "Vaccine #{vaccine.id} updated."
  end

  def down
    vaccine = Vaccine.find_by(upload_name: "Revaxis")
    Rails.logger.info "Editing vaccine #{vaccine.id}..."

    vaccine.update!(
      snomed_product_code: "7374511000001107",
      snomed_product_term: "Revaxis vaccine suspension for injection 0.5ml pre-filled syringes (Sanofi) " \
        "1 pre-filled disposable injection (product)"
    )

    Rails.logger.info "Vaccine #{vaccine.id} updated."
  end
end
