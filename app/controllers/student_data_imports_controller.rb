class StudentDataImportsController < ApplicationController
  before_action :set_data_import, only: %i[show confirm]
  before_action :load_sections, only: %i[new create]

  def index
    authorize StudentDataImport
    @data_imports = policy_scope(StudentDataImport)
      .includes(:section, :uploaded_by, file_attachment: :blob)
      .order(created_at: :desc)
  end

  def show
    authorize @data_import
  end

  def new
    @data_import = StudentDataImport.new(import_type: requested_import_type)
    authorize StudentDataImport
  end

  def create
    section = policy_scope(Section).includes(:school).find(data_import_params[:section_id])
    @data_import = StudentDataImport.new(data_import_params.except(:section_id))
    @data_import.assign_attributes(
      organization: section.organization,
      school: section.school,
      section:,
      uploaded_by: current_user,
      status: "pending"
    )
    authorize @data_import

    if @data_import.save
      StudentDataImports::Preview.new(data_import: @data_import, request_id: request.request_id).call
      if @data_import.status == "invalid"
        redirect_to student_data_import_path(@data_import), alert: "CSV uploaded. Fix the validation errors before importing."
      else
        redirect_to student_data_import_path(@data_import), notice: "CSV uploaded and validated."
      end
    else
      render :new, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordNotUnique
    @data_import.errors.add(:file, "has already been uploaded for this section and import type")
    render :new, status: :unprocessable_content
  rescue StudentDataImports::Preview::PreviewError
    redirect_to student_data_import_path(@data_import), alert: "The CSV could not be previewed. No student data was changed."
  end

  def confirm
    authorize @data_import, :confirm?
    StudentDataImports::Apply.new(data_import: @data_import, request_id: request.request_id).call
    redirect_to student_data_import_path(@data_import), notice: "Student data imported successfully."
  rescue StandardError
    redirect_to student_data_import_path(@data_import), alert: "The import failed without saving partial student data."
  end

  def template
    authorize StudentDataImport, :template?
    import_type = requested_import_type
    send_data(
      StudentDataImports::Templates.fetch(import_type),
      filename: "learningsignal-#{import_type}-template.csv",
      type: "text/csv",
      disposition: "attachment"
    )
  end

  private

  def set_data_import
    @data_import = policy_scope(StudentDataImport)
      .includes(:section, :school, :uploaded_by, file_attachment: :blob)
      .find(params[:id])
  end

  def load_sections
    @sections = policy_scope(Section).includes(:course).order(:name)
  end

  def data_import_params
    params.require(:student_data_import).permit(:import_type, :section_id, :file)
  end

  def requested_import_type
    params[:import_type].presence_in(StudentDataImport::IMPORT_TYPES) || "roster"
  end
end
