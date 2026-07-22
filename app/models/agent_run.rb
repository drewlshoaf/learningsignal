class AgentRun < ApplicationRecord
  belongs_to :organization
  belongs_to :investigation

  validates :agent_name, :status, :provider, :model, :prompt_version, :started_at, presence: true
end
