# DocuSense

An AI-powered document management and chat system built with Rails 8, featuring intelligent document processing, vector embeddings, and conversational AI.

## Features

- 📄 **Document Management**: Upload, process, and organize documents (PDF, DOCX, TXT)
- 🤖 **AI-Powered Chat**: Ask questions about your documents using OpenAI's GPT models
- 🔍 **Vector Search**: Semantic similarity search using embeddings (with optional pgvector support)
- 👥 **Multi-tenant**: Support for multiple customers with isolated document collections
- 🔐 **Authentication**: User roles (admin, regular, read_only) with Devise
- ⚡ **Background Jobs**: Async document processing with Sidekiq
- 💾 **Caching**: Redis-based caching for improved performance

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐     ┌─────────────────┐
│   Document      │    │   Text          │     │   Embedding     │
│   Upload        │───▶│   Extraction    │───▶│   Generation    │
└─────────────────┘    └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Chat          │     │   Document      │     │   Vector        │
│   Interface     │◀───│   Retrieval      │◀───│   Storage       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐     ┌─────────────────┐
│   Response      │     │   Caching       │
│   Generation    │◀───│   Layer          │
└─────────────────┘     └─────────────────┘
```

## Prerequisites

- Ruby 3.4+ (managed via asdf)
- PostgreSQL 16+ (via Docker)
- Redis 7+ (via Docker)
- Docker and Docker Compose
- OpenAI API key

## Setup Instructions

### 1. Clone and Install Dependencies

```bash
# Install Ruby dependencies
bundle install

# Install Node.js dependencies (if using any JS packages)
# npm install  # or yarn install
```

### 2. Configure Environment Variables

Copy the example environment file and update with your values:

```bash
cp .env.example .env
```

Then edit `.env` and update the following required values:
- `OPENAI_API_KEY`: Your OpenAI API key (required for AI features)
- Database credentials if different from defaults
- Redis URL if different from default

The `.env.example` file contains all available configuration options with sensible defaults.

### 3. Start Docker Services

```bash
# Start PostgreSQL and Redis containers
docker compose up -d postgres redis

# Verify containers are running
docker compose ps
```

### 4. Database Setup

```bash
# Create the database
rails db:create

# Run migrations
rails db:migrate

# (Optional) Load seed data with sample users and documents
rails db:seed
```

### 5. Start the Application

```bash
# Start Rails server
rails s

# In a separate terminal, start Sidekiq for background jobs
bundle exec sidekiq
```

The application will be available at `http://localhost:3000`

## Optional: Setting Up pgvector

For enhanced vector similarity search performance, you can set up pgvector:

### 1. Update Docker Compose

The `docker-compose.yml` already uses the `pgvector/pgvector:pg16` image which includes pgvector.

### 2. Install pgvector Gem

Add to your `Gemfile`:

```ruby
gem "pgvector", "~> 0.2"
```

Then run:

```bash
bundle install
```

### 3. Enable pgvector Extension

Create a migration:

```bash
rails generate migration EnablePgvectorExtension
```

Edit the migration:

```ruby
class EnablePgvectorExtension < ActiveRecord::Migration[8.0]
  def change
    enable_extension "vector"
  end
end
```

### 4. Update Embedding Vector Column

Create a migration to change the column type:

```bash
rails generate migration ConvertEmbeddingVectorToPgvector
```

```ruby
class ConvertEmbeddingVectorToPgvector < ActiveRecord::Migration[8.0]
  def up
    # Convert text column to vector type
    execute <<-SQL
      ALTER TABLE document_embeddings
      ALTER COLUMN embedding_vector TYPE vector(1536)
      USING embedding_vector::vector;
    SQL

    # Add vector similarity index
    execute <<-SQL
      CREATE INDEX index_embeddings_on_vector_cosine
      ON document_embeddings
      USING ivfflat (embedding_vector vector_cosine_ops)
      WITH (lists = 100);
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX IF EXISTS index_embeddings_on_vector_cosine;
      ALTER TABLE document_embeddings
      ALTER COLUMN embedding_vector TYPE text;
    SQL
  end
end
```

### 5. Run Migrations

```bash
rails db:migrate
```

### 6. Update Feature Flag

In `config/initializers/docusense_config.rb`, set:

```ruby
FEATURE_FLAGS = {
  enable_pgvector: true,  # Change from false to true
  # ...
}
```

## Seed Data

The seed file creates sample data including:

- **2 Customers**: Acme Corporation and Smith & Associates Law Firm
- **4 Users**: Admin, regular user, read-only user, and lawyer
- **3 Document Collections**: HR Policies, Technical Documentation, Legal Documents
- **3 Sample Documents**: Employee Handbook, API Documentation, Service Agreement
- **2 Chat Sessions**: With sample conversations

After running `rails db:seed`, you'll see login credentials printed to the console.

## Default Users (from seeds)

After running `rails db:seed`, the following users are created:

### Acme Corporation
- **Admin**: `admin@acme.com` / `password123`
  - Role: Admin
  - Full access to all features

- **Regular User**: `user@acme.com` / `password123`
  - Role: Regular
  - Can upload documents and use chat

- **Read-Only User**: `viewer@acme.com` / `password123`
  - Role: Read Only
  - Can view documents and chat, but cannot upload

### Smith & Associates Law Firm
- **Lawyer**: `lawyer@smithlaw.com` / `password123`
  - Role: Admin
  - Full access for the law firm

## Development

### Running Tests

```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/user_test.rb
```

### Code Quality

```bash
# Run RuboCop
bundle exec rubocop

# Run Brakeman (security scanner)
bundle exec brakeman
```

### Database Console

```bash
rails dbconsole
```

### Rails Console

```bash
rails console
```

## Production Deployment

1. Set production environment variables
2. Configure production database credentials
3. Set up SSL/TLS certificates
4. Configure Redis for production
5. Set up Sidekiq workers
6. Enable pgvector if using vector search

## Troubleshooting

### Database Connection Issues

If you get connection errors:
- Ensure Docker containers are running: `docker compose ps`
- Check `.env` file has correct `DATABASE_URL` pointing to `localhost`
- Verify PostgreSQL is accessible: `docker compose logs postgres`

### Redis Connection Issues

- Check Redis is running: `docker compose ps redis`
- Verify `REDIS_URL` in `.env` uses `localhost` for local development
- Test connection: `redis-cli -h localhost ping`

### Migration Errors

- If you get errors about missing tables, ensure you've run `rails db:create` first
- For pgvector errors, ensure the extension is enabled: `rails dbconsole` then `CREATE EXTENSION IF NOT EXISTS vector;`
