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

  it "collects objective-mapped question responses as assessment evidence" do
    scenario = build_learning_scenario
    assessment_data = build_assessment_for(scenario)
    attempt = AssessmentAttempt.create!(
      organization: scenario.fetch(:organization),
      student: scenario.fetch(:student),
      assessment: assessment_data.fetch(:assessment),
      section: scenario.fetch(:section),
      external_ref: "ATTEMPT-1",
      attempt_number: 1,
      status: "submitted",
      submitted_at: Time.current,
      synthetic: true
    )
    response = attempt.question_responses.create!(
      organization: scenario.fetch(:organization),
      assessment_question: assessment_data.fetch(:questions).first,
      selected_answer: "A",
      correct: false,
      points_earned: 0,
      submitted_at: Time.current
    )
    attempt.recalculate_score!
    investigation = Investigation.create!(
      organization: scenario.fetch(:organization),
      school: scenario.fetch(:school),
      student_signal: scenario.fetch(:signal),
      teacher: scenario.fetch(:teacher),
      status: "queued",
      current_step: "queued"
    )

    described_class.new(investigation:, provider: Ai::Providers::DeterministicProvider.new).call

    evidence = investigation.retrieved_evidences.find_by!(source_type: "QuestionResponse", source_id: response.id)
    expect(evidence).to have_attributes(citation_id: "A1", evidence_type: "assessment_response")
    expect(evidence.excerpt).to include("answered \"A\"", "incorrect")
  end
end
