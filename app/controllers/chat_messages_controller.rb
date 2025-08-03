class ChatMessagesController < ApplicationController
  before_action :ensure_customer_access
  before_action :set_chat_session
  before_action :authorize_chat_session

  def create
    @chat_message = @chat_session.chat_messages.build(chat_message_params)

    if @chat_message.save
      # Process the message and generate AI response
      Chat::Jobs::ProcessChatMessageJob.perform_later(@chat_message.id)

      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "chat_messages",
            partial: "chat_sessions/messages",
            locals: { chat_messages: @chat_session.chat_messages.reload.order(:created_at) }
          )
        }
        format.html { redirect_to @chat_session }
      end
    else
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.replace(
            "chat_form",
            partial: "chat_messages/form",
            locals: { chat_session: @chat_session, chat_message: @chat_message }
          )
        }
        format.html { redirect_to @chat_session, alert: "Failed to send message." }
      end
    end
  end

  private

  def set_chat_session
    @chat_session = Chat::Models::ChatSession.find(params[:chat_session_id])
  end

  def authorize_chat_session
    unless @chat_session.user == current_user
      raise Pundit::NotAuthorizedError, "Not authorized to access this chat session"
    end
  end

  def chat_message_params
    params.require(:chat_message).permit(:content, :role)
  end
end
