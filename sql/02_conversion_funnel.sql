-- =============================================
-- ANALYSIS: Trial-to-Paid Conversion Funnel
-- Business Question: Where are we losing
-- potential customers in the funnel, and what
-- predicts conversion?
-- =============================================


-- -------------------------------------------------
-- 1. Overall funnel: Signup → Onboarding → Activation → Conversion
-- The product team's most important view
-- -------------------------------------------------
WITH funnel AS (
    SELECT
        a.account_id,
        1 AS signed_up,
        CASE WHEN EXISTS (
            SELECT 1 FROM product_events pe
            WHERE pe.account_id = a.account_id AND pe.event_type = 'Completed Onboarding'
        ) THEN 1 ELSE 0 END AS completed_onboarding,
        CASE WHEN EXISTS (
            SELECT 1 FROM product_events pe
            WHERE pe.account_id = a.account_id AND pe.event_type = 'Created First Report'
        ) THEN 1 ELSE 0 END AS created_first_report,
        CASE WHEN EXISTS (
            SELECT 1 FROM product_events pe
            WHERE pe.account_id = a.account_id AND pe.event_type = 'Invited Team Member'
        ) THEN 1 ELSE 0 END AS invited_team,
        CASE WHEN a.conversion_date IS NOT NULL AND a.conversion_date != '' THEN 1 ELSE 0 END AS converted
    FROM accounts a
)
SELECT
    COUNT(*) AS total_signups,
    SUM(completed_onboarding) AS onboarded,
    ROUND(SUM(completed_onboarding) * 100.0 / COUNT(*), 1) AS onboarding_rate,
    SUM(created_first_report) AS activated,
    ROUND(SUM(created_first_report) * 100.0 / COUNT(*), 1) AS activation_rate,
    SUM(invited_team) AS invited_team,
    ROUND(SUM(invited_team) * 100.0 / COUNT(*), 1) AS team_invite_rate,
    SUM(converted) AS converted,
    ROUND(SUM(converted) * 100.0 / COUNT(*), 1) AS conversion_rate
FROM funnel;


-- -------------------------------------------------
-- 2. Conversion rate by acquisition source
-- Where should marketing spend their budget?
-- -------------------------------------------------
SELECT
    a.source,
    COUNT(*) AS signups,
    COUNT(CASE WHEN a.conversion_date != '' THEN 1 END) AS conversions,
    ROUND(COUNT(CASE WHEN a.conversion_date != '' THEN 1 END) * 100.0 / COUNT(*), 1) AS conversion_rate,
    ROUND(AVG(CASE WHEN a.mrr > 0 THEN a.mrr END), 2) AS avg_mrr_of_converted,
    ROUND(
        COUNT(CASE WHEN a.conversion_date != '' THEN 1 END) * 1.0 / COUNT(*)
        * AVG(CASE WHEN a.mrr > 0 THEN a.mrr END), 2
    ) AS revenue_per_signup
FROM accounts a
GROUP BY a.source
ORDER BY revenue_per_signup DESC;


-- -------------------------------------------------
-- 3. Conversion rate by company size
-- Are we building for the right customer profile?
-- -------------------------------------------------
SELECT
    a.company_size,
    COUNT(*) AS signups,
    COUNT(CASE WHEN a.conversion_date != '' THEN 1 END) AS conversions,
    ROUND(COUNT(CASE WHEN a.conversion_date != '' THEN 1 END) * 100.0 / COUNT(*), 1) AS conversion_rate,
    ROUND(AVG(CASE WHEN a.mrr > 0 THEN a.mrr END), 2) AS avg_mrr,
    -- What plan do they pick?
    COUNT(CASE WHEN a.plan = 'Enterprise' THEN 1 END) AS enterprise_count,
    COUNT(CASE WHEN a.plan = 'Growth' THEN 1 END) AS growth_count,
    COUNT(CASE WHEN a.plan = 'Starter' THEN 1 END) AS starter_count
FROM accounts a
GROUP BY a.company_size
ORDER BY conversion_rate DESC;


-- -------------------------------------------------
-- 4. Time to convert (trial → paid)
-- How long does the decision take?
-- -------------------------------------------------
SELECT
    a.plan,
    COUNT(*) AS accounts,
    ROUND(AVG(julianday(a.conversion_date) - julianday(a.signup_date)), 1) AS avg_days_to_convert,
    ROUND(MIN(julianday(a.conversion_date) - julianday(a.signup_date)), 1) AS fastest_conversion,
    ROUND(MAX(julianday(a.conversion_date) - julianday(a.signup_date)), 1) AS slowest_conversion
FROM accounts a
WHERE a.conversion_date IS NOT NULL AND a.conversion_date != ''
GROUP BY a.plan
ORDER BY avg_days_to_convert;


-- -------------------------------------------------
-- 5. Monthly signup and conversion trend
-- Is our funnel improving over time?
-- -------------------------------------------------
SELECT
    strftime('%Y-%m', a.signup_date) AS signup_month,
    COUNT(*) AS signups,
    COUNT(CASE WHEN a.conversion_date != '' THEN 1 END) AS conversions,
    ROUND(COUNT(CASE WHEN a.conversion_date != '' THEN 1 END) * 100.0 / COUNT(*), 1) AS conversion_rate,
    ROUND(SUM(a.mrr), 2) AS new_mrr_added
FROM accounts a
GROUP BY strftime('%Y-%m', a.signup_date)
ORDER BY signup_month;
