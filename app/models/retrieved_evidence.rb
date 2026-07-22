class RetrievedEvidence < ApplicationRecord
  belongs_to :organization
  belongs_to :investigation
  has_many :observation_evidences, dependent: :destroy
  has_many :investigation_observations, through: :observation_evidences

  validates :citation_id, :evidence_type, :source_type, :source_id, :excerpt, :locator, presence: true
  validates :citation_id, uniqueness: { scope: :investigation_id }
end
