# Synthetic Project Management Dataset — Virgool Luxembourg RAG Demo

**Status:** Fully synthetic training/demo data  
**Company represented:** Fictionalized Virgool Luxembourg entity  
**Employees:** 50, reused from the synthetic finance package  
**Client projects:** 10  
**Period:** 2026  
**Purpose:** Demonstrate named project-time retrieval, project cost control, portfolio reporting and role-based RAG access.

> No employee, client, project, rate, timesheet, cost, milestone or risk in this package is real.

## What this package demonstrates

- Some employees are dedicated to one project.
- Some specialists and managers work across several projects.
- Employees record time weekly against a project and work package.
- Project managers can see who recorded time, where it was recorded and the resulting project cost.
- Project managers can monitor budget consumption, EAC, utilization, milestones, RAID and change requests.
- C-Level users can later receive aggregate project views without raw employee-level detail.
- Normal employees have no access to the restricted project RAG knowledge.

## Files

1. `01_project_portfolio_master.csv`
2. `02_resource_directory_and_cost_rates.csv`
3. `03_project_resource_allocations.csv`
4. `04_weekly_timesheets_2026.csv`
5. `05_monthly_timesheet_approval_log.csv`
6. `06_work_packages_and_milestones.csv`
7. `07_project_budget_and_cost_control.csv`
8. `08_resource_capacity_and_utilization.csv`
9. `09_raid_log.csv`
10. `10_change_request_log.csv`
11. `11_timesheet_exception_report.csv`
12. `12_portfolio_status_summary.md`
13. `13_project_governance_and_access_policy.md`
14. `14_data_dictionary.md`
15. `project_charters/` — one Markdown charter per project.
16. `project_status_reports/` — one Markdown status report per project.
17. `project_management_dataset_2026.xlsx` — consolidated management workbook.

## Headline portfolio values

- Client projects: **10**
- Named employees: **50**
- Detailed weekly timesheet lines: **10,288**
- Planned resource-allocation records: **181**
- Total project hours recorded: **56,322.0**
- Actual project cost to date: **€5,730,842**
- Portfolio EAC: **€6,359,708**
- Timesheet exceptions: **83**

## Recommended knowledge bases

### Project Management Detailed
Upload all CSV and Markdown files. Restrict to the Project Management and Finance groups.

### Executive Project Overview
Upload:
- `01_project_portfolio_master.csv`
- `06_work_packages_and_milestones.csv`
- `07_project_budget_and_cost_control.csv`
- `09_raid_log.csv`
- `10_change_request_log.csv`
- `12_portfolio_status_summary.md`
- project status reports

Do not include raw timesheets, named allocations, cost rates or exception files in the executive knowledge base.
