# Mock Epic on FHIR Connectors (HL7 FHIR R4)

Self-contained mocks of an **Epic-on-FHIR** connector for Workato, built for live demos. Each
file mirrors the **HL7 FHIR R4** REST surface (read / search / create / update / delete on any
resourceType) but serves **embedded clinical data** — so you can demo realistic FHIR recipes
with no live Epic sandbox, no OAuth, and no network access.

- **No external HTTP** — actions and triggers never make a network call.
- **No credentials** — `authorization: { type: 'none' }`; nothing to configure.
- **Stateless, simulated writes** — `create`/`update`/`delete` synthesize and return a real
  FHIR resource (generated `id` + `meta.versionId`/`meta.lastUpdated`) without persisting.
- **FHIR R4 fidelity** — faithful resource shapes: `resourceType`, `meta`, references
  (`{ reference, display }`), CodeableConcepts with real systems (LOINC, ICD-10-CM, RxNorm,
  SNOMED), Bundles for search, and OperationOutcome for errors.

## Variants (one connector file each)

| File | Variant | Resources (8) |
|---|---|---|
| [connector_provider.rb](connector_provider.rb) | **Provider / clinical** | Patient, Practitioner, Organization, Encounter, Appointment, Observation, Condition, MedicationRequest |
| [connector_payer.rb](connector_payer.rb) | **Payer / coverage & claims** | Patient (member), Coverage, Claim, ExplanationOfBenefit, Organization, Practitioner, Encounter, Condition |

The Provider mock models *Cedar Valley Health System* (patient records, scheduling, orders,
clinical documentation). The Payer mock models *BlueRiver Health Plan* (members, coverage,
claims, and explanation-of-benefit adjudication). **The connector logic is identical across
both files** — only the resource set and embedded data differ.

---

## Shared reference

### Resources & schema

Every resource carries `resourceType`, `id`, and `meta { versionId, lastUpdated }`, with
FHIR-accurate nesting. Seed data is internally consistent — Encounters/Observations/
Conditions/Claims/etc. reference real Patients, Practitioners, and Organizations.

### Actions

One action set covers all resources — the resource type is chosen via the `resource_types`
pick list and I/O is driven by the dynamic schema.

| Action | FHIR interaction | Behavior |
|---|---|---|
| `get_resource` | read `[type]/[id]` | Returns the matching resource, or raises a FHIR `OperationOutcome` not-found error. |
| `search_resources` | search `[type]?params` | Structured param rows and/or a raw query string → a FHIR **Bundle** (`type: searchset`, `total`, `entry[]`). |
| `create_resource` | create `POST [type]` | Generates `id` + `meta` (versionId 1, lastUpdated now), echoes the resource (simulated). |
| `update_resource` | update `PUT [type]/[id]` | Merges input, increments `meta.versionId`, bumps `lastUpdated` (simulated). |
| `delete_resource` | delete `[type]/[id]` | Returns an `OperationOutcome` success (simulated). |

### Triggers (polling)

| Trigger | Behavior |
|---|---|
| `new_resource` | Returns resources where `meta.lastUpdated > closure.since` (FHIR `_lastUpdated` semantics); first poll defaults `since` to `1970-01-01` so all flow once; dedup on `id`. |
| `new_or_updated_resource` | Same pattern; dedup on `id@versionId` so a re-versioned resource can fire again. |

### FHIR-search-lite

`search_resources` accepts structured **param / value** rows and/or a raw FHIR query string:

```
[ResourceType]?param1=value1&param2=value2
```

Supported params (pragmatic subset): `_id`, `_lastUpdated`, `identifier`, `name`, `family`,
`given`, `gender`, `birthdate`, `status`, `clinical-status`, `intent`, `code` (token, e.g.
LOINC/RxNorm), `category`, `patient`/`subject`, `encounter`, `organization`/`payor`/`insurer`,
`date`, `authoredon`. String params match case-insensitive substring; token params match
exact; reference params accept `Type/id` or a bare `id`; **date** params support FHIR prefixes
`eq` / `ne` / `ge` / `gt` / `le` / `lt` (e.g. `date=ge2026-06-01`). Anything else falls back to
an exact match on a top-level field.

### Response shapes

- **Search** → a FHIR `Bundle` `{ resourceType: "Bundle", type: "searchset", total, entry: [{ fullUrl, resource, search: { mode: "match" } }] }`.
- **Errors / delete** → a FHIR `OperationOutcome` `{ resourceType: "OperationOutcome", issue: [{ severity, code, diagnostics }] }`.

---

## Set up a connector in Workato

You demo these by creating a **custom Connector SDK connector** in Workato, pasting the code
in, and then **building a recipe** that uses its actions/triggers — no local tooling required.

