require "rails_helper"

RSpec.describe "Student academic profiles" do
  def sign_in(teacher)
    post session_path, params: { email_address: teacher.email_address, password: "test-password" }
  end

  it "shows tenant-scoped mastery, assessment responses, signals, and interventions" do
    scenario = build_learning_scenario
    assessment_data = build_assessment_for(scenario)
    attempt = AssessmentAttempt.create!(
      organization: scenario.fetch(:organization),
      section: scenario.fetch(:section),
      student: scenario.fetch(:student),
      assessment: assessment_data.fetch(:assessment),
      external_ref: "ATTEMPT-1",
      attempt_number: 1,
      status: "submitted",
      submitted_at: Time.current,
      synthetic: true
    )
    attempt.question_responses.create!(
      organization: scenario.fetch(:organization),
      assessment_question: assessment_data.fetch(:questions).first,
      selected_answer: "B",
      correct: true,
      points_earned: 2,
      submitted_at: Time.current
    )
    attempt.recalculate_score!
    sign_in(scenario.fetch(:teacher))

    get student_path(scenario.fetch(:student))

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(
      "Academic profile",
      "Learning-objective mastery",
      "Assessment attempts and responses",
      "Linear Relationships Check",
      "Response: B",
      scenario.fetch(:signal).title
    )
  end

  it "does not expose a student taught by another teacher in the same organization" do
    scenario = build_learning_scenario
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
    scenario.fetch(:section).update!(teacher: other_teacher)
    sign_in(scenario.fetch(:teacher))

    get student_path(scenario.fetch(:student))

    expect(response).to have_http_status(:not_found)
  end
end
