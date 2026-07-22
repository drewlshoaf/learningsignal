require "rails_helper"

RSpec.describe StudentDataImports::AssessmentCatalogParser do
  it "normalizes objective-mapped questions and preserves source lines" do
    scenario = build_learning_scenario
    data_import = build_student_data_import(
      scenario,
      import_type: "assessment_catalog",
      csv: <<~CSV
        assessment_external_ref,assessment_title,assessment_type,assessment_status,question_external_ref,objective_code,prompt_reference,question_type,maximum_points,answer_key
        CHECK-1,Linear Check,quiz,published,Q1,#{scenario.fetch(:objective).code},Slope from points,multiple_choice,2,B
      CSV
    )

    result = described_class.new(data_import:, path: attachment_path(data_import)).call

    expect(result.errors).to be_empty
    expect(result.rows.first).to include(
      "assessment_external_ref" => "CHECK-1",
      "question_external_ref" => "Q1",
      "maximum_points" => "2.0",
      "line" => 2
    )
  end

  it "rejects objectives outside the course and inconsistent assessment metadata" do
    scenario = build_learning_scenario
    other = build_learning_scenario
    data_import = build_student_data_import(
      scenario,
      import_type: "assessment_catalog",
      csv: <<~CSV
        assessment_external_ref,assessment_title,assessment_type,assessment_status,question_external_ref,objective_code,prompt_reference,question_type,maximum_points,answer_key
        CHECK-1,Linear Check,quiz,published,Q1,#{other.fetch(:objective).code},Slope from points,multiple_choice,2,B
        CHECK-1,Different Title,test,published,Q2,#{scenario.fetch(:objective).code},Slope vs intercept,multiple_choice,2,C
      CSV
    )

    result = described_class.new(data_import:, path: attachment_path(data_import)).call

    expect(result.errors).to include(
      hash_including("line" => 2, "field" => "objective_code"),
      hash_including("line" => 3, "field" => "assessment_external_ref", "message" => include("conflicting"))
    )
  end

  it "locks scored question fields after responses exist" do
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
      submitted_at: Time.current
    )
    attempt.question_responses.create!(
      organization: scenario.fetch(:organization),
      assessment_question: assessment_data.fetch(:questions).first,
      selected_answer: "B",
      correct: true,
      points_earned: 2
    )
    data_import = build_student_data_import(
      scenario,
      import_type: "assessment_catalog",
      csv: <<~CSV
        assessment_external_ref,assessment_title,assessment_type,assessment_status,question_external_ref,objective_code,prompt_reference,question_type,maximum_points,answer_key
        #{assessment_data.fetch(:assessment).external_ref},Linear Relationships Check,quiz,published,Q1,#{scenario.fetch(:objective).code},Slope from points,multiple_choice,2,A
      CSV
    )

    result = described_class.new(data_import:, path: attachment_path(data_import)).call

    expect(result.errors).to include(
      hash_including("field" => "question_external_ref", "message" => include("recorded responses"))
    )
  end

  def attachment_path(data_import)
    data_import.file.blob.service.path_for(data_import.file.key)
  end
end
