# Mock Salesforce Connectors — Vertical Demo Pack (Workato Connector SDK)

Self-contained mocks of Workato's **standard Salesforce connector**, built for live demos.
Each file mirrors the standard connector's object model and action/trigger surface but
serves **embedded demo data** tailored to an industry — so an SE can pick the vertical that
matches the prospect and run a believable, network-free Salesforce demo.

- **No external HTTP** — actions and triggers never make a network call.
- **No credentials** — `authorization: { type: 'none' }`; the only connection field is a
  display-only "Instance label".
- **Stateless writes** — a Workato connector doesn't persist state between executions, so
  `create` / `update` / `upsert` / `delete` **synthesize and return** a realistic result
  record (generated 18-char Salesforce-style Id + timestamps) instead of mutating the seed
  data.

## Verticals (one connector file each)

| File | Vertical | Sample accounts |
|---|---|---|
| [connector_financial_services.rb](connector_financial_services.rb) | Financial Services | Meridian Capital Bank, Harbor Mutual Insurance, Vantage Wealth Advisors, Cobalt Payments, Summit Credit Union, Ironclad Asset Management |
| [connector_healthcare.rb](connector_healthcare.rb) | Healthcare / Life Sciences | Cedar Valley Health System, Northstar Pediatric Group, Helix Genomics, Asclepius Medical Devices, BlueRiver Health Plan, Meridian Home Care |
| [connector_manufacturing.rb](connector_manufacturing.rb) | Manufacturing / Industrial | Titan Industrial Equipment, Ferrous Steel Works, Apex Robotics, Cascade Packaging, Continental Auto Parts, Granite Tooling |
| [connector_retail.rb](connector_retail.rb) | Retail / E-commerce | Lark & Finch Apparel, Summit Outdoor Co., Harborview Grocers, Glow Beauty, UrbanNest Home, Pace Athletics |
| [connector_technology.rb](connector_technology.rb) | Technology / B2B SaaS | Northwind Software, Quantum Analytics, Cloudpeak Systems, Bitforge DevTools, Lumen AI, Stackline Security |

> **The connector logic is identical across all five files.** Only the embedded `mock_data`
> (and the `title` / instance label) differs. Anything you learn about one applies to all.

---

## Shared reference (applies to every vertical)

### Objects & schema

Six objects, each with a static Salesforce schema and internally-consistent seed records
(Contacts/Opportunities/Cases reference real `AccountId`s; every record references a real
`OwnerId` in `User`; Cases reference a real `ContactId`):

| Object | Records | Key fields |
|---|---|---|
| **Account** | 6 | Id, Name, Industry, AnnualRevenue, Type, OwnerId, Website, CreatedDate, LastModifiedDate |
| **Contact** | 7 | Id, FirstName, LastName, Email, Title, AccountId, OwnerId, Phone, … |
| **Lead** | 5 | Id, FirstName, LastName, Company, Email, Status, LeadSource, IsConverted, … |
| **Opportunity** | 6 | Id, Name, AccountId, StageName, Amount, CloseDate, Probability, IsClosed, IsWon, … |
| **Case** | 5 | Id, CaseNumber, Subject, Status, Priority, AccountId, ContactId, OwnerId, … |
| **User** | 5 | Id, Name, Email, IsActive, Username |

**Ids are identical across every vertical**, so any example Id works in any file:

| Object | Id range |
|---|---|
| User | `005RM0000001AAAAAA` … `005RM0000005EEEEEE` |
| Account | `001RM0000001AAAAAA` … `001RM0000006AAAAAA` |
| Contact | `003RM0000001AAAAAA` … `003RM0000007AAAAAA` |
| Lead | `00QRM0000001AAAAAA` … `00QRM0000005AAAAAA` |
| Opportunity | `006RM0000001AAAAAA` … `006RM0000006AAAAAA` |
| Case | `500RM0000001AAAAAA` … `500RM0000005AAAAAA` |

In every vertical, account `…0001` and `…0005` are the two largest, `…0004` and `…0006` are
`Type = Prospect` (the rest are `Customer`); opportunity `…0003` is `Closed Won` and `…0005`
is `Closed Lost`; the other four opps are open across early-funnel to late-funnel stages.

### Actions

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

### Triggers (polling)

| Trigger | Behavior |
|---|---|
| `new_record` | Returns seed records where `CreatedDate > closure.since`; first poll defaults `since` to `1970-01-01` so all flow once; dedup on `Id`. |
| `new_or_updated_record` | Same pattern keyed on `LastModifiedDate`. |

