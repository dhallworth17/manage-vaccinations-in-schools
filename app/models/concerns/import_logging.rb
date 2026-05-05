# frozen_string_literal: true

module ImportLogging
  def log_started
    log_with_tags(:info, "started")
  end

  def log_finished
    log_with_tags(
      :info,
      "finished",
      duration_ms: ((Time.zone.now - created_at) * 1000).to_i,
      count: rows_count
    )
  end

  def log_with_tags(log_level, *)
    SemanticLogger.tagged(id:, team_workgroup: team.workgroup) do
      logger.public_send(log_level, *)
    end
  end
end
