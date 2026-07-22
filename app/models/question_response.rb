class QuestionResponse < ApplicationRecord
  belongs_to :organization
  belongs_to :assessment_attempt
  belongs_to :assessment_question

  validates :assessment_question_id, uniqueness: { scope: :assessment_attempt_id }
  validates :points_earned, numericality: { greater_than_or_equal_to: 0 }
  validate :response_present
  validate :consistent_scope
  validate :points_within_question_maximum

  def answer
    selected_answer.presence || response_text.to_s
  end

  private

  def response_present
    errors.add(:base, "A selected answer or response text is required") if selected_answer.blank? && response_text.blank?
  end

  def consistent_scope
    return if organization.blank? || assessment_attempt.blank? || assessment_question.blank?

    errors.add(:assessment_attempt, "must belong to the organization") unless assessment_attempt.organization_id == organization_id
    unless assessment_question.organization_id == organization_id && assessment_question.assessment_id == assessment_attempt.assessment_id
      errors.add(:assessment_question, "must belong to the attempt assessment")
    end
  end

  def points_within_question_maximum
    return if assessment_question.blank? || points_earned.blank?

    errors.add(:points_earned, "cannot exceed the question maximum") if points_earned > assessment_question.maximum_points
  end
end
