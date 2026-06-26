# Financial Services — sample world

**Anchor company:** Meridian Capital Bank
**Connectors:** [Salesforce (FS)](../salesforce/connector_financial_services.rb) ·
[Workday HCM (FS)](../workday-hcm/connector_financial_services.rb)

## Companies

| Company | Role in the world | Where it appears |
| --- | --- | --- |
| **Meridian Capital Bank** | Anchor enterprise (Workday tenant; Salesforce account #1) | Salesforce, Workday |
| Harbor Mutual Insurance | Customer (insurance) | Salesforce account |
| Vantage Wealth Advisors | Customer (wealth management) | Salesforce account |
| Cobalt Payments | Prospect (fintech) | Salesforce account |
| Summit Credit Union | Customer (banking) | Salesforce account |
| Ironclad Asset Management | Prospect (asset management) | Salesforce account |

## Workday — Meridian Capital Bank workforce

| Worker | Name | Title | Dept | Manager | Status | Type |
| --- | --- | --- | --- | --- | --- | --- |
| `WD-EMP-000001` | **Eleanor Vance** | Chief Operating Officer | Executive | — | Active | Employee |
| `WD-EMP-000002` | **Marcus Reyes** | Director of Human Resources | Human Resources | …0001 | Active | Employee |
| `WD-EMP-000003` | **Priya Raman** | Director of Information Technology | Technology | …0001 | Active | Employee |
| `WD-EMP-000004` | David Okonkwo | Finance Manager | Finance | …0001 | Active | Employee |
| `WD-EMP-000005` | Hannah Brooks | Financial Analyst | Finance | …0004 | Active | Employee · **joiner** (hired 2025-01-06) |
| `WD-EMP-000006` | Daniel Osei | Systems Administrator | Technology | …0003 | Active | Employee · **mover** |
| `WD-EMP-000007` | Maria Santos | HR Generalist | Human Resources | …0002 | **On_Leave** | Employee |
| `WD-EMP-000008` | **James Whitfield** | IT Support Contractor | Technology | …0003 | Active | **Contractor** · **leaver** |

```text
Eleanor Vance (COO)
├── Marcus Reyes (Dir HR)
│   └── Maria Santos (HR Generalist, On_Leave)
├── Priya Raman (Dir IT)
│   ├── Daniel Osei (Systems Administrator)
│   └── James Whitfield (IT Support Contractor)
└── David Okonkwo (Finance Manager)
    └── Hannah Brooks (Financial Analyst, new hire)
```

JML demo targets: open req `WD-POS-000005` (Senior Software Engineer); submitted leave
`WD-LVE-000003` (Hannah Brooks, FMLA); on-leave worker Maria Santos (`WD-LVE-000001`, Parental).

## Salesforce — contacts & users

**Contacts** (at the accounts above):

| Name | Title | Company |
| --- | --- | --- |
| **Eleanor Vance** | CFO | Meridian Capital Bank |
| Raj Patel | VP, Treasury | Meridian Capital Bank |
| Grace Okafor | Chief Risk Officer | Harbor Mutual Insurance |
| Liam Donnelly | Managing Director | Vantage Wealth Advisors |
| Hannah Kim | Head of Partnerships | Cobalt Payments |
| Marcus Bauer | COO | Summit Credit Union |
| Yuki Tanaka | Portfolio Manager | Ironclad Asset Management |

**Users** (record owners): **James Whitfield**, **Marcus Reyes**, **Priya Raman**,
**Tobias Greer**, Sofia Castellano *(inactive)*.

## Cross-connector identities

- **Eleanor Vance** — Salesforce contact at Meridian (CFO) **and** the top of the Workday org
  (COO).
- **Marcus Reyes**, **Priya Raman** — Salesforce Users **and** Workday directors at Meridian.
- **James Whitfield** — Salesforce User **and** the Workday IT contractor (leaver). The flagship
  cross-system story: terminate him in Workday → deactivate his Salesforce user + reassign records.
- Note the two Marcuses are different people: **Marcus Reyes** (Meridian HR director / internal)
  vs **Marcus Bauer** (COO at customer Summit Credit Union).
