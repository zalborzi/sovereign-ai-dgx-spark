# Project Management Dataset — Data Dictionary

All records are synthetic. Monetary fields use EUR.

## 01_project_portfolio_master.csv
The ten-project portfolio master, including dates, manager, sponsor, delivery stage, completion and overall RAG status.

## 02_resource_directory_and_cost_rates.csv
The 50-person synthetic resource directory. It contains a standard hourly project cost rate, but deliberately excludes salary and payroll fields.

## 03_project_resource_allocations.csv
Named employee-to-project assignments, project role, allocation period, allocation percentage and planned weekly hours.

## 04_weekly_timesheets_2026.csv
Detailed weekly time entries showing employee, project, work package, activity, billable status, hours, project-cost rate, labor cost and approval status.

## 05_monthly_timesheet_approval_log.csv
Monthly submission and approval summary by employee.

## 06_work_packages_and_milestones.csv
Project work packages, milestones, planned dates, forecast or actual dates, effort and status.

## 07_project_budget_and_cost_control.csv
Baseline and adjusted cost budgets, actual hours and costs, estimate to complete, estimate at completion, cost variance, planned value, earned value, CPI and SPI.

## 08_resource_capacity_and_utilization.csv
Monthly capacity, leave, holiday, client hours, billable hours, utilization, target and allocation status by employee.

## 09_raid_log.csv
Risks, assumptions, issues and dependencies, including rating, owner, due date, status and mitigation.

## 10_change_request_log.csv
Scope, technical, schedule and compliance change requests with estimated and approved impacts.

## 11_timesheet_exception_report.csv
Under-logging, pending or rejected entries, over-allocation and other time-recording exceptions.

## Markdown documents
- Portfolio summary gives an aggregate RAG-friendly management view.
- Governance policy defines group-level access and response restrictions.
- Each project has a charter and a status report optimized for project-specific retrieval.
