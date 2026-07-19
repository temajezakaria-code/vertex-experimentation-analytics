-- =============================================================================
-- Vertex Commerce — A/B Testing Portfolio SQL Analysis
-- 10 queries covering statistical significance (computed directly in SQL),
-- sample ratio mismatch, power/sample-size adequacy, guardrail regressions,
-- segment heterogeneity, and novelty decay. Tested and verified against
-- vertex_experiments.db (SQLite).
-- =============================================================================

-- =============================================================================
-- QUERY 1: PORTFOLIO SIGNIFICANCE SUMMARY (TWO-PROPORTION Z-TEST, COMPUTED IN SQL)
-- Techniques: CTE, aggregate, statistical formula in SQL, CASE
-- =============================================================================
-- WHY: Rather than eyeballing "treatment rate looks higher," this computes an
-- actual two-proportion z-test (z = (p1-p2) / SE_pooled) directly in SQL for
-- every test in the portfolio in one pass — the correct, rigorous way to
-- determine statistical significance, not just visual inspection of a bar
-- chart.
-- BUSINESS VALUE: Gives leadership a single, statistically defensible table
-- of "which tests actually won" instead of 30 separate ad hoc judgment calls.
-- HOW A HIRING MANAGER READS THIS: Computing a z-test manually in SQL (not
-- just calling a library function) demonstrates genuine understanding of
-- the underlying statistics, not just tool familiarity.
-- =============================================================================
WITH stats AS (
    SELECT
        test_id,
        SUM(CASE WHEN variant='Control' THEN converted ELSE 0 END) AS x1,
        SUM(CASE WHEN variant='Control' THEN 1 ELSE 0 END) AS n1,
        SUM(CASE WHEN variant='Treatment' THEN converted ELSE 0 END) AS x2,
        SUM(CASE WHEN variant='Treatment' THEN 1 ELSE 0 END) AS n2
    FROM fact_assignments
    GROUP BY test_id
),
calc AS (
    SELECT
        test_id,
        x1*1.0/n1 AS p1, x2*1.0/n2 AS p2, n1, n2,
        (x1+x2)*1.0/(n1+n2) AS p_pool
    FROM stats
)
SELECT
    e.test_name, e.category,
    ROUND(p1*100,2) AS control_rate_pct, ROUND(p2*100,2) AS treatment_rate_pct,
    ROUND((p2-p1)/p1*100,1) AS relative_lift_pct,
    ROUND((p2-p1) / SQRT(p_pool*(1-p_pool)*(1.0/n1+1.0/n2)), 2) AS z_score,
    CASE WHEN ABS((p2-p1) / SQRT(p_pool*(1-p_pool)*(1.0/n1+1.0/n2))) >= 1.96 THEN 'Significant' ELSE 'Not Significant' END AS result
FROM calc c
JOIN dim_experiments e ON e.test_id = c.test_id
ORDER BY z_score DESC;


