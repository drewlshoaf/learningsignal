class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = false
  def show? = same_organization?
  def create? = same_organization?
  def new? = create?
  def update? = same_organization?
  def edit? = update?
  def destroy? = false

  private

  def same_organization?
    user.present? && record.respond_to?(:organization_id) && user.organization_ids.include?(record.organization_id)
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(organization_id: user.organization_ids)
    end

    private

    attr_reader :user, :scope
  end
end
