class StudentSignalPolicy < ApplicationPolicy
  def investigate? = show?
end
