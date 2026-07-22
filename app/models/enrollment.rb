class Enrollment < ApplicationRecord
  belongs_to :organization
  belongs_to :section
  belongs_to :student

  validates :student_id, uniqueness: { scope: :section_id }
end
