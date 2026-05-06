# frozen_string_literal: true

class BackfillNHSNumberFirstAddedAtForPatients < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  BATCH_SIZE = 1000

  def up
    migration = self.class.name
    started_at = Time.zone.now
    scope = Patient.where(nhs_number_first_added_at: nil).where.not(nhs_number: nil)
    total_records = scope.count
    total_batches = (total_records.to_f / BATCH_SIZE).ceil
    records_updated = 0

    Rails.logger.info(
      event: "data_migration_start",
      migration:,
      total_records:,
      batch_size: BATCH_SIZE,
      total_batches:
    )

    scope.in_batches(of: BATCH_SIZE).each_with_index do |batch, index|
      updated_count = batch.update_all("nhs_number_first_added_at = created_at")
      records_updated += updated_count

      Rails.logger.info(
        event: "data_migration_batch",
        migration:,
        batch_number: index + 1,
        total_batches:,
        updated_count:,
        records_updated:
      )
    end

    duration_minutes = ((Time.zone.now - started_at) / 60.0).round

    Rails.logger.info(
      event: "data_migration_finish",
      migration:,
      duration_minutes:,
      records_updated:
    )
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end