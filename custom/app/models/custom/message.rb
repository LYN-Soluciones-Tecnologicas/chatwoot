# frozen_string_literal: true

module Custom::Message
  extend ActiveSupport::Concern

  included do
    after_create_commit :auto_pause_bot_if_agent_reply
  end

  private

  # When a human agent writes a public outgoing message, automatically pause
  # the bot for this conversation so it stops responding while the agent handles it.
  def auto_pause_bot_if_agent_reply
    return unless message_type == 'outgoing'
    return unless sender_type == 'User'
    return if private?
    return if conversation.bot_paused?

    conversation.pause_bot!
  end
end
