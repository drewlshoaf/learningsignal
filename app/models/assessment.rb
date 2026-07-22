class Assessment < ApplicationRecord
  TYPES = %w[quiz test benchmark formative summative].freeze
  STATUSES = %w[draft published archived].freeze

  belongs_to :organization
  belongs_to :course
  has_many :assessment_questions, dependent: :destroy
  has_many :assessment_attempts, dependent: :restrict_with_exception

  validates :external_ref, :title, presence: true
  validates :external_ref, uniqueness: { scope: :organization_id }
  validates :assessment_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :maximum_score, numericality: { greater_than_or_equal_to: 0 }
  validate :course_matches_organization

  def recalculate_maximum_score!
    update!(maximum_score: assessment_questions.sum(:maximum_points))
  end

  private

  def course_matches_organization
    return if organization.blank? || course.blank?

    errors.add(:course, "must belong to the organization") unless course.organization_id == organization_id
  end
end
