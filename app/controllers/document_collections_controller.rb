class DocumentCollectionsController < ApplicationController
  before_action :ensure_customer_access
  before_action :set_document_collection, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_collection, only: [ :show, :edit, :update, :destroy ]

  def index
    @document_collections = current_user.customer.document_collections.includes(:documents).order(:sort_order)
  end

  def show
    @documents = @document_collection.documents.includes(:document_embeddings).order(:created_at)
  end

  def new
    @document_collection = current_user.customer.document_collections.build
  end

  def create
    @document_collection = current_user.customer.document_collections.build(document_collection_params)

    if @document_collection.save
      redirect_to document_collection_path(@document_collection), notice: "Document collection was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @document_collection.update(document_collection_params)
      redirect_to @document_collection, notice: "Document collection was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @document_collection.destroy
    redirect_to document_collections_path, notice: "Document collection was successfully deleted."
  end

  private

  def set_document_collection
    @document_collection = Documents::Models::DocumentCollection.find(params[:id])
  end

  def authorize_collection
    unless current_user.can_access_collection?(@document_collection)
      raise Pundit::NotAuthorizedError, "Not authorized to access this collection"
    end
  end

  def document_collection_params
    params[:document_collection] = params[:documents_models_document_collection]
    params.require(:document_collection).permit(:name, :description, :category, :status, :sort_order)
  end
end
