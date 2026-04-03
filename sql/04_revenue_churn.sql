-- =============================================
-- ANALYSIS: Revenue, Churn & Customer Health
-- Business Question: What's our revenue health,
-- who's at risk of churning, and where is
-- expansion revenue coming from?
-- =============================================


-- -------------------------------------------------
-- 1. MRR breakdown by plan
-- Where does our revenue actually come from?
-- -------------------------------------------------
SELECT
    a.plan,
    COUNT(*) AS accounts,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM accounts WHERE plan != 'Free'), 1) AS pct_of_paid,
    ROUND(SUM(a.mrr), 2) AS total_mrr,
    ROUND(SUM(a.mrr) * 100.0 / (SELECT SUM(mrr) FROM accounts WHERE mrr > 0), 1) AS pct_of_revenue,
    ROUND(AVG(a.mrr), 2) AS avg_mrr,
    -- Revenue concentration
    ROUND(SUM(CASE WHEN a.churned = 'No' THEN a.mrr ELSE 0 END), 2) AS active_mrr,
    ROUND(SUM(CASE WHEN a.churned = 'Yes' THEN a.mrr ELSE 0 END), 2) AS churned_mrr
FROM accounts a
WHERE a.plan != 'Free'
GROUP BY a.plan
ORDER BY total_mrr DESC;


