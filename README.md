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

## Startign the app

```bash
docker compose up
rails s
```
