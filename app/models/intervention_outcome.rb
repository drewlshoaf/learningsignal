class InterventionOutcome < ApplicationRecord
  STATUSES = %w[in_progress completed].freeze
  EFFECTIVENESS_RATINGS = %w[effective ineffective].freeze

  belongs_to :organization
  belongs_to :intervention_plan
  belongs_to :recorded_by, class_name: "User"

  validates :status, inclusion: { in: STATUSES }
  validates :effectiveness, inclusion: { in: EFFECTIVENESS_RATINGS }, allow_nil: true
  validates :follow_up_mastery_score, numericality: { in: 0..100 }, allow_nil: true
  validates :recorded_at, presence: true
  validates :intervention_plan_id, uniqueness: true
  validates :student_completed, inclusion: { in: [ true, false ] }
  validates :effectiveness, :follow_up_mastery_score, :teacher_assessment, presence: true, if: :completed?
  validate :approved_plan
  validate :consistent_scope

  scope :completed, -> { where(status: "completed") }

  before_validation { self.effectiveness = nil if effectiveness.blank? }

  def completed? = status == "completed"

  def snapshot
    {
      status: status,
      effectiveness: effectiveness,
      follow_up_mastery_score: follow_up_mastery_score&.to_f,
      teacher_assessment: teacher_assessment,
      student_completed: student_completed,
      notes: notes,
      recorded_at: recorded_at&.iso8601
    }
  end

  private

  def approved_plan
    return if intervention_plan.blank? || intervention_plan.status == "approved"

    errors.add(:intervention_plan, "must be approved before an outcome is recorded")
  end

  def consistent_scope
    return if organization.blank? || intervention_plan.blank? || recorded_by.blank?

    errors.add(:intervention_plan, "must belong to the organization") unless intervention_plan.organization_id == organization_id
    errors.add(:recorded_by, "must belong to the organization") unless recorded_by.organization_ids.include?(organization_id)
  end
end
