class CurriculumDocumentsController < ApplicationController
  before_action :set_document, only: %i[show reprocess]
  before_action :load_objectives, only: %i[new create]

  def index
    authorize CurriculumDocument
    @documents = policy_scope(CurriculumDocument)
      .includes(:course, :learning_objective, :uploaded_by, file_attachment: :blob)
      .order(created_at: :desc)
  end

  def show
    authorize @document
    @chunks = @document.document_chunks.order(:id)
  end

  def new
    @document = CurriculumDocument.new(organization: Current.organization, status: "pending")
    authorize @document
  end

  def create
    objective = policy_scope(LearningObjective).includes(:course).find(document_params[:learning_objective_id])
    @document = CurriculumDocument.new(document_params.except(:learning_objective_id))
    @document.assign_attributes(
      organization: objective.organization,
      course: objective.course,
      learning_objective: objective,
      uploaded_by: current_user,
      status: "pending"
    )
    authorize @document

    if @document.save
      Audit::Record.call(
        organization: @document.organization,
        school: @document.course.school,
        user: current_user,
        auditable: @document,
        action: "curriculum_document.uploaded",
        changes: { filename: @document.file.filename.to_s, byte_size: @document.file.byte_size },
        request_id: request.request_id
      )
      CurriculumIngestionJob.perform_later(@document.id)
      redirect_to curriculum_document_path(@document), notice: "Curriculum PDF uploaded and queued for processing."
    else
      render :new, status: :unprocessable_content
    end
  end

  def reprocess
    authorize @document, :reprocess?
    @document.update!(status: "pending", failure_message: nil)
    CurriculumIngestionJob.perform_later(@document.id)
    redirect_to curriculum_document_path(@document), notice: "Curriculum PDF queued again."
  end

  private

  def set_document
    @document = CurriculumDocument.includes(:course, :learning_objective, :uploaded_by, file_attachment: :blob).find(params[:id])
  end

  def load_objectives
    @objectives = policy_scope(LearningObjective).joins(:course).includes(:course).order("courses.name", :code)
  end

  def document_params
    params.require(:curriculum_document).permit(:title, :source_label, :learning_objective_id, :file)
  end
end
