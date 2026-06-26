# Profiles — the shared sample world

Every mock connector in this repo draws its people and companies from **one shared sample
world**, so a multi-system demo (Workday → Salesforce → Epic) feels like one enterprise rather
than three unrelated datasets. This folder is the **canonical reference** for that world: who the
people are, which companies they belong to, and how the same identity shows up across connectors.

> These are the source-of-truth profiles. If a connector's seed data and this folder ever
> disagree, the connector is wrong — fix it to match here.

## How the world is organized

The repo has **five industry verticals**. Each vertical is one "slice" of the world: an **anchor
company** (the enterprise whose HR / CRM / clinical systems we mock), a set of **secondary
companies** (its customers and partners), and a **people roster**.

The same named people recur across connectors. We use **one roster, role per system** — a person
keeps one name and home company, and each connector casts them in the object type it models:

| Connector | Casts the roster as… |
|---|---|
| **Workday HCM** | the anchor company's internal **Workforce** (the Worker hierarchy) |
| **Salesforce** | internal **Users** (record owners) + **Contacts** at the anchor & secondary accounts |
| **Epic on FHIR** (healthcare only) | **Practitioners** (clinicians) + **Patients / Members** |

So, for example, **Priya Raman** is one person: a Workday employee, a Salesforce record owner,
and — in healthcare — an Epic physician. Same name, same home company, three system views.

> Verticals are **parallel worlds**, not one giant org. The recurring cast (Eleanor Vance, Priya
> Raman, …) plays a role in each vertical the way a repertory company reuses the same actors — but
> a person is never two different people *within* a vertical.

## Anchor companies

| Vertical | Anchor company | Appears in |
|---|---|---|
| [Financial Services](financial-services.md) | **Meridian Capital Bank** | Salesforce (FS), Workday (FS) |
| [Healthcare](healthcare.md) | **Cedar Valley Health System** | Salesforce (HC), Epic Provider, Epic Payer, Workday (HC) |
| [Manufacturing](manufacturing.md) | **Titan Industrial Equipment** | Salesforce (MFG), Workday (MFG) |
| [Retail](retail.md) | **Lark & Finch Apparel** | Salesforce (Retail), Workday (Retail) |
| [Technology](technology.md) | **Northwind Software** | Salesforce (Tech), Workday (Tech) |

Healthcare also features **BlueRiver Health Plan** (the payer — a Salesforce HC account and the
Epic Payer organization). Each vertical's secondary companies are the five other Salesforce
accounts in that vertical; see the per-vertical files.

## The recurring cast

These people appear in **every** vertical, always with the same name. Their company and exact
title are set per vertical (see each vertical file).

| Person | Where they appear | Role they play |
|---|---|---|
| **Eleanor Vance** | Salesforce (Contact, anchor account) · Workday (Worker — top of hierarchy) | The anchor company's top executive |
| **Marcus Reyes** | Salesforce (User) · Workday (Worker) | Director of Human Resources at the anchor |
| **Priya Raman** | Salesforce (User) · Workday (Worker) · Epic (Practitioner, HC only) | A department director; the Family-Medicine physician in healthcare |
| **Tobias Greer** | Salesforce (User) · Workday (Worker) · Epic (Practitioner, HC only) | A department director / clinician (the hospitalist in healthcare) |
| **James Whitfield** | Salesforce (User) · Workday (Worker) | The **IT support contractor** — the JML "leaver" target |
| **Sofia Castellano** | Salesforce (User, inactive) | A deactivated CRM user |

Vertical-specific people (Salesforce external contacts like **Raj Patel**, **Grace Okafor**,
**Liam Donnelly**, **Hannah Kim**, **Marcus Bauer**, **Yuki Tanaka**; Workday-only personas like
**David Okonkwo**, **Daniel Osei**, **Hannah Brooks**, **Maria Santos**; the healthcare clinician
**Alan Mercer**; and Epic patients **Martha Reynolds / James Calderon / Sofia Nguyen / Robert
Okafor**) are documented in their vertical's file.

## Cross-connector identity highlights

These are the links that make a multi-system demo land:

- **James Whitfield** is a Salesforce User *and* the Workday contractor. When HR terminates him in
  Workday (the "leaver" event), a recipe can deactivate his Salesforce user and reassign his
  records — one story spanning two connectors.
- **Priya Raman / Tobias Greer / Alan Mercer** are Cedar Valley clinicians in **Epic**, employees
  in **Workday Healthcare**, and (Raman, Greer) Salesforce Users — the same doctors seen from the
  HR, CRM, and clinical systems at once.
- **Cedar Valley Health System** is the anchor across **four** connectors (Salesforce HC, Epic
  Provider, Epic Payer, Workday HC); **BlueRiver Health Plan** spans Salesforce HC + Epic Payer.
- **Eleanor Vance** anchors leadership in every vertical — the executive contact in Salesforce and
  the top of the Workday org chart.

## How this world was reconciled

The seed data previously had name collisions (the "same" person under different names). These were
unified to one canonical identity each:

| Was | Now | Note |
|---|---|---|
| Eleanor **Voss** (SF) / Eleanor **Vance** (WD) | **Eleanor Vance** | anchor top executive |
| Priya **Nair** (WD) / Priya **Raman** (SF, Epic) | **Priya Raman** | one director/physician |
| **Dana** Whitfield (SF User) / **James** Whitfield (WD contractor) | **James Whitfield** | single identity; powers the leaver demo |
| Marcus **Lindqvist** (SF User) / Marcus **Reyes** (WD) | **Marcus Reyes** | anchor HR director (the external SF contact **Marcus Bauer** is a different person — a customer) |

IDs were never changed — only names/titles/emails — so existing recipes, dedup keys, and demo
playbooks keep working.
