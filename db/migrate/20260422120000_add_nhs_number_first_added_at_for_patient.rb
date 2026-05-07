# frozen_string_literal: true

class AddNHSNumberFirstAddedAtForPatient < ActiveRecord::Migration[8.1]
  def change
    add_column :patients, :nhs_number_first_added_at, :datetime
  end
end
