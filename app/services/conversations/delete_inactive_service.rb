# Deletes conversations that have been inactive for a configurable period.
# Driven by per-account settings: `delete_inactive_conversations_enabled` and
# `delete_inactive_conversations_after` (minutes). When the flag is not enabled
# or the inactivity threshold is not positive, this service is a no-op.
class Conversations::DeleteInactiveService
  BATCH_SIZE = 1_000

  def initialize(account:)
    @account = account
  end

  def perform
    return 0 unless @account.inactive_conversations_deletion_enabled?

    total_deleted = 0
    inactive_after = @account.delete_inactive_conversations_after.to_i

    log("Starting deletion of inactive conversations (>= #{inactive_after} min) for account #{@account.id}")

    @account.conversations.deletable_by_inactivity(inactive_after).find_in_batches(batch_size: BATCH_SIZE) do |batch|
      conversation_ids = batch.map(&:id)
      Conversation.where(id: conversation_ids).destroy_all
      total_deleted += batch.size
      log("Deleted #{batch.size} inactive conversations (#{total_deleted} total) for account #{@account.id}")
    end

    log("Completed deletion for account #{@account.id}. Total deleted: #{total_deleted}")
    total_deleted
  end

  private

  def log(message)
    Rails.logger.info "[Conversations::DeleteInactiveService] #{message}"
  end
end
