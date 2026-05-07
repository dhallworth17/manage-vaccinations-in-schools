# frozen_string_literal: true

describe ProcessImportJob do
  subject(:perform) { described_class.new.perform(import.to_global_id.to_s) }

  before do
    allow(GlobalID::Locator).to receive(:locate).with(
      import.to_global_id.to_s
    ).and_return(import)
  end

  after { perform }

  context "with a class import" do
    let(:import) { create(:class_import) }

    it "parses and processes the rows" do
      expect(import).to receive(:parse_rows!)
      expect(import).to receive(:process!)
    end
  end

  context "with a cohort import" do
    let(:import) { create(:cohort_import) }

    it "parses and processes the rows" do
      expect(import).to receive(:parse_rows!)
      expect(import).to receive(:process!)
    end
  end

  context "with an immunisation import" do
    let(:import) { create(:immunisation_import) }

    it "parses and processes the rows" do
      expect(import).to receive(:parse_rows!)
      expect(import).to receive(:process!)
    end
  end
end
