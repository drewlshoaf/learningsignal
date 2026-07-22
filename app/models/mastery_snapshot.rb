class MasterySnapshot < ApplicationRecord
  belongs_to :organization
  belongs_to :student
  belongs_to :learning_objective

  validates :score, numericality: { in: 0..100 }
  validates :observed_on, :source, presence: true
end