1. **Sign in to Workato** and open the project (or folder) for the demo.
2. **Create the connector.** Click **Create → Connector SDK** (also under **Tools → Connector
   SDK**). Name it, e.g. *Mock Epic on FHIR – Provider*. The code editor opens.
3. **Paste the code.** In the **Source code** tab, replace the starter template with the
   **entire contents** of the chosen `connector_*.rb` (one Ruby hash beginning `{ title: … }`).
   **Save code**.
4. **Set up the connection.** Open the **Connection** tab. The only field is the optional
   **FHIR base URL label** (display-only). Click **Connect** — because `authorization` is
   `none`, it connects instantly (the `test:` lambda returns success). **No credentials.**
5. **Release the connector.** Click **Release latest version** so it's selectable in recipes.
6. **Build a recipe.** **Create → Recipe**, pick a **trigger**, add **action steps** that use
   your *Mock Epic on FHIR (…)* connector — select the **Resource type** and fill the input
   fields with the values from the demo flows below. **Save**, then run the recipe to demo.
   (For read/write actions a simple **manual/scheduled trigger** is enough; for the trigger
   demos, the connector's own polling trigger *is* the recipe trigger.)

> The **Test code** console (right panel of the connector editor) is handy for a quick action
> check while developing — but the demo itself is the recipe you build in step 6. Exact menu
> labels vary slightly by Workato UI version.

**Operations (recipe trigger/action names):** Get resource by ID, Search resources, Create
resource, Update resource, Delete resource (actions); New resource, New or updated resource
(triggers).

---

# Demo scenarios

Each step is a tiny **recipe** — a trigger + one connector action. The JSON under each step is
the **field values** to enter on that action (Resource type + its inputs). Set up the matching
variant connector (paste, connect, release), then build the recipes.

## 1. Provider / clinical — `connector_provider.rb`

**Discovery questions**
- How do you move patient, encounter, and order data between Epic (FHIR) and downstream systems today?
- When a new lab result or diagnosis is filed, what needs to react (care management, analytics, patient outreach)?
- How are referrals and appointment events integrated across your stack?
- Are you standardizing on FHIR R4 APIs, and where does Workato fit?

**Demo flow** — each step is a small recipe (trigger + one connector action)

**1) Read a patient — Martha Reynolds** — *manual trigger → **Get resource by ID***. Resource **Patient**, fields:
```json
{ "resource": "Patient", "id": "pat-mreynolds" }
```
**2) A patient's lab results** — *manual trigger → **Search resources***. Resource **Observation**, fields:
```json
{ "resource": "Observation", "params": [{ "param": "patient", "value": "pat-jcalderon" }, { "param": "category", "value": "laboratory" }] }
```
**3) An HbA1c result by LOINC code** — *manual trigger → **Search resources*** (raw FHIR query):
```json
{ "resource": "Observation", "query": "Observation?code=4548-4" }
```
**4) Upcoming appointments from a date** — *manual trigger → **Search resources*** (FHIR date prefix). Resource **Appointment**, fields:
```json
{ "resource": "Appointment", "params": [{ "param": "date", "value": "ge2026-06-15" }] }
```
**5) File a new diagnosis** — *manual trigger → **Create resource*** (simulated write → new FHIR id + meta). Resource **Condition**, fields:
```json
{ "resource": "Condition", "clinicalStatus": { "text": "Active" }, "code": { "coding": [{ "system": "http://hl7.org/fhir/sid/icd-10-cm", "code": "E66.9", "display": "Obesity, unspecified" }], "text": "Obesity" }, "subject": { "reference": "Patient/pat-mreynolds", "display": "Martha Reynolds" } }
```
**6) New/updated clinical results auto-flow** — *recipe trigger **New or updated resource***, Resource **Observation** → add a notify/log step. Re-run to show only-new + dedup:
```json
{ "resource": "Observation" }
```

**Talk track** — Open on a Patient to show real FHIR R4 schema (identifiers/MRN, name arrays,
references) flowing through Workato with no mapping gymnastics. The Observation search by
`patient` + `category` and the raw `?code=4548-4` (LOINC) query show FHIR-native targeting.
The Condition `create` returns a genuine FHIR resource with a generated `id` and `meta` — "this
is what your downstream care-management or analytics system receives." The
new-or-updated-Observation trigger is the event hook: "every new lab result can route to care
management, populate a data warehouse, or trigger patient outreach." No PHI leaves the box — all mock.

**Key resources to name-drop:** Martha Reynolds (`pat-mreynolds`), HbA1c result
(`obs-calderon-a1c`, LOINC 4548-4, High), Condition CAD (`cond-okafor-cad`, ICD-10 I25.10),
inpatient Encounter (`enc-okafor-001`).

