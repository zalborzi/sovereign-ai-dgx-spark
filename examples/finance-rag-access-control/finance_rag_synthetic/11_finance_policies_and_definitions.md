# Finance Policies, Definitions and RAG Access Rules

**Classification:** Finance Restricted  
**Purpose:** Synthetic RAG demonstration

## Access rules

### Finance group
May retrieve:
- individual salaries and benefits;
- monthly payroll records;
- operating expenses;
- revenue and billing;
- project profitability;
- receivables;
- budgets and forecasts;
- aggregated executive financial reports.

### C-Level group
May retrieve:
- company revenue, total costs, profit and margin;
- department and project profitability;
- project risk and receivables;
- budget-versus-actual results;
- aggregate headcount and personnel-cost figures.

C-Level responses should normally avoid naming an employee or returning an individual salary. The chatbot should answer at aggregated company, department or project level unless the user has also been explicitly assigned the Finance detailed-data entitlement.

### Project Management group
In a later dataset phase, may retrieve:
- employee time recorded by project;
- billable and non-billable hours;
- project labor-cost calculations;
- project budget consumption.

The group should not retrieve individual salary values or company-wide financial records.

### Normal Employee group
Has no restricted RAG knowledge. The chatbot operates as a general local LLM only.

## Financial definitions

- **Recognized revenue:** Revenue recorded for work delivered in the financial period.
- **Billed revenue:** Amount invoiced to clients.
- **Unbilled revenue:** Delivered revenue not yet invoiced.
- **Personnel cost:** Base salary, overtime, bonus, employer social charges and benefits.
- **Direct project cost:** Labor and non-labor cost attributable to a project.
- **Gross profit:** Project recognized revenue minus project delivery cost.
- **Gross margin:** Gross profit divided by recognized revenue.
- **Operating profit:** Company revenue minus all operating costs.
- **Operating margin:** Operating profit divided by company revenue.
- **Accounts receivable:** Client invoices not yet collected.
- **Budget variance:** Actual result minus budget. For cost, a positive variance is unfavorable; for revenue, a positive variance is favorable.

## RAG response policy

1. Use retrieved files as the factual source.
2. Mention the relevant period and unit.
3. Do not infer a real employee identity from synthetic names.
4. Do not reveal employee-level compensation to users outside Finance.
5. For C-Level users, aggregate detailed finance data before responding.
6. State “I do not have access to that information” when the necessary knowledge base is unavailable.
7. Never treat these synthetic figures as real Virgool Luxembourg information.
