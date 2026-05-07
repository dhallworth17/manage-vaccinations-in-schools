# frozen_string_literal: true

describe "Consent forms" do
  let(:team) { create(:team) }
  let(:nurse) { create(:nurse, teams: [team]) }

  describe "q → query redirect" do
    let(:team) { create(:team) }
    let(:nurse) { create(:nurse, teams: [team]) }

    before do
      sign_in nurse
      2.times { follow_redirect! }
    end

    it "redirects GET /consent-forms?q= to ?query= with 301" do
      get "/consent-forms", params: { q: "alice" }
      expect(response).to redirect_to("/consent-forms?query=alice")
      expect(response).to have_http_status(:moved_permanently)
    end

    it "redirects GET /consent-forms/:id/search?q= to ?query= with 301" do
      get "/consent-forms/1/search", params: { q: "alice" }
      expect(response).to redirect_to("/consent-forms/1/search?query=alice")
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe "downloading paper version" do
    let(:path) { "/consent-form/mmr" }

    before do
      sign_in nurse
      2.times { follow_redirect! }
    end

    it "downloads a PDF file with a suitable filename" do
      get path
      expect(response.headers["Content-Type"]).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to include(
        "filename=\"MMR Consent Form.pdf\""
      )
    end
  end
end
