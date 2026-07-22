class Organization < ApplicationRecord
  has_many :schools, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :audit_events, dependent: :restrict_with_exception
  has_many :student_data_imports, dependent: :restrict_with_exception
  has_many :assessments, dependent: :restrict_with_exception
  has_many :assessment_attempts, dependent: :restrict_with_exception
  has_many :question_responses, dependent: :restrict_with_exception

  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
end
