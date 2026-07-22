class SectionPolicy < ApplicationPolicy
  def index? = user.present?

  class Scope < ApplicationPolicy::Scope
    def resolve
      super.where(teacher_id: user.id)
    end
  end
end
