class OrderPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    # def resolve
    #   scope.all
    # end

    def resolve
      if user.customer?
        scope.where(customer_id: user.id)
      else
        # Allow merchants to see orders with status 0 and their own orders
        scope.where(status: 0).or(scope.where(merchant_id: user.id))
      end
    end
  end

  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.customer?
  end

  def update?
    record.customer_id == user.id || record.merchant_id == user.id
  end

  def destroy?
    record.customer_id == user.id
  end

  def confirm?
    user.merchant? && record.created_by_user? && record.merchant_id.nil?
  end

  def progress?
    record.merchant_id == user.id
  end
end
