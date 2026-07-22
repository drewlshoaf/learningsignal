class StudentSignal < ApplicationRecord
  PRIORITIES = %w[low medium high].freeze
  STATUSES = %w[open investigating resolved dismissed].freeze

  belongs_to :organization
  belongs_to :school
  belongs_to :student
  belongs_to :section
  belongs_to :learning_objective
  has_many :investigations, dependent: :destroy

  validates :kind, :title, :explanation, :fingerprint, :detected_at, presence: true
  validates :priority, inclusion: { in: PRIORITIES }
  validates :status, inclusion: { in: STATUSES }
  validates :fingerprint, uniqueness: { scope: :organization_id }

  scope :open_first, -> { order(Arel.sql("CASE priority WHEN 'high' THEN 0 WHEN 'medium' THEN 1 ELSE 2 END"), detected_at: :desc) }
end
