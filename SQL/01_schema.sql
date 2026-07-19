-- =============================================================================
-- Vertex Commerce — A/B Testing Portfolio Database Schema
-- =============================================================================
-- Business scenario: Vertex Commerce runs dozens of A/B tests per quarter
-- across checkout, onboarding, pricing, email, search, and recommendations,
-- but leadership has no consolidated view of experiment quality or true
-- business impact. This dataset is entirely synthetic, with PROGRAMMED true
-- underlying effects (including deliberately embedded pitfalls: underpowered
-- tests, true nulls, novelty decay, segment heterogeneity, guardrail
-- regressions) — real companies never publish raw multi-test experiment
-- data, so this is the only way to build a portfolio with verifiable ground
-- truth to test analytical rigor against.
-- =============================================================================

CREATE TABLE dim_experiments (
    test_id                          INTEGER PRIMARY KEY,
    test_name                        VARCHAR(60) NOT NULL,
    category                         VARCHAR(20) NOT NULL,
    start_date                       DATE NOT NULL,
    end_date                         DATE NOT NULL,
    planned_sample_size_per_variant  INTEGER NOT NULL,
    primary_metric                   VARCHAR(30) NOT NULL,
    guardrail_metric                 VARCHAR(30) NOT NULL
);

-- Grain: one row per user assignment within a test
CREATE TABLE fact_assignments (
    assignment_id         INTEGER PRIMARY KEY,
    test_id                INTEGER NOT NULL REFERENCES dim_experiments(test_id),
    variant                VARCHAR(10) NOT NULL,   -- Control / Treatment
    device_type            VARCHAR(10) NOT NULL,   -- Mobile / Desktop
    user_type               VARCHAR(10) NOT NULL,   -- New / Returning
    assignment_date         DATE NOT NULL,
    days_elapsed_in_test     INTEGER NOT NULL,       -- how far into the test's run this user was assigned
    converted               INTEGER NOT NULL,        -- 1/0, primary metric outcome
    revenue                 DECIMAL(10,2) NOT NULL,
    guardrail_event         INTEGER NOT NULL         -- 1/0, e.g. refund/complaint -- secondary metric
);

CREATE INDEX idx_assign_test ON fact_assignments(test_id);
CREATE INDEX idx_assign_variant ON fact_assignments(test_id, variant);
CREATE INDEX idx_assign_device ON fact_assignments(test_id, device_type);
