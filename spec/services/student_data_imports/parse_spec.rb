require "rails_helper"

RSpec.describe StudentDataImports::Parse do
  it "normalizes a valid roster and preserves source line numbers" do
    scenario = build_learning_scenario
    data_import = build_student_data_import(
      scenario,
      import_type: "roster",
      csv: "student_external_ref,first_name,last_initial\nSYN-2001, Avery , k \n"
    )

    result = described_class.new(data_import:).call

    expect(result.errors).to be_empty
    expect(result.total_rows).to eq(1)
    expect(result.rows).to eq([
      {
        "student_external_ref" => "SYN-2001",
        "first_name" => "Avery",
        "last_initial" => "K",
        "line" => 2
      }
    ])
  end

  it "reports exact header, field, and duplicate errors without returning invalid rows" do
    scenario = build_learning_scenario
    data_import = build_student_data_import(
      scenario,
      import_type: "roster",
      csv: "student_external_ref,first_name,last_initial\nSYN-2001,Avery,K\nSYN-2001,,22\n"
    )

    result = described_class.new(data_import:).call

    expect(result.rows.length).to eq(1)
    expect(result.errors).to include(
      hash_including("line" => 3, "field" => "first_name", "message" => "is required"),
      hash_including("line" => 3, "field" => "last_initial", "message" => "must be one letter")
    )
  end

  it "rejects mastery references outside the selected section and course" do
    scenario = build_learning_scenario
    other = build_learning_scenario
    data_import = build_student_data_import(
      scenario,
      import_type: "mastery",
      csv: <<~CSV
        student_external_ref,objective_code,score,observed_on,source
        #{other.fetch(:student).external_ref},#{other.fetch(:objective).code},61,2026-07-20,Quiz
      CSV
    )

    result = described_class.new(data_import:).call

    expect(result.rows).to be_empty
    expect(result.errors.map { |error| error.fetch("field") }).to contain_exactly("student_external_ref", "objective_code")
  end

  it "requires the exact template headers" do
    scenario = build_learning_scenario
    data_import = build_student_data_import(
      scenario,
      import_type: "mastery",
      csv: "student_id,objective,score,date,source\nSYN-1,ALG1,50,2026-07-20,Quiz\n"
    )

    result = described_class.new(data_import:).call

    expect(result.errors.first).to include("line" => 1, "field" => "headers")
    expect(result.errors.first.fetch("message")).to include("missing:", "unexpected:")
  end

  it "does not overwrite an existing non-synthetic student" do
    scenario = build_learning_scenario
    scenario.fetch(:student).update!(synthetic: false)
    data_import = build_student_data_import(
      scenario,
      import_type: "roster",
      csv: "student_external_ref,first_name,last_initial\n#{scenario.fetch(:student).external_ref},Changed,N\n"
    )

    result = described_class.new(data_import:).call

    expect(result.rows).to be_empty
    expect(result.errors.first.fetch("message")).to include("non-synthetic")
  end
end
