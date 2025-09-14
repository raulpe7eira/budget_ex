# BudgetEx

A collaborative budget tracking application built with Phoenix LiveView and Elixir.

## About

This project is based on the YouTube playlist tutorial series by [Christian Alexander](https://github.com/ChristianAlexander) available at:
https://youtube.com/playlist?list=PL31bV6MaFAPllC8JP0vaRKrVm5kj7c1vc

## Architecture

```mermaid
graph TB
    subgraph "Frontend Layer"
        A[Phoenix LiveView Pages]
        A1[BudgetListLive]
        A2[BudgetShowLive]
        A3[PeriodShowLive]
        A4[UserAuthLives]
        A --> A1
        A --> A2
        A --> A3
        A --> A4
    end

    subgraph "Web Layer (BudgetExWeb)"
        B[Router]
        C[Controllers]
        D[LiveView Components]
        E[Authentication Pipeline]
        B --> C
        B --> A
        E --> A
    end

    subgraph "Context Layer (BudgetEx)"
        F[Accounts Context]
        G[Tracking Context]

        subgraph "Accounts"
            F1[User]
            F2[UserToken]
            F3[UserNotifier]
            F --> F1
            F --> F2
            F --> F3
        end

        subgraph "Tracking"
            G1[Budget]
            G2[BudgetPeriod]
            G3[BudgetTransaction]
            G4[BudgetCollaborator]
            G5[BudgetJoinLink]
            G --> G1
            G --> G2
            G --> G3
            G --> G4
            G --> G5
        end
    end

    subgraph "Data Layer"
        H[PostgreSQL Database]
        I[Ecto Repo]
        J[Migrations]
        I --> H
        J --> H
    end

    subgraph "Asset Pipeline"
        K[Tailwind CSS]
        L[Esbuild JavaScript]
        M[Heroicons]
        N[Static Assets]
        K --> N
        L --> N
        M --> N
    end

    A --> B
    C --> F
    C --> G
    A --> F
    A --> G
    F --> I
    G --> I
    A --> N

    classDef context fill:#e1f5fe
    classDef web fill:#f3e5f5
    classDef data fill:#e8f5e8
    classDef assets fill:#fff3e0

    class F,G context
    class A,B,C,D,E web
    class H,I,J data
    class K,L,M,N assets
```

## Features

- **User Authentication**: Registration, login, password reset with email confirmation
- **Collaborative Budgets**: Create budgets and invite collaborators via shareable links
- **Budget Periods**: Organize budgets into time-based periods (monthly, quarterly, etc.)
- **Transaction Management**: Track income and expenses within budget periods
- **Real-time Updates**: LiveView provides real-time collaboration without page refreshes
- **Responsive Design**: Built with Tailwind CSS for mobile-friendly interface

## Getting Started

### Prerequisites

Make sure you have PostgreSQL running. You can use Docker Compose to start a PostgreSQL instance:

```bash
docker compose up postgres
```

### Setup and Run

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
