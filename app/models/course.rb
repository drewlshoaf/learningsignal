class Course < ApplicationRecord
  belongs_to :organization
  belongs_to :school
  has_many :sections, dependent: :destroy
  has_many :learning_objectives, dependent: :destroy
  has_many :curriculum_documents, dependent: :destroy
  has_many :assessments, dependent: :destroy

  validates :name, :code, :subject, :grade_level, presence: true
  validates :code, uniqueness: { scope: :organization_id }
end
