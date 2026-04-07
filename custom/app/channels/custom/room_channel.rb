# frozen_string_literal: true

module Custom::RoomChannel
  private

  def broadcast_presence
    return if @current_account.blank?

    data = { account_id: @current_account.id, users: ::OnlineStatusTracker.get_available_users(@current_account.id) }

    if @current_user.is_a?(User)
      account_user = AccountUser.find_by(account_id: @current_account.id, user_id: @current_user.id)
      if account_user&.administrator?
        data[:contacts] = ::OnlineStatusTracker.get_available_contacts(@current_account.id)
      else
        inbox_ids = @current_user.inboxes.where(account_id: @current_account.id).pluck(:id)
        all_contacts = ::OnlineStatusTracker.get_available_contacts(@current_account.id)
        contact_ids_in_inboxes = ContactInbox.where(inbox_id: inbox_ids).pluck(:contact_id)
        data[:contacts] = all_contacts.select { |id, _| contact_ids_in_inboxes.include?(id.to_i) }
      end
    end

    ActionCable.server.broadcast(pubsub_token, { event: 'presence.update', data: data })
  end
end
