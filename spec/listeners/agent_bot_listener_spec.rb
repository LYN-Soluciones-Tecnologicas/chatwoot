require 'rails_helper'
describe AgentBotListener do
  let(:listener) { described_class.instance }
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:agent_bot) { create(:agent_bot) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox, assignee: user) }

  describe '#message_created' do
    let(:event_name) { 'message.created' }
    let!(:event) { Events::Base.new(event_name, Time.zone.now, message: message) }
    let!(:message) do
      create(:message, message_type: 'outgoing',
                       account: account, inbox: inbox, conversation: conversation)
    end

    context 'when agent bot is not configured' do
      it 'does not send message to agent bot' do
        expect(AgentBots::WebhookJob).to receive(:perform_later).exactly(0).times
        listener.message_created(event)
      end
    end

    context 'when agent bot is configured' do
      it 'sends message to agent bot' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        expect(AgentBots::WebhookJob).to receive(:perform_later).with(agent_bot.outgoing_url,
                                                                      message.webhook_data.merge(event: 'message_created')).once
        listener.message_created(event)
      end

      it 'does not send message to agent bot if url is empty' do
        agent_bot = create(:agent_bot, outgoing_url: '')
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        expect(AgentBots::WebhookJob).not_to receive(:perform_later)
        listener.message_created(event)
      end

      context 'when conversation has a different assignee agent bot' do
        let!(:conversation_bot) { create(:agent_bot) }

        before do
          create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
          conversation.update!(assignee_agent_bot: conversation_bot, assignee: nil)
        end

        it 'sends message to both bots exactly once' do
          payload = message.webhook_data.merge(event: 'message_created')

          expect(AgentBots::WebhookJob).to receive(:perform_later).with(agent_bot.outgoing_url, payload).once
          expect(AgentBots::WebhookJob).to receive(:perform_later).with(conversation_bot.outgoing_url, payload).once

          listener.message_created(event)
        end
      end
    end
  end

  describe '#conversation_deleted' do
    let(:event_name) { 'conversation.deleted' }
    let(:conversation_data) { JSON.parse(conversation.webhook_data.to_json) }
    let(:event) do
      Events::Base.new(event_name, Time.zone.now, conversation_data: conversation_data, account_id: account.id)
    end

    context 'when no agent bot is configured on the inbox' do
      it 'does not notify any bot' do
        expect(AgentBots::WebhookJob).not_to receive(:perform_later)
        listener.conversation_deleted(event)
      end
    end

    context 'when an agent bot is configured on the inbox' do
      it 'notifies the bot at outgoing_url by default (same channel as messages)' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        expect(AgentBots::WebhookJob).to receive(:perform_later).with(
          agent_bot.outgoing_url,
          conversation_data.merge(event: 'conversation_deleted')
        ).once
        listener.conversation_deleted(event)
      end

      it 'notifies the dedicated conversation_deleted_url when configured in bot_config' do
        agent_bot.update!(bot_config: { 'conversation_deleted_url' => 'https://host-middleware/chatwoot/end-conversation' })
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        expect(AgentBots::WebhookJob).to receive(:perform_later).with(
          'https://host-middleware/chatwoot/end-conversation',
          conversation_data.merge(event: 'conversation_deleted')
        ).once
        listener.conversation_deleted(event)
      end

      it 'does not notify when the resolved url is blank' do
        blank_bot = create(:agent_bot, outgoing_url: '')
        create(:agent_bot_inbox, inbox: inbox, agent_bot: blank_bot)
        expect(AgentBots::WebhookJob).not_to receive(:perform_later)
        listener.conversation_deleted(event)
      end
    end

    context 'when payload is incomplete' do
      it 'does nothing when conversation_data is blank' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        blank_event = Events::Base.new(event_name, Time.zone.now, conversation_data: nil, account_id: account.id)
        expect(AgentBots::WebhookJob).not_to receive(:perform_later)
        listener.conversation_deleted(blank_event)
      end

      it 'does nothing when the inbox no longer exists' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)
        data = conversation_data.merge('inbox_id' => 0)
        missing_event = Events::Base.new(event_name, Time.zone.now, conversation_data: data, account_id: account.id)
        expect(AgentBots::WebhookJob).not_to receive(:perform_later)
        listener.conversation_deleted(missing_event)
      end
    end
  end

  describe '#webwidget_triggered' do
    let(:event_name) { 'webwidget.triggered' }

    context 'when agent bot is configured' do
      it 'send message to agent bot URL' do
        create(:agent_bot_inbox, inbox: inbox, agent_bot: agent_bot)

        event = double
        allow(event).to receive(:data)
          .and_return(
            {
              contact_inbox: conversation.contact_inbox,
              event_info: { country: 'US' }
            }
          )
        expect(AgentBots::WebhookJob).to receive(:perform_later)
          .with(
            agent_bot.outgoing_url,
            conversation.contact_inbox.webhook_data.merge(event: 'webwidget_triggered', event_info: { country: 'US' })
          ).once

        listener.webwidget_triggered(event)
      end
    end
  end
end
