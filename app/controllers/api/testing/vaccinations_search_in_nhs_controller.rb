# frozen_string_literal: true

class API::Testing::VaccinationsSearchInNHSController < API::Testing::BaseController
  def create
    EnqueueVaccinationsSearchInNHSJob.perform_async
    render status: :accepted
  end

  def show
    queue = Sidekiq::Queue.new("immunisations_api_search")
    # rubocop:disable Style/ZeroLengthPredicate -- Sidekiq::Queue has no #empty?
    render status: queue.size.zero? ? :ok : :accepted
    # rubocop:enable Style/ZeroLengthPredicate
  end
end
