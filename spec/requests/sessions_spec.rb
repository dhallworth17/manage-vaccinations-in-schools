# frozen_string_literal: true

describe "Sessions" do
  let(:team) { create(:team) }
  let(:nurse) { create(:nurse, teams: [team]) }
  let(:session) { create(:session, team:) }

  before do
    sign_in nurse
    2.times { follow_redirect! }
  end

  describe "GET /sessions" do
    it "redirects q to query with a 301" do
      get "/sessions", params: { q: "spring" }
      expect(response).to redirect_to("/sessions?query=spring")
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe "GET /sessions/:session_slug/record" do
    it "redirects q to query with a 301" do
      get "/sessions/#{session.slug}/record", params: { q: "alice" }
      expect(response).to redirect_to(
        "/sessions/#{session.slug}/record?query=alice"
      )
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe "GET /sessions/:session_slug/patients" do
    it "redirects q to query with a 301" do
      get "/sessions/#{session.slug}/patients", params: { q: "alice" }
      expect(response).to redirect_to(
        "/sessions/#{session.slug}/patients?query=alice"
      )
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe "GET /sessions/:session_slug/patient-specific-directions" do
    it "redirects q to query with a 301" do
      get "/sessions/#{session.slug}/patient-specific-directions",
          params: {
            q: "alice"
          }
      expect(response).to redirect_to(
        "/sessions/#{session.slug}/patient-specific-directions?query=alice"
      )
      expect(response).to have_http_status(:moved_permanently)
    end
  end
end
