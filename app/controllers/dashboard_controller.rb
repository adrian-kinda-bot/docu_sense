class DashboardController < ApplicationController
  before_action :ensure_customer_access

  def index
    @customer = current_user.customer
    @document_collections = @customer.document_collections.includes(:documents).order(:sort_order)
    @recent_documents = @customer.documents.includes(:document_collection).recent.limit(5)
    @recent_chat_sessions = current_user.recent_chat_sessions(5)
    @stats = {
      total_documents: @customer.documents.count,
      total_collections: @customer.document_collections.count,
      processed_documents: @customer.documents.processed.count,
      documents_with_embeddings: @customer.documents.with_embeddings.count
    }
  end
end
