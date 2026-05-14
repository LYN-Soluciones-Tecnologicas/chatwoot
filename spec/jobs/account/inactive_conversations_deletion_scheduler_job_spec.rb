require 'rails_helper'

RSpec.describe Account::InactiveConversationsDeletionSchedulerJob do
  subject(:job) { described_class.perform_later }

  let!(:account) { create(:account) }

  it 'enqueues the job' do
    expect { job }.to have_enqueued_job(described_class).on_queue('scheduled_jobs')
  end

  it 'does not enqueue per-account jobs when deletion is disabled' do
    expect(Conversations::InactiveDeletionJob).not_to receive(:perform_later)
    described_class.perform_now
  end

  it 'enqueues a per-account job for accounts with deletion enabled' do
    account.update!(delete_inactive_conversations_enabled: true, delete_inactive_conversations_after: 60)
    expect(Conversations::InactiveDeletionJob).to receive(:perform_later).with(account: account).once
    described_class.perform_now
  end

  it 'skips accounts where the flag is enabled but threshold is missing' do
    account.update!(delete_inactive_conversations_enabled: true, delete_inactive_conversations_after: nil)
    expect(Conversations::InactiveDeletionJob).not_to receive(:perform_later)
    described_class.perform_now
  end
end
