# Vertex Commerce — Experimentation Program Insights & Recommendations

All figures below are pulled directly from the SQL analysis and Python notebooks in
this repository (30 experiments, 433,900 user assignments, 2024-2025). This project
uses fictional data with programmed ground truth — every statistical claim below was
verified against a known, true underlying effect, not just observed and assumed.

---

## 15 Executive Insights

1. **Every single test in the portfolio — 30 of 30 — was statistically underpowered**
   to reliably detect a 5% relative lift, even tests with 7,000-9,500 users per arm
   that would look "adequately sized" at a glance. This is the single most important
   finding in this analysis.
2. **Only 3 of 30 tests (10%) reached statistical significance** — consistent with,
   and largely explained by, the severe underpowering above.
3. **Data quality is clean**: a sample ratio mismatch (SRM) check across all 30 tests
   found zero randomization issues — the testing infrastructure itself is not the
   problem.
4. **2 of 30 tests showed a primary-metric win paired with a guardrail-metric
   regression** — both roughly doubled the refund/complaint rate, and both would have
   shipped as "wins" under a primary-metric-only review process.
5. **The single largest revenue-lift-per-user result in the portfolio ($2.27) came
   from a test that was NOT statistically significant** (n=600 per arm) — exactly the
   kind of promising-but-underpowered result a primary-metric-only review would
   discard as "inconclusive."
6. **Win rates vary sharply by category**: Pricing (25%), Search (16.7%), and
   Onboarding (14.3%) show real wins; Recommendations, Email, and Checkout show zero
   significant wins in this period.
7. **2 tests showed an aggregate "win" driven entirely by one segment** (Desktop),
   with the majority segment (Mobile, ~62% of traffic) showing no significant effect
   at all (p=0.48 and p=0.44 respectively) — an aggregate result that doesn't
   represent what most users experienced.
8. **2 tests showed a novelty effect** — an elevated early lift that faded toward (or
   below) the control rate by the test's later weeks, visible once a proper trend
   curve was fit instead of a coarse before/after comparison.
9. **Sample sizes across the portfolio ranged from 600 to 9,500 per arm** (median
   8,000) — a nearly 16x spread, with no apparent standardized minimum.
10. **The portfolio's overall p-value distribution (10% below 0.05) is modestly above
    the ~5% expected under pure chance alone** — consistent with a mix of some real
    effects and many true nulls, not a red flag for the testing methodology itself.
11. **Checkout category ran the most tests (8) of any category but produced zero
    significant wins** — either checkout is already well-optimized, or checkout
    tests specifically need larger samples given how costly checkout drop-off is.
12. **The 4 deliberately smallest-sample tests (600-800 users per arm) all carried
    real, programmed effects that went undetected** — a direct, quantified
    illustration of the cost of underpowering.
13. **Both guardrail-regression tests were in different categories (Pricing,
    Checkout)** — suggesting this isn't a category-specific risk but a general
    review-process gap (checking only the primary metric).
14. **No test showed BOTH a significant primary-metric win AND a guardrail
    regression that was individually significant** — the guardrail issues were only
    caught by deliberately checking the guardrail metric, not because they were
    otherwise obvious.
15. **The single most statistically strong result in the portfolio (Free Shipping
    Threshold Banner, z=2.58) also ranks in the top 5 for revenue lift** — a rare case
    where statistical and business significance clearly align, and the clearest
    "ship immediately" candidate in the portfolio.

---

## 10 Operational Risks

1. **Systemic underpowering risks a false "nothing works" narrative** — if most
   tests can't detect real effects, leadership may wrongly conclude the
   experimentation program itself isn't generating value, when the sample sizing is
   the actual problem.
2. **Shipping decisions based on primary-metric-only review risk repeating the 2
   guardrail-regression cases** found here, at a larger scale, if the review process
   doesn't change.
3. **High-potential but underpowered results (like the $2.27/user finding) risk
    being permanently discarded** as "no effect" rather than flagged for re-testing.
4. **The zero-win-rate categories (Recommendations, Email, Checkout) risk being
    deprioritized for future testing budget** even though the real issue may be
    under-sized samples, not bad ideas.
