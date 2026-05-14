class Conversations::InactiveDeletionJob < ApplicationJob
  queue_as :purgable

  def perform(account:)
    Conversations::DeleteInactiveService.new(account: account).perform
  end
end
