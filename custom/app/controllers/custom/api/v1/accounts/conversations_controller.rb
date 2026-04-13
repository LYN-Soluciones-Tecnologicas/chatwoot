# frozen_string_literal: true

module Custom::Api::V1::Accounts::ConversationsController
  def pause_bot
    @conversation.pause_bot!
    render json: { bot_paused: true }
  end

  def resume_bot
    @conversation.resume_bot!
    render json: { bot_paused: false }
  end
end
