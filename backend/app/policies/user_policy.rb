class UserPolicy < ApplicationPolicy
  private

  def pm_code
    "user_manage"
  end
end
