class AssessmentQuestion < ApplicationRecord
  TYPES = %w[multiple_choice true_false short_answer constructed_response].freeze

  belongs_to :organization
  belongs_to :assessment
  belongs_to :learning_objective
  has_many :question_responses, dependent: :restrict_with_exception

  validates :external_ref, :prompt_reference, presence: true
  validates :external_ref, uniqueness: { scope: :assessment_id }
  validates :question_type, inclusion: { in: TYPES }
  validates :maximum_points, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validate :answer_key_present
  validate :consistent_scope

  def answer_key
    metadata.fetch("answer_key", "")
  end

  private

  def answer_key_present
    errors.add(:metadata, "must include an answer key") if answer_key.blank?
  end

  def consistent_scope
    return if organization.blank? || assessment.blank? || learning_objective.blank?

    errors.add(:assessment, "must belong to the organization") unless assessment.organization_id == organization_id
    unless learning_objective.organization_id == organization_id && learning_objective.course_id == assessment.course_id
      errors.add(:learning_objective, "must belong to the assessment course")
    end
  end
end
