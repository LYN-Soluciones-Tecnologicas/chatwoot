require 'rails_helper'

RSpec.describe Conversations::DeleteInactiveService do
  subject(:service) { described_class.new(account: account) }

  let!(:account) { create(:account) }

  context 'when the feature is disabled' do
    it 'does nothing by default' do
      conversation = create(:conversation, account: account, last_activity_at: 30.days.ago)
      expect { service.perform }.not_to change(Conversation, :count)
      expect(conversation.reload).to be_persisted
    end

    it 'does nothing when only the flag is enabled but threshold is missing' do
      account.update!(delete_inactive_conversations_enabled: true, delete_inactive_conversations_after: nil)
      conversation = create(:conversation, account: account, last_activity_at: 30.days.ago)
      expect { service.perform }.not_to change(Conversation, :count)
      expect(conversation.reload).to be_persisted
    end

    it 'does nothing when threshold is set but flag is off' do
      account.update!(delete_inactive_conversations_enabled: false, delete_inactive_conversations_after: 60)
      conversation = create(:conversation, account: account, last_activity_at: 30.days.ago)
      expect { service.perform }.not_to change(Conversation, :count)
      expect(conversation.reload).to be_persisted
    end
  end

  context 'when the feature is enabled' do
    before do
      account.update!(delete_inactive_conversations_enabled: true, delete_inactive_conversations_after: 60)
    end

    it 'deletes conversations older than the configured inactivity threshold' do
      inactive = create(:conversation, account: account, last_activity_at: 2.hours.ago)
      recent = create(:conversation, account: account, last_activity_at: 10.minutes.ago)

      expect { service.perform }.to change(Conversation, :count).by(-1)
      expect(Conversation.exists?(inactive.id)).to be(false)
      expect(Conversation.exists?(recent.id)).to be(true)
    end

    it 'does not touch conversations from other accounts' do
      other_account = create(:account)
      foreign_conversation = create(:conversation, account: other_account, last_activity_at: 2.hours.ago)

      service.perform

      expect(Conversation.exists?(foreign_conversation.id)).to be(true)
    end

    it 'skips orphan conversations without a contact_id' do
      orphan = create(:conversation, account: account, last_activity_at: 2.hours.ago)
      orphan.update_columns(contact_id: nil) # rubocop:disable Rails/SkipsModelValidations
      regular = create(:conversation, account: account, last_activity_at: 2.hours.ago)

      service.perform

      expect(Conversation.exists?(orphan.id)).to be(true)
      expect(Conversation.exists?(regular.id)).to be(false)
    end

    it 'returns the number of deleted conversations' do
      create_list(:conversation, 3, account: account, last_activity_at: 2.hours.ago)
      expect(service.perform).to eq(3)
    end
  end
end
