class MasterySnapshot < ApplicationRecord
  belongs_to :organization
  belongs_to :student
  belongs_to :section
  belongs_to :learning_objective

  validates :score, numericality: { in: 0..100 }
  validates :observed_on, :source, presence: true
  validates :student_id, uniqueness: {
    scope: %i[organization_id section_id learning_objective_id observed_on source]
  }
  validate :consistent_scope

  private

  def consistent_scope
    return if organization.blank? || student.blank? || section.blank? || learning_objective.blank?

    errors.add(:student, "must belong to the organization") unless student.organization_id == organization_id
    errors.add(:section, "must belong to the organization") unless section.organization_id == organization_id
    errors.add(:learning_objective, "must belong to the section course") unless learning_objective.course_id == section.course_id
    errors.add(:student, "must be enrolled in the section") unless section.enrollments.exists?(student_id: student_id)
  end
end
