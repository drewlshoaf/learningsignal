class AssessmentAttempt < ApplicationRecord
  STATUSES = %w[in_progress submitted].freeze

  belongs_to :organization
  belongs_to :student
  belongs_to :assessment
  belongs_to :section
  has_many :question_responses, dependent: :destroy

  validates :external_ref, presence: true
  validates :external_ref, uniqueness: { scope: %i[organization_id section_id] }
  validates :attempt_number, numericality: { only_integer: true, greater_than: 0 }
  validates :attempt_number, uniqueness: { scope: %i[assessment_id student_id section_id] }
  validates :score, :maximum_score, numericality: { greater_than_or_equal_to: 0 }
  validates :percentage, numericality: { in: 0..100 }
  validates :status, inclusion: { in: STATUSES }
  validate :consistent_scope

  def recalculate_score!
    earned = question_responses.sum(:points_earned)
    possible = assessment.maximum_score
    calculated_percentage = possible.positive? ? (earned / possible * 100).round(2) : 0
    update!(score: earned, maximum_score: possible, percentage: calculated_percentage)
  end

  private

  def consistent_scope
    return if organization.blank? || student.blank? || assessment.blank? || section.blank?

    errors.add(:student, "must belong to the organization") unless student.organization_id == organization_id
    errors.add(:assessment, "must belong to the section course") unless assessment.organization_id == organization_id && assessment.course_id == section.course_id
    errors.add(:section, "must belong to the organization") unless section.organization_id == organization_id
    errors.add(:student, "must be enrolled in the section") unless section.enrollments.exists?(student_id: student_id)
  end
end