5. **Segment-level heterogeneity, if unchecked, risks shipping features that
    provide zero benefit — or even harm — to the majority Mobile user base** while
    looking like a clean aggregate win.
6. **Novelty-effect-driven "wins," if shipped without decay-awareness, risk
    disappointing post-launch performance** relative to the test-period numbers used
    to justify the launch.
7. **Without a standardized minimum sample size, future tests risk repeating the
    same underpowering problem** indefinitely, rather than it being a one-time,
    fixable issue.
8. **The lack of a formal guardrail-check step in the apparent review process is a
    repeatable risk**, not a one-time miss, until it's built into the standard test
    evaluation template.
9. **Checkout's zero significant wins across 8 tests, combined with a guardrail
    regression also occurring in Checkout, suggests this may be the highest-risk
    category** for shipping changes without rigorous review.
10. **Relying on informal sample-size heuristics** (e.g., "a few thousand users
    feels like enough") **instead of a formal power calculation is itself the root
    risk** behind most of the findings above.

---

## 15 Strategic Recommendations

1. **Establish a mandatory minimum sample size, based on formal power calculations
   for the actual baseline conversion rate and typical hypothesized lift** — not an
   intuition-based number.
2. **Re-test the 4 identified underpowered tests with adequately-sized samples**
   before concluding their underlying ideas don't work.
3. **Add a mandatory guardrail-metric check to the standard test evaluation
   template**, so a primary-metric win can never ship without a secondary-metric
   review.
4. **Re-test the "Micro-Copy Tweaks on CTA" result specifically** ($2.27/user
   revenue lift, but underpowered) — the single highest-potential, most
   under-examined result in the portfolio.
5. **Segment every test result by device type as standard practice**, not just when
   something looks unusual — the 2 heterogeneity cases here were only found because
   this was checked deliberately.
6. **Run experiments for a minimum duration long enough to distinguish a durable
   lift from a novelty effect** — both flagged tests here ran only 4 weeks.
7. **Prioritize future testing budget toward Pricing and Search** (the two highest
   win-rate categories), while re-examining whether Checkout and Email tests are
   underpowered rather than simply deprioritizing them.
8. **Ship the Free Shipping Threshold Banner result immediately** — the clearest
   case in the portfolio where statistical and business significance both clearly
   support it.
9. **Do not ship the Aggressive Upsell Prompt or One-Page Express Checkout changes**
   as currently designed, given their guardrail regressions, without a redesign that
   addresses the underlying complaint/refund driver.
10. **Build the sample-ratio-mismatch (SRM) check into the standard experimentation
    pipeline** as an automated pre-analysis gate, not a one-time manual audit like
    the one performed here.
11. **Communicate the "30 of 30 underpowered" finding directly to whoever owns the
    testing program's standard operating procedure** — this is a process fix, not an
    individual-test fix.
12. **Build a simple internal power-calculator tool** so anyone launching a new test
    can check their planned sample size against the actual required size before
    launch, not after.
13. **Track win rate by category over time** as a standing metric, to see whether
    the Pricing/Search advantage persists as sample sizes are corrected.
14. **Re-evaluate whether the "10% significant" portfolio result is actually healthy**
    once sample sizes are fixed — this baseline number should improve if
    underpowering, not bad ideas, was the primary constraint.
15. **Treat Recommendations 1-4 as the single highest-priority initiative** — fixing
    sample sizing addresses the root cause behind more than half of this report's
    other findings.

---

## 10 Quick Wins (Low Cost / Fast to Implement)

1. Share the "30 of 30 underpowered" finding in the next experimentation program
   review meeting — it reframes the entire portfolio's narrative on its own.
2. Flag the 2 guardrail-regression tests to whoever owns them for an immediate
   design review, before any further rollout consideration.
3. Add "re-test with larger sample" as a formal disposition category (distinct from
   "no effect") in the test-tracking system.
4. Publish the category win-rate ranking to help the next quarter's test-planning
   prioritization conversation.
5. Ship the Free Shipping Threshold Banner change — no further testing needed given
   its strong result.
6. Add a single guardrail-metric column to the standard test results reporting
   template as an immediate, low-effort process fix.
7. Build a simple sample-size lookup table (using this project's power analysis
   method) for the 3-4 most common baseline conversion rates the team tests against.
8. Flag the Micro-Copy Tweaks test for a re-test slot in the next testing cycle.
9. Add device-type segmentation as a default column in the standard test results
   dashboard.
10. Circulate the p-value distribution chart internally as a simple visual proof
    point for why sample sizing needs attention.

---

## 10 Long-Term Improvement Opportunities

1. Build a proper sequential-testing framework (e.g., using alpha-spending
   functions) to allow valid early stopping without inflating false-positive rates —
   this project intentionally used a fixed-horizon design and flagged the "peeking"
   problem conceptually rather than solving it, since that requires infrastructure
   changes.
2. Develop an internal experimentation platform that automatically runs power
   calculations at test-design time, blocking underpowered tests before launch.
3. Build a standardized guardrail-metric library (refunds, complaints, support
   tickets, unsubscribes) that every test is automatically checked against.
4. Develop a formal novelty-effect monitoring dashboard that tracks lift trend
   within a test's run automatically, rather than requiring a manual notebook
   analysis after the fact.
5. Build a segment-heterogeneity auto-check into the standard results pipeline for
   every test, not just ones that look unusual on inspection.
6. Establish a quarterly experimentation program health review, using this
   analysis's framework (power, guardrails, segments, novelty) as a standing
   template.
7. Invest in increasing overall traffic/sample availability for high-priority test
   slots, since sample size is now a demonstrated, quantified constraint.
8. Build a meta-analysis capability that periodically re-examines the whole
   portfolio's p-value distribution as a health check on the testing program itself.
9. Create a lightweight internal training on statistical power for whoever designs
   tests, given how widespread the underpowering issue turned out to be.
10. Revisit this entire analysis in a future quarter once sample sizes are
    corrected, to measure whether the "10% significant" baseline actually improves.

---

## Critical Assessment & Next Steps

An experimentation analysis that stops at "here's the dashboard" isn't finished —
here's what I'd flag before this reaches a program review, and what I'd do
differently with more time or access.

**Limitations of this analysis:**
- **This dataset is entirely synthetic**, with every experiment's true effect
  programmed in advance so statistical findings could be verified against known
  ground truth. Real companies never publish raw multi-test experiment data, so this
  is the only way to build a portfolio project with verifiable statistical rigor
  rather than narrated claims.
- **This project used a fixed-horizon testing design and did not implement
  sequential testing correction.** The well-known "peeking problem" (stopping a test
  early when it looks significant, which inflates the true false-positive rate) is
  discussed conceptually in this project's framing but not directly simulated or
  corrected for — a genuine limitation, not an oversight to hide.
- **Two of the embedded pitfall patterns (novelty decay, segment heterogeneity) were
  generated with some natural randomness that made one instance of each cleaner than
  the other** (e.g., one heterogeneity test showed a clean reversal, the other showed
  a flatter, non-significant Mobile effect rather than a literal sign flip). This was
  reported honestly rather than adjusted to look more dramatic than the data
  actually supports.
- **No multiple-comparisons correction was applied across the 30-test portfolio.**
  With 30 tests at alpha=0.05, roughly 1-2 significant results could occur by chance
  alone even under a fully-null portfolio — the 3 significant results found here are
  only modestly above that chance baseline, a nuance worth stating rather than
  treating "3 wins" as unambiguously meaningful.

**What I'd do with more time or access:**
- Implement a proper sequential testing framework (e.g., mSPRT or alpha-spending)
  to allow valid early stopping, rather than only flagging the peeking problem
  conceptually.
- Apply a formal multiple-comparisons correction (e.g., Benjamini-Hochberg FDR
  control) across the portfolio's 30 simultaneous tests before treating any single
  result as fully conclusive.
- Build the guardrail and segment-heterogeneity checks into an automated pipeline
  rather than a one-time manual notebook analysis, so future tests are checked by
  default.
- Re-run this entire analysis on a corrected-sample-size version of the portfolio to
  quantify exactly how much the "10% significant" figure improves once the
  underpowering issue identified here is fixed.

I'd rather flag these gaps — including the ones in how I built and analyzed the
data — than let a clean set of dashboards imply more statistical certainty than a
first analytical pass, even a rigorous one, can fully support.
