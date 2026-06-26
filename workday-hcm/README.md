# Mock Workday HCM Connectors — Vertical Demo Pack (Workato Connector SDK)

Self-contained mocks of a **Workday HCM connector**, built for live demos. Each file mirrors
Workday's core HCM object model (Worker, Position, Organization, Leave Request) and a standard
action/trigger surface but serves **embedded demo data** tailored to an industry — so an SE can
run a believable, network-free **joiner / mover / leaver (JML)** demo without Workday
credentials, sandbox provisioning, or a live tenant.

- **No external HTTP** — actions and triggers never make a network call.
- **No credentials** — `authorization: { type: 'none' }`; the only connection field is a
  display-only "Tenant label".
- **Stateless writes** — a Workato connector doesn't persist state between executions, so
  `create` / `update` / `upsert` / `delete` **synthesize and return** a realistic result
  record (generated Workday-style ID + timestamps) instead of mutating the seed data. A
  re-read after a create will *not* find the created record.

## Verticals (one connector file each)

| File | Vertical | Organizations in seed data |
| --- | --- | --- |
| [connector_financial_services.rb](connector_financial_services.rb) | Financial Services | Meridian Capital Bank (+ departments & cost centers) |
| [connector_healthcare.rb](connector_healthcare.rb) | Healthcare | Cedar Valley Health System (clinicians shared with the Epic on FHIR mock) |
| [connector_manufacturing.rb](connector_manufacturing.rb) | Manufacturing | Titan Industrial Equipment |
| [connector_retail.rb](connector_retail.rb) | Retail | Lark & Finch Apparel |
| [connector_technology.rb](connector_technology.rb) | Technology | Northwind Software |

> **All five verticals are built.** The connector logic is vertical-agnostic — each variant is
> the same connector with the embedded `mock_data` (and the `title` / tenant label) swapped.
> Everything in the shared reference below applies to every variant.

Each workforce anchors on its vertical's company (above), drawn from the repo's **shared sample
world**. Recurring personas — **Eleanor Vance** (top executive), **Marcus Reyes** (HR director),
**Priya Raman** and **Tobias Greer** (directors; also Epic clinicians in Healthcare),
**James Whitfield** (the contractor / leaver), and **Maria Santos** (on-leave) — appear across the
Salesforce and Epic mocks too, so multi-system recipe demos feel like one enterprise. See
[../profiles/](../profiles/) for the full company/people roster and cross-connector identities.

---

## Shared reference (applies to every vertical)

### Objects & schema

Four objects, each with a static Workday schema and internally-consistent seed records (every
`Manager_ID`, `Cost_Center`, `Incumbent_ID`, `Parent_Org_ID`, leave `Worker_ID`, and
`Approved_By` resolves to a real seed record — no dangling references):

| Object | Records | Key fields |
| --- | --- | --- |
| **Worker** | 8 | Worker_ID, Employee_Number, Legal_Name *(nested)*, Preferred_Name *(nested)*, Email, Position_Title, Department, Cost_Center, Manager_ID, Hire_Date, Status, Worker_Type, Location, Work_Phone, Start_Date, Updated_At |
| **Position** | 6 | Position_ID, Title, Department, Grade, Is_Open, Headcount_Budget, Incumbent_ID |
| **Organization** | 5 | Org_ID, Name, Org_Type, Manager_ID, Parent_Org_ID, Member_Count |
| **Leave_Request** | 4 | Leave_ID, Worker_ID, Leave_Type, Start_Date, End_Date, Status, Total_Days, Submitted_Date, Approved_By |

> `Legal_Name` and `Preferred_Name` are **nested objects** (`{ First_Name, Last_Name }`),
> matching Workday's structure — not flat strings.

**ID formats** match Workday's convention exactly:

| Object | ID format | Seed range |
| --- | --- | --- |
| Worker | `WD-EMP-{6 digits}` | `WD-EMP-000001` … `WD-EMP-000008` |
| Position | `WD-POS-{6 digits}` | `WD-POS-000001` … `WD-POS-000006` |
| Organization | `WD-ORG-{6 digits}` | `WD-ORG-000001` … `WD-ORG-000005` |
| Leave Request | `WD-LVE-{6 digits}` | `WD-LVE-000001` … `WD-LVE-000004` |

