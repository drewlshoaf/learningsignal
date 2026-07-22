require "rails_helper"

RSpec.describe StudentDataImports::AssessmentResponsesParser do
  it "accepts raw responses for an enrolled student and known question" do
    scenario = build_learning_scenario
    assessment_data = build_assessment_for(scenario)
    data_import = build_student_data_import(
      scenario,
      import_type: "assessment_responses",
      csv: <<~CSV
        attempt_external_ref,assessment_external_ref,student_external_ref,attempt_number,question_external_ref,selected_answer,response_text,submitted_at,status
        ATTEMPT-1,#{assessment_data.fetch(:assessment).external_ref},#{scenario.fetch(:student).external_ref},1,Q1,B,,2026-07-20T15:30:00Z,submitted
      CSV
    )

    result = described_class.new(data_import:, path: attachment_path(data_import)).call

    expect(result.errors).to be_empty
    expect(result.rows.first).to include("attempt_number" => 1, "submitted_at" => "2026-07-20T15:30:00Z")
  end

  it "rejects unknown students, questions, and conflicting attempt rows" do
    scenario = build_learning_scenario
    assessment_data = build_assessment_for(scenario)
    data_import = build_student_data_import(
      scenario,
      import_type: "assessment_responses",
      csv: <<~CSV
        attempt_external_ref,assessment_external_ref,student_external_ref,attempt_number,question_external_ref,selected_answer,response_text,submitted_at,status
        ATTEMPT-1,#{assessment_data.fetch(:assessment).external_ref},missing,1,Q1,B,,2026-07-20T15:30:00Z,submitted
        ATTEMPT-1,#{assessment_data.fetch(:assessment).external_ref},#{scenario.fetch(:student).external_ref},2,missing,C,,2026-07-21T15:30:00Z,submitted
      CSV
    )

    result = described_class.new(data_import:, path: attachment_path(data_import)).call

    expect(result.errors.map { |error| error.fetch("field") }).to include(
      "student_external_ref", "question_external_ref", "attempt_external_ref"
    )
  end

  def attachment_path(data_import)
    data_import.file.blob.service.path_for(data_import.file.key)
  end
end
