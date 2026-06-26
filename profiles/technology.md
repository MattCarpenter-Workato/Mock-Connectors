# Technology — sample world

**Anchor company:** Northwind Software
**Connectors:** [Salesforce (Tech)](../salesforce/connector_technology.rb) ·
[Workday HCM (Tech)](../workday-hcm/connector_technology.rb)

## Companies

| Company | Role in the world | Where it appears |
|---|---|---|
| **Northwind Software** | Anchor enterprise (Workday tenant; Salesforce account #1) | Salesforce, Workday |
| Quantum Analytics | Customer (data & analytics) | Salesforce account |
| Cloudpeak Systems | Customer (cloud infrastructure) | Salesforce account |
| Bitforge DevTools | Prospect (developer tools) | Salesforce account |
| Lumen AI | Customer (artificial intelligence) | Salesforce account |
| Stackline Security | Prospect (cybersecurity) | Salesforce account |

## Workday — Northwind Software workforce

| Worker | Name | Title | Dept | Manager | Status | Type |
|---|---|---|---|---|---|---|
| `WD-EMP-000001` | **Eleanor Vance** | Chief Operating Officer | Executive | — | Active | Employee |
| `WD-EMP-000002` | **Marcus Reyes** | Director of Human Resources | Human Resources | …0001 | Active | Employee |
| `WD-EMP-000003` | **Priya Raman** | Director of Engineering | Engineering | …0001 | Active | Employee |
| `WD-EMP-000004` | **Tobias Greer** | Director of Information Technology | Technology | …0001 | Active | Employee |
| `WD-EMP-000005` | Hannah Brooks | Software Engineer | Engineering | …0003 | Active | Employee · **joiner** (hired 2025-01-06) |
| `WD-EMP-000006` | Daniel Osei | Site Reliability Engineer | Technology | …0004 | Active | Employee · **mover** |
| `WD-EMP-000007` | Maria Santos | HR Generalist | Human Resources | …0002 | **On_Leave** | Employee |
| `WD-EMP-000008` | **James Whitfield** | IT Support Contractor | Technology | …0004 | Active | **Contractor** · **leaver** |

```
Eleanor Vance (COO)
├── Marcus Reyes (Dir HR)
│   └── Maria Santos (HR Generalist, On_Leave)
├── Priya Raman (Dir Engineering)
│   └── Hannah Brooks (Software Engineer, new hire)
└── Tobias Greer (Dir IT)
    ├── Daniel Osei (Site Reliability Engineer)
    └── James Whitfield (IT Support Contractor)
```

JML demo targets: open req `WD-POS-000005` (Senior Software Engineer); submitted leave
`WD-LVE-000003` (Hannah Brooks, FMLA); on-leave worker Maria Santos (`WD-LVE-000001`, Parental).

## Salesforce — contacts & users

**Contacts:**

| Name | Title | Company |
|---|---|---|
| **Eleanor Vance** | VP Engineering | Northwind Software |
| Raj Patel | Director of RevOps | Northwind Software |
| Grace Okafor | Chief Technology Officer | Quantum Analytics |
| Liam Donnelly | Director of Platform | Cloudpeak Systems |
| Hannah Kim | Head of Developer Relations | Bitforge DevTools |
| Marcus Bauer | VP Product | Lumen AI |
| Yuki Tanaka | Director of Information Security | Stackline Security |

**Users** (record owners): **James Whitfield**, **Marcus Reyes**, **Priya Raman**,
**Tobias Greer**, Sofia Castellano *(inactive)*.

## Cross-connector identities

- **Eleanor Vance** — Salesforce VP Engineering contact at Northwind **and** top of the Workday
  org.
- **Marcus Reyes**, **Priya Raman**, **Tobias Greer** — Salesforce Users **and** Workday directors
  at Northwind.
- **James Whitfield** — Salesforce User **and** the Workday IT contractor (leaver).
- The two Marcuses are different people: **Marcus Reyes** (Northwind HR director / internal) vs
  **Marcus Bauer** (VP Product at customer Lumen AI).
