# Domain-Driven Design (DDD) Structure

This application follows Domain-Driven Design principles with a modular structure organized by business domains.

## Directory Structure

```
modules/
├── users/           # User management domain
│   ├── models/      # User and Customer entities
│   ├── services/    # User-related business logic
│   ├── commands/    # User operations (create, update, etc.)
│   ├── jobs/        # Background jobs for user operations
│   └── events/      # User-related domain events
├── documents/       # Document management domain
│   ├── models/      # Document, DocumentCollection, DocumentEmbedding
│   ├── services/    # Document processing, validation
│   ├── commands/    # Document operations (upload, delete, etc.)
│   ├── jobs/        # Background processing jobs
│   └── events/      # Document-related domain events
├── chat/           # Chat functionality domain
│   ├── models/      # ChatSession, ChatMessage
│   ├── services/    # AI service, chat logic
│   ├── commands/    # Chat operations (send message, etc.)
│   ├── jobs/        # Message processing jobs
│   └── events/      # Chat-related domain events
└── subscriptions/  # Subscription management domain
    ├── models/      # Subscription entity
    ├── services/    # Subscription business logic
    ├── commands/    # Subscription operations
    ├── jobs/        # Subscription-related jobs
    └── events/      # Subscription events
```

## Domain Boundaries

### Users Domain
- **Models**: `Users::Models::User`, `Users::Models::Customer`
- **Responsibility**: User authentication, authorization, and customer management
- **Key Services**: User validation, customer domain validation

### Documents Domain
- **Models**: `Documents::Models::Document`, `Documents::Models::DocumentCollection`, `Documents::Models::DocumentEmbedding`
- **Responsibility**: Document storage, processing, and embedding generation
- **Key Services**: Document processing, text extraction, embedding generation

### Chat Domain
- **Models**: `Chat::Models::ChatSession`, `Chat::Models::ChatMessage`
- **Responsibility**: Chat functionality and AI interactions
- **Key Services**: AI service, message processing, document search

### Subscriptions Domain
- **Models**: `Subscriptions::Models::Subscription`
- **Responsibility**: Subscription management and billing
- **Key Services**: Plan validation, usage tracking

## Usage Examples

### Using Domain Models
```ruby
# Users domain
user = Users::User.find(1)
customer = Users::Customer.find(1)

# Documents domain
document = Documents::Models::Document.find(1)
collection = Documents::Models::DocumentCollection.find(1)

# Chat domain
session = Chat::ChatSession.find(1)
message = Chat::Models::ChatMessage.find(1)

# Subscriptions domain
subscription = Subscriptions::Models::Subscription.find(1)
```

### Using Domain Services
```ruby
# AI service for chat
ai_service = Chat::Services::AiService.instance
response = ai_service.generate_chat_response(messages, context)

# Document processing
processor = Documents::Services::DocumentProcessingService.instance
result = processor.process_document(document)
```

### Using Domain Commands
```ruby
# Upload document
command = Documents::Commands::UploadDocumentCommand.new(
  title: "My Document",
  file: uploaded_file,
  document_collection_id: collection.id,
  user_id: user.id
).execute

# Send chat message
command = Chat::Commands::SendChatMessageCommand.new(
  content: "Hello",
  chat_session_id: session.id,
  user_id: user.id
).execute
```

### Using Domain Jobs
```ruby
# Process chat message
Chat::Jobs::ProcessChatMessageJob.perform_later(message.id)

# Generate embeddings
Documents::Jobs::EmbeddingGenerationJob.perform_later(document)
```

## Benefits of This Structure

1. **Clear Domain Boundaries**: Each domain has its own namespace and clear responsibilities
2. **Maintainability**: Related code is grouped together
3. **Testability**: Each domain can be tested independently
4. **Scalability**: Easy to add new domains or extend existing ones
5. **Team Organization**: Different teams can work on different domains

## Migration Notes

- Controllers and views remain in the `app/` directory for Rails conventions
- Models, services, commands, jobs, and events are moved to the `modules/` directory
- All references to models have been updated to use the new namespaced versions
- The autoload configuration ensures Rails can find all the new classes
