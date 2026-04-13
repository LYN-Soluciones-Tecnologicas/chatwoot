# frozen_string_literal: true

module Custom::Conversation
  BOT_PAUSED_KEY = 'bot_paused'

  def bot_paused?
    custom_attributes.is_a?(Hash) && custom_attributes[BOT_PAUSED_KEY] == true
  end

  def pause_bot!
    self.custom_attributes = (custom_attributes || {}).merge(BOT_PAUSED_KEY => true)
    save!
  end

  def resume_bot!
    self.custom_attributes = (custom_attributes || {}).merge(BOT_PAUSED_KEY => false)
    save!
  end

  private

  # Override: keep bot conversations in 'open' so human agents see them immediately.
  # The bot still receives events via AgentBotListener independently of status,
  # so responses continue to work. Human takeover happens via pause_bot!.
  def determine_conversation_status
    self.status = :resolved and return if contact.blocked?
    return handle_campaign_status if campaign.present?

    self.status = :open
  end
end
