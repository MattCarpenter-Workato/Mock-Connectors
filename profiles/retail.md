# Retail — sample world

**Anchor company:** Lark & Finch Apparel
**Connectors:** [Salesforce (Retail)](../salesforce/connector_retail.rb) ·
[Workday HCM (Retail)](../workday-hcm/connector_retail.rb)

## Companies

| Company | Role in the world | Where it appears |
| --- | --- | --- |
| **Lark & Finch Apparel** | Anchor enterprise (Workday tenant; Salesforce account #1) | Salesforce, Workday |
| Summit Outdoor Co. | Customer (sporting goods) | Salesforce account |
| Harborview Grocers | Customer (grocery) | Salesforce account |
| Glow Beauty | Prospect (health & beauty) | Salesforce account |
| UrbanNest Home | Customer (home goods) | Salesforce account |
| Pace Athletics | Prospect (footwear/athletics) | Salesforce account |

## Workday — Lark & Finch Apparel workforce

| Worker | Name | Title | Dept | Manager | Status | Type |
| --- | --- | --- | --- | --- | --- | --- |
| `WD-EMP-000001` | **Eleanor Vance** | Chief Operating Officer | Executive | — | Active | Employee |
| `WD-EMP-000002` | **Marcus Reyes** | Director of Human Resources | Human Resources | …0001 | Active | Employee |
| `WD-EMP-000003` | **Priya Raman** | Director of Information Technology | Technology | …0001 | Active | Employee |
| `WD-EMP-000004` | **Tobias Greer** | Director of Retail Operations | Retail Operations | …0001 | Active | Employee |
| `WD-EMP-000005` | Hannah Brooks | Merchandising Analyst | Merchandising | …0004 | Active | Employee · **joiner** (hired 2025-01-06) |
| `WD-EMP-000006` | Daniel Osei | Store Systems Specialist | Retail Operations | …0004 | Active | Employee · **mover** |
| `WD-EMP-000007` | Maria Santos | HR Generalist | Human Resources | …0002 | **On_Leave** | Employee |
| `WD-EMP-000008` | **James Whitfield** | IT Support Contractor | Technology | …0003 | Active | **Contractor** · **leaver** |

```text
Eleanor Vance (COO)
├── Marcus Reyes (Dir HR)
│   └── Maria Santos (HR Generalist, On_Leave)
├── Priya Raman (Dir IT)
│   └── James Whitfield (IT Support Contractor)
└── Tobias Greer (Dir Retail Operations)
    ├── Hannah Brooks (Merchandising Analyst, new hire)
    └── Daniel Osei (Store Systems Specialist)
```

JML demo targets: open req `WD-POS-000005` (E-commerce Manager); submitted leave `WD-LVE-000003`
(Hannah Brooks, FMLA); on-leave worker Maria Santos (`WD-LVE-000001`, Parental).

## Salesforce — contacts & users

**Contacts:**

| Name | Title | Company |
| --- | --- | --- |
| **Eleanor Vance** | VP E-commerce | Lark & Finch Apparel |
| Raj Patel | Director of Merchandising | Lark & Finch Apparel |
| Grace Okafor | Head of Digital | Summit Outdoor Co. |
| Liam Donnelly | Director of Store Operations | Harborview Grocers |
| Hannah Kim | CMO | Glow Beauty |
| Marcus Bauer | VP Supply Chain | UrbanNest Home |
| Yuki Tanaka | Loyalty Program Manager | Pace Athletics |

**Users** (record owners): **James Whitfield**, **Marcus Reyes**, **Priya Raman**,
**Tobias Greer**, Sofia Castellano *(inactive)*.

## Cross-connector identities

- **Eleanor Vance** — Salesforce VP E-commerce contact at Lark & Finch **and** top of the Workday
  org.
- **Marcus Reyes**, **Priya Raman**, **Tobias Greer** — Salesforce Users **and** Workday directors
  at Lark & Finch.
- **James Whitfield** — Salesforce User **and** the Workday IT contractor (leaver).
- The two Marcuses are different people: **Marcus Reyes** (Lark & Finch HR director / internal) vs
  **Marcus Bauer** (VP Supply Chain at customer UrbanNest Home).
