require "rails_helper"

RSpec.describe Investigations::Orchestrator do
  it "persists a cited observation, editable plan, agent run, and audit event" do
    scenario = build_learning_scenario
    investigation = Investigation.create!(
      organization: scenario.fetch(:organization),
      school: scenario.fetch(:school),
      student_signal: scenario.fetch(:signal),
      teacher: scenario.fetch(:teacher),
      status: "queued",
      current_step: "queued"
    )

    described_class.new(investigation:, provider: Ai::Providers::DeterministicProvider.new).call
    investigation.reload

    expect(investigation).to have_attributes(status: "completed", current_step: "ready_for_review")
    expect(investigation.retrieved_evidences.count).to eq(5)
    expect(investigation.investigation_observations.first.retrieved_evidences).not_to be_empty
    expect(investigation.intervention_plan).to have_attributes(status: "draft")
    expect(investigation.intervention_plan.intervention_actions.count).to eq(3)
    expect(investigation.agent_runs.first).to have_attributes(status: "completed", provider: "deterministic")
    expect(scenario.fetch(:organization).audit_events.last.action).to eq("investigation.completed")
  end
end