-- -------------------------------------------------
-- 2. Churn analysis by segment
-- Who's leaving and what do they look like?
-- -------------------------------------------------
SELECT
    a.plan,
    a.industry,
    COUNT(*) AS paid_accounts,
    COUNT(CASE WHEN a.churned = 'Yes' THEN 1 END) AS churned,
    ROUND(COUNT(CASE WHEN a.churned = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct,
    ROUND(SUM(CASE WHEN a.churned = 'Yes' THEN a.mrr ELSE 0 END), 2) AS lost_mrr,
    ROUND(AVG(CASE WHEN a.churned = 'Yes'
        THEN julianday(a.churn_date) - julianday(a.conversion_date)
        END), 1) AS avg_days_before_churn
FROM accounts a
WHERE a.plan != 'Free'
GROUP BY a.plan, a.industry
HAVING COUNT(*) >= 3
ORDER BY churn_rate_pct DESC
LIMIT 20;


-- -------------------------------------------------
-- 3. Monthly cohort retention (by signup month)
-- Classic SaaS cohort analysis
-- -------------------------------------------------
WITH monthly_active AS (
    SELECT
        fu.account_id,
        fu.usage_month
    FROM feature_usage fu
    GROUP BY fu.account_id, fu.usage_month
),
cohorts AS (
    SELECT
        a.account_id,
        strftime('%Y-%m', a.signup_date) AS cohort
    FROM accounts a
    WHERE a.plan != 'Free'
)
SELECT
    c.cohort,
    COUNT(DISTINCT c.account_id) AS cohort_size,
    COUNT(DISTINCT CASE WHEN ma.usage_month = c.cohort THEN ma.account_id END) AS month_0,
    COUNT(DISTINCT CASE
        WHEN ma.usage_month = strftime('%Y-%m', date(c.cohort || '-01', '+1 month'))
        THEN ma.account_id END) AS month_1,
    COUNT(DISTINCT CASE
        WHEN ma.usage_month = strftime('%Y-%m', date(c.cohort || '-01', '+2 month'))
        THEN ma.account_id END) AS month_2,
    COUNT(DISTINCT CASE
        WHEN ma.usage_month = strftime('%Y-%m', date(c.cohort || '-01', '+3 month'))
        THEN ma.account_id END) AS month_3,
    COUNT(DISTINCT CASE
        WHEN ma.usage_month = strftime('%Y-%m', date(c.cohort || '-01', '+6 month'))
        THEN ma.account_id END) AS month_6
FROM cohorts c
LEFT JOIN monthly_active ma ON c.account_id = ma.account_id
GROUP BY c.cohort
ORDER BY c.cohort;


-- -------------------------------------------------
-- 4. Customer health score
-- Flag accounts at risk before they churn
-- -------------------------------------------------
WITH recent_usage AS (
    SELECT
        account_id,
        COUNT(DISTINCT feature) AS features_last_month,
        SUM(times_used) AS total_usage_last_month
    FROM feature_usage
    WHERE usage_month = '2024-12'
    GROUP BY account_id
),
recent_tickets AS (
    SELECT
        account_id,
        COUNT(*) AS tickets_last_90d,
        COUNT(CASE WHEN priority IN ('High', 'Critical') THEN 1 END) AS urgent_tickets
    FROM support_tickets
    WHERE created_date >= '2024-10-01'
    GROUP BY account_id
)
SELECT
    a.account_id,
    a.plan,
    a.industry,
    a.mrr,
    COALESCE(ru.features_last_month, 0) AS features_used_dec,
    COALESCE(ru.total_usage_last_month, 0) AS usage_dec,
    COALESCE(rt.tickets_last_90d, 0) AS recent_tickets,
    COALESCE(rt.urgent_tickets, 0) AS urgent_tickets,
    -- Simple health score: usage + features - ticket issues
    CASE
        WHEN COALESCE(ru.total_usage_last_month, 0) = 0 THEN 'Critical Risk'
        WHEN COALESCE(ru.features_last_month, 0) <= 2 AND COALESCE(rt.urgent_tickets, 0) > 0 THEN 'High Risk'
        WHEN COALESCE(ru.features_last_month, 0) <= 3 THEN 'Medium Risk'
        ELSE 'Healthy'
    END AS health_status
FROM accounts a
LEFT JOIN recent_usage ru ON a.account_id = ru.account_id
LEFT JOIN recent_tickets rt ON a.account_id = rt.account_id
WHERE a.plan != 'Free' AND a.churned = 'No'
ORDER BY
    CASE
        WHEN COALESCE(ru.total_usage_last_month, 0) = 0 THEN 1
        WHEN COALESCE(ru.features_last_month, 0) <= 2 THEN 2
        ELSE 3
    END,
    a.mrr DESC;


-- -------------------------------------------------
-- 5. Support ticket patterns and churn correlation
-- Do unhappy customers leave? (Spoiler: yes)
-- -------------------------------------------------
WITH ticket_stats AS (
    SELECT
        account_id,
        COUNT(*) AS total_tickets,
        COUNT(CASE WHEN priority IN ('High', 'Critical') THEN 1 END) AS urgent_count,
        ROUND(AVG(CASE WHEN resolution_hours != '' THEN resolution_hours END), 1) AS avg_resolution_hrs,
        COUNT(CASE WHEN resolved = 'No' THEN 1 END) AS unresolved_count
    FROM support_tickets
    GROUP BY account_id
)
SELECT
    CASE
        WHEN ts.total_tickets >= 8 THEN 'Heavy (8+)'
        WHEN ts.total_tickets >= 4 THEN 'Moderate (4-7)'
        WHEN ts.total_tickets >= 1 THEN 'Light (1-3)'
        ELSE 'None'
    END AS ticket_volume,
    COUNT(*) AS accounts,
    ROUND(COUNT(CASE WHEN a.churned = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct,
    ROUND(AVG(ts.avg_resolution_hrs), 1) AS avg_resolution_hrs,
    ROUND(AVG(ts.unresolved_count), 1) AS avg_unresolved
FROM accounts a
LEFT JOIN ticket_stats ts ON a.account_id = ts.account_id
WHERE a.plan != 'Free'
GROUP BY ticket_volume
ORDER BY churn_rate_pct DESC;


-- -------------------------------------------------
-- 6. Executive dashboard: key SaaS metrics
-- -------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM accounts WHERE plan != 'Free') AS paying_customers,
    (SELECT ROUND(SUM(mrr), 2) FROM accounts WHERE plan != 'Free' AND churned = 'No') AS current_mrr,
    (SELECT ROUND(SUM(mrr) * 12, 2) FROM accounts WHERE plan != 'Free' AND churned = 'No') AS arr,
    (SELECT ROUND(AVG(mrr), 2) FROM accounts WHERE plan != 'Free') AS arpu,
    (SELECT ROUND(COUNT(CASE WHEN churned = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 1)
     FROM accounts WHERE plan != 'Free') AS churn_rate_pct,
    (SELECT ROUND(COUNT(CASE WHEN conversion_date != '' THEN 1 END) * 100.0 / COUNT(*), 1)
     FROM accounts) AS trial_conversion_rate,
    (SELECT COUNT(DISTINCT account_id) FROM feature_usage WHERE usage_month = '2024-12') AS mau_december;
