# frozen_string_literal: true

module Custom::AgentBotListener
  private

  # Override: skip bot entirely if the conversation has bot paused.
  # This enables per-conversation bot pause without affecting other conversations.
  def agent_bots_for(inbox, conversation = nil)
    return [] if conversation&.bot_paused?

    super
  end
end
