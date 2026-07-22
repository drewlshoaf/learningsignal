class AuditEvent < ApplicationRecord
  belongs_to :organization
  belongs_to :school, optional: true
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true

  validates :action, :event_hash, :occurred_at, presence: true
end
