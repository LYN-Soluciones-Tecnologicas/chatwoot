# frozen_string_literal: true

module Custom::Api::V1::Accounts::Contacts::BaseController
  private

  def ensure_contact
    if Current.account_user&.administrator? || Current.user.nil?
      @contact = Current.account.contacts.find(params[:contact_id])
      return
    end

    contact_scope = Custom::Contacts::PermissionFilterService.new(
      Current.account.contacts, Current.user, Current.account
    ).perform
    @contact = contact_scope.find(params[:contact_id])
  end
end
