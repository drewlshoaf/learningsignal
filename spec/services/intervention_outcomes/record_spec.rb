require "rails_helper"

RSpec.describe InterventionOutcomes::Record do
  def completed_attributes(score: 82)
    {
      status: "completed",
      effectiveness: "effective",
      follow_up_mastery_score: score,
      teacher_assessment: "The student now distinguishes slope from the y-intercept.",
      student_completed: true,
      notes: "Recheck transfer next week."
    }
  end

  it "records an audited closed loop and creates mastery evidence for an entered score" do
    scenario = build_learning_scenario
    plan = build_approved_plan(scenario)
    completed_action = plan.intervention_actions.first

    outcome = described_class.call(
      outcome: plan.build_intervention_outcome,
      actor: scenario.fetch(:teacher),
      attributes: completed_attributes,
      completed_action_ids: [ completed_action.id ],
      request_id: "request-1"
    )

    expect(outcome).to have_attributes(status: "completed", follow_up_mastery_score: 82, student_completed: true)
    expect(completed_action.reload.completion_status).to eq("completed")
    expect(plan.intervention_actions.second.reload.completion_status).to eq("pending")
    expect(scenario.fetch(:signal).reload.status).to eq("resolved")
    expect(scenario.fetch(:student).mastery_snapshots.find_by!(source: "Intervention outcome #{outcome.id}").score).to eq(82)
    expect(scenario.fetch(:organization).audit_events.last).to have_attributes(
      auditable: outcome,
      action: "intervention_outcome.created",
      request_id: "request-1"
    )
  end

  it "can select existing post-approval mastery without duplicating it" do
    scenario = build_learning_scenario
    plan = build_approved_plan(scenario)
    selected = MasterySnapshot.create!(
      organization: scenario.fetch(:organization),
      section: scenario.fetch(:section),
      student: scenario.fetch(:student),
      learning_objective: scenario.fetch(:objective),
      score: 88,
      observed_on: Date.current,
      source: "Follow-up assessment"
    )

    expect do
      outcome = described_class.call(
        outcome: plan.build_intervention_outcome,
        actor: scenario.fetch(:teacher),
        attributes: completed_attributes(score: 70),
        completed_action_ids: [],
        mastery_snapshot_id: selected.id
      )
      expect(outcome.follow_up_mastery_score).to eq(88)
    end.not_to change(MasterySnapshot, :count)
  end

  it "keeps in-progress outcomes out of mastery history and reopens the signal" do
    scenario = build_learning_scenario
    plan = build_approved_plan(scenario)
    scenario.fetch(:signal).update!(status: "resolved")

    outcome = described_class.call(
      outcome: plan.build_intervention_outcome,
      actor: scenario.fetch(:teacher),
      attributes: { status: "in_progress", student_completed: false },
      completed_action_ids: []
    )

    expect(outcome).to be_persisted
    expect(outcome).not_to be_completed
    expect(scenario.fetch(:signal).reload.status).to eq("open")
    expect(scenario.fetch(:student).mastery_snapshots.where("source LIKE ?", "Intervention outcome %")).to be_empty
  end
end
