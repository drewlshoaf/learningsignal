class Investigation < ApplicationRecord
  STATUSES = %w[queued running completed failed].freeze

  belongs_to :organization
  belongs_to :school
  belongs_to :student_signal
  belongs_to :teacher, class_name: "User"
  has_many :agent_runs, dependent: :destroy
  has_many :retrieved_evidences, dependent: :destroy
  has_many :investigation_observations, dependent: :destroy
  has_one :intervention_plan, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
  validates :current_step, presence: true

  after_update_commit :broadcast_progress

  delegate :student, :section, :learning_objective, to: :student_signal

  private

  def broadcast_progress
    broadcast_refresh_to self
  end
end
