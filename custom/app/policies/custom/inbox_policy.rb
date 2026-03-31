# frozen_string_literal: true

module Custom::InboxPolicy
  def update?
    return true if @account_user.administrator?

    @account_user.supervisor? && user_has_inbox_access?
  end

  private

  def user_has_inbox_access?
    @user.inboxes.where(account_id: @account&.id).exists?(id: record.id)
  end
end