### SOQL-lite

`search_records` accepts a raw query in a small SOQL subset:

```
SELECT <fields|*> FROM <Object> [WHERE <field> <op> <value> [AND <field> <op> <value> ...]]
```

Operators: `=  !=  >  >=  <  <=  LIKE  IN`. String literals single-quoted; `LIKE` uses
SQL-style `%` wildcards; `IN` takes a parenthesized list. Unparseable queries raise a
friendly error. Structured filter rows are the primary path; raw SOQL is a convenience for
demoing query-style flows.

---

## Set up a connector in Workato

You demo these by creating a **custom Connector SDK connector** in Workato, pasting the code
in, and then **building a recipe** that uses its actions/triggers — no local tooling required.

1. **Sign in to Workato** and open the project (or folder) where you want the demo connector.
2. **Create the connector.** Click **Create → Connector SDK** (also reachable via
   **Tools → Connector SDK**). Give it a name, e.g. *Mock Salesforce – Financial Services*.
   The Connector SDK code editor opens.
3. **Paste the code.** In the **Source code** tab, select all of the starter template and
   replace it with the **entire contents** of the chosen `connector_<vertical>.rb` (the file
   is one Ruby hash beginning `{ title: … }`). Then click **Save code**.
4. **Set up the connection.** Open the **Connection** tab. The only field is the optional
   **Instance label** (display-only — leave the default or type a demo org name). Click
   **Connect**. Because `authorization` is `none`, it connects instantly: the `test:` lambda
   runs and returns a success payload. **No credentials are required.**
5. **Release the connector.** Click **Release latest version** so the connector becomes
   selectable in the recipe builder.
6. **Build a recipe.** **Create → Recipe**, pick a **trigger**, then add **action steps** that
   use your *Mock Salesforce (…)* connector — select the **Object** and fill the input fields
   with the values from the demo flows below. **Save**, then **Test** / run the recipe to
   demo. (For read/write actions, a simple **manual or scheduled trigger** is enough; for the
   trigger demos, the connector's own polling trigger *is* the recipe trigger.)

**One connector = one vertical.** Either create a separate SDK connector for each
`connector_<vertical>.rb`, or just swap the **Source code** of a single connector and
re-save to switch verticals between demos.

> The **Test code** console (right panel of the connector editor) is handy for a quick action
> check while developing — but the demo itself is the recipe you build in step 6.
>
> Exact menu labels vary slightly by Workato UI version, but the flow is always
> *create connector → paste source → connect → release → build recipe*.

**Operations (recipe trigger/action names)** — what you'll pick when adding a step:

| Code | Recipe step name |
|---|---|
| `get_record` | **Get record by ID** (action) |
| `search_records` | **Search records** (action) |
| `create_record` | **Create record** (action) |
| `update_record` | **Update record** (action) |
| `upsert_record` | **Upsert record** (action) |
| `delete_record` | **Delete record** (action) |
| `new_record` | **New record** (trigger) |
| `new_or_updated_record` | **New or updated record** (trigger) |

---

# Demo scenarios

Each playbook below is self-contained: **discovery questions** to open with, a **demo flow**
(each step is a tiny **recipe** — a trigger + one connector action), and a **talk track** that
ties each step back to the value of Workato + Salesforce. Set up the matching vertical
connector (paste its file, connect, release), then build the recipes below. The JSON under
each step lists the **field values** to enter in that action — Object plus its inputs.

The same five-beat flow works in every vertical:
1. **Get** a marquee account by Id — *manual trigger → Get record by ID* (show real SF schema).
2. **Search** with a structured filter — *manual trigger → Search records* (queryable data).
3. **SOQL-lite** query — *manual trigger → Search records* (query-style flows for SOQL audiences).
4. **Create/Update/Upsert** a record — *manual trigger → write action* (simulated write, real SF-style Id).
5. **Trigger** on new/updated records — *the connector's polling trigger is the recipe trigger* → a downstream notify/log step (event-driven sync, with dedup across runs).

---

## 1. Financial Services — `connector_financial_services.rb`

**Discovery questions**
- How do you sync customers and accounts between your core banking/policy system and Salesforce today?
- When a new account or opportunity is created, what downstream systems need to know (KYC, onboarding, billing)?
- How are service Cases (wire/payment issues, claims) routed and escalated across teams?
- Do your analysts query Salesforce data directly (SOQL/reports), or pull it into a warehouse?

**Demo flow** — each step is a small recipe (trigger + one connector action)

**1) Marquee account — Meridian Capital Bank** — *manual trigger → **Get record by ID***. Object **Account**, fields:
```json
{ "object": "Account", "Id": "001RM0000001AAAAAA" }
```
**2) All Banking accounts** — *manual trigger → **Search records*** (structured filter). Object **Account**, fields:
```json
{ "object": "Account", "filters": [{ "field": "Industry", "operator": "=", "value": "Banking" }] }
```
**3) High-value open pipeline** — *manual trigger → **Search records*** (SOQL-lite). Object **Opportunity**, fields:
```json
{ "object": "Opportunity", "soql": "SELECT Id, Name, Amount FROM Opportunity WHERE Amount > 500000 AND IsClosed = false" }
```
**4) Create a Contact under Meridian** — *manual trigger → **Create record*** (simulated write → new `003…` Id). Object **Contact**, fields:
```json
{ "object": "Contact", "FirstName": "Ada", "LastName": "Lovelace", "Title": "Treasury Analyst", "Email": "ada.lovelace@meridiancapital.example.com", "AccountId": "001RM0000001AAAAAA" }
```
**5) New Cases auto-route** — *recipe trigger **New record***, Object **Case** → add a notify/log step. Re-run to show only-new records + dedup:
```json
{ "object": "Case" }
```

