# Mermaid Diagrams (~20KB)

Tests Mermaid rendering performance. Each diagram requires async dynamic import
of the mermaid library and individual render calls.

## Flowchart

```mermaid
flowchart TD
    A([Start]) --> B{User authenticated?}
    B -->|No| C[Redirect to login]
    C --> D[Show login form]
    D --> E{Valid credentials?}
    E -->|No| F[Show error]
    F --> D
    E -->|Yes| G[Generate JWT]
    G --> H[Set cookie]
    B -->|Yes| I{Token expired?}
    I -->|Yes| J[Refresh token]
    J --> K{Refresh valid?}
    K -->|No| C
    K -->|Yes| L[Issue new token]
    L --> M[Continue request]
    I -->|No| M
    H --> M
    M --> N([End])
```

## Sequence Diagram

```mermaid
sequenceDiagram
    participant U as User
    participant F as Frontend
    participant A as API Gateway
    participant S as Auth Service
    participant D as Database
    participant C as Cache

    U->>F: Click "Login"
    F->>A: POST /auth/login {credentials}
    A->>S: Validate credentials
    S->>C: GET user:{email}
    alt Cache hit
        C-->>S: Return cached user
    else Cache miss
        S->>D: SELECT * FROM users WHERE email=?
        D-->>S: User record
        S->>C: SET user:{email} TTL=300
    end
    S->>S: Verify password hash
    S->>S: Generate JWT (15min) + Refresh (7d)
    S-->>A: {accessToken, refreshToken}
    A-->>F: 200 OK {tokens}
    F->>F: Store tokens securely
    F-->>U: Redirect to dashboard
```

## Class Diagram

```mermaid
classDiagram
    class Entity {
        +UUID id
        +DateTime createdAt
        +DateTime updatedAt
        +validate() bool
        +toJSON() string
    }

    class User {
        +string email
        +string passwordHash
        +string displayName
        +UserRole role
        +bool isActive
        +updatePassword(newHash: string)
        +deactivate()
    }

    class Organization {
        +string name
        +string slug
        +Plan plan
        +int memberCount
        +addMember(user: User)
        +removeMember(userId: UUID)
        +upgradePlan(plan: Plan)
    }

    class Membership {
        +UUID userId
        +UUID organizationId
        +MemberRole role
        +DateTime joinedAt
        +changeRole(role: MemberRole)
    }

    class Document {
        +string title
        +string content
        +string contentType
        +UUID authorId
        +UUID organizationId
        +bool isPublic
        +publish()
        +archive()
        +fork() Document
    }

    class Comment {
        +string body
        +UUID authorId
        +UUID documentId
        +UUID parentId
        +edit(body: string)
        +delete()
    }

    Entity <|-- User
    Entity <|-- Organization
    Entity <|-- Document
    Entity <|-- Comment
    Entity <|-- Membership

    User "1" --> "many" Membership
    Organization "1" --> "many" Membership
    User "1" --> "many" Document : authors
    Organization "1" --> "many" Document : owns
    Document "1" --> "many" Comment
    Comment "0..1" --> "many" Comment : replies
```

## State Diagram

```mermaid
stateDiagram-v2
    [*] --> Draft

    Draft --> InReview : submit()
    Draft --> Archived : archive()

    InReview --> Draft : requestChanges()
    InReview --> Approved : approve()
    InReview --> Rejected : reject()

    Approved --> Published : publish()
    Approved --> Draft : reopen()

    Published --> Archived : archive()
    Published --> Draft : unpublish()

    Rejected --> Draft : reopen()
    Rejected --> Archived : archive()

    Archived --> [*]

    state InReview {
        [*] --> PendingReview
        PendingReview --> UnderReview : assignReviewer()
        UnderReview --> PendingReview : unassign()
    }
```

## Gantt Chart

```mermaid
gantt
    title FluxMarkdown Development Timeline
    dateFormat  YYYY-MM-DD
    section Architecture
    Design spec           :done, arch1, 2024-01-01, 2024-01-07
    Review & approval     :done, arch2, after arch1, 5d
    section Core Renderer
    markdown-it setup     :done, core1, 2024-01-08, 5d
    Syntax highlighting   :done, core2, after core1, 7d
    KaTeX integration     :done, core3, after core2, 5d
    Mermaid integration   :done, core4, after core3, 7d
    section Swift Bridge
    WKWebView setup       :done, swift1, 2024-01-15, 5d
    JS bridge protocol    :done, swift2, after swift1, 5d
    File monitoring       :done, swift3, after swift2, 3d
    section Features
    TOC panel             :done, feat1, 2024-02-01, 7d
    Search functionality  :done, feat2, after feat1, 7d
    Zoom & scroll memory  :done, feat3, after feat2, 5d
    section Performance
    Baseline measurement  :active, perf1, 2025-02-01, 7d
    JS layer optimization :perf2, after perf1, 14d
    Swift layer opt       :perf3, after perf2, 7d
    section Release
    Beta testing          :2025-03-01, 14d
    v2.0 release          :milestone, 2025-03-15, 0d
```

## Entity Relationship Diagram

```mermaid
erDiagram
    USERS {
        uuid id PK
        string email UK
        string password_hash
        string display_name
        enum role
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    ORGANIZATIONS {
        uuid id PK
        string name
        string slug UK
        enum plan
        timestamp created_at
    }

    MEMBERSHIPS {
        uuid user_id FK
        uuid organization_id FK
        enum role
        timestamp joined_at
    }

    DOCUMENTS {
        uuid id PK
        string title
        text content
        uuid author_id FK
        uuid organization_id FK
        boolean is_public
        enum status
        timestamp created_at
        timestamp updated_at
    }

    COMMENTS {
        uuid id PK
        text body
        uuid author_id FK
        uuid document_id FK
        uuid parent_id FK
        timestamp created_at
    }

    TAGS {
        uuid id PK
        string name UK
        string color
    }

    DOCUMENT_TAGS {
        uuid document_id FK
        uuid tag_id FK
    }

    USERS ||--o{ MEMBERSHIPS : "has"
    ORGANIZATIONS ||--o{ MEMBERSHIPS : "has"
    USERS ||--o{ DOCUMENTS : "authors"
    ORGANIZATIONS ||--o{ DOCUMENTS : "owns"
    DOCUMENTS ||--o{ COMMENTS : "has"
    COMMENTS ||--o{ COMMENTS : "replies to"
    DOCUMENTS }o--o{ TAGS : "tagged with"
```

## Pie Chart

```mermaid
pie title Bundle Size Distribution (Before Optimization)
    "highlight.js" : 38
    "mermaid" : 28
    "KaTeX" : 18
    "markdown-it" : 6
    "CSS & fonts" : 7
    "App code" : 3
```

## Git Graph

```mermaid
gitGraph
   commit id: "Initial commit"
   commit id: "Add markdown-it"
   branch feature/mermaid
   checkout feature/mermaid
   commit id: "Add mermaid support"
   commit id: "Fix mermaid theming"
   checkout main
   merge feature/mermaid id: "Merge mermaid"
   branch feature/katex
   checkout feature/katex
   commit id: "Add KaTeX"
   commit id: "Add KaTeX CSS"
   checkout main
   branch fix/process-pool
   checkout fix/process-pool
   commit id: "Add shared process pool"
   checkout main
   merge fix/process-pool
   merge feature/katex id: "Merge KaTeX"
   commit id: "Release v1.13"
   branch performance/baseline
   checkout performance/baseline
   commit id: "Add benchmark fixtures"
   commit id: "Add JS benchmark"
```
