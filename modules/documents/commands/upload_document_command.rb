module Documents
  module Commands
    class UploadDocumentCommand
      include ActiveModel::Model

      attr_accessor :title, :file, :document_collection_id, :user_id

      validates :title, presence: true, length: { minimum: 1, maximum: 200 }
      validates :file, presence: true
      validates :document_collection_id, presence: true
      validates :user_id, presence: true

      def execute
        return false unless valid?

        document_collection = Documents::DocumentCollection.find(document_collection_id)
        user = Users::User.find(user_id)

        # Validate user can access collection
        return false unless user.can_access_collection?(document_collection)

        # Validate file
        validation_result = Documents::Services::DocumentProcessingService.instance.validate_file(file)
        return false unless validation_result[:valid]

        # Create document
        document = document_collection.documents.build(
          title: title,
          file: file
        )

        if document.save
          # Publish event
          Documents::Events::DocumentUploadedEvent.new(document: document, user: user).publish
          true
        else
          errors.merge!(document.errors)
          false
        end
      end
    end
  end
end
