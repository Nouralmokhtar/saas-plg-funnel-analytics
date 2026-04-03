# SaaS Product-Led Growth: Funnel & Retention Analytics

## Overview

This project analyzes the **full customer journey** of a B2B SaaS platform — from signup through trial, conversion, feature adoption, and churn. The analysis was built to support Product, Growth, and CS teams with **data-backed recommendations**, not just dashboards.

### Business Context

The SaaS company was seeing strong top-of-funnel growth (signups were up 40% YoY) but revenue wasn't keeping pace. Leadership needed to understand:

1. **Where are we losing potential customers in the trial-to-paid funnel?**
2. **Which product behaviors predict conversion and long-term retention?**
3. **Who is at risk of churning, and can we intervene before they leave?**

---

## Key Findings & Recommendations

### Finding 1: The Onboarding Drop-Off
A significant portion of signups never complete onboarding. Accounts that complete onboarding convert at nearly 2x the rate of those who don't.

**Recommendation:** Redesign the onboarding flow to reduce steps, add progress indicators, and trigger an email sequence if a user stalls at onboarding for more than 48 hours.

### Finding 2: The "Aha Moment" Is Team Collaboration
Accounts that invite a team member during the trial convert and retain at significantly higher rates than those who use the product solo. This is our strongest activation signal.

**Recommendation:** Move "Invite your team" earlier in the onboarding flow (Step 2, not Step 5). Add a persistent in-app prompt for solo users during the trial.

### Finding 3: Feature Depth = Retention Shield
Paid accounts using 7+ features have dramatically lower churn than accounts using 1-3 features. Underused premium features (Automations, Advanced Analytics) represent untapped retention levers.

**Recommendation:** Launch a "Feature Discovery" campaign for accounts in months 2-3 that haven't tried premium features. Assign CSMs to proactively demo underused features during QBRs.

### Finding 4: Referrals Are the Best Channel
Referral signups convert at the highest rate AND have the highest average MRR. Paid ads bring volume but low-quality trials.

**Recommendation:** Double investment in referral program. Reallocate 20% of paid ad budget to referral incentives. Track cost-per-qualified-lead by channel, not just cost-per-signup.

---

## Project Structure

```
saas-plg-funnel-analytics/
│
├── README.md                        ← You are here
│
├── data/
│   ├── generate_data.py             ← Python script to create synthetic data
│   ├── accounts.csv                 ← 1,500 company accounts
│   ├── feature_usage.csv            ← Monthly feature usage per account
│   ├── support_tickets.csv          ← Customer support history
│   └── product_events.csv           ← Key activation events
│
├── sql/
│   ├── 01_schema.sql                ← Table definitions & data loading
│   ├── 02_conversion_funnel.sql     ← Trial-to-paid funnel analysis
│   ├── 03_feature_adoption.sql      ← Feature usage & "aha moment" analysis
│   └── 04_revenue_churn.sql         ← Revenue health, churn, customer scoring
│
└── screenshots/                     ← Query result screenshots (optional)
```

## Data Description

| Table | Rows | Description |
|-------|------|-------------|
| `accounts` | 1,500 | Company profiles with plan, MRR, source, churn status |
| `feature_usage` | ~80,000 | Monthly usage counts per feature per account |
| `support_tickets` | ~7,000 | Support history with priority, resolution, categories |
| `product_events` | ~10,000 | Activation milestones (onboarding, first report, etc.) |

**Note:** All data is synthetic, generated to reflect realistic SaaS conversion rates, usage patterns, and churn behavior. No real company data was used.

---

## How to Run

### Step 1: Generate the data
```bash
cd data/
python generate_data.py
```

### Step 2: Load into SQLite
```bash
cd data/
sqlite3 saas.db < ../sql/01_schema.sql
```
Then in the SQLite shell:
```sql
.mode csv
.import --skip 1 accounts.csv accounts
.import --skip 1 feature_usage.csv feature_usage
.import --skip 1 support_tickets.csv support_tickets
.import --skip 1 product_events.csv product_events
```

### Step 3: Run the analysis
```bash
sqlite3 saas.db < ../sql/02_conversion_funnel.sql
sqlite3 saas.db < ../sql/03_feature_adoption.sql
sqlite3 saas.db < ../sql/04_revenue_churn.sql
```

---

## SQL Techniques Used

- Common Table Expressions (CTEs) for multi-step analysis
- Window functions for within-group calculations
- Funnel analysis using EXISTS subqueries
- CASE statements for customer health scoring
- Cohort retention analysis with date arithmetic
- Conditional aggregation for pivot-style outputs

---

## Tools

- **SQL** (SQLite-compatible, portable to PostgreSQL/BigQuery/Snowflake)
- **Python** (data generation only — standard library, no packages needed)

---

## About

This project demonstrates a **product-focused data analyst's** approach to SaaS growth analytics — connecting feature usage data to business outcomes, building actionable customer health scores, and providing the kind of insights that Product, Growth, and Customer Success teams can act on immediately.

The analysis reflects experience working with SaaS startups on funnel optimization, feature adoption tracking, and churn prevention — always focused on decisions and impact, not just numbers.
