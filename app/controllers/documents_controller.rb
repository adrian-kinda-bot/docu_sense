class DocumentsController < ApplicationController
  before_action :ensure_customer_access
  before_action :set_document_collection, only: [ :index, :new, :create ]
  before_action :set_document, only: [ :show, :edit, :update, :destroy, :regenerate_embeddings ]
  before_action :authorize_document, only: [ :show, :edit, :update, :destroy, :regenerate_embeddings ]

  def index
    @documents = @document_collection.documents.includes(:document_embeddings).order(:created_at)
  end

  def show
  end

  def new
    @document = @document_collection.documents.build
  end

  def create
    @document = @document_collection.documents.build(document_params)

    if @document.save
      redirect_to document_url(@document), notice: "Document was successfully uploaded and is being processed."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @document.update(document_params)
      redirect_to document_path(@document), notice: "Document was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @document.destroy
    redirect_to document_collection_url(@document.document_collection), notice: "Document was successfully deleted."
  end

  def regenerate_embeddings
    if @document.can_generate_embeddings?
      @document.schedule_embedding_generation
      redirect_to document_path(@document), notice: "Embedding generation has been scheduled."
    else
      redirect_to document_path(@document), alert: "Document is not ready for embedding generation."
    end
  end

  private

  def set_document_collection
    @document_collection = current_user.customer.document_collections.find(params[:document_collection_id])
  end

  def set_document
    @document = Documents::Models::Document.find(params[:id])
  end

  def authorize_document
    unless current_user.can_access_collection?(@document.document_collection)
      raise Pundit::NotAuthorizedError, "Not authorized to access this document"
    end
  end

  def document_params
    params[:document] = params[:documents_models_document]
    params.require(:document).permit(:title, :file)
  end
end
