# frozen_string_literal: true

module Custom::Api::V1::Accounts::AgentsController
  def create
    if Current.account_user.supervisor? && new_agent_params['role'] != 'agent'
      render json: { error: 'Supervisors can only create agents' }, status: :forbidden
      return
    end

    super
  end

  def update
    if Current.account_user.supervisor?
      role_param = params.dig(:agent, :role)
      if role_param.present? && role_param != 'agent'
        render json: { error: 'Supervisors can only assign agent role' }, status: :forbidden
        return
      end
    end

    super
  end

  private

  def agents
    return super unless Current.account_user.supervisor?

    supervisor_inbox_ids = Current.user.inboxes.where(account_id: Current.account.id).select(:id)

    @agents ||= Current.account.users
                        .where(id: InboxMember.where(inbox_id: supervisor_inbox_ids).select(:user_id))
                        .order_by_full_name
                        .includes(:account_users, { avatar_attachment: [:blob] })
  end
end
