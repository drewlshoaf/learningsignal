class InterventionPlan < ApplicationRecord
  STATUSES = %w[draft approved rejected].freeze

  belongs_to :organization
  belongs_to :investigation
  has_many :intervention_actions, -> { order(:position) }, dependent: :destroy
  has_many :teacher_decisions, dependent: :destroy

  accepts_nested_attributes_for :intervention_actions

  validates :summary, presence: true
  validates :status, inclusion: { in: STATUSES }

  def snapshot
    {
      summary: summary,
      teacher_notes: teacher_notes,
      actions: intervention_actions.map do |action|
        {
          position: action.position,
          title: action.title,
          instructions: action.instructions,
          duration: action.duration,
          success_criteria: action.success_criteria
        }
      end
    }
  end
end
