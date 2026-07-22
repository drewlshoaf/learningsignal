require "rails_helper"

RSpec.describe InterventionOutcome do
  it "requires completed outcomes to include follow-up evidence and assessment" do
    scenario = build_learning_scenario
    plan = build_approved_plan(scenario)
    outcome = plan.build_intervention_outcome(
      organization: scenario.fetch(:organization),
      recorded_by: scenario.fetch(:teacher),
      status: "completed",
      recorded_at: Time.current
    )

    expect(outcome).not_to be_valid
    expect(outcome.errors).to include(:effectiveness, :follow_up_mastery_score, :teacher_assessment)
  end

  it "rejects outcomes until the intervention plan is approved" do
    scenario = build_learning_scenario
    plan = build_approved_plan(scenario)
    plan.update!(status: "draft", approved_at: nil)
    outcome = plan.build_intervention_outcome(
      organization: scenario.fetch(:organization),
      recorded_by: scenario.fetch(:teacher),
      status: "in_progress",
      recorded_at: Time.current
    )

    expect(outcome).not_to be_valid
    expect(outcome.errors[:intervention_plan]).to include("must be approved before an outcome is recorded")
  end
end
