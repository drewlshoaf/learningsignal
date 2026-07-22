class LearningObjectivePolicy < ApplicationPolicy
  def index? = user.present?
end
