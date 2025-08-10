class ChatSessionsController < ApplicationController
  before_action :ensure_customer_access
  before_action :set_chat_session, only: [ :show, :update, :destroy ]
  before_action :authorize_chat_session, only: [ :show, :update, :destroy ]

  def index
    @chat_sessions = current_user.chat_sessions.includes(:chat_messages).order(updated_at: :desc)
  end

  def show
    @chat_messages = @chat_session.chat_messages.order(:created_at)
    @chat_message = Chat::Models::ChatMessage.new
    @document_collections = current_user.customer.document_collections.active
  end

  def new
    @chat_session = current_user.chat_sessions.build
    @document_collections = current_user.customer.document_collections.with_embeddings.active
  end

  def create
    @chat_session = current_user.chat_sessions.build(chat_session_params)

    if @chat_session.save
      redirect_to chat_session_path(@chat_session), notice: "Chat session was successfully created."
    else
      @document_collections = current_user.customer.document_collections.active
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @chat_session.update(chat_session_params)
      respond_to do |format|
        format.json { render json: { success: true, title: @chat_session.title } }
        format.html { redirect_to chat_session_path(@chat_session), notice: "Chat session was successfully updated." }
      end
    else
      respond_to do |format|
        format.json { render json: { success: false, errors: @chat_session.errors.full_messages } }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @chat_session.destroy
    redirect_to chat_sessions_path, notice: "Chat session was successfully deleted."
  end

  private

  def set_chat_session
    @chat_session = Chat::Models::ChatSession.find(params[:id])
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
