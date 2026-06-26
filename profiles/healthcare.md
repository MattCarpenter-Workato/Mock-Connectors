# Healthcare — sample world

**Anchor company:** Cedar Valley Health System
**Connectors:** [Salesforce (HC)](../salesforce/connector_healthcare.rb) ·
[Epic on FHIR — Provider](../epic-fhir/connector_provider.rb) ·
[Epic on FHIR — Payer](../epic-fhir/connector_payer.rb) ·
[Workday HCM (HC)](../workday-hcm/connector_healthcare.rb)

Healthcare is the most cross-connected vertical: Cedar Valley appears in **four** connectors, and
its clinicians are the same people in Epic, Workday, and Salesforce.

## Companies

| Company | Role in the world | Where it appears |
|---|---|---|
| **Cedar Valley Health System** | Anchor health system (Workday tenant; Salesforce account #1; Epic provider org) | Salesforce, Epic Provider, Epic Payer, Workday |
| **BlueRiver Health Plan** | Payer | Salesforce account, Epic Payer org |
| Cedar Valley Cardiology | Cedar Valley's cardiology department | Epic Provider org |
| Northstar Pediatric Group | Customer (ambulatory) | Salesforce account |
| Helix Genomics | Customer (biotech) | Salesforce account |
| Asclepius Medical Devices | Prospect (medical devices) | Salesforce account |
| Meridian Home Care | Prospect (home health) | Salesforce account |

## Workday — Cedar Valley Health System workforce

| Worker | Name | Title | Dept | Manager | Status | Type |
|---|---|---|---|---|---|---|
| `WD-EMP-000001` | **Eleanor Vance** | Chief Medical Officer | Executive | — | Active | Employee |
| `WD-EMP-000002` | **Marcus Reyes** | Director of Human Resources | Human Resources | …0001 | Active | Employee |
| `WD-EMP-000003` | **Priya Raman** | Director of Primary Care | Primary Care | …0001 | Active | Employee |
| `WD-EMP-000004` | **Alan Mercer** | Director of Cardiology | Cardiology | …0001 | Active | Employee |
| `WD-EMP-000005` | Hannah Brooks | Registered Nurse | Nursing | …0003 | Active | Employee · **joiner** (hired 2025-01-06) |
| `WD-EMP-000006` | **Tobias Greer** | Hospitalist | Hospital Medicine | …0004 | Active | Employee · **mover** |
| `WD-EMP-000007` | Maria Santos | HR Generalist | Human Resources | …0002 | **On_Leave** | Employee |
| `WD-EMP-000008` | **James Whitfield** | IT Support Contractor | Information Technology | …0003 | Active | **Contractor** · **leaver** |

```
Eleanor Vance (CMO)
├── Marcus Reyes (Dir HR)
│   └── Maria Santos (HR Generalist, On_Leave)
├── Priya Raman (Dir Primary Care)        ← Epic Family-Medicine physician
│   ├── Hannah Brooks (Registered Nurse, new hire)
│   └── James Whitfield (IT Support Contractor)
└── Alan Mercer (Dir Cardiology)          ← Epic cardiologist
    └── Tobias Greer (Hospitalist)        ← Epic hospitalist
```

JML demo targets: open req `WD-POS-000005` (Nurse Practitioner); submitted leave `WD-LVE-000003`
(Hannah Brooks, FMLA); on-leave worker Maria Santos (`WD-LVE-000001`, Parental).

## Epic on FHIR

**Practitioners** (Cedar Valley clinicians — the *same people* as the Workday directors above):

| Epic id | Name | Specialty | Also in Workday as |
|---|---|---|---|
| `prac-raman` | **Priya Raman, MD** | Family Medicine / PCP | Director of Primary Care (`WD-EMP-000003`) |
| `prac-mercer` | **Alan Mercer, MD** | Cardiovascular Disease | Director of Cardiology (`WD-EMP-000004`) |
| `prac-greer` | **Tobias Greer, MD** | Hospitalist | Hospitalist (`WD-EMP-000006`) |

**Patients / members** (Epic only — Cedar Valley's patients; BlueRiver's insured):

| Epic id | Name | Notes |
|---|---|---|
| `pat-mreynolds` | Martha Reynolds | Hypertension; BlueRiver member `BRH-100482` |
| `pat-jcalderon` | James Calderon | Type 2 diabetes; BlueRiver member `BRH-100513` |
| `pat-snguyen` | Sofia Nguyen | Annual physical; BlueRiver member `BRH-100547` |
| `pat-rokafor` | Robert Okafor | Coronary artery disease (inpatient) — Provider only |

## Salesforce — contacts & users

**Contacts:**

| Name | Title | Company |
|---|---|---|
| **Eleanor Vance** | Chief Medical Officer | Cedar Valley Health System |
| Raj Patel | VP, Clinical Informatics | Cedar Valley Health System |
| Grace Okafor | Director of Revenue Cycle | Northstar Pediatric Group |
| Liam Donnelly | VP, Regulatory Affairs | Helix Genomics |
| Hannah Kim | Director of Population Health | Asclepius Medical Devices |
| Marcus Bauer | Head of Payer Relations | BlueRiver Health Plan |
| Yuki Tanaka | Chief Nursing Officer | Meridian Home Care |

**Users** (record owners): **James Whitfield**, **Marcus Reyes**, **Priya Raman**,
**Tobias Greer**, Sofia Castellano *(inactive)*.

## Cross-connector identities

- **Priya Raman / Alan Mercer / Tobias Greer** — Cedar Valley clinicians seen three ways: Epic
  practitioners (clinical), Workday employees (HR), and (Raman, Greer) Salesforce Users (CRM).
- **Eleanor Vance** — Salesforce CMO contact at Cedar Valley **and** top of the Workday org.
- **James Whitfield** — Salesforce User **and** Workday IT contractor (leaver).
- **Cedar Valley Health System** ↔ **BlueRiver Health Plan** — the provider/payer pair that lets
  you demo a claim or coverage flow (Epic Payer) against the same patients the provider treats
  (Epic Provider), all for accounts that also exist in Salesforce.
