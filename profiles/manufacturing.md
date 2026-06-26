# Manufacturing — sample world

**Anchor company:** Titan Industrial Equipment
**Connectors:** [Salesforce (MFG)](../salesforce/connector_manufacturing.rb) ·
[Workday HCM (MFG)](../workday-hcm/connector_manufacturing.rb)

## Companies

| Company | Role in the world | Where it appears |
| --- | --- | --- |
| **Titan Industrial Equipment** | Anchor enterprise (Workday tenant; Salesforce account #1) | Salesforce, Workday |
| Ferrous Steel Works | Customer (metals & mining) | Salesforce account |
| Apex Robotics | Customer (automation/robotics) | Salesforce account |
| Cascade Packaging | Prospect (packaging) | Salesforce account |
| Continental Auto Parts | Customer (automotive) | Salesforce account |
| Granite Tooling | Prospect (tooling & machining) | Salesforce account |

## Workday — Titan Industrial Equipment workforce

| Worker | Name | Title | Dept | Manager | Status | Type |
| --- | --- | --- | --- | --- | --- | --- |
| `WD-EMP-000001` | **Eleanor Vance** | Chief Operating Officer | Executive | — | Active | Employee |
| `WD-EMP-000002` | **Marcus Reyes** | Director of Human Resources | Human Resources | …0001 | Active | Employee |
| `WD-EMP-000003` | **Priya Raman** | Director of Information Technology | Technology | …0001 | Active | Employee |
| `WD-EMP-000004` | **Tobias Greer** | Director of Operations | Operations | …0001 | Active | Employee |
| `WD-EMP-000005` | Hannah Brooks | Process Engineer | Engineering | …0004 | Active | Employee · **joiner** (hired 2025-01-06) |
| `WD-EMP-000006` | Daniel Osei | Maintenance Technician | Operations | …0004 | Active | Employee · **mover** |
| `WD-EMP-000007` | Maria Santos | HR Generalist | Human Resources | …0002 | **On_Leave** | Employee |
| `WD-EMP-000008` | **James Whitfield** | IT Support Contractor | Technology | …0003 | Active | **Contractor** · **leaver** |

```text
Eleanor Vance (COO)
├── Marcus Reyes (Dir HR)
│   └── Maria Santos (HR Generalist, On_Leave)
├── Priya Raman (Dir IT)
│   └── James Whitfield (IT Support Contractor)
└── Tobias Greer (Dir Operations)
    ├── Hannah Brooks (Process Engineer, new hire)
    └── Daniel Osei (Maintenance Technician)
```

JML demo targets: open req `WD-POS-000005` (Manufacturing Engineer); submitted leave
`WD-LVE-000003` (Hannah Brooks, FMLA); on-leave worker Maria Santos (`WD-LVE-000001`, Parental).

## Salesforce — contacts & users

**Contacts:**

| Name | Title | Company |
| --- | --- | --- |
| **Eleanor Vance** | VP of Operations | Titan Industrial Equipment |
| Raj Patel | Plant Manager | Titan Industrial Equipment |
| Grace Okafor | Director of Supply Chain | Ferrous Steel Works |
| Liam Donnelly | VP Engineering | Apex Robotics |
| Hannah Kim | Quality Manager | Cascade Packaging |
| Marcus Bauer | Director of Procurement | Continental Auto Parts |
| Yuki Tanaka | Maintenance Manager | Granite Tooling |

**Users** (record owners): **James Whitfield**, **Marcus Reyes**, **Priya Raman**,
**Tobias Greer**, Sofia Castellano *(inactive)*.

## Cross-connector identities

- **Eleanor Vance** — Salesforce VP of Operations contact at Titan **and** top of the Workday org.
- **Marcus Reyes**, **Priya Raman**, **Tobias Greer** — Salesforce Users **and** Workday directors
  at Titan.
- **James Whitfield** — Salesforce User **and** the Workday IT contractor (leaver).
- The two Marcuses are different people: **Marcus Reyes** (Titan HR director / internal) vs
  **Marcus Bauer** (Director of Procurement at customer Continental Auto Parts).
