# Clear existing data
puts "Clearing existing data..."
Users::Models::User.destroy_all
Users::Models::Customer.destroy_all
Documents::Models::DocumentCollection.destroy_all
Documents::Models::Document.destroy_all
Chat::Models::ChatSession.destroy_all
Chat::Models::ChatMessage.destroy_all

# Create sample customers
puts "Creating customers..."

acme_corp = Users::Models::Customer.create!(
  name: "Acme Corporation",
  email: "admin@acme.com",
  domain: "acme.com",
  status: "active",
  description: "A leading technology company",
  phone: "+1-555-0123",
  address: "123 Tech Street, Silicon Valley, CA",
  website: "https://acme.com"
)

legal_firm = Users::Models::Customer.create!(
  name: "Smith & Associates Law Firm",
  email: "contact@smithlaw.com",
  domain: "smithlaw.com",
  status: "active",
  description: "Premier legal services",
  phone: "+1-555-0456",
  address: "456 Legal Avenue, New York, NY",
  website: "https://smithlaw.com"
)

# Create sample users
puts "Creating users..."

# Acme Corp users
admin_user = Users::Models::User.create!(
  email: "admin@acme.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "John",
  last_name: "Admin",
  role: "admin",
  customer: acme_corp,
  confirmed_at: Time.current
)

regular_user = Users::Models::User.create!(
  email: "user@acme.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Jane",
  last_name: "User",
  role: "regular",
  customer: acme_corp,
  confirmed_at: Time.current
)

read_only_user = Users::Models::User.create!(
  email: "viewer@acme.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Bob",
  last_name: "Viewer",
  role: "read_only",
  customer: acme_corp,
  confirmed_at: Time.current
)

# Law firm users
lawyer_user = Users::Models::User.create!(
  email: "lawyer@smithlaw.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Sarah",
  last_name: "Lawyer",
  role: "admin",
  customer: legal_firm,
  confirmed_at: Time.current
)

# Create document collections
puts "Creating document collections..."

# Acme Corp collections
hr_collection = Documents::Models::DocumentCollection.create!(
  name: "HR Policies",
  description: "Human resources policies and procedures",
  category: "hr",
  status: "active",
  sort_order: 1,
  customer: acme_corp
)

tech_collection = Documents::Models::DocumentCollection.create!(
  name: "Technical Documentation",
  description: "Technical specifications and documentation",
  category: "technical",
  status: "active",
  sort_order: 2,
  customer: acme_corp
)

# Law firm collections
legal_collection = Documents::Models::DocumentCollection.create!(
  name: "Legal Documents",
  description: "Legal contracts and agreements",
  category: "legal",
  status: "active",
  sort_order: 1,
  customer: legal_firm
)

# Create sample documents (without actual files for now)
puts "Creating sample documents..."

# Sample HR document
hr_doc = Documents::Models::Document.create!(
  title: "Employee Handbook",
  file_type: "pdf",
  file_size: 1024000,
  status: "processed",
  content: "This is the employee handbook for Acme Corporation. It contains all the policies and procedures that employees must follow. The handbook covers topics such as workplace conduct, benefits, time off policies, and disciplinary procedures. All employees are required to read and understand this handbook.",
  processed_at: Time.current,
  document_collection: hr_collection
)

# Sample technical document
tech_doc = Documents::Models::Document.create!(
  title: "API Documentation",
  file_type: "pdf",
  file_size: 2048000,
  status: "processed",
  content: "This document provides comprehensive API documentation for our platform. It includes authentication methods, endpoint specifications, request/response formats, and code examples. Developers should refer to this documentation when integrating with our services.",
  processed_at: Time.current,
  document_collection: tech_collection
)

# Sample legal document
legal_doc = Documents::Models::Document.create!(
  title: "Service Agreement Template",
  file_type: "docx",
  file_size: 512000,
  status: "processed",
  content: "This is a standard service agreement template used by Smith & Associates Law Firm. It includes standard terms and conditions, liability clauses, payment terms, and termination procedures. This template should be customized for each client based on their specific needs.",
  processed_at: Time.current,
  document_collection: legal_collection
)

# Create sample chat sessions
puts "Creating sample chat sessions..."

# Acme Corp chat session
acme_chat = Chat::Models::ChatSession.create!(
  title: "HR Policy Questions",
  status: "active",
  last_activity_at: Time.current,
  user: regular_user,
  document_collection: hr_collection
)

# Add some chat messages
Chat::Models::ChatMessage.create!(
  content: "What are the company's vacation policies?",
  role: "user",
  message_type: "question",
  chat_session: acme_chat,
  user: regular_user
)

Chat::Models::ChatMessage.create!(
  content: "Based on the Employee Handbook, Acme Corporation provides 20 days of paid vacation per year for full-time employees. Employees must submit vacation requests at least 2 weeks in advance and receive approval from their manager. Vacation days do not roll over to the next year and must be used within the calendar year.",
  role: "assistant",
  message_type: "answer",
  chat_session: acme_chat,
  user: regular_user
)

# Law firm chat session
legal_chat = Chat::Models::ChatSession.create!(
  title: "Contract Review",
  status: "active",
  last_activity_at: Time.current,
  user: lawyer_user,
  document_collection: legal_collection
)

Chat::Models::ChatMessage.create!(
  content: "What are the standard terms in our service agreement?",
  role: "user",
  message_type: "question",
  chat_session: legal_chat,
  user: lawyer_user
)

Chat::Models::ChatMessage.create!(
  content: "According to the Service Agreement Template, the standard terms include: 1) Service scope and deliverables, 2) Payment terms (net 30 days), 3) Liability limitations, 4) Confidentiality provisions, 5) Termination clauses (30-day notice required), and 6) Dispute resolution procedures. These terms should be reviewed and customized for each client engagement.",
  role: "assistant",
  message_type: "answer",
  chat_session: legal_chat,
  user: lawyer_user
)

puts "Seed data created successfully!"
puts "Created #{Users::Models::Customer.count} customers"
puts "Created #{Users::Models::User.count} users"
puts "Created #{Documents::Models::DocumentCollection.count} document collections"
puts "Created #{Documents::Models::Document.count} documents"
puts "Created #{Chat::Models::ChatSession.count} chat sessions"
puts "Created #{Chat::Models::ChatMessage.count} chat messages"

puts "\nSample login credentials:"
puts "Acme Corp Admin: admin@acme.com / password123"
puts "Acme Corp User: user@acme.com / password123"
puts "Law Firm Lawyer: lawyer@smithlaw.com / password123"
