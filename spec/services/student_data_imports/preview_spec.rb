require "rails_helper"

RSpec.describe StudentDataImports::Preview do
  it "marks unexpected parser failures without exposing internals or changing student data" do
    scenario = build_learning_scenario
    data_import = build_student_data_import(
      scenario,
      import_type: "roster",
      csv: "student_external_ref,first_name,last_initial\nSYN-2001,Avery,K\n"
    )
    allow(StudentDataImports::Parse).to receive(:new).and_raise(StandardError, "sensitive parser detail")

    student_count = Student.count
    expect do
      described_class.new(data_import:).call
    end.to raise_error(described_class::PreviewError, "The CSV preview failed.")

    expect(Student.count).to eq(student_count)
    expect(data_import.reload).to have_attributes(
      status: "failed",
      failure_message: "The CSV could not be previewed. No student data was changed."
    )
    expect(data_import.failure_message).not_to include("sensitive")
    expect(scenario.fetch(:organization).audit_events.last.action).to eq("student_data_import.preview_failed")
  end
end
