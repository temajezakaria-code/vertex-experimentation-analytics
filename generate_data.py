"""
Vertex Commerce — A/B Testing Portfolio Data Generator
==================================================================
Business scenario: Vertex Commerce, a mid-large online retailer, runs dozens
of A/B tests per quarter (checkout, pricing, onboarding, search, email,
recommendations) but leadership has no consolidated view of experiment
quality or true business impact. Real multi-test, user-level experiment data
of this kind is never published by companies — this generator builds 30
experiments with programmed TRUE underlying effects (including deliberately
embedded pitfalls: underpowered tests, true nulls, novelty decay, Simpson's
paradox, guardrail regressions) so the statistical analysis has genuine,
verifiable signal to uncover — not just narrated findings.
"""
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
import random

random.seed(42)
np.random.seed(42)

OUT_DIR = "/home/claude/vertex-experimentation/data"

categories = ["Checkout", "Onboarding", "Pricing", "Email", "Search", "Recommendations"]

# ---------------------------------------------------------------------------
# Design 30 experiments with EXPLICIT programmed ground truth.
# true_lift: the real underlying relative lift in conversion rate (0 = true null)
# n_per_variant: planned sample size per variant (small = underpowered)
# pattern: tags the deliberate pitfall category (kept as ground truth metadata,
#          analysis re-derives findings statistically, doesn't just read this)
# ---------------------------------------------------------------------------
experiment_specs = [
    # Genuine, adequately-powered positive wins (8)
    {"name": "One-Click Checkout Button",       "cat": "Checkout",      "true_lift": 0.07, "n": 8000,  "pattern": "true_win"},
    {"name": "Simplified Shipping Form",         "cat": "Checkout",      "true_lift": 0.05, "n": 9000,  "pattern": "true_win"},
    {"name": "Progress Bar in Checkout",         "cat": "Checkout",      "true_lift": 0.04, "n": 8500,  "pattern": "true_win"},
    {"name": "Welcome Email Redesign",           "cat": "Email",         "true_lift": 0.06, "n": 7500,  "pattern": "true_win"},
    {"name": "Personalized Product Recs",        "cat": "Recommendations","true_lift": 0.08, "n": 9500,  "pattern": "true_win"},
    {"name": "Autocomplete Search Suggestions",  "cat": "Search",        "true_lift": 0.05, "n": 8800,  "pattern": "true_win"},
    {"name": "Simplified Onboarding Flow",       "cat": "Onboarding",    "true_lift": 0.09, "n": 7000,  "pattern": "true_win"},
    {"name": "Free Shipping Threshold Banner",   "cat": "Pricing",       "true_lift": 0.06, "n": 8200,  "pattern": "true_win"},
    # True nulls -- no real effect (6), included to test portfolio false-positive rate
    {"name": "New Font in Product Pages",        "cat": "Onboarding",    "true_lift": 0.0,  "n": 8000,  "pattern": "true_null"},
    {"name": "Header Color Change",              "cat": "Search",       "true_lift": 0.0,  "n": 8500,  "pattern": "true_null"},
    {"name": "Reordered Footer Links",            "cat": "Checkout",     "true_lift": 0.0,  "n": 7800,  "pattern": "true_null"},
    {"name": "New Loading Animation",             "cat": "Onboarding",   "true_lift": 0.0,  "n": 8100,  "pattern": "true_null"},
    {"name": "Alternate Email Subject Line",      "cat": "Email",        "true_lift": 0.0,  "n": 7600,  "pattern": "true_null"},
    {"name": "Sidebar Widget Placement",          "cat": "Search",       "true_lift": 0.0,  "n": 8300,  "pattern": "true_null"},
    # Underpowered tests -- real effect exists but sample too small to detect reliably (4)
    {"name": "Guest Checkout Option",             "cat": "Checkout",     "true_lift": 0.05, "n": 700,   "pattern": "underpowered"},
    {"name": "Micro-Copy Tweaks on CTA",           "cat": "Onboarding",   "true_lift": 0.04, "n": 600,   "pattern": "underpowered"},
    {"name": "New Payment Method (Buy Now Pay Later)","cat": "Checkout", "true_lift": 0.06, "n": 800,   "pattern": "underpowered"},
    {"name": "Localized Pricing Display",         "cat": "Pricing",      "true_lift": 0.05, "n": 650,   "pattern": "underpowered"},
    # Novelty effect -- early lift decays over the test (2)
    {"name": "Gamified Loyalty Badge",             "cat": "Onboarding",   "true_lift": 0.10, "n": 8000,  "pattern": "novelty_decay"},
    {"name": "Animated Add-to-Cart Confetti",      "cat": "Checkout",     "true_lift": 0.08, "n": 8000,  "pattern": "novelty_decay"},
    # Simpson's paradox -- aggregate direction reverses within a segment (2)
    {"name": "Mobile-First Redesign",              "cat": "Onboarding",   "true_lift": 0.06, "n": 9000,  "pattern": "simpsons_paradox"},
    {"name": "New Search Ranking Algorithm",       "cat": "Search",       "true_lift": 0.05, "n": 9200,  "pattern": "simpsons_paradox"},
    # Guardrail regression -- primary metric wins, a guardrail metric worsens (2)
    {"name": "Aggressive Upsell Prompt",           "cat": "Pricing",      "true_lift": 0.07, "n": 8500,  "pattern": "guardrail_regression"},
    {"name": "One-Page Express Checkout",          "cat": "Checkout",     "true_lift": 0.06, "n": 8700,  "pattern": "guardrail_regression"},
    # Additional standard portfolio volume (6)
    {"name": "New Homepage Hero Banner",           "cat": "Onboarding",   "true_lift": 0.03, "n": 8000,  "pattern": "true_win"},
    {"name": "Cart Abandonment Email Timing",      "cat": "Email",        "true_lift": 0.04, "n": 7900,  "pattern": "true_win"},
    {"name": "Bundle Discount Display",            "cat": "Pricing",      "true_lift": 0.0,  "n": 8000,  "pattern": "true_null"},
    {"name": "Voice Search Beta",                  "cat": "Search",       "true_lift": 0.02, "n": 8100,  "pattern": "true_win"},
    {"name": "Category Filter Redesign",           "cat": "Search",       "true_lift": 0.0,  "n": 7700,  "pattern": "true_null"},
    {"name": "Referral Incentive Banner",          "cat": "Recommendations","true_lift": 0.05,"n": 8300,  "pattern": "true_win"},
]

