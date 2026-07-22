require "digest"

class DocumentChunk < ApplicationRecord
  has_neighbors :embedding

  belongs_to :organization
  belongs_to :curriculum_document
  belongs_to :learning_objective, optional: true

  validates :content, :locator, :content_checksum, presence: true

  before_validation :capture_content_checksum

  private

  def capture_content_checksum
    self.content_checksum = Digest::SHA256.hexdigest(content) if content.present?
  end
end
