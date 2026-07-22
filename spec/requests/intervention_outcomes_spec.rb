require "rails_helper"

RSpec.describe "Intervention outcomes" do
  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "test-password" }
  end

  it "lets the section teacher record completion and see the comparison" do
    scenario = build_learning_scenario
    plan = build_approved_plan(scenario)
    sign_in(scenario.fetch(:teacher))

    get new_intervention_plan_intervention_outcome_path(plan)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Record intervention outcome", "Pre-intervention mastery", "Or select existing mastery evidence")

    post intervention_plan_intervention_outcome_path(plan), params: {
      intervention_outcome: {
        status: "completed",
        effectiveness: "effective",
        follow_up_mastery_score: "84",
        teacher_assessment: "The student transferred the strategy to a new representation.",
        student_completed: "1",
        notes: "Continue weekly checks.",
        completed_action_ids: plan.intervention_actions.pluck(:id)
      }
    }

    outcome = plan.reload.intervention_outcome
    expect(response).to redirect_to(investigation_path(plan.investigation, anchor: "intervention-outcome"))
    expect(outcome).to have_attributes(status: "completed", effectiveness: "effective", follow_up_mastery_score: 84)

    get edit_intervention_plan_intervention_outcome_path(plan)
    expect(response.body).not_to include("Intervention outcome #{outcome.id}")

    get investigation_path(plan.investigation)
    expect(response.body).to include("Pre- and post-intervention comparison", "84%")
    expect(response.body).to include("Teacher edits recorded").or include("No content edits")

    get student_path(scenario.fetch(:student))
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Intervention outcomes", "84%", "View comparison")
  end

  it "does not allow another teacher in the organization to record the outcome" do
    scenario = build_learning_scenario
    plan = build_approved_plan(scenario)
    other_teacher = User.create!(
      name: "Other Teacher",
      email_address: "other-#{SecureRandom.hex(4)}@example.test",
      password: "test-password"
    )
    Membership.create!(
      organization: scenario.fetch(:organization),
      school: scenario.fetch(:school),
      user: other_teacher,
      role: "teacher"
    )
    sign_in(other_teacher)

    expect do
      post intervention_plan_intervention_outcome_path(plan), params: {
        intervention_outcome: { status: "in_progress", student_completed: "0", completed_action_ids: [] }
      }
    end.not_to change(InterventionOutcome, :count)
    expect(response).to redirect_to(root_path)
  end

  it "renders completion requirements without partially saving an invalid outcome" do
    scenario = build_learning_scenario
    plan = build_approved_plan(scenario)
    sign_in(scenario.fetch(:teacher))

    expect do
      post intervention_plan_intervention_outcome_path(plan), params: {
        intervention_outcome: { status: "completed", student_completed: "1", completed_action_ids: [] }
      }
    end.not_to change(InterventionOutcome, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(CGI.unescapeHTML(response.body)).to include(
      "Please review the outcome details.",
      "Effectiveness can't be blank",
      "Follow up mastery score can't be blank",
      "Teacher assessment can't be blank"
    )
  end

  it "excludes in-progress outcomes from dashboard effectiveness aggregates" do
    scenario = build_learning_scenario
    completed_plan = build_approved_plan(scenario)
    pending_plan = build_approved_plan(scenario)
    InterventionOutcomes::Record.call(
      outcome: completed_plan.build_intervention_outcome,
      actor: scenario.fetch(:teacher),
      attributes: {
        status: "completed",
        effectiveness: "effective",
        follow_up_mastery_score: 80,
        teacher_assessment: "Improved.",
        student_completed: true
      },
      completed_action_ids: []
    )
    InterventionOutcomes::Record.call(
      outcome: pending_plan.build_intervention_outcome,
      actor: scenario.fetch(:teacher),
      attributes: { status: "in_progress", effectiveness: "ineffective", student_completed: false },
      completed_action_ids: []
    )
    sign_in(scenario.fetch(:teacher))

    get root_path

    expect(response.body).to include("1 completed · 100% effective")
  end
end