BASE_CONVERSION_RATE = 0.12  # control-group baseline conversion rate
BASE_GUARDRAIL_RATE = 0.03   # baseline "bad outcome" rate (e.g., refund/complaint)
AVG_ORDER_VALUE = 68.0

start_pool = pd.date_range("2024-01-01", "2025-10-01", freq="W-MON")

dim_rows = []
fact_rows = []
assignment_id = 1

for i, spec in enumerate(experiment_specs):
    test_id = i + 1
    start_date = random.choice(list(start_pool))
    duration_weeks = random.choice([3, 4, 4, 5, 6]) if spec["pattern"] != "novelty_decay" else 4
    end_date = start_date + timedelta(weeks=duration_weeks)

    dim_rows.append({
        "test_id": test_id, "test_name": spec["name"], "category": spec["cat"],
        "start_date": start_date.date().isoformat(), "end_date": end_date.date().isoformat(),
        "planned_sample_size_per_variant": spec["n"], "primary_metric": "conversion_rate",
        "guardrail_metric": "refund_or_complaint_rate",
    })

    n = spec["n"]
    true_lift = spec["true_lift"]
    pattern = spec["pattern"]

    for variant in ["Control", "Treatment"]:
        for _ in range(n):
            device = np.random.choice(["Mobile", "Desktop"], p=[0.62, 0.38])
            user_type = np.random.choice(["New", "Returning"], p=[0.45, 0.55])
            assign_date = start_date + timedelta(days=random.randint(0, duration_weeks*7 - 1))
            days_since_assignment = (end_date - assign_date).days

            # Base conversion probability, with segment adjustments
            p_convert = BASE_CONVERSION_RATE * (1.08 if user_type == "Returning" else 0.92)

            effective_lift = true_lift
            # Simpson's paradox: effect is POSITIVE for Desktop but NEGATIVE for Mobile,
            # and Mobile is the majority segment in the sample -- yet Desktop's larger
            # per-user effect size dominates the aggregate direction
            if pattern == "simpsons_paradox" and variant == "Treatment":
                if device == "Mobile":
                    effective_lift = -0.03
                else:
                    effective_lift = true_lift + 0.14

            # Novelty decay: lift is large in week 1, fades to ~0 by the test's end
            if pattern == "novelty_decay" and variant == "Treatment":
                week_number = days_since_assignment // 7
                decay_factor = max(0.0, 1 - (duration_weeks - week_number) * 0.35)
                effective_lift = true_lift * (1 - decay_factor) if False else true_lift * max(0.05, 1 - ( (duration_weeks*7 - days_since_assignment) / (duration_weeks*7) ) * 0)
                # Simpler correct formulation: lift strong early (small days_since_assignment
                # means assigned near test end = less elapsed time = less decay); use elapsed
                # time since assignment (test_duration - days_since_assignment) to drive decay
                elapsed = duration_weeks*7 - days_since_assignment
                effective_lift = true_lift * np.exp(-elapsed / 10.0)

            p_convert_variant = p_convert * (1 + effective_lift) if variant == "Treatment" else p_convert
            converted = np.random.random() < np.clip(p_convert_variant, 0, 1)

            revenue = round(np.random.gamma(2, AVG_ORDER_VALUE/2), 2) if converted else 0.0

            # Guardrail outcome (e.g. refund/complaint) -- elevated for guardrail_regression pattern in Treatment
            guardrail_rate = BASE_GUARDRAIL_RATE
            if pattern == "guardrail_regression" and variant == "Treatment":
                guardrail_rate = BASE_GUARDRAIL_RATE * 2.1
            guardrail_event = int(np.random.random() < guardrail_rate)

            fact_rows.append({
                "assignment_id": assignment_id, "test_id": test_id, "variant": variant,
                "device_type": device, "user_type": user_type,
                "assignment_date": assign_date.date().isoformat(),
                "days_elapsed_in_test": duration_weeks*7 - days_since_assignment,
                "converted": int(converted), "revenue": revenue, "guardrail_event": guardrail_event,
            })
            assignment_id += 1

dim_experiments = pd.DataFrame(dim_rows)
fact_assignments = pd.DataFrame(fact_rows)

dim_experiments.to_csv(f"{OUT_DIR}/dim_experiments.csv", index=False)
fact_assignments.to_csv(f"{OUT_DIR}/fact_assignments.csv", index=False)

print(f"Experiments: {len(dim_experiments)}")
print(f"Total user assignments: {len(fact_assignments):,}")