**Talk track** — Open on Meridian to show the *real* Salesforce schema (`AnnualRevenue`,
`OwnerId`, `Industry`) flowing through Workato with zero custom mapping. The Banking filter
and SOQL query show you can target exactly the records a recipe needs. The Contact `create`
returns a genuine `003…` Salesforce-style Id and timestamps — "this is what your downstream
onboarding/KYC system would receive." The Case poll is the hook for an event-driven recipe:
"every new wire/claims Case can auto-route to the right queue or open a ServiceNow ticket."

**Key records to name-drop:** Meridian Capital Bank (`001RM0000001AAAAAA`), opportunity
*Meridian – Core Banking Modernization* (`006RM0000001AAAAAA`), Case *Wire transfer API
returning 500 errors* (`500RM0000001AAAAAA`).

---

## 2. Healthcare / Life Sciences — `connector_healthcare.rb`

**Discovery questions**
- How do you keep patient/account and provider records consistent between your EHR, payer systems, and Salesforce?
- When a referral or new patient-engagement opportunity is created, which systems need to react?
- How are integration Cases (HL7/FHIR, claims, portal access) triaged today?
- Are you moving toward FHIR APIs, and how does Salesforce fit that roadmap?

**Demo flow** — each step is a small recipe (trigger + one connector action)

**1) Marquee account — Cedar Valley Health System** — *manual trigger → **Get record by ID***. Object **Account**, fields:
```json
{ "object": "Account", "Id": "001RM0000001AAAAAA" }
```
**2) Provider accounts in a segment** — *manual trigger → **Search records*** (structured filter). Object **Account**, fields:
```json
{ "object": "Account", "filters": [{ "field": "Industry", "operator": "=", "value": "Hospitals & Providers" }] }
```
**3) Open EHR/portal pipeline** — *manual trigger → **Search records*** (SOQL-lite). Object **Opportunity**, fields:
```json
{ "object": "Opportunity", "soql": "SELECT Id, Name, StageName FROM Opportunity WHERE IsClosed = false AND Amount >= 250000" }
```
**4) Create a Contact at Cedar Valley** — *manual trigger → **Create record*** (simulated write). Object **Contact**, fields:
```json
{ "object": "Contact", "FirstName": "Grace", "LastName": "Hopper", "Title": "VP Clinical Informatics", "Email": "grace.hopper@cedarvalley.example.com", "AccountId": "001RM0000001AAAAAA" }
```
**5) New integration Cases auto-route** — *recipe trigger **New record***, Object **Case** → add a notify/log step. Re-run to show only-new records + dedup:
```json
{ "object": "Case" }
```

**Talk track** — Lead with Cedar Valley to show provider/payer schema flowing cleanly. The
Case poll is the star: subjects like *HL7 interface dropping ADT messages* and *FHIR API
returning 500 on appointment fetch* make the "auto-route integration incidents" story land
with technical buyers. The Opportunity SOQL query shows revenue-cycle/EHR pipeline you can
sync to a planning system. Emphasize that no PHI ever leaves the box — it's all mock.

