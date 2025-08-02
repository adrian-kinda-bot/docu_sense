class ChatSessionsController < ApplicationController
  before_action :ensure_customer_access
  before_action :set_chat_session, only: [ :show, :destroy ]
  before_action :authorize_chat_session, only: [ :show, :destroy ]

  def index
    @chat_sessions = current_user.chat_sessions.includes(:chat_messages).order(updated_at: :desc)
  end

  def show
    @chat_messages = @chat_session.chat_messages.order(:created_at)
    @document_collections = current_user.customer.document_collections.active
  end

  def new
    @chat_session = current_user.chat_sessions.build
    @document_collections = current_user.customer.document_collections.active
  end

  def create
    @chat_session = current_user.chat_sessions.build(chat_session_params)

    if @chat_session.save
      redirect_to @chat_session, notice: "Chat session was successfully created."
    else
      @document_collections = current_user.customer.document_collections.active
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @chat_session.destroy
    redirect_to chat_sessions_path, notice: "Chat session was successfully deleted."
  end

  private

  def set_chat_session
    @chat_session = ChatSession.find(params[:id])
  end

  def authorize_chat_session
    unless @chat_session.user == current_user
      raise Pundit::NotAuthorizedError, "Not authorized to access this chat session"
    end
  end

  def chat_session_params
    params.require(:chat_session).permit(:title, :document_collection_id)
  end
end
