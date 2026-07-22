require "rails_helper"

RSpec.describe StudentDataImports::Apply do
  it "upserts assessments and questions while calculating the assessment maximum" do
    scenario = build_learning_scenario
    data_import = build_student_data_import(
      scenario,
      import_type: "assessment_catalog",
      csv: <<~CSV
        assessment_external_ref,assessment_title,assessment_type,assessment_status,question_external_ref,objective_code,prompt_reference,question_type,maximum_points,answer_key
        CHECK-1,Linear Check,quiz,published,Q1,#{scenario.fetch(:objective).code},Slope from points,multiple_choice,2,B
        CHECK-1,Linear Check,quiz,published,Q2,#{scenario.fetch(:objective).code},Slope vs intercept,multiple_choice,3,C
      CSV
    )
    StudentDataImports::Preview.new(data_import:).call

    expect do
      described_class.new(data_import:).call
    end.to change(Assessment, :count).by(1).and change(AssessmentQuestion, :count).by(2)

    assessment = Assessment.find_by!(external_ref: "CHECK-1")
    expect(assessment.maximum_score).to eq(5)
    expect(data_import.reload.applied_summary).to include(
      "assessments_created" => 1,
      "questions_created" => 2
    )
  end

  it "calculates response correctness, attempt score, and objective mastery from raw answers" do
    scenario = build_learning_scenario
    assessment_data = build_assessment_for(scenario)
    data_import = build_student_data_import(
      scenario,
      import_type: "assessment_responses",
      csv: <<~CSV
        attempt_external_ref,assessment_external_ref,student_external_ref,attempt_number,question_external_ref,selected_answer,response_text,submitted_at,status
        ATTEMPT-1,#{assessment_data.fetch(:assessment).external_ref},#{scenario.fetch(:student).external_ref},1,Q1,b,,2026-07-20T15:30:00Z,submitted
        ATTEMPT-1,#{assessment_data.fetch(:assessment).external_ref},#{scenario.fetch(:student).external_ref},1,Q2,A,,2026-07-20T15:30:00Z,submitted
      CSV
    )
    StudentDataImports::Preview.new(data_import:).call

    expect do
      described_class.new(data_import:).call
    end.to change(AssessmentAttempt, :count).by(1)
      .and change(QuestionResponse, :count).by(2)
      .and change(MasterySnapshot, :count).by(1)

    attempt = AssessmentAttempt.find_by!(external_ref: "ATTEMPT-1")
    expect(attempt).to have_attributes(score: 2, maximum_score: 4, percentage: 50)
    expect(attempt.question_responses.order(:assessment_question_id).pluck(:correct, :points_earned)).to eq([
      [ true, 2.to_d ], [ false, 0.to_d ]
    ])
    expect(attempt.student.mastery_snapshots.find_by!(source: "Assessment attempt ATTEMPT-1").score).to eq(50)
  end

  it "updates an existing synthetic attempt without duplicating responses or mastery" do
    scenario = build_learning_scenario
    assessment_data = build_assessment_for(scenario)
    csv = <<~CSV
      attempt_external_ref,assessment_external_ref,student_external_ref,attempt_number,question_external_ref,selected_answer,response_text,submitted_at,status
      ATTEMPT-1,#{assessment_data.fetch(:assessment).external_ref},#{scenario.fetch(:student).external_ref},1,Q1,B,,2026-07-20T15:30:00Z,submitted
    CSV
    first_import = build_student_data_import(scenario, import_type: "assessment_responses", csv:)
    StudentDataImports::Preview.new(data_import: first_import).call
    described_class.new(data_import: first_import).call
    expect(AssessmentAttempt.find_by!(external_ref: "ATTEMPT-1")).to have_attributes(score: 2, maximum_score: 4, percentage: 50)
    expect(MasterySnapshot.find_by!(source: "Assessment attempt ATTEMPT-1").score).to eq(50)

    second_import = build_student_data_import(scenario, import_type: "assessment_responses", csv: csv.sub("B,,", "A,,"), filename: "responses-corrected.csv")
    StudentDataImports::Preview.new(data_import: second_import).call

    expect do
      described_class.new(data_import: second_import).call
    end.not_to change { [ AssessmentAttempt.count, QuestionResponse.count, MasterySnapshot.count ] }
    expect(AssessmentAttempt.find_by!(external_ref: "ATTEMPT-1")).to have_attributes(score: 0, percentage: 0)
  end
end
