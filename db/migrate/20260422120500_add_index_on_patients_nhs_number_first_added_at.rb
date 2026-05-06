# frozen_string_literal: true

class AddIndexOnPatientsNHSNumberFirstAddedAt < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :patients, :nhs_number_first_added_at, algorithm: :concurrently
  end
end
