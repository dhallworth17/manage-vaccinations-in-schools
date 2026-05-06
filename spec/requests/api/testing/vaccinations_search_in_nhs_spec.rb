# frozen_string_literal: true

describe "/api/testing/vaccinations-search-in-nhs" do
  before { Flipper.enable(:testing_api) }

  describe "POST" do
    it "runs the enqueue job synchronously and responds with accepted" do
      expect {
        post "/api/testing/vaccinations-search-in-nhs"
      }.to enqueue_sidekiq_job(EnqueueVaccinationsSearchInNHSJob)
      expect(response).to have_http_status(:accepted)
    end
  end

  describe "GET" do
    context "when the search queue is empty" do
      before do
        allow(Sidekiq::Queue).to receive(:new).with(
          "immunisations_api_search"
        ).and_return(instance_double(Sidekiq::Queue, size: 0))
      end

      it "responds with ok" do
        get "/api/testing/vaccinations-search-in-nhs"
        expect(response).to have_http_status(:ok)
      end
    end

    context "when the search queue has pending jobs" do
      before do
        allow(Sidekiq::Queue).to receive(:new).with(
          "immunisations_api_search"
        ).and_return(instance_double(Sidekiq::Queue, size: 3))
      end

      it "responds with accepted" do
        get "/api/testing/vaccinations-search-in-nhs"
        expect(response).to have_http_status(:accepted)
      end
    end
  end
end
