class ObservationEvidence < ApplicationRecord
  belongs_to :investigation_observation
  belongs_to :retrieved_evidence

  validates :retrieved_evidence_id, uniqueness: { scope: :investigation_observation_id }
end
