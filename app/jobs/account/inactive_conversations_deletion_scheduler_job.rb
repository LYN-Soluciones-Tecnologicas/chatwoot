class Account::InactiveConversationsDeletionSchedulerJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Account.with_inactive_conversations_deletion.find_each(batch_size: 100) do |account|
      Conversations::InactiveDeletionJob.perform_later(account: account)
    end
  end
end
