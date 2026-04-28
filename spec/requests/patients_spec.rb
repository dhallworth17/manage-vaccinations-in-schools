# frozen_string_literal: true

describe "Patients" do
  let(:team) { create(:team) }
  let(:nurse) { create(:nurse, teams: [team]) }

  before do
    sign_in nurse
    2.times { follow_redirect! }
  end

  describe "GET /patients" do
    it "redirects q to query with a 301" do
      get "/patients", params: { q: "alice" }
      expect(response).to redirect_to("/patients?query=alice")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "preserves other params when redirecting q to query" do
      get "/patients", params: { q: "alice", missing_nhs_number: true }
      expect(response).to redirect_to(
        "/patients?missing_nhs_number=true&query=alice"
      )
    end
  end
end
