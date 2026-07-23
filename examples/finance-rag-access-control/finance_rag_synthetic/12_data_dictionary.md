# Data Dictionary

All datasets are synthetic. Monetary fields are expressed in EUR unless stated otherwise.

## 01_employee_compensation_master.csv
- `employee_id`: Synthetic unique employee identifier.
- `employee_name`: Fictional employee name.
- `department`: Organizational department.
- `job_title`: Synthetic job title.
- `rag_access_group`: Demo access group.
- `annual_base_salary_eur`: Annual gross base salary.
- `target_bonus_pct`: Target variable-pay percentage.
- `company_car_annual_cost_eur`: Annual employer cost of company car.
- `meal_vouchers_annual_cost_eur`: Annual meal-voucher employer cost.
- `other_benefits_annual_cost_eur`: Other annual benefits.

## 02_monthly_payroll_2026.csv
- `monthly_base_salary_eur`: Monthly base salary.
- `overtime_and_allowances_eur`: Overtime and allowances.
- `variable_bonus_eur`: Bonus paid in the period.
- `employer_social_charges_eur`: Synthetic employer social-cost estimate.
- `benefits_cost_eur`: Monthly benefits cost.
- `total_employer_cost_eur`: Total monthly employer cost.

## 03_project_financials_2026.csv
- `contract_value_eur`: Signed synthetic contract value.
- `completion_pct`: Delivery completion at year end.
- `revenue_recognized_2026_eur`: Revenue recognized in FY2026.
- `delivery_labor_cost_eur`: Labor attributed to project delivery.
- `total_project_cost_eur`: Total delivery cost.
- `gross_profit_eur`: Recognized revenue less project cost.
- `gross_margin_pct`: Gross profit divided by recognized revenue.
- `financial_status`: Healthy, Watch or At Risk.

## 04_revenue_ledger_2026.csv
Monthly project revenue split into recognized, billed and unbilled values.

## 05_operating_expenses_2026.csv
Monthly corporate operating expenses by category, actual, budget and variance.

## 06_accounts_receivable_aging_2026.csv
Client receivables split by current, 1–30, 31–60 and 61+ day aging buckets.

## 07_company_pnl_monthly_2026.csv
Monthly revenue, cost, operating profit and operating margin.

## 08_budget_vs_actual_2026.csv
Budget and actual values for revenue and operating cost.

## 09_balance_sheet_2026.csv
Synthetic year-end assets, liabilities and equity entries.
