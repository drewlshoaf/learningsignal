class CurriculumDocument < ApplicationRecord
  STATUSES = %w[pending processing ready failed].freeze
  MAX_FILE_SIZE = 25.megabytes

  belongs_to :organization
  belongs_to :course
  belongs_to :learning_objective, optional: true
  belongs_to :uploaded_by, class_name: "User", optional: true
  has_many :document_chunks, dependent: :destroy
  has_one_attached :file

  validates :title, :source_label, :status, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :file_checksum, uniqueness: { scope: :organization_id }, allow_nil: true
  validate :acceptable_file
  validate :objective_matches_course

  before_validation :capture_file_checksum
  after_update_commit :broadcast_progress

  private

  def acceptable_file
    errors.add(:file, "is required") if status == "pending" && !file.attached?
    return unless file.attached?

    errors.add(:file, "must be a PDF") unless file.blob.content_type == "application/pdf"
    errors.add(:file, "must be smaller than 25 MB") if file.blob.byte_size > MAX_FILE_SIZE
  end

  def capture_file_checksum
    self.file_checksum = file.blob.checksum if file.attached?
  end

  def objective_matches_course
    return if learning_objective.blank? || learning_objective.course_id == course_id

    errors.add(:learning_objective, "must belong to the selected course")
  end

  def broadcast_progress
    broadcast_refresh_to self
  end
end
