class School < ApplicationRecord
  belongs_to :organization
  has_many :memberships, dependent: :destroy
  has_many :sections, dependent: :destroy
  has_many :students, dependent: :destroy
  has_many :student_data_imports, dependent: :restrict_with_exception

  validates :name, :slug, presence: true
  validates :slug, uniqueness: { scope: :organization_id }
end
