class Section < ApplicationRecord
  belongs_to :organization
  belongs_to :school
  belongs_to :course
  belongs_to :teacher, class_name: "User"
  has_many :enrollments, dependent: :destroy
  has_many :students, through: :enrollments
  has_many :student_signals, dependent: :destroy

  validates :name, :academic_term, presence: true
end
