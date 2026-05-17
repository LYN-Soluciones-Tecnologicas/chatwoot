# == Schema Information
#
# Table name: agent_bots
#
#  id           :bigint           not null, primary key
#  bot_config   :jsonb
#  bot_type     :integer          default("webhook")
#  description  :string
#  name         :string
#  outgoing_url :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint
#
# Indexes
#
#  index_agent_bots_on_account_id  (account_id)
#

class AgentBot < ApplicationRecord
  include AccessTokenable
  include Avatarable

  scope :accessible_to, lambda { |account|
    account_id = account&.id
    where(account_id: [nil, account_id])
  }

  has_many :agent_bot_inboxes, dependent: :destroy_async
  has_many :inboxes, through: :agent_bot_inboxes
  has_many :messages, as: :sender, dependent: :nullify
  has_many :assigned_conversations, class_name: 'Conversation',
                                    foreign_key: :assignee_agent_bot_id,
                                    dependent: :nullify,
                                    inverse_of: :assignee_agent_bot
  belongs_to :account, optional: true
  enum bot_type: { webhook: 0 }

  validates :outgoing_url, length: { maximum: Limits::URL_LENGTH_LIMIT }

  def available_name
    name
  end

  def push_event_data(inbox = nil)
    {
      id: id,
      name: name,
      avatar_url: avatar_url || inbox&.avatar_url,
      type: 'agent_bot'
    }
  end

  def webhook_data
    {
      id: id,
      name: name,
      type: 'agent_bot'
    }
  end

  # Endpoint the bot system exposes to clean up a conversation when it is
  # deleted in Chatwoot. Configurable per bot via bot_config; falls back to
  # the same outgoing_url that already receives messages so the deletion
  # travels over the exact same integration as the rest of the bot traffic.
  def conversation_deleted_url
    bot_config&.dig('conversation_deleted_url').presence || outgoing_url
  end

  def system_bot?
    account.nil?
  end
end
