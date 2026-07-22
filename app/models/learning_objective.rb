class LearningObjective < ApplicationRecord
  belongs_to :organization
  belongs_to :course
  has_many :mastery_snapshots, dependent: :destroy
  has_many :document_chunks, dependent: :nullify
  has_many :curriculum_documents, dependent: :nullify
  has_many :assessment_questions, dependent: :restrict_with_exception

  validates :code, :title, :description, presence: true
  validates :code, uniqueness: { scope: :organization_id }
end