## 2. Payer / coverage & claims — `connector_payer.rb`

**Discovery questions**
- How do member, coverage, and claims data flow between your core admin platform (FHIR) and downstream systems?
- When a claim is adjudicated, what needs to know (member portal, provider remittance, analytics)?
- How do you surface coverage/eligibility to partners and providers?
- Are you adopting the CMS interoperability (Patient Access / FHIR) APIs, and where does Workato fit?

**Demo flow** — each step is a small recipe (trigger + one connector action)

**1) Read a member's coverage** — *manual trigger → **Get resource by ID***. Resource **Coverage**, fields:
```json
{ "resource": "Coverage", "id": "cov-reynolds" }
```
**2) A member's claims** — *manual trigger → **Search resources***. Resource **Claim**, fields:
```json
{ "resource": "Claim", "params": [{ "param": "patient", "value": "pat-mreynolds" }] }
```
**3) Adjudicated EOBs by status** — *manual trigger → **Search resources*** (raw FHIR query):
```json
{ "resource": "ExplanationOfBenefit", "query": "ExplanationOfBenefit?status=active" }
```
**4) Coverage active in a period** — *manual trigger → **Search resources*** (FHIR date prefix). Resource **Coverage**, fields:
```json
{ "resource": "Coverage", "params": [{ "param": "patient", "value": "pat-jcalderon" }, { "param": "status", "value": "active" }] }
```
**5) Submit a new claim** — *manual trigger → **Create resource*** (simulated write → new FHIR id + meta). Resource **Claim**, fields:
```json
{ "resource": "Claim", "status": "active", "use": "claim", "patient": { "reference": "Patient/pat-snguyen", "display": "Sofia Nguyen" }, "provider": { "reference": "Organization/org-cvhs", "display": "Cedar Valley Health System" }, "total": { "value": 210.00, "currency": "USD" } }
```
**6) New EOBs trigger member notifications** — *recipe trigger **New resource***, Resource **ExplanationOfBenefit** → add a notify/log step. Re-run to show only-new + dedup:
```json
{ "resource": "ExplanationOfBenefit" }
```

**Talk track** — Lead with a Coverage record to show FHIR member/plan structure (payor,
class/group/plan, subscriber). Claims search by `patient` and the `?status=active` EOB query
show how Workato targets exactly the records a recipe needs; the EOB carries real adjudication
(`submitted`/`eligible`/`copay`/`benefit`) and a `payment`. The Claim `create` returns a
genuine FHIR resource — "this is what flows to your provider-remittance or analytics pipeline."
The new-EOB trigger is the member-experience hook: "every adjudicated EOB can push a member
notification or update the member portal." All data is mock — no PHI.

**Key resources:** Coverage `cov-reynolds` (BlueRiver PPO 2026), Claim `claim-calderon-001`
($320), EOB `eob-reynolds-001` (claim → `claim-reynolds-001`, benefit $170), payer Organization
`org-blueriver` (BlueRiver Health Plan).

---

## Standard-connector behaviors: simulated vs. faithfully reproduced

**Faithfully reproduced**
- FHIR R4 resource model and shapes: `resourceType`, `id`, `meta { versionId, lastUpdated }`,
  references (`{ reference, display }`), CodeableConcepts with real systems (LOINC, ICD-10-CM,
  RxNorm, SNOMED, HL7 terminology), identifiers with systems (MRN, NPI, member id).
- The FHIR REST interaction set (read / search / create / update / delete) via one
  resource-type pick list + dynamic schema.
- **Bundle** (`type: searchset`) search responses and **OperationOutcome** errors/delete.
- Common search params + FHIR **date prefixes**; incremental polling via `_lastUpdated`.
- ISO-8601 instants/dateTimes; `date` as `YYYY-MM-DD`; numeric quantities and money.

**Simulated (demo shortcuts)**
- **All data is embedded** in each file's `mock_data` — no real Epic/FHIR server, no OAuth/SMART, no API call.
- **Writes are stateless**: `create`/`update`/`delete` return a synthesized resource but
  **persist nothing**. Re-reading after a "create" will not find it.
- **FHIR-search-lite** is a deliberate subset — common params, `AND`-only, the prefixes above;
  not the full FHIR search grammar (no `_include`/`_revinclude`, chaining, `:modifiers`,
  composite params, `_sort`, paging).
- `Bundle.total` reflects matches in the mock dataset only.
- No SMART-on-FHIR scopes, `$operations` (e.g. `$everything`), conditional updates, or
  versioned reads (`vread`).
