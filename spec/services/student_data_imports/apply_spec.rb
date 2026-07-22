require "rails_helper"

RSpec.describe StudentDataImports::Apply do
  it "creates synthetic students and enrollments after a valid preview" do
    scenario = build_learning_scenario
    data_import = build_student_data_import(
      scenario,
      import_type: "roster",
      csv: <<~CSV
        student_external_ref,first_name,last_initial
        SYN-2001,Avery,K
        SYN-2002,Jordan,M
      CSV
    )
    StudentDataImports::Preview.new(data_import:).call

    expect do
      described_class.new(data_import:).call
    end.to change(Student, :count).by(2).and change(Enrollment, :count).by(2)

    expect(data_import.reload).to have_attributes(
      status: "completed",
      applied_summary: {
        "students_created" => 2,
        "students_updated" => 0,
        "enrollments_created" => 2,
        "signals_detected" => 0
      }
    )
    expect(Student.where(external_ref: %w[SYN-2001 SYN-2002])).to all(have_attributes(synthetic: true))
    expect(scenario.fetch(:organization).audit_events.last.action).to eq("student_data_import.completed")
  end

  it "upserts mastery snapshots and runs section-scoped signal detection" do
    scenario = build_learning_scenario
    external_ref = scenario.fetch(:student).external_ref
    objective_code = scenario.fetch(:objective).code
    data_import = build_student_data_import(
      scenario,
      import_type: "mastery",
      csv: <<~CSV
        student_external_ref,objective_code,score,observed_on,source
        #{external_ref},#{objective_code},82,#{1.day.ago.to_date.iso8601},Imported benchmark
        #{external_ref},#{objective_code},60,#{Date.current.iso8601},Imported benchmark
      CSV
    )
    StudentDataImports::Preview.new(data_import:).call

    expect do
      described_class.new(data_import:).call
    end.to change(MasterySnapshot, :count).by(2).and change(StudentSignal, :count).by(1)

    expect(data_import.reload.applied_summary).to include(
      "snapshots_created" => 2,
      "snapshots_updated" => 0,
      "signals_detected" => 1
    )
    expect(scenario.fetch(:student).mastery_snapshots.order(:observed_on).last.section).to eq(scenario.fetch(:section))
  end

  it "is idempotent when a completed import is deliberately replayed" do
    scenario = build_learning_scenario
    data_import = build_student_data_import(
      scenario,
      import_type: "roster",
      csv: "student_external_ref,first_name,last_initial\nSYN-2001,Avery,K\n"
    )
    StudentDataImports::Preview.new(data_import:).call
    described_class.new(data_import:).call
    data_import.update!(status: "previewed")

    expect do
      described_class.new(data_import:).call
    end.not_to change { [ Student.count, Enrollment.count ] }
    expect(data_import.reload.applied_summary).to include(
      "students_created" => 0,
      "students_updated" => 1,
      "enrollments_created" => 0
    )
  end

  it "revalidates the source and saves no rows when references changed after preview" do
    scenario = build_learning_scenario
    external_ref = scenario.fetch(:student).external_ref
    objective = scenario.fetch(:objective)
    data_import = build_student_data_import(
      scenario,
      import_type: "mastery",
      csv: <<~CSV
        student_external_ref,objective_code,score,observed_on,source
        #{external_ref},#{objective.code},55,#{Date.current.iso8601},Imported quiz
      CSV
    )
    StudentDataImports::Preview.new(data_import:).call
    scenario.fetch(:section).enrollments.find_by!(student: scenario.fetch(:student)).destroy!

    expect do
      described_class.new(data_import:).call
    end.not_to change(MasterySnapshot, :count)
    expect(data_import.reload).to have_attributes(status: "invalid", error_count: 1)
  end
end