Synthesized IDs from `create`/`upsert` use the `900000`–`999999` range (e.g. `WD-EMP-9xxxxx`)
so they never collide with seed records.

**The seed workforce** (a valid management hierarchy under Meridian Capital Bank):

| Worker | Name | Title | Dept | Manager | Status | Type |
| --- | --- | --- | --- | --- | --- | --- |
| `WD-EMP-000001` | Eleanor Vance | Chief Operating Officer | Executive | — | Active | Employee |
| `WD-EMP-000002` | Marcus Reyes | Director of Human Resources | Human Resources | `…0001` | Active | Employee |
| `WD-EMP-000003` | Priya Nair | Director of Information Technology | Technology | `…0001` | Active | Employee |
| `WD-EMP-000004` | David Okonkwo | Finance Manager | Finance | `…0001` | Active | Employee |
| `WD-EMP-000005` | Hannah Brooks | Financial Analyst | Finance | `…0004` | Active | Employee *(hired 2025-01-06)* |
| `WD-EMP-000006` | Daniel Osei | Systems Administrator | Technology | `…0003` | Active | Employee |
| `WD-EMP-000007` | Maria Santos | HR Generalist | Human Resources | `…0002` | **On_Leave** | Employee |
| `WD-EMP-000008` | James Whitfield | IT Support Contractor | Technology | `…0003` | Active | **Contractor** |

`WD-POS-000005` (Senior Software Engineer) is the one **open requisition** (`Is_Open = true`)
— the target of the joiner demo. `WD-LVE-000003` (Hannah Brooks, FMLA) is the one **Submitted**
leave request — the target of the leave-management demo. Worker `…0007`'s `On_Leave` status
ties to leave `WD-LVE-000001` (Maria Santos, Parental).

### Actions

One action set covers all objects — the object is chosen via the `objects` pick list and I/O
is driven by the dynamic `object_definitions` schema.

| Action | Behavior |
| --- | --- |
| `get_record` | Object + ID → matching seed record, or a Workday-style `Invalid ID value` error. |
| `search_records` | Object + structured filter rows and/or a free-text search string → `{ total, data }`. |
| `create_record` | Generates a new Workday-style ID + timestamp, echoes the record (simulated). |
| `update_record` | Merges input over the located/synthesized record, bumps `Updated_At` for Workers (simulated). |
| `upsert_record` | Matches by ID → `{ created, id, record }` (simulated). |
| `delete_record` | → `{ id, success: true, errors: [] }` (simulated). |

### Triggers (polling) — the JML pattern

Unlike the Salesforce mock (one generic object trigger), Workday's triggers are **bound to a
specific object and timestamp field**, matching the joiner / mover / leaver story:

| Trigger | Object | Polls on | Dedup | Use case |
| --- | --- | --- | --- | --- |
| `new_worker` | Worker | `Hire_Date > since` | `Worker_ID` | **Joiner** — someone is hired |
| `new_or_updated_worker` | Worker | `Updated_At > since` | `Worker_ID@Updated_At` | **Mover** (dept change) / **Leaver** (`Status = Terminated`) |
| `new_leave_request` | Leave_Request | `Submitted_Date > since` | `Leave_ID` | Leave management |

All three use the same closure cursor: `since` defaults to `1970-01-01T00:00:00Z` on the first
poll (so all seed records flow once), then advances to "now" each poll.

### Search

`search_records` takes structured filter rows (`field` / `operator` / `value`, all ANDed) and/or
an optional free-text **Search string** (case-insensitive substring matched across every field,
including nested name fields). Workday has no SOQL, so there is no raw-query language here.

Operators: `=  !=  >  >=  <  <=  LIKE  IN`. `LIKE` uses SQL-style `%` wildcards; `IN` takes a
comma-separated list. Numeric fields compare numerically; everything else compares as strings.

---

## Set up a connector in Workato

You demo this by creating a **custom Connector SDK connector** in Workato, pasting the code in,
and then **building a recipe** that uses its actions/triggers — no local tooling required.

