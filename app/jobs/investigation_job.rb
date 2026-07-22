class InvestigationJob < ApplicationJob
  queue_as :investigations

  retry_on Ai::ProviderError, wait: :polynomially_longer, attempts: 3

  def perform(investigation_id)
    investigation = Investigation.find(investigation_id)
    Investigations::Orchestrator.new(investigation: investigation).call
  end
end
