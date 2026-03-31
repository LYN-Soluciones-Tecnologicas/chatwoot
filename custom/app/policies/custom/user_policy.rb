# frozen_string_literal: true

module Custom::UserPolicy
  def create?
    @account_user.administrator? || @account_user.supervisor?
  end

  def update?
    @account_user.administrator? || @account_user.supervisor?
  end

  def destroy?
    @account_user.administrator? || @account_user.supervisor?
  end

  def bulk_create?
    @account_user.administrator? || @account_user.supervisor?
  end
end
