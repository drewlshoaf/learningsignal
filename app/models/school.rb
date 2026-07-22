class School < ApplicationRecord
  belongs_to :organization
  has_many :memberships, dependent: :destroy
  has_many :sections, dependent: :destroy
  has_many :students, dependent: :destroy

  validates :name, :slug, presence: true
  validates :slug, uniqueness: { scope: :organization_id }
end
