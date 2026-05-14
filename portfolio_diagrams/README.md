# Portfolio diagrams (PlantUML source + rendered PNG)

All eight portfolio diagrams now live here as PlantUML. Edit the `.puml` file
and re-render to keep the slide deck in sync.

## File → slide mapping

| Slide # / section | PlantUML source | Rendered PNG |
|---|---|---|
| §2.1 Use case — Bujet (top level) | `04_usecase_top_level.puml` | `UseCase_TopLevel.png` |
| §2.1 Use case — Transaction Import | `05_usecase_transaction_import.puml` | `UseCase_TransactionImport.png` |
| §2.1 Use case — Manual Transaction Entry | `06_usecase_manual_transaction.puml` | `UseCase_ManualTransactionEntry.png` |
| §2.1 Use case — Pause before purchase | `07_usecase_pause_before_purchase.puml` | `UseCase_PauseBeforePurchase.png` |
| §3.1 Architecture — three-tier | `08_architecture_three_tier.puml` | `Architecture_ThreeTier.png` |
| §3.2 Class diagram — Sprints 1 & 2 | `01_sprint1_2_class_diagram.puml` | `ClassDiagram_Sprint1_2.png` |
| §3.2 Class diagram — Sprint 3 (Data, Domain, Views) | `02_sprint3_data_domains_views.puml` | `ClassDiagram_Sprint3_DataDomainsViews.png` |
| §3.3 Sequence — Connect bank | `09_sequence_connect_bank.puml` | `Sequence_ConnectBank.png` |
| §3.3 Sequence — Manually record a transaction | `10_sequence_manual_record.puml` | `Sequence_ManualRecordTransaction.png` |
| §3.3 Sequence — Pause & Reflect (wait + re-decision) | `11_sequence_pause_reflect.puml` | `Sequence_PauseReflect_WaitRedecision.png` |

## Re-rendering

Single file:
```
"C:\Users\Zak\PlantUML\plantuml.bat" -tpng portfolio_diagrams\04_usecase_top_level.puml
```

All files at once:
```
"C:\Users\Zak\PlantUML\plantuml.bat" -tpng portfolio_diagrams\*.puml
```

To export as SVG (scales better in PowerPoint at high zoom):
```
"C:\Users\Zak\PlantUML\plantuml.bat" -tsvg portfolio_diagrams\*.puml
```

## Naming convention note (abstract vs. real)

The use-case and class diagrams use slightly idealised names that are
**internally consistent with the rest of the portfolio** (use case tables,
detailed class descriptions, slide narrative) but don't always match the
Swift class names 1:1. The brief calls §3.2 the *"Class Diagram (Abstract)"*,
so abstraction is fine.

Known divergences between portfolio names and the actual codebase:

| Portfolio name (Sprints 1 & 2) | Actual code |
|---|---|
| `ConnectBankView` | `HomeView` + `BankProviderPickerSheet` (no dedicated connect-bank view) |
| `ConnectBankViewModel` | `HomeViewModel` |
| `BankConnectionService` | split across `BackendAuthClient` / `TrueLayerAuthService` / `BankAccountConnector` |
| `SecureTokenStore` | token handling lives inside `BackendAuthClient` (proxy backend) |
| `BankConnectionRepository` | `BankConnectionStateStore` |
| `TransactionSyncService` | part of `TransactionImportFlow` |
| `TransactionEntryView` / `TransactionEntryViewModel` | `ManualTransactionSheet` / `ManualTransactionFlow` |

Sprint 3 names already match the codebase 1:1
(`PreSpendInterventionFlow`, `PreSpendInterventionUseCase`,
`SpendingContextProvider`, `LLMNarrativeService` + `Template…` / `FoundationModels…`,
`WaitReminderScheduler`, `WaitReminderRouter`, `NotificationCenterDelegate`,
`LocalInterventionLogRepository`, `LocalGoalRepository`,
`InterventionProposal`, `InterventionDecision`, `InterventionLog`,
`SpendingFacts`, `Goal`, `WishlistItem`).

If you ever want the Sprints 1+2 diagrams to also match real names exactly,
edit `01_sprint1_2_class_diagram.puml`, `09_sequence_connect_bank.puml`,
and `10_sequence_manual_record.puml`. The detailed class descriptions on
slide 24 (e.g. `BankConnectionService`, `LocalTransactionRepository`) would
need updating to match.
