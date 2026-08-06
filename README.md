# Simplified EHR

Rails app modeling providers (e.g. dietitians), their clients, and health journal entries.

## Data model

```
Provider ──< Enrollment >── Client ──< HealthJournalEntry
    └──────────────< HealthJournalEntry
```

| Model | Columns | Notes |
| --- | --- | --- |
| `Provider` | `name`, `email` | `email` unique |
| `Client` | `name`, `email` | `email` unique |
| `Enrollment` | `client_id`, `provider_id`, `plan_type` | join model; unique on `[client_id, provider_id]` |
| `HealthJournalEntry` | `client_id`, `provider_id`, `body` | sorted by `created_at` |

`Enrollment` is a `has_many :through` join rather than a plain `has_and_belongs_to_many`
because the plan is a property of the *pair*: a client can be premium with one provider and
basic with another. The unique index enforces one plan per client-provider pair.

Journal entries sort on `created_at`, assuming the time an entry is written is the time it
describes. If clients need to be able to backdate entries, I'd add an `entered_at` or
`entry_date` column (depending on if we want to track the datetime or just the date).

## The four queries

```ruby
provider.clients                              # all clients for a given provider
client.providers                              # all providers for a given client
client.health_journal_entries.newest_first    # a client's entries, sorted by date
provider.health_journal_entries.newest_first  # entries addressed to a provider, sorted
```

An entry names the provider it was written for, so `Provider has_many :health_journal_entries`
directly. A shared client's journal spans providers; each provider sees only its own slice of
it, while the client sees all of it.

## Running it locally

Requires Ruby (see `.ruby-version`). The database is SQLite, no external services needed.

```bash
bundle install
bin/rails db:prepare   # create + migrate
bin/rails db:seed      # sample data to run the queries against
```

`db:seed` clears and recreates the seeded records, so it's safe to re-run.

To poke at it directly:

```bash
bin/rails console
```

```ruby
Provider.first.clients
Client.first.health_journal_entries.newest_first
```

## Tests

```bash
bin/rails test
```

Model tests cover the associations in both directions, the per-pair plan, the unique-enrollment
constraint, and `newest_first` ordering.
