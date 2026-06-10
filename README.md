# Mock Salesforce Connector (Workato Connector SDK)

A **self-contained mock of Workato's standard Salesforce connector**, built for live
demos. It mirrors the standard connector's object model and action/trigger surface but
serves **embedded demo data** for a believable mid-market **financial-services** CRM
(banks, insurers, wealth managers, payments, credit unions).

- **No external HTTP** — actions and triggers never make a network call.
- **No credentials** — `authorization: { type: 'none' }`; the only connection field is a
  display-only "Instance label".
- **Stateless writes** — a Workato connector doesn't persist state between executions, so
  `create` / `update` / `upsert` / `delete` **synthesize and return** a realistic result
  record (generated 18-char Salesforce-style Id + timestamps) instead of mutating the
  embedded dataset.

Everything lives in [`connector.rb`](connector.rb). All seed data is inline in the
`mock_data` method — nothing is loaded from external files.

---

## Objects & data

Six objects, each with a static schema and internally-consistent seed records
(Contacts / Opportunities / Cases reference real `AccountId`s; records reference real
`OwnerId`s in `User`):

| Object | Seed records | Notable fields |
|---|---|---|
| **Account** | 6 | Id, Name, Industry, AnnualRevenue, Type, OwnerId, Website, CreatedDate, LastModifiedDate |
| **Contact** | 7 | Id, FirstName, LastName, Email, Title, AccountId, OwnerId, Phone, … |
| **Lead** | 5 | Id, FirstName, LastName, Company, Email, Status, LeadSource, IsConverted, … |
| **Opportunity** | 6 | Id, Name, AccountId, StageName, Amount, CloseDate, Probability, IsClosed, IsWon, … |
| **Case** | 5 | Id, CaseNumber, Subject, Status, Priority, AccountId, ContactId, OwnerId, … |
| **User** | 5 | Id, Name, Email, IsActive, Username |

Sample accounts: *Meridian Capital Bank*, *Harbor Mutual Insurance*, *Vantage Wealth
Advisors*, *Cobalt Payments*, *Summit Credit Union*, *Ironclad Asset Management*.

## Actions

One action set covers all objects — the object is chosen via the `objects` pick list and
I/O is driven by the dynamic `object_definitions` schema.

| Action | Behavior |
|---|---|
| `get_record` | Object + Id → matching seed record, or a Salesforce-style `NOT_FOUND` error. |
| `search_records` | Object + structured filter rows and/or a raw SOQL-lite string → `{ totalSize, done, records }`. |
| `create_record` | Generates a new Id + `CreatedDate`/`LastModifiedDate = now`, echoes the record (simulated). |
| `update_record` | Merges input over the located/synthesized record, bumps `LastModifiedDate` (simulated). |
| `upsert_record` | Matches by Id → `{ created, id, record }` (simulated). |
| `delete_record` | → `{ id, success: true, errors: [] }` (simulated). |

## Triggers (polling)

| Trigger | Behavior |
|---|---|
| `new_record` | Returns seed records where `CreatedDate > closure.since`; first poll defaults `since` to `1970-01-01` so all flow once; dedup on `Id`. |
| `new_or_updated_record` | Same pattern keyed on `LastModifiedDate`. |

## SOQL-lite

`search_records` accepts a raw query in a small SOQL subset:

```
SELECT <fields|*> FROM <Object> [WHERE <field> <op> <value> [AND <field> <op> <value> ...]]
```

Operators: `=  !=  >  >=  <  <=  LIKE  IN`. String literals are single-quoted; `LIKE` uses
SQL-style `%` wildcards; `IN` takes a parenthesized list. Unparseable queries raise a
friendly error. Structured filter rows are the primary path; raw SOQL is a convenience for
demoing query-style flows.

---

## Run it locally

Requires Ruby and the [`workato-connector-sdk`](https://github.com/workato/workato-connector-sdk) gem.

```bash
gem install workato-connector-sdk
```

There is no auth, so no `settings.yaml` is needed (pass `--settings` only if your SDK
version requires it — an empty `{}` file works).

### Read a record

```bash
workato exec actions.get_record.execute \
  --input='{"object":"Account","Id":"001RM0000001AAAAAA"}'
```

### Search with a structured filter

```bash
workato exec actions.search_records.execute \
  --input='{"object":"Account","filters":[{"field":"Industry","operator":"=","value":"Banking"}]}'
```

### Search with raw SOQL-lite

```bash
workato exec actions.search_records.execute \
  --input='{"object":"Account","soql":"SELECT Id, Name FROM Account WHERE Industry = '"'"'Banking'"'"'"}'
```

### Create a record (simulated)

```bash
workato exec actions.create_record.execute \
  --input='{"object":"Contact","FirstName":"Ada","LastName":"Lovelace","Email":"ada@example.com","AccountId":"001RM0000001AAAAAA"}'
```

### Poll a trigger

```bash
workato exec triggers.new_record.poll --input='{"object":"Opportunity"}'
```

> **Windows PowerShell tip:** single-quote escaping differs. Put the JSON in a file and use
> `--input=input.json`, e.g.
> `'{"object":"Account","Id":"001RM0000001AAAAAA"}' | Set-Content input.json`,
> then `workato exec actions.get_record.execute --input=input.json`. These throwaway input
> files hold only *call inputs*, never connector data.

### Interactive console

```bash
workato edit connector.rb     # validate / inspect
workato exec --help           # full CLI reference
```

---

## Standard-connector behaviors: simulated vs. faithfully reproduced

**Faithfully reproduced**

- Salesforce object model and **field names / casing / types** (`Id`, `AccountId`,
  `OwnerId`, `StageName`, `Amount`, `IsClosed`, `CreatedDate`, `LastModifiedDate`, …).
- Single object selector (`pick_list`) + dynamic `object_definitions` schema driving every
  action and trigger's inputs/outputs.
- Salesforce-style **18-char Ids** with correct object key prefixes
  (`001` Account, `003` Contact, `00Q` Lead, `006` Opportunity, `500` Case, `005` User).
- `NOT_FOUND` error shape for missing records.
- **Polling trigger semantics**: closure-based `since` cursor, far-past default on first
  poll, `dedup`, `sample_output`.
- ISO-8601 datetimes; currency/revenue as numbers; real booleans.

**Simulated (demo shortcuts)**

- **All data is embedded** in `mock_data` — there is no real org, no auth, and no API call.
- **Writes are stateless**: `create`/`update`/`upsert`/`delete` return a synthesized,
  realistic record but **persist nothing**. Re-reading after a "create" will not find it.
- **SOQL-lite** is a deliberate subset (single-level `WHERE` with `AND`, the operators
  above) — not the full SOQL grammar (no joins, subqueries, `ORDER BY`, `LIMIT`, functions).
- `totalSize` reflects matches in the mock dataset only.
- Field-level validation, picklist enforcement, and governor limits are not simulated.