1. **Sign in to Workato** and open the project (or folder) where you want the demo connector.
2. **Create the connector.** Click **Create → Connector SDK** (also reachable via
   **Tools → Connector SDK**). Give it a name, e.g. *Mock Workday HCM – Financial Services*.
   The Connector SDK code editor opens.
3. **Paste the code.** In the **Source code** tab, select all of the starter template and
   replace it with the **entire contents** of `connector_financial_services.rb` (the file is
   one Ruby hash beginning `{ title: … }`). Then click **Save code**.
4. **Set up the connection.** Open the **Connection** tab. The only field is the optional
   **Tenant label** (display-only — leave the default or type a demo tenant name). Click
   **Connect**. Because `authorization` is `none`, it connects instantly: the `test:` lambda
   runs and returns a success payload. **No credentials are required.**
5. **Release the connector.** Click **Release latest version** so the connector becomes
   selectable in the recipe builder.
6. **Build a recipe.** **Create → Recipe**, pick a **trigger**, then add **action steps** that
   use your *Mock Workday HCM (…)* connector — select the **Object** and fill the input fields
   with the values from the demo flows below. **Save**, then **Test** / run the recipe. (For
   read/write actions, a simple **manual or scheduled trigger** is enough; for the trigger
   demos, the connector's own polling trigger *is* the recipe trigger.)

> The **Test code** console (right panel of the connector editor) is handy for a quick action
> check while developing — but the demo itself is the recipe you build in step 6.
>
> Exact menu labels vary slightly by Workato UI version, but the flow is always
> *create connector → paste source → connect → release → build recipe*.

**Operations (recipe trigger/action names)** — what you'll pick when adding a step:

| Code | Recipe step name |
| --- | --- |
| `get_record` | **Get record by ID** (action) |
| `search_records` | **Search records** (action) |
| `create_record` | **Create record** (action) |
| `update_record` | **Update record** (action) |
| `upsert_record` | **Upsert record** (action) |
| `delete_record` | **Delete record** (action) |
| `new_worker` | **New worker** (trigger) |
| `new_or_updated_worker` | **New or updated worker** (trigger) |
| `new_leave_request` | **New leave request** (trigger) |

---

# Demo scenarios

The JML (joiner / mover / leaver) story is the most universally relevant Workday use case in
every enterprise. Each playbook below is self-contained: **discovery questions** to open with,
a **demo flow** (each step is a tiny recipe — a trigger + one connector action), and a **talk
track** that ties each step back to the value of Workato + Workday. The JSON under each step
lists the **field values** to enter in that action.

> The playbooks below use the **Financial Services** seed data (Meridian Capital Bank). Every
> vertical shares the **same record IDs and structure** (`WD-EMP-000001`…`000008`, the open req
> `WD-POS-000005`, the submitted leave `WD-LVE-000003`), so the steps work verbatim in any
> variant — only the names, titles, and company change. See [../profiles/](../profiles/) for each
> vertical's roster.

**Discovery questions**
- How do you provision access today when someone joins — how many IT tickets does it take?
- What breaks when someone is terminated and IT isn't notified for hours?
- How many systems need updating when an employee changes departments — and do their
  permissions update *that day*?
- When a contractor finishes an engagement, who removes their access?
- How do leave requests stay in sync between HR, payroll, and workforce scheduling?

---

## 1. Joiner flow — "The moment someone is hired, the machine starts"

**1) The open requisition** — *manual trigger → **Get record by ID***. Object **Position**:
```json
{ "object": "Position", "id": "WD-POS-000005" }
```
**2) The new hire's Workday record** — *manual trigger → **Get record by ID***. Object **Worker** (Hannah Brooks, hired 2025-01-06):
```json
{ "object": "Worker", "id": "WD-EMP-000005" }
```
**3) Joiner trigger fires** — *recipe trigger **New worker*** → downstream provisioning steps (create Azure AD account, open a ServiceNow onboarding task for IT, post a Slack welcome). The trigger emits every seed worker on first poll, then only newly-hired workers:
```json
{}
```
**4) Provision a brand-new worker** — *manual trigger → **Create record*** (simulated write → new `WD-EMP-9xxxxx` ID + current `Updated_At`). Object **Worker**:
```json
{ "object": "Worker", "Legal_Name": { "First_Name": "Ada", "Last_Name": "Lovelace" }, "Email": "ada.lovelace@meridiancapital.example.com", "Position_Title": "Senior Software Engineer", "Department": "Technology", "Cost_Center": "CC-10001", "Manager_ID": "WD-EMP-000003", "Hire_Date": "2026-07-01", "Status": "Active", "Worker_Type": "Employee", "Location": "New York, NY" }
```

