# Mock Connectors

A collection of **self-contained mock connectors for Workato** (built with the
[Connector SDK](https://docs.workato.com/developing-connectors/sdk.html)), made for **live
demos and enablement**. Each mock mirrors a real connector's object model and
action/trigger surface, but serves **embedded demo data** — so you can show realistic,
end-to-end Workato recipes without a live system, credentials, or network access.

## Why this exists

Demoing an integration usually means standing up a real source system, loading sample data,
and managing auth — fragile and slow on a sales/enablement call. These mock connectors remove
all of that:

- **No external HTTP** — actions and triggers never make a network call.
- **No credentials** — connection uses `authorization: { type: 'none' }`; nothing to configure.
- **Embedded, believable data** — internally-consistent sample records baked into each
  connector, often in multiple industry flavors.
- **Stateless, simulated writes** — `create`/`update`/`upsert`/`delete` synthesize and return
  realistic result records (real-looking IDs + timestamps) without persisting anything.
- **Schema parity** — field names, casing, and types match the real connector, so recipes
  look exactly like the genuine article.

The result: paste one file into a Workato custom SDK connector, connect instantly, and build
a working recipe in minutes.

## What's in here

The repo is organized **one folder per mocked system**:

| Folder | Mocks | Highlights |
| --- | --- | --- |
| [salesforce/](salesforce/) | **Salesforce** | 6 objects (Account, Contact, Lead, Opportunity, Case, User), 6 actions, 2 polling triggers, SOQL-lite. Ships in **5 industry verticals** (Financial Services, Healthcare, Manufacturing, Retail, Technology) with a per-vertical demo playbook. |
| [epic-fhir/](epic-fhir/) | **Epic on FHIR (HL7 FHIR R4)** | 8 FHIR R4 resources, CRUD + search → Bundle, 2 polling triggers, FHIR-search-lite (params + date prefixes). Ships in **2 variants** — Provider (clinical) and Payer (coverage/claims) — with a per-variant demo playbook. |
| [workday-hcm/](workday-hcm/) | **Workday HCM** | 4 objects (Worker, Position, Organization, Leave Request), 6 actions, 3 object-bound polling triggers for the **joiner / mover / leaver (JML)** pattern. Ships today in the **Financial Services** vertical (Meridian Capital Bank) with joiner/mover/leaver/leave demo playbooks; more verticals are clones with swapped data. |

See each folder's own README for the object/action/trigger reference, setup steps, and demo
scenarios. → [salesforce/README.md](salesforce/README.md) · [epic-fhir/README.md](epic-fhir/README.md) · [workday-hcm/README.md](workday-hcm/README.md)

*More mocked systems can be added as sibling folders following the same pattern.*

## Using a mock connector (high level)

1. Open the folder for the system you want to demo (e.g. [salesforce/](salesforce/)).
2. In Workato, **Create → Connector SDK**, and paste the chosen `connector_*.rb` into the
   **Source code** tab; **Save**.
3. **Connect** (no credentials needed), then **Release latest version**.
4. **Build a recipe** that uses the connector's actions/triggers and run it.

Each folder's README gives the exact steps, the operation names, and copy-paste field values
for a guided demo.

## Design conventions (shared by all mocks)

- All seed data lives **inline** in the connector file (a `mock_data` method) — each file is
  fully self-contained; nothing is loaded externally.
- Reusable logic (data access, filtering, ID generation) lives in `methods` and is invoked
  with `call(...)`.
- Datetimes are ISO-8601; numbers/booleans use real types; IDs imitate the real system's
  format.
- A short **"simulated vs. faithfully reproduced"** note in each folder's README makes it
  clear on a demo call what's real schema/behavior vs. a demo shortcut.

## Adding a new mock connector

1. Create a new top-level folder named after the system (e.g. `netsuite/`, `servicenow/`).
2. Add one self-contained `connector*.rb` per variant, following the conventions above.
3. Add a folder README (object/action/trigger reference + setup + demo scenarios).
4. Add a row to the **What's in here** table above.
