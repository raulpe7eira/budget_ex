# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Development
- `mix setup` - Install dependencies, setup database, and build assets
- `mix phx.server` - Start Phoenix server at localhost:4000
- `iex -S mix phx.server` - Start server with interactive Elixir shell

### Database
- `mix ecto.create` - Create database
- `mix ecto.migrate` - Run migrations
- `mix ecto.reset` - Drop and recreate database with seeds
- `mix run priv/repo/seeds.exs` - Run seed data

### Testing
- `mix test` - Run all tests (automatically creates test DB and runs migrations)
- `mix test test/path/to/specific_test.exs` - Run a specific test file
- `mix test --cover` - Run tests with coverage (uses ExCoveralls)

### Assets
- `mix assets.build` - Build CSS and JS assets for development
- `mix assets.deploy` - Build and minify assets for production
- After project rename issues, always run `mix assets.deploy` to recompile

## Architecture

### Project Structure
BudgetEx is a Phoenix 1.7+ LiveView application for collaborative budget tracking. The project was recently renamed from "Budget" to "BudgetEx" - ensure all references use the new naming.

### Core Contexts

**BudgetEx.Accounts** - User authentication and management
- Handles registration, login, password reset, email confirmation
- Uses Argon2 for password hashing
- Token-based email verification system

**BudgetEx.Tracking** - Core budget functionality
- `Budget` - Main budget entity with creator and collaborators
- `BudgetPeriod` - Time-based budget periods with start/end dates
- `BudgetTransaction` - Financial transactions (income/expense) within periods
- `BudgetCollaborator` - Users who can access a budget
- `BudgetJoinLink` - Shareable links for joining budgets

### Key Domain Logic

**Budget Query System**: The Tracking context uses a flexible criteria-based query system:
```elixir
# Example usage
BudgetEx.Tracking.list_budgets(user: user, preload: [:periods, :collaborators])
```

**Transaction Periods**: Transactions are automatically associated with budget periods based on their effective date using SQL date range queries.

**Collaborative Access**: Budgets can be shared via join links (with codes) and users can be added as collaborators.

### Web Layer (BudgetExWeb)

**LiveView Pages**:
- `BudgetListLive` - Main budget dashboard
- `BudgetShowLive` - Individual budget view with transactions
- `PeriodShowLive` - Detailed period view with transaction management
- User auth pages (registration, login, settings, etc.)

**Authentication Pipeline**:
- `:require_authenticated_user` - For protected pages
- `:redirect_if_user_is_authenticated` - For login/register pages
- Uses session-based authentication with secure tokens

### Database
- PostgreSQL with Ecto migrations
- Uses binary UUIDs for primary keys (`binary_id: true` in generators)
- Database operations often use Ecto.Multi for transactional consistency

### Frontend
- Phoenix LiveView with Tailwind CSS
- Heroicons for UI icons
- Esbuild for JavaScript bundling
- Asset compilation configuration in `mix.exs` aliases

### Testing
- ExMachina for test data factories (see `test/support/factory.ex`)
- ExCoveralls for code coverage
- LiveView testing utilities for integration tests

### Important Note on Project Rename
The project was renamed from "Budget" to "BudgetEx". When working with assets:
1. Verify Tailwind config paths point to `lib/budget_ex_web/**/*.*ex`
2. Check dev.exs live_reload patterns reference `budget_ex_web`
3. Run `mix assets.deploy` after any configuration changes