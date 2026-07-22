class CurriculumDocument < ApplicationRecord
  belongs_to :organization
  belongs_to :course
  has_many :document_chunks, dependent: :destroy

  validates :title, :source_label, :status, presence: true
end
