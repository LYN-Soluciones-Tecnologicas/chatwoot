# frozen_string_literal: true

class Custom::Contacts::PermissionFilterService
  attr_reader :contacts, :user, :account

  def initialize(contacts, user, account)
    @contacts = contacts
    @user = user
    @account = account
  end

  def perform
    return contacts if user_role == 'administrator'

    accessible_contacts
  end

  private

  def accessible_contacts
    contacts.where(
      id: ContactInbox.where(
        inbox_id: user.inboxes.where(account_id: account.id).select(:id)
      ).select(:contact_id)
    )
  end

  def account_user
    @account_user ||= AccountUser.find_by(account_id: account.id, user_id: user.id)
  end

  def user_role
    account_user&.role
  end
end
