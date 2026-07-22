class Student < ApplicationRecord
  belongs_to :organization
  belongs_to :school
  has_many :enrollments, dependent: :destroy
  has_many :sections, through: :enrollments
  has_many :mastery_snapshots, dependent: :destroy
  has_many :student_signals, dependent: :destroy

  validates :external_ref, :first_name, :last_initial, presence: true
  validates :external_ref, uniqueness: { scope: :organization_id }

  def display_name
    "#{first_name} #{last_initial}."
  end
end
