# frozen_string_literal: true

describe "Draft vaccination records" do
  let(:team) { create(:team) }
  let(:nurse) { create(:nurse, teams: [team]) }

  before do
    sign_in nurse
    2.times { follow_redirect! }
  end

  describe "GET /draft-vaccination-record/:id" do
    it "redirects q to query with a 301" do
      get "/draft-vaccination-record/1", params: { q: "alice" }
      expect(response).to redirect_to("/draft-vaccination-record/1?query=alice")
      expect(response).to have_http_status(:moved_permanently)
    end
  end
end