**Key records:** Cedar Valley Health System (`001RM0000001AAAAAA`), *BlueRiver – Claims
Automation* (`006RM0000002AAAAAA`), Case *Claims 837 file rejected by clearinghouse*
(`500RM0000002AAAAAA`).

---

## 3. Manufacturing / Industrial — `connector_manufacturing.rb`

**Discovery questions**
- How do account, opportunity, and order data move between Salesforce and your ERP/MES today?
- When a deal closes, how does it become a work order or production schedule?
- How do plant/field service Cases (line-down, equipment) get routed and escalated?
- Do supplier/distributor relationships live in Salesforce, your ERP, or both?

**Demo flow** — each step is a small recipe (trigger + one connector action)

**1) Marquee account — Titan Industrial Equipment** — *manual trigger → **Get record by ID***. Object **Account**, fields:
```json
{ "object": "Account", "Id": "001RM0000001AAAAAA" }
```
**2) Automotive accounts** — *manual trigger → **Search records*** (structured filter). Object **Account**, fields:
```json
{ "object": "Account", "filters": [{ "field": "Industry", "operator": "=", "value": "Automotive" }] }
```
**3) Late-stage industrial deals** — *manual trigger → **Search records*** (SOQL-lite). Object **Opportunity**, fields:
```json
{ "object": "Opportunity", "soql": "SELECT Id, Name, StageName FROM Opportunity WHERE StageName = 'Negotiation/Review'" }
```
**4) Move a deal to Closed Won** — *manual trigger → **Update record*** (simulated write → bumps `LastModifiedDate`). Object **Opportunity**, fields:
```json
{ "object": "Opportunity", "Id": "006RM0000001AAAAAA", "StageName": "Closed Won", "Probability": 100, "IsClosed": true, "IsWon": true }
```
**5) Sync closed deals to ERP** — *recipe trigger **New or updated record***, Object **Opportunity** → add a notify/log step. Re-run after step 4 to show the update flow through + dedup:
```json
{ "object": "Opportunity" }
```

**Talk track** — Use the `update` → `new_or_updated_record` pairing here: move *Titan – MES
Rollout* to Closed Won, then show the updated-record trigger picking up the change. "The
moment a deal closes in Salesforce, Workato can push a work order into your ERP/MES." The
Automotive filter shows segment-based routing; the Case subjects (*Production line down – PLC
integration failure*, *Supplier EDI 856 ASN rejected*) anchor the service/supply-chain story.

**Key records:** Titan Industrial Equipment (`001RM0000001AAAAAA`), *Titan – MES Rollout*
(`006RM0000001AAAAAA`), Case *ERP sync dropping work orders* (`500RM0000002AAAAAA`).

---

## 4. Retail / E-commerce — `connector_retail.rb`

**Discovery questions**
- How do customer, order, and account records stay in sync across Salesforce, your e-comm platform, and OMS?
- When a high-value B2B/wholesale opportunity is created, what needs to happen downstream?
- How are customer-experience Cases (checkout, returns, loyalty) handled across channels?
- Are you replatforming toward headless commerce, and where does Salesforce sit?

**Demo flow** — each step is a small recipe (trigger + one connector action)

**1) Marquee account — Lark & Finch Apparel** — *manual trigger → **Get record by ID***. Object **Account**, fields:
```json
{ "object": "Account", "Id": "001RM0000001AAAAAA" }
```
**2) Customer (vs. prospect) accounts** — *manual trigger → **Search records*** (structured filter). Object **Account**, fields:
```json
{ "object": "Account", "filters": [{ "field": "Type", "operator": "=", "value": "Customer" }] }
```
**3) Brands in selected segments** — *manual trigger → **Search records*** (SOQL-lite, `IN` list). Object **Account**, fields:
```json
{ "object": "Account", "soql": "SELECT Id, Name, Industry FROM Account WHERE Industry IN ('Apparel & Fashion','Footwear/Athletics')" }
```
**4) Create a Lead from a web signup** — *manual trigger → **Create record*** (simulated write → new `00Q…` Id). Object **Lead**, fields:
```json
{ "object": "Lead", "FirstName": "Mia", "LastName": "Chen", "Company": "Cedarwood Outfitters", "Email": "mia@cedarwoodoutfitters.example.com", "Status": "Open - Not Contacted", "LeadSource": "Web" }
```
**5) New CX Cases auto-triage** — *recipe trigger **New record***, Object **Case** → add a notify/log step. Re-run to show only-new records + dedup:
```json
{ "object": "Case" }
```

