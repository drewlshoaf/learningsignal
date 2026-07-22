require "rails_helper"

RSpec.describe "Curriculum documents" do
  include ActiveJob::TestHelper

  def sign_in(teacher)
    post session_path, params: { email_address: teacher.email_address, password: "test-password" }
  end

  def uploaded_file(content_type: "application/pdf")
    file = Tempfile.new([ "curriculum", content_type == "application/pdf" ? ".pdf" : ".txt" ])
    file.write(content_type == "application/pdf" ? "%PDF-1.4 local request fixture" : "plain text is not a PDF")
    file.rewind
    Rack::Test::UploadedFile.new(file.path, content_type, original_filename: File.basename(file.path))
  end

  it "queues an authorized PDF for local ingestion" do
    scenario = build_learning_scenario
    sign_in(scenario.fetch(:teacher))

    expect do
      post curriculum_documents_path, params: {
        curriculum_document: {
          title: "Linear relationships guide",
          source_label: "Teacher upload",
          learning_objective_id: scenario.fetch(:objective).id,
          file: uploaded_file
        }
      }
    end.to have_enqueued_job(CurriculumIngestionJob).on_queue("ingestion")

    document = CurriculumDocument.order(:id).last
    expect(response).to redirect_to(curriculum_document_path(document))
    expect(document).to have_attributes(
      organization: scenario.fetch(:organization),
      course: scenario.fetch(:course),
      learning_objective: scenario.fetch(:objective),
      uploaded_by: scenario.fetch(:teacher),
      status: "pending"
    )
    expect(document.file).to be_attached
  end

  it "rejects a non-PDF upload" do
    scenario = build_learning_scenario
    sign_in(scenario.fetch(:teacher))

    expect do
      post curriculum_documents_path, params: {
        curriculum_document: {
          title: "Not a PDF",
          source_label: "Teacher upload",
          learning_objective_id: scenario.fetch(:objective).id,
          file: uploaded_file(content_type: "text/plain")
        }
      }
    end.not_to have_enqueued_job(CurriculumIngestionJob)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("File must be a PDF")
  end

  it "rejects a duplicate PDF within the same tenant" do
    scenario = build_learning_scenario
    sign_in(scenario.fetch(:teacher))
    attributes = {
      title: "First copy",
      source_label: "Teacher upload",
      learning_objective_id: scenario.fetch(:objective).id,
      file: uploaded_file
    }
    post curriculum_documents_path, params: { curriculum_document: attributes }

    expect do
      post curriculum_documents_path, params: {
        curriculum_document: attributes.merge(title: "Duplicate copy", file: uploaded_file)
      }
    end.not_to have_enqueued_job(CurriculumIngestionJob)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("File checksum has already been taken")
  end

  it "does not expose another tenant's curriculum document" do
    scenario = build_learning_scenario
    other = build_learning_scenario
    sign_in(scenario.fetch(:teacher))

    get curriculum_document_path(other.fetch(:course).curriculum_documents.first)

    expect(response).to redirect_to(root_path)
  end

  it "allows the uploader to retry a failed ingestion" do
    scenario = build_learning_scenario
    sign_in(scenario.fetch(:teacher))
    post curriculum_documents_path, params: {
      curriculum_document: {
        title: "Retryable PDF",
        source_label: "Teacher upload",
        learning_objective_id: scenario.fetch(:objective).id,
        file: uploaded_file
      }
    }
    document = CurriculumDocument.order(:id).last
    document.update!(status: "failed", failure_message: "Temporary extraction failure")

    expect do
      post reprocess_curriculum_document_path(document)
    end.to have_enqueued_job(CurriculumIngestionJob).on_queue("ingestion")

    expect(response).to redirect_to(curriculum_document_path(document))
    expect(document.reload).to have_attributes(status: "pending", failure_message: nil)
  end
end
