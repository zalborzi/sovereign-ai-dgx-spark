# Project Management Governance and RAG Access Policy

**Classification:** Project Management Restricted  
**Purpose:** Synthetic access-control demonstration

## Project Management group

May retrieve:

- employee allocation by project;
- who logged time against which project and work package;
- weekly and monthly timesheet status;
- standard project costing rates;
- project labor and non-labor costs;
- resource capacity, utilization and over-allocation;
- work packages, milestones and stage gates;
- RAID items;
- change requests;
- project cost forecasts and EVM-style indicators;
- named project status reports.

The group must not receive individual salary, bonus, payroll or personal-benefit information. The standard hourly project cost rate is a management costing rate and must not be reverse-engineered into salary.

## C-Level group

May retrieve aggregate project status, cost, estimate-at-completion, delivery risk and portfolio trends. C-Level answers should normally omit raw employee-level timesheet lines unless the question requires a documented operational investigation and the user has explicit detailed-project entitlement.

## Finance group

May combine this project data with detailed finance data to reconcile payroll, project cost, revenue and margin.

## Normal Employee group

Has no access to this project-management knowledge base. The chatbot operates as a general LLM without restricted RAG retrieval.

## RAG response rules

1. Cite project ID, reporting period and unit.
2. Distinguish baseline budget, adjusted budget, actual cost and estimate at completion.
3. Do not call a standard project cost rate a salary.
4. Do not expose named timesheet records outside the Project Management or Finance groups.
5. For C-Level users, aggregate by project or portfolio.
6. When the knowledge base is unavailable, answer that the information is not accessible.
7. Never present synthetic figures as real Virgool Luxembourg information.
