require "rails_helper"

RSpec.describe "Student data imports" do
  def sign_in(teacher)
    post session_path, params: { email_address: teacher.email_address, password: "test-password" }
  end

  def uploaded_csv(content, filename: "students.csv", content_type: "text/csv")
    file = Tempfile.new([ "student-data", File.extname(filename) ])
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, content_type, original_filename: filename)
  end

  it "uploads, previews, and confirms a roster CSV" do
    scenario = build_learning_scenario
    sign_in(scenario.fetch(:teacher))

    post student_data_imports_path, params: {
      student_data_import: {
        import_type: "roster",
        section_id: scenario.fetch(:section).id,
        file: uploaded_csv("student_external_ref,first_name,last_initial\nSYN-3001,Riley,T\n")
      }
    }

    data_import = StudentDataImport.order(:id).last
    expect(response).to redirect_to(student_data_import_path(data_import))
    expect(data_import).to have_attributes(status: "previewed", total_rows: 1, valid_rows: 1)

    expect do
      post confirm_student_data_import_path(data_import)
    end.to change(Student, :count).by(1).and change(Enrollment, :count).by(1)
    expect(response).to redirect_to(student_data_import_path(data_import))
  end

  it "renders row-level validation errors without changing student data" do
    scenario = build_learning_scenario
    sign_in(scenario.fetch(:teacher))

    expect do
      post student_data_imports_path, params: {
        student_data_import: {
          import_type: "mastery",
          section_id: scenario.fetch(:section).id,
          file: uploaded_csv("student_external_ref,objective_code,score,observed_on,source\nmissing,wrong,120,07/20/2026,Quiz\n")
        }
      }
    end.not_to change(MasterySnapshot, :count)

    data_import = StudentDataImport.order(:id).last
    expect(data_import).to have_attributes(status: "invalid")
    get student_data_import_path(data_import)
    expect(response.body).to include("Fix these CSV errors", "must be between 0 and 100", "must use YYYY-MM-DD")
  end

  it "rejects non-CSV files" do
    scenario = build_learning_scenario
    sign_in(scenario.fetch(:teacher))

    post student_data_imports_path, params: {
      student_data_import: {
        import_type: "roster",
        section_id: scenario.fetch(:section).id,
        file: uploaded_csv("not csv", filename: "students.txt", content_type: "text/plain")
      }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("File must use a .csv filename")
  end

  it "does not allow a teacher to target another tenant's section" do
    scenario = build_learning_scenario
    other = build_learning_scenario
    sign_in(scenario.fetch(:teacher))

    expect do
      post student_data_imports_path, params: {
        student_data_import: {
          import_type: "roster",
          section_id: other.fetch(:section).id,
          file: uploaded_csv("student_external_ref,first_name,last_initial\nSYN-3001,Riley,T\n")
        }
      }
    end.not_to change(StudentDataImport, :count)
    expect(response).to have_http_status(:not_found)
  end

  it "serves exact CSV templates" do
    scenario = build_learning_scenario
    sign_in(scenario.fetch(:teacher))

    get template_student_data_imports_path(import_type: "mastery")

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/csv")
    expect(response.body.lines.first.chomp).to eq("student_external_ref,objective_code,score,observed_on,source")
  end
end
