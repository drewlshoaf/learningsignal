class StudentDataImport < ApplicationRecord
  IMPORT_TYPES = %w[roster mastery].freeze
  STATUSES = %w[pending previewed invalid applying completed failed].freeze
  MAX_FILE_SIZE = 5.megabytes
  ACCEPTED_CONTENT_TYPES = %w[text/csv application/csv application/vnd.ms-excel text/plain].freeze

  belongs_to :organization
  belongs_to :school
  belongs_to :section
  belongs_to :uploaded_by, class_name: "User", inverse_of: :student_data_imports
  has_one_attached :file

  validates :import_type, inclusion: { in: IMPORT_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :source_filename, :file_checksum, presence: true
  validates :file_checksum, uniqueness: { scope: %i[organization_id section_id import_type] }
  validate :acceptable_file
  validate :consistent_scope

  before_validation :capture_file_metadata

  def confirmable?
    status == "previewed"
  end

  private

  def capture_file_metadata
    return unless file.attached?

    self.source_filename = file.filename.to_s
    self.file_checksum = file.blob.checksum
  end

  def acceptable_file
    errors.add(:file, "is required") unless file.attached?
    return unless file.attached?

    errors.add(:file, "must use a .csv filename") unless file.filename.extension_without_delimiter.downcase == "csv"
    errors.add(:file, "must be CSV content") unless ACCEPTED_CONTENT_TYPES.include?(file.blob.content_type)
    errors.add(:file, "must be smaller than 5 MB") if file.blob.byte_size > MAX_FILE_SIZE
  end

  def consistent_scope
    return if organization.blank? || school.blank? || section.blank?

    errors.add(:school, "must belong to the organization") unless school.organization_id == organization_id
    unless section.organization_id == organization_id && section.school_id == school_id
      errors.add(:section, "must belong to the selected school and organization")
    end
  end
end