**Talk track** — The `IN (...)` SOQL query is a nice flourish for retail audiences managing
many brands/segments. The Lead `create` mirrors a web-signup → Salesforce flow ("Workato
captures the storefront signup and lands a clean Lead with a real Id"). The Case poll —
*Checkout failing at payment step*, *Returns/RMA webhook not firing* — sets up the
"auto-triage CX incidents and notify the right channel team" recipe.

**Key records:** Lark & Finch Apparel (`001RM0000001AAAAAA`), *Harborview – Order Management
(OMS) Integration* (`006RM0000003AAAAAA`, Closed Won), Case *Inventory not syncing to
storefront* (`500RM0000002AAAAAA`).

---

## 5. Technology / B2B SaaS — `connector_technology.rb`

**Discovery questions**
- How do account, subscription, and usage data sync between Salesforce, your billing system, and product DB?
- When a deal closes or a plan upgrades, how is provisioning/entitlement triggered?
- How do support Cases (API, SSO, latency) flow between Salesforce and your engineering tools?
- Does RevOps query Salesforce directly, or replicate it into a warehouse?

**Demo flow** — each step is a small recipe (trigger + one connector action)

**1) Marquee account — Northwind Software** — *manual trigger → **Get record by ID***. Object **Account**, fields:
```json
{ "object": "Account", "Id": "001RM0000001AAAAAA" }
```
**2) SaaS accounts** — *manual trigger → **Search records*** (structured filter). Object **Account**, fields:
```json
{ "object": "Account", "filters": [{ "field": "Industry", "operator": "=", "value": "SaaS" }] }
```
**3) Open expansion/upgrade pipeline** — *manual trigger → **Search records*** (SOQL-lite). Object **Opportunity**, fields:
```json
{ "object": "Opportunity", "soql": "SELECT Id, Name, Amount FROM Opportunity WHERE IsClosed = false AND Probability >= 50" }
```
**4) Upsert an account by Id** — *manual trigger → **Upsert record*** (simulated → `created: false` on an existing Id). Object **Account**, fields:
```json
{ "object": "Account", "Id": "001RM0000001AAAAAA", "Type": "Customer", "AnnualRevenue": 260000000 }
```
**5) New support Cases auto-route** — *recipe trigger **New record***, Object **Case** → add a notify/log step. Re-run to show only-new records + dedup:
```json
{ "object": "Case" }
```

**Talk track** — The `upsert` against an existing Id returns `created: false`, which is the
perfect "idempotent sync" talking point for a technical SaaS audience ("Workato won't create
duplicates — match on Id/external Id and update in place"). The Probability-filtered SOQL is
your forecast/RevOps angle. The Case subjects — *REST API returning 429 rate-limit errors*,
*SSO SAML assertion rejected* — make the "route product incidents from Salesforce to
Jira/PagerDuty" story concrete.

**Key records:** Northwind Software (`001RM0000001AAAAAA`), *Cloudpeak – SSO/SCIM Rollout*
(`006RM0000003AAAAAA`, Closed Won), Case *Webhook deliveries failing intermittently*
(`500RM0000002AAAAAA`).

---

## Standard-connector behaviors: simulated vs. faithfully reproduced

**Faithfully reproduced**
- Salesforce object model and **field names / casing / types** (`Id`, `AccountId`,
  `OwnerId`, `StageName`, `Amount`, `IsClosed`, `CreatedDate`, `LastModifiedDate`, …).
- Single object selector (`pick_list`) + dynamic `object_definitions` schema driving every
  action and trigger's I/O.
- Salesforce-style **18-char Ids** with correct object key prefixes
  (`001` Account, `003` Contact, `00Q` Lead, `006` Opportunity, `500` Case, `005` User).
- `NOT_FOUND` error shape for missing records.
- **Polling trigger semantics**: closure-based `since` cursor, far-past default on first
  poll, `dedup`, `sample_output`.
- ISO-8601 datetimes; currency/revenue as numbers; real booleans.

**Simulated (demo shortcuts)**
- **All data is embedded** in each file's `mock_data` — no real org, no auth, no API call.
- **Writes are stateless**: `create`/`update`/`upsert`/`delete` return a synthesized,
  realistic record but **persist nothing**. Re-reading after a "create" will not find it.
- **SOQL-lite** is a deliberate subset (single-level `WHERE` with `AND`, the operators
  above) — not full SOQL (no joins, subqueries, `ORDER BY`, `LIMIT`, functions).
- `totalSize` reflects matches in the mock dataset only.
- Field-level validation, picklist enforcement, and governor limits are not simulated.
