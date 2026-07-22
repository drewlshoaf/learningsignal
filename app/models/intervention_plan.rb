class InterventionPlan < ApplicationRecord
  STATUSES = %w[draft approved rejected].freeze

  belongs_to :organization
  belongs_to :investigation
  has_many :intervention_actions, -> { order(:position) }, dependent: :destroy
  has_many :teacher_decisions, dependent: :destroy
  has_one :intervention_outcome, dependent: :destroy

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

  def baseline_mastery_snapshot
    evidence_ids = investigation.retrieved_evidences
      .where(source_type: "MasterySnapshot")
      .pluck(:source_id)
    evidence_snapshot = MasterySnapshot.where(id: evidence_ids).order(observed_on: :desc).first
    return evidence_snapshot if evidence_snapshot

    investigation.student.mastery_snapshots
      .where(section: investigation.section, learning_objective: investigation.learning_objective)
      .where(observed_on: ..(approved_at || created_at).to_date)
      .where.not("source LIKE ?", "Intervention outcome %")
      .order(observed_on: :desc)
      .first
  end

  def edited_from_original?
    original_snapshot.present? && original_snapshot.deep_stringify_keys != snapshot.deep_stringify_keys
  end
end