**Talk track** — Open on the open Senior Software Engineer req, then the worker record to show
the *real* Workday schema (nested `Legal_Name`, `Cost_Center`, `Manager_ID`) flowing through
Workato with zero custom mapping. The **New worker** trigger is the hook: "the instant a hire
lands in Workday, Workato can create their Azure AD account, open a ServiceNow onboarding task
for IT, and post a Slack welcome — zero manual tickets, provisioning automatic on hire date."
The `create` returns a genuine `WD-EMP-…` ID — "this is exactly what your downstream identity
and ITSM systems receive."

**Key records:** open position *Senior Software Engineer* (`WD-POS-000005`), new hire
*Hannah Brooks* (`WD-EMP-000005`), her manager *David Okonkwo* (`WD-EMP-000004`).

---

## 2. Mover flow — "Department transfers are where access drift starts"

**1) Find a worker to move** — *manual trigger → **Get record by ID***. Object **Worker** (Daniel Osei, currently Technology):
```json
{ "object": "Worker", "id": "WD-EMP-000006" }
```
**2) Transfer him to Finance** — *manual trigger → **Update record*** (simulated → bumps `Updated_At`). Object **Worker**:
```json
{ "object": "Worker", "Worker_ID": "WD-EMP-000006", "Department": "Finance", "Cost_Center": "CC-10002", "Manager_ID": "WD-EMP-000004" }
```
**3) Mover trigger picks up the change** — *recipe trigger **New or updated worker*** → downstream steps (remove old Okta group, add new; notify the new manager; update the Salesforce user record). Re-run after step 2 to show the changed record flow through with dedup:
```json
{}
```

**Talk track** — Use the `update` → **New or updated worker** pairing: move Daniel from
Technology to Finance, then show the trigger catching the change (dedup is on
`Worker_ID@Updated_At`, so a genuinely changed worker re-fires). "What happens today when
someone moves between your compliance and engineering teams — do their permissions update that
day? With Workato, the Okta group swap, the manager notification, and the Salesforce role
update all fire off one Workday change event."

**Key records:** mover *Daniel Osei* (`WD-EMP-000006`), new manager *David Okonkwo*
(`WD-EMP-000004`), destination cost center `CC-10002`.

---

## 3. Leaver flow — "Terminated employees are a live security risk every hour IT doesn't know"

**1) Terminate the contractor** — *manual trigger → **Update record*** (simulated → `Status = Terminated`, bumps `Updated_At`). Object **Worker** (James Whitfield, contractor):
```json
{ "object": "Worker", "Worker_ID": "WD-EMP-000008", "Status": "Terminated" }
```
**2) Leaver trigger fires on termination** — *recipe trigger **New or updated worker***, then filter the recipe on `Status = Terminated` → downstream steps (suspend Active Directory, open a ServiceNow offboarding incident for IT + HR, revoke the Salesforce license, Slack the manager and HRIS team):
```json
{}
```
**3) Confirm the change** — *manual trigger → **Search records*** (find all terminated workers). Object **Worker**:
```json
{ "object": "Worker", "filters": [{ "field": "Status", "operator": "=", "value": "Terminated" }] }
```

**Talk track** — Termination is an *update* event in Workday, so the **New or updated worker**
trigger with a `Status = Terminated` filter is the leaver hook. "The average enterprise takes
2.5 days to revoke access after a termination. With Workato, the moment HR sets the worker to
Terminated in Workday, AD is suspended, a ServiceNow offboarding incident opens for IT and HR,
the Salesforce license is revoked, and the manager is notified — within seconds, not days."
James Whitfield being a **contractor** lets you extend the story: "same flow handles contractor
end-of-engagement, which is where access most often gets orphaned."

**Key records:** leaver *James Whitfield* (`WD-EMP-000008`, contractor), his manager
*Priya Nair* (`WD-EMP-000003`).

