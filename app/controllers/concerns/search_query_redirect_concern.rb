# frozen_string_literal: true

module SearchQueryRedirectConcern
  extend ActiveSupport::Concern

  included do
    before_action :redirect_q_to_query,
                  if: -> { params[:q].present? && params[:query].blank? }
  end

  private

  def redirect_q_to_query
    params =
      request
        .query_parameters
        .except(:q)
        .merge(query: request.query_parameters[:q])
    redirect_to url_for(params:), status: :moved_permanently
  end
end
