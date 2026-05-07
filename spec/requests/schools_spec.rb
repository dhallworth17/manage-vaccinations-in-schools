# frozen_string_literal: true

describe "Schools" do
  let(:team) { create(:team) }
  let(:nurse) { create(:nurse, teams: [team]) }

  before do
    sign_in nurse
    2.times { follow_redirect! }
  end

  describe "GET /schools" do
    it "redirects q to query with a 301" do
      get "/schools", params: { q: "Waterloo" }
      expect(response).to redirect_to("/schools?query=Waterloo")
      expect(response).to have_http_status(:moved_permanently)
    end
  end

  describe "GET /schools/:school_urn_and_site/patients" do
    let(:school) { create(:gias_school) }

    before do
      create(
        :team_location,
        team:,
        location: school,
        academic_year: AcademicYear.pending
      )
    end

    it "redirects q to query with a 301" do
      get "/schools/#{school.urn}/patients", params: { q: "alice" }
      expect(response).to redirect_to(
        "/schools/#{school.urn}/patients?query=alice"
      )
      expect(response).to have_http_status(:moved_permanently)
    end
  end
end