---

## 4. Leave management — "Leave is where HR and payroll go out of sync"

**1) The submitted leave request** — *manual trigger → **Get record by ID***. Object **Leave_Request** (Hannah Brooks, FMLA, Submitted):
```json
{ "object": "Leave_Request", "id": "WD-LVE-000003" }
```
**2) Leave trigger fires on submission** — *recipe trigger **New leave request*** → notify the worker's manager for approval. The trigger emits all seed leave requests on first poll, then only newly submitted ones:
```json
{}
```
**3) Approve it** — *manual trigger → **Update record*** (simulated → `Status = Approved`). Object **Leave_Request**:
```json
{ "object": "Leave_Request", "Leave_ID": "WD-LVE-000003", "Status": "Approved", "Approved_By": "WD-EMP-000004" }
```
**4) Show open leaves** — *manual trigger → **Search records*** (active and submitted leave). Object **Leave_Request**:
```json
{ "object": "Leave_Request", "filters": [{ "field": "Status", "operator": "IN", "value": "Submitted,Active,Approved" }] }
```

**Talk track** — The **New leave request** trigger fires when a worker submits leave. "On
submission, Workato notifies the manager for approval; on approval it updates payroll (ADP) and
workforce scheduling — so leave, pay, and coverage never drift apart." Hannah's FMLA request
(`WD-LVE-000003`) is the live Submitted record; approving it shows the write path and the
`Approved_By` manager reference. Maria Santos's active Parental leave (`WD-LVE-000001`, tied to
her `On_Leave` worker status) shows the in-progress state.

**Key records:** submitted leave *Hannah Brooks – FMLA* (`WD-LVE-000003`), active leave
*Maria Santos – Parental* (`WD-LVE-000001`), on-leave worker *Maria Santos* (`WD-EMP-000007`).

---

## Standard-connector behaviors: simulated vs. faithfully reproduced

**Faithfully reproduced**
- Workday HCM object model and **field names / casing / types** — including **nested**
  `Legal_Name` / `Preferred_Name` objects, `Manager_ID` hierarchy, `Cost_Center`, `Hire_Date`,
  `Updated_At`, leave `Submitted_Date` / `Approved_By`.
- **Workday-style IDs** with correct object prefixes (`WD-EMP-`, `WD-POS-`, `WD-ORG-`,
  `WD-LVE-`) and 6-digit zero-padded bodies.
- A single object selector (`pick_list`) + dynamic `object_definitions` schema driving every
  action's I/O.
- **Object-bound polling triggers** matching the JML pattern (`new_worker` on `Hire_Date`,
  `new_or_updated_worker` on `Updated_At`, `new_leave_request` on `Submitted_Date`) with
  closure-based `since` cursor, far-past default on first poll, `dedup`, and `sample_output`.
- Status enums (`Active` / `On_Leave` / `Terminated`, `Employee` / `Contractor`) and ISO-8601
  dates/datetimes; headcount/member counts as integers.
- Internally consistent foreign keys — every `Manager_ID`, `Cost_Center`, `Incumbent_ID`,
  `Parent_Org_ID`, leave `Worker_ID`, and `Approved_By` resolves to a real seed record.

**Simulated (demo shortcuts)**
- **All data is embedded** in the file's `mock_data` — no real tenant, no auth, no API call.
- **Writes are stateless**: `create` / `update` / `upsert` / `delete` return a synthesized,
  realistic record but **persist nothing**. Re-reading after a "create" will not find it; the
  leaver/mover demos rely on the trigger reacting to the *returned* event, not on the seed data
  changing.
- **Search** is structured filters + a free-text substring scan — not a real Workday report,
  WQL query, or RaaS endpoint (no joins, aggregation, or sorting beyond the trigger's cursor).
- Business-process workflows, approval chains, effective-dating, and validation rules are not
  simulated — the seed `Status` values represent end states.
- **All five verticals** (Financial Services, Healthcare, Manufacturing, Retail, Technology) ship
  today; each is the same connector with `mock_data` swapped for its anchor company's workforce.
  See [../profiles/](../profiles/) for the shared people/company roster and cross-connector links.
