# frozen_string_literal: true

module Custom::Api::V1::Accounts::ContactsController
  def search
    render json: { error: 'Specify search string with parameter q' }, status: :unprocessable_entity if params[:q].blank? && return

    contacts = Current.account.contacts.where(
      'name ILIKE :search OR email ILIKE :search OR phone_number ILIKE :search OR contacts.identifier LIKE :search',
      search: "%#{params[:q].strip}%"
    )
    contacts = Custom::Contacts::PermissionFilterService.new(contacts, Current.user, Current.account).perform
    @contacts = fetch_contacts_with_has_more(contacts)
  end

  def active
    contacts = Current.account.contacts.where(id: ::OnlineStatusTracker.get_available_contact_ids(Current.account.id))
    contacts = Custom::Contacts::PermissionFilterService.new(contacts, Current.user, Current.account).perform
    @contacts = fetch_contacts(contacts)
    @contacts_count = @contacts.total_count
  end

  private

  def resolved_contacts
    result = super
    Custom::Contacts::PermissionFilterService.new(result, Current.user, Current.account).perform
  end

  def fetch_contact
    contact_scope = Current.account.contacts
    contact_scope = Custom::Contacts::PermissionFilterService.new(contact_scope, Current.user, Current.account).perform
    contact_scope = contact_scope.includes(contact_inboxes: [:inbox]) if @include_contact_inboxes
    @contact = contact_scope.find(params[:id])
  end
end
