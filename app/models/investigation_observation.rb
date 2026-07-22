class InvestigationObservation < ApplicationRecord
  belongs_to :organization
  belongs_to :investigation
  has_many :observation_evidences, dependent: :destroy
  has_many :retrieved_evidences, through: :observation_evidences

  validates :statement, :confidence, presence: true
end
