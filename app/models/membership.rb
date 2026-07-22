class Membership < ApplicationRecord
  ROLES = %w[teacher instructional_coach school_admin platform_admin].freeze

  belongs_to :organization
  belongs_to :school
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: [ :organization_id, :school_id ] }
end