-- =============================================================================
-- QUERY 2: SAMPLE RATIO MISMATCH (SRM) CHECK
-- Techniques: aggregate, CASE, data-quality validation
-- =============================================================================
-- WHY: Before trusting ANY result from a test, check whether the randomizer
-- actually split traffic ~50/50 as intended. A meaningful imbalance (Sample
-- Ratio Mismatch) is a classic sign of a broken experiment — often caused by
-- a bug in the assignment logic — that invalidates the result regardless of
-- what the conversion rates show.
-- BUSINESS VALUE: Catches broken experiments BEFORE they influence a ship/
-- no-ship decision, rather than after a flawed test has already misled
-- leadership.
-- HOW A HIRING MANAGER READS THIS: SRM checking is a real, standard
-- practice at every major tech company's experimentation platform, and it's
-- almost never seen in portfolio projects — a strong differentiator.
-- =============================================================================
SELECT
    e.test_name,
    SUM(CASE WHEN variant='Control' THEN 1 ELSE 0 END) AS control_n,
    SUM(CASE WHEN variant='Treatment' THEN 1 ELSE 0 END) AS treatment_n,
    ROUND(SUM(CASE WHEN variant='Control' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_control,
    CASE WHEN ABS(SUM(CASE WHEN variant='Control' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) - 50) > 2
         THEN 'Check for SRM' ELSE 'OK' END AS srm_flag
FROM fact_assignments f
JOIN dim_experiments e ON e.test_id = f.test_id
GROUP BY e.test_name
ORDER BY ABS(pct_control - 50) DESC
LIMIT 10;


-- =============================================================================
-- QUERY 3: SAMPLE SIZE ADEQUACY VS. A MINIMUM DETECTABLE EFFECT BENCHMARK
-- Techniques: CASE, aggregate, business-formula calculation
-- =============================================================================
-- WHY: A test with no significant result could mean "no real effect" OR
-- "the sample size was too small to reliably detect a real effect" — this
-- flags which planned sample sizes fall well below what a standard power
-- calculation would require to detect a modest 5% relative lift, so a null
-- result isn't automatically read as "this doesn't work."
-- BUSINESS VALUE: Prevents leadership from prematurely killing an idea that
-- might actually work, just because the test was underpowered.
-- HOW A HIRING MANAGER READS THIS: Distinguishing "not significant" from
-- "underpowered" is one of the most common statistical mistakes junior
-- analysts make — explicitly flagging it shows real rigor.
-- =============================================================================
SELECT
    test_name, category, planned_sample_size_per_variant,
    CASE
        WHEN planned_sample_size_per_variant < 2000 THEN 'Likely Underpowered for a 5% Relative Lift'
        WHEN planned_sample_size_per_variant < 5000 THEN 'Marginally Powered'
        ELSE 'Adequately Powered'
    END AS power_assessment
FROM dim_experiments
ORDER BY planned_sample_size_per_variant ASC
LIMIT 10;


-- =============================================================================
-- QUERY 4: GUARDRAIL METRIC REGRESSION CHECK
-- Techniques: CTE, aggregate, CASE
-- =============================================================================
-- WHY: A primary-metric "win" can hide a guardrail-metric regression (e.g.,
-- conversion goes up but refunds/complaints double). Checking both together
-- prevents shipping a change that trades short-term conversion for
-- long-term customer harm.
-- BUSINESS VALUE: Directly prevents a "win" from being shipped that would
-- quietly damage a different, equally important business outcome.
-- HOW A HIRING MANAGER READS THIS: Evaluating a test on ONE metric alone is
-- the single most common mistake in real experimentation programs — this
-- query demonstrates the discipline to check both, every time.
-- =============================================================================
WITH primary_and_guardrail AS (
    SELECT
        test_id,
        AVG(CASE WHEN variant='Control' THEN converted*1.0 END) AS ctrl_conversion,
        AVG(CASE WHEN variant='Treatment' THEN converted*1.0 END) AS treat_conversion,
        AVG(CASE WHEN variant='Control' THEN guardrail_event*1.0 END) AS ctrl_guardrail,
        AVG(CASE WHEN variant='Treatment' THEN guardrail_event*1.0 END) AS treat_guardrail
    FROM fact_assignments
    GROUP BY test_id
)
SELECT
    e.test_name,
    ROUND(ctrl_conversion*100,2) AS ctrl_conv_pct, ROUND(treat_conversion*100,2) AS treat_conv_pct,
    ROUND(ctrl_guardrail*100,2) AS ctrl_guardrail_pct, ROUND(treat_guardrail*100,2) AS treat_guardrail_pct,
    CASE WHEN treat_conversion > ctrl_conversion AND treat_guardrail > ctrl_guardrail * 1.3
         THEN 'PRIMARY WIN BUT GUARDRAIL REGRESSION' ELSE 'OK' END AS flag
FROM primary_and_guardrail p
JOIN dim_experiments e ON e.test_id = p.test_id
ORDER BY (treat_guardrail - ctrl_guardrail) DESC
LIMIT 10;


-- =============================================================================
-- QUERY 5: SEGMENT HETEROGENEITY CHECK (DEVICE TYPE)
-- Techniques: CTE, multi-dimensional aggregation, CASE
-- =============================================================================
-- WHY: An aggregate "win" can be driven entirely by one segment while the
-- majority segment sees no effect at all — this is functionally the same
-- risk as Simpson's Paradox: an aggregate number that doesn't represent what
-- most users actually experienced.
-- BUSINESS VALUE: Tells product teams whether to ship a change to everyone,
-- or only to the segment where it actually works.
-- HOW A HIRING MANAGER READS THIS: Segmenting results before declaring a
-- universal win is exactly the discipline that separates "ran a query" from
-- "understands experimentation."
-- =============================================================================
SELECT
    e.test_name,
    f.device_type,
    SUM(CASE WHEN variant='Control' THEN 1 ELSE 0 END) AS n_control,
    ROUND(AVG(CASE WHEN variant='Control' THEN converted*1.0 END)*100,2) AS ctrl_rate,
    ROUND(AVG(CASE WHEN variant='Treatment' THEN converted*1.0 END)*100,2) AS treat_rate
FROM fact_assignments f
JOIN dim_experiments e ON e.test_id = f.test_id
WHERE e.test_id IN (21, 22)
GROUP BY e.test_name, f.device_type
ORDER BY e.test_name, f.device_type;


-- =============================================================================
-- QUERY 6: NOVELTY EFFECT DECAY — EARLY VS. LATE CONVERSION WITHIN A TEST
-- Techniques: CASE bucketing, aggregate, time-based analysis
-- =============================================================================
-- WHY: Checks whether a test's lift is stable across its runtime or front-
-- loaded (a novelty effect that will fade after launch) by comparing
-- treatment performance in the first vs. last third of the test window.
-- BUSINESS VALUE: Prevents shipping a change based on an inflated early
-- signal that would disappoint once the novelty wears off post-launch.
-- HOW A HIRING MANAGER READS THIS: Checking for novelty/primacy effects is
-- a known best practice almost never demonstrated in portfolio projects.
-- =============================================================================
SELECT
    e.test_name,
    CASE WHEN days_elapsed_in_test <= 7 THEN 'Early (days 0-7)' ELSE 'Late (days 21+)' END AS test_period,
    ROUND(AVG(CASE WHEN variant='Treatment' THEN converted*1.0 END)*100,2) AS treatment_conv_rate,
    ROUND(AVG(CASE WHEN variant='Control' THEN converted*1.0 END)*100,2) AS control_conv_rate
FROM fact_assignments f
JOIN dim_experiments e ON e.test_id = f.test_id
WHERE e.test_id IN (19, 20) AND (days_elapsed_in_test <= 7 OR days_elapsed_in_test > 21)
GROUP BY e.test_name, test_period
ORDER BY e.test_name, test_period DESC;


-- =============================================================================
-- QUERY 7: REVENUE IMPACT RANKING (BUSINESS SIGNIFICANCE, NOT JUST STATISTICAL)
-- Techniques: aggregate, ranking, business-value calculation
-- =============================================================================
-- WHY: A statistically significant test isn't automatically a business
-- priority — this ranks tests by actual incremental revenue per user, which
-- is what should drive prioritization of engineering resources to actually
-- ship the winning variant.
-- BUSINESS VALUE: Directly answers "which winning tests should we implement
-- first," not just "which tests were statistically significant."
-- HOW A HIRING MANAGER READS THIS: Separating statistical significance from
-- business significance is a mature, business-first analytical instinct.
-- =============================================================================
SELECT
    e.test_name, e.category,
    ROUND(AVG(CASE WHEN variant='Control' THEN revenue END),2) AS avg_revenue_control,
    ROUND(AVG(CASE WHEN variant='Treatment' THEN revenue END),2) AS avg_revenue_treatment,
    ROUND(AVG(CASE WHEN variant='Treatment' THEN revenue END) - AVG(CASE WHEN variant='Control' THEN revenue END), 2) AS revenue_lift_per_user
FROM fact_assignments f
JOIN dim_experiments e ON e.test_id = f.test_id
GROUP BY e.test_name, e.category
ORDER BY revenue_lift_per_user DESC
LIMIT 10;


-- =============================================================================
-- QUERY 8: WIN RATE BY EXPERIMENT CATEGORY
-- Techniques: CTE, aggregate, ranking
-- =============================================================================
-- WHY: Aggregates the significance results (from Query 1's logic) up to the
-- category level to see which type of experiment (Checkout, Pricing, Email,
-- etc.) has the best track record.
-- BUSINESS VALUE: Informs where to invest future experimentation resources
-- — categories with a strong historical win rate deserve more test slots.
-- HOW A HIRING MANAGER READS THIS: Rolling up individual test results into
-- a portfolio-level resource-allocation insight is exactly the kind of
-- meta-analysis a senior analyst is expected to produce.
-- =============================================================================
WITH stats AS (
    SELECT test_id,
        SUM(CASE WHEN variant='Control' THEN converted ELSE 0 END)*1.0 / SUM(CASE WHEN variant='Control' THEN 1 ELSE 0 END) AS p1,
        SUM(CASE WHEN variant='Treatment' THEN converted ELSE 0 END)*1.0 / SUM(CASE WHEN variant='Treatment' THEN 1 ELSE 0 END) AS p2,
        SUM(CASE WHEN variant='Control' THEN 1 ELSE 0 END) AS n1, SUM(CASE WHEN variant='Treatment' THEN 1 ELSE 0 END) AS n2,
        (SUM(converted)*1.0)/COUNT(*) AS p_pool
    FROM fact_assignments GROUP BY test_id
)
SELECT
    e.category,
    COUNT(*) AS tests_run,
    SUM(CASE WHEN ABS((p2-p1)/SQRT(p_pool*(1-p_pool)*(1.0/n1+1.0/n2))) >= 1.96 AND p2 > p1 THEN 1 ELSE 0 END) AS significant_wins,
    ROUND(SUM(CASE WHEN ABS((p2-p1)/SQRT(p_pool*(1-p_pool)*(1.0/n1+1.0/n2))) >= 1.96 AND p2 > p1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS win_rate_pct
FROM stats s JOIN dim_experiments e ON e.test_id = s.test_id
GROUP BY e.category
ORDER BY win_rate_pct DESC;


-- =============================================================================
-- QUERY 9: STATISTICAL SIGNIFICANCE VS. BUSINESS IMPACT QUADRANT
-- Techniques: CTE, CASE, multi-factor classification
-- =============================================================================
-- WHY: Classifies every test into a 2x2 framework (significant/not x
-- large-revenue-impact/small) — the actual decision framework a
-- prioritization meeting should use, instead of treating "significant" as
-- the only criterion for shipping.
-- BUSINESS VALUE: A statistically significant test with negligible revenue
-- impact may not be worth the engineering cost to ship: a not-quite-
-- significant test with a large potential impact may be worth re-testing
-- with a bigger sample rather than discarding.
-- HOW A HIRING MANAGER READS THIS: This is literally how real
-- experimentation review meetings prioritize a backlog — demonstrating this
-- framework shows direct exposure to how the job actually works.
-- =============================================================================
WITH stats AS (
    SELECT test_id,
        SUM(CASE WHEN variant='Control' THEN converted ELSE 0 END)*1.0 / SUM(CASE WHEN variant='Control' THEN 1 ELSE 0 END) AS p1,
        SUM(CASE WHEN variant='Treatment' THEN converted ELSE 0 END)*1.0 / SUM(CASE WHEN variant='Treatment' THEN 1 ELSE 0 END) AS p2,
        SUM(CASE WHEN variant='Control' THEN 1 ELSE 0 END) AS n1, SUM(CASE WHEN variant='Treatment' THEN 1 ELSE 0 END) AS n2,
        (SUM(converted)*1.0)/COUNT(*) AS p_pool,
        AVG(CASE WHEN variant='Treatment' THEN revenue END) - AVG(CASE WHEN variant='Control' THEN revenue END) AS revenue_lift
    FROM fact_assignments GROUP BY test_id
)
SELECT
    e.test_name,
    ROUND(ABS((p2-p1)/SQRT(p_pool*(1-p_pool)*(1.0/n1+1.0/n2))),2) AS z_score,
    ROUND(revenue_lift,2) AS revenue_lift_per_user,
    CASE
        WHEN ABS((p2-p1)/SQRT(p_pool*(1-p_pool)*(1.0/n1+1.0/n2))) >= 1.96 AND revenue_lift > 0.3 THEN 'Ship Now: Significant + High Impact'
        WHEN ABS((p2-p1)/SQRT(p_pool*(1-p_pool)*(1.0/n1+1.0/n2))) >= 1.96 AND revenue_lift <= 0.3 THEN 'Low Priority: Significant but Low Impact'
        WHEN ABS((p2-p1)/SQRT(p_pool*(1-p_pool)*(1.0/n1+1.0/n2))) < 1.96 AND revenue_lift > 0.3 THEN 'Re-test with Larger Sample: High Potential, Underpowered'
        ELSE 'Do Not Ship'
    END AS decision_quadrant
FROM stats s JOIN dim_experiments e ON e.test_id = s.test_id
ORDER BY revenue_lift_per_user DESC
LIMIT 15;


-- =============================================================================
-- QUERY 10: NEW VS. RETURNING USER SEGMENT LIFT COMPARISON (PORTFOLIO-WIDE)
-- Techniques: aggregate, multi-dimensional grouping, ranking
-- =============================================================================
-- WHY: Checks whether experiment effects systematically differ between new
-- and returning users across the whole portfolio, not just one test — a
-- portfolio-level pattern would suggest segment-specific experimentation
-- strategy is warranted network-wide.
-- BUSINESS VALUE: If new users are consistently more responsive to changes
-- than returning users (or vice versa), that reshapes how the whole
-- experimentation roadmap should be segmented going forward.
-- HOW A HIRING MANAGER READS THIS: Looking for a portfolio-wide pattern
-- across 30 tests (not just analyzing each test in isolation) is a
-- meta-analytical instinct that shows strategic, not just tactical, thinking.
-- =============================================================================
SELECT
    user_type,
    COUNT(DISTINCT test_id) AS tests_included,
    ROUND(AVG(CASE WHEN variant='Control' THEN converted*1.0 END)*100,2) AS avg_control_rate,
    ROUND(AVG(CASE WHEN variant='Treatment' THEN converted*1.0 END)*100,2) AS avg_treatment_rate
FROM fact_assignments
GROUP BY user_type;
