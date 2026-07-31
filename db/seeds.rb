# Sample data for demonstrating the four queries the exercise asks for.
# Idempotent: re-running replaces the seeded records rather than duplicating them.
#
#   bin/rails db:seed

HealthJournalEntry.delete_all
Enrollment.delete_all
Client.delete_all
Provider.delete_all

# --- Providers -------------------------------------------------------------

dana = Provider.create!(name: "Dana Reyes, RD", email: "dana@example-practice.com")
omar = Provider.create!(name: "Omar Silva, RD", email: "omar@example-practice.com")

# --- Clients ---------------------------------------------------------------

jules = Client.create!(name: "Jules Park", email: "jules@example.com")
robin = Client.create!(name: "Robin Alvarez", email: "robin@example.com")
sam   = Client.create!(name: "Sam Okafor", email: "sam@example.com")

# --- Enrollments -----------------------------------------------------------
# Robin sees both providers, on a different plan with each — the case that
# forces plan_type onto the join rather than onto Client.

Enrollment.create!(client: jules, provider: dana, plan_type: "premium")
Enrollment.create!(client: robin, provider: dana, plan_type: "basic")
Enrollment.create!(client: robin, provider: omar, plan_type: "premium")
Enrollment.create!(client: sam,   provider: omar, plan_type: "basic")

# --- Journal entries -------------------------------------------------------
# Backdated and interleaved across clients so ordering is visible.

[
  [ jules, "Started the new meal plan today.",            10.days.ago ],
  [ robin, "Ran 5k without stopping for the first time.",  8.days.ago ],
  [ jules, "Two weeks in, sleeping better.",               5.days.ago ],
  [ sam,   "Logged everything I ate this week.",           3.days.ago ],
  [ robin, "Energy dipped in the afternoon again.",        1.day.ago ]
].each do |client, body, created_at|
  HealthJournalEntry.create!(client: client, body: body, created_at: created_at)
end
