class StudentDataImportPolicy < ApplicationPolicy
  def index? = user.present?
  def create? = record.is_a?(Class) ? user.present? : same_organization?
  def template? = user.present?
  def confirm? = update? && record.confirmable?

  class Scope < ApplicationPolicy::Scope
    def resolve
      super.where(section_id: Section.where(teacher_id: user.id))
    end
  end
end
