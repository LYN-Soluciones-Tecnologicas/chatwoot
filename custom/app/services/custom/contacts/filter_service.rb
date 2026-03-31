# frozen_string_literal: true

module Custom::Contacts::FilterService
  def base_relation
    contacts = super
    Custom::Contacts::PermissionFilterService.new(contacts, @user, @account).perform
  end
end
