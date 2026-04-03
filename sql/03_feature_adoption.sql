-- =============================================
-- ANALYSIS: Feature Adoption & Product Engagement
-- Business Question: Which features drive
-- retention and expansion? Where are users
-- getting stuck?
-- =============================================


-- -------------------------------------------------
-- 1. Feature adoption rates across all accounts
-- Which features are popular vs underused?
-- -------------------------------------------------
SELECT
    fu.feature,
    COUNT(DISTINCT fu.account_id) AS accounts_using,
    ROUND(COUNT(DISTINCT fu.account_id) * 100.0 / (SELECT COUNT(*) FROM accounts), 1) AS adoption_rate_pct,
    ROUND(AVG(fu.times_used), 1) AS avg_monthly_usage,
    ROUND(SUM(fu.times_used) * 1.0 / COUNT(DISTINCT fu.usage_month), 1) AS usage_per_month
FROM feature_usage fu
GROUP BY fu.feature
ORDER BY adoption_rate_pct DESC;


-- -------------------------------------------------
-- 2. Feature usage by plan tier
-- Are paid users getting value from premium features?
-- -------------------------------------------------
SELECT
    a.plan,
    fu.feature,
    COUNT(DISTINCT fu.account_id) AS users,
    ROUND(AVG(fu.times_used), 1) AS avg_usage
FROM feature_usage fu
JOIN accounts a ON fu.account_id = a.account_id
WHERE a.plan != 'Free'
GROUP BY a.plan, fu.feature
ORDER BY a.plan, avg_usage DESC;


-- -------------------------------------------------
-- 3. Features that predict conversion
-- Accounts that used X before converting vs not
-- This is the "aha moment" analysis
-- -------------------------------------------------
WITH trial_feature_usage AS (
    SELECT
        fu.account_id,
        fu.feature,
        SUM(fu.times_used) AS trial_usage
    FROM feature_usage fu
    JOIN accounts a ON fu.account_id = a.account_id
    WHERE fu.usage_month <= strftime('%Y-%m', a.trial_end_date)
    GROUP BY fu.account_id, fu.feature
),
conversion_by_feature AS (
    SELECT
        tfu.feature,
        COUNT(DISTINCT tfu.account_id) AS used_during_trial,
        COUNT(DISTINCT CASE WHEN a.conversion_date != '' THEN a.account_id END) AS converted,
        COUNT(DISTINCT CASE WHEN a.conversion_date = '' OR a.conversion_date IS NULL THEN a.account_id END) AS did_not_convert
    FROM trial_feature_usage tfu
    JOIN accounts a ON tfu.account_id = a.account_id
    GROUP BY tfu.feature
)
SELECT
    feature,
    used_during_trial,
    converted,
    did_not_convert,
    ROUND(converted * 100.0 / used_during_trial, 1) AS conversion_rate_if_used,
    ROUND(
        (SELECT COUNT(CASE WHEN conversion_date != '' THEN 1 END) * 100.0 / COUNT(*)
         FROM accounts), 1
    ) AS overall_conversion_rate
FROM conversion_by_feature
ORDER BY conversion_rate_if_used DESC;


-- -------------------------------------------------
-- 4. Feature depth score vs churn
-- Do accounts using more features churn less?
-- -------------------------------------------------
WITH account_feature_depth AS (
    SELECT
        fu.account_id,
        COUNT(DISTINCT fu.feature) AS features_used,
        SUM(fu.times_used) AS total_usage
    FROM feature_usage fu
    GROUP BY fu.account_id
)
SELECT
    CASE
        WHEN afd.features_used >= 7 THEN 'Power User (7+)'
        WHEN afd.features_used >= 4 THEN 'Engaged (4-6)'
        WHEN afd.features_used >= 2 THEN 'Light (2-3)'
        ELSE 'Minimal (1)'
    END AS engagement_level,
    COUNT(*) AS accounts,
    ROUND(COUNT(CASE WHEN a.churned = 'Yes' THEN 1 END) * 100.0 / COUNT(*), 1) AS churn_rate_pct,
    ROUND(AVG(a.mrr), 2) AS avg_mrr,
    ROUND(AVG(afd.total_usage), 1) AS avg_total_usage
FROM account_feature_depth afd
JOIN accounts a ON afd.account_id = a.account_id
WHERE a.plan != 'Free'
GROUP BY engagement_level
ORDER BY churn_rate_pct;


-- -------------------------------------------------
-- 5. Activation milestones and their impact
-- Which product events correlate with success?
-- -------------------------------------------------
SELECT
    pe.event_type,
    COUNT(DISTINCT pe.account_id) AS accounts_completed,
    ROUND(COUNT(DISTINCT pe.account_id) * 100.0 / (SELECT COUNT(*) FROM accounts), 1) AS completion_rate,
    ROUND(
        COUNT(DISTINCT CASE WHEN a.conversion_date != '' THEN a.account_id END) * 100.0
        / NULLIF(COUNT(DISTINCT pe.account_id), 0), 1
    ) AS conversion_rate_after,
    ROUND(
        COUNT(DISTINCT CASE WHEN a.churned = 'No' AND a.plan != 'Free' THEN a.account_id END) * 100.0
        / NULLIF(COUNT(DISTINCT CASE WHEN a.plan != 'Free' THEN a.account_id END), 0), 1
    ) AS retention_rate_after
FROM product_events pe
JOIN accounts a ON pe.account_id = a.account_id
GROUP BY pe.event_type
ORDER BY conversion_rate_after DESC;
