class AgentBotListener < BaseListener
  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    event_name = __method__.to_s
    payload = conversation.webhook_data.merge(event: event_name)
    agent_bots_for(inbox, conversation).each { |agent_bot| process_webhook_bot_event(agent_bot, payload) }
  end

  def conversation_opened(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    event_name = __method__.to_s
    payload = conversation.webhook_data.merge(event: event_name)
    agent_bots_for(inbox, conversation).each { |agent_bot| process_webhook_bot_event(agent_bot, payload) }
  end

  # The conversation is already destroyed here, so we work off the snapshot
  # captured in Conversation#prepare_conversation_deleted_payload. Routed
  # through the SAME AgentBot integration as messages (sync dispatcher ->
  # AgentBots::WebhookJob) so the bot connected to the inbox is notified of
  # the deletion exactly the way it receives messages.
  def conversation_deleted(event)
    conversation_data = event.data[:conversation_data]
    return if conversation_data.blank?

    inbox = Inbox.find_by(id: conversation_data['inbox_id'])
    return if inbox.nil?

    payload = conversation_data.merge(event: __method__.to_s)
    agent_bots_for(inbox).each do |agent_bot|
      process_webhook_bot_event(agent_bot, payload, agent_bot.conversation_deleted_url)
    end
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox
    return unless message.webhook_sendable?

    method_name = __method__.to_s
    agent_bots_for(inbox, message.conversation).each { |agent_bot| process_message_event(method_name, agent_bot, message, event) }
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox
    return unless message.webhook_sendable?

    method_name = __method__.to_s
    agent_bots_for(inbox, message.conversation).each { |agent_bot| process_message_event(method_name, agent_bot, message, event) }
  end

  def webwidget_triggered(event)
    contact_inbox = event.data[:contact_inbox]
    inbox = contact_inbox.inbox
    event_name = __method__.to_s
    payload = contact_inbox.webhook_data.merge(event: event_name)
    payload[:event_info] = event.data[:event_info]
    agent_bots_for(inbox).each { |agent_bot| process_webhook_bot_event(agent_bot, payload) }
  end

  private

  def agent_bots_for(inbox, conversation = nil)
    bots = []
    bots << conversation.assignee_agent_bot if conversation&.assignee_agent_bot.present?
    inbox_bot = active_inbox_agent_bot(inbox)
    bots << inbox_bot if inbox_bot.present?
    bots.compact.uniq
  end

  def active_inbox_agent_bot(inbox)
    return unless inbox.agent_bot_inbox&.active?

    inbox.agent_bot
  end

  def process_message_event(method_name, agent_bot, message, _event)
    # Only webhook bots are supported
    payload = message.webhook_data.merge(event: method_name)
    process_webhook_bot_event(agent_bot, payload)
  end

  def process_webhook_bot_event(agent_bot, payload, url = nil)
    target_url = url.presence || agent_bot.outgoing_url
    return if target_url.blank?

    AgentBots::WebhookJob.perform_later(target_url, payload)
  end
end
