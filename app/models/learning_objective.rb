class LearningObjective < ApplicationRecord
  belongs_to :organization
  belongs_to :course
  has_many :mastery_snapshots, dependent: :destroy
  has_many :document_chunks, dependent: :nullify

  validates :code, :title, :description, presence: true
  validates :code, uniqueness: { scope: :organization_id }
end
