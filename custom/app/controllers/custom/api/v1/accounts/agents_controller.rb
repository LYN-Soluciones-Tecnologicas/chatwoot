# frozen_string_literal: true

module Custom::Api::V1::Accounts::AgentsController
  def create
    if Current.account_user.supervisor? && new_agent_params['role'] != 'agent'
      render json: { error: 'Supervisors can only create agents' }, status: :forbidden
      return
    end

    super
  end

  private

  def agents
    return super unless Current.account_user.supervisor?

    supervisor_inbox_ids = Current.user.inboxes.where(account_id: Current.account.id).select(:id)
    user_ids_in_my_inboxes = InboxMember.where(inbox_id: supervisor_inbox_ids).select(:user_id)
    user_ids_with_any_inbox = InboxMember.joins(:inbox).where(inboxes: { account_id: Current.account.id }).select(:user_id)

    @agents ||= Current.account.users
                        .where('users.id IN (?) OR users.id NOT IN (?)', user_ids_in_my_inboxes, user_ids_with_any_inbox)
                        .order_by_full_name
                        .includes(:account_users, { avatar_attachment: [:blob] })
  end
end
