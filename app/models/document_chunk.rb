class DocumentChunk < ApplicationRecord
  has_neighbors :embedding

  belongs_to :organization
  belongs_to :curriculum_document
  belongs_to :learning_objective, optional: true

  validates :content, :locator, presence: true
end
