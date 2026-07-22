class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :sections, foreign_key: :teacher_id, inverse_of: :teacher
  has_many :uploaded_curriculum_documents, class_name: "CurriculumDocument", foreign_key: :uploaded_by_id, inverse_of: :uploaded_by

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :name, :email_address, presence: true
  validates :email_address, uniqueness: { case_sensitive: false }

  def membership_for(organization)
    memberships.find_by(organization: organization)
  end
end
