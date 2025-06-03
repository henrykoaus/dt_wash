class ImagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      # Example: Only allow access to images owned by the current user
    end
  end
  # ...
end
