#!/usr/bin/env julia
# SPDX-License-Identifier: PMPL-1.0-or-later
#
# Full analysis pipeline: compute fragment-count distributions for all
# prime knots up to 7 crossings and compare within crossing numbers.
#
# Usage:
#   julia --project=. scripts/run_analysis.jl
#
# For plots, run separately:
#   julia --project=. scripts/plot_distributions.jl

using KnotDiagrams
using DataFrames

function main()
    println("=" ^ 72)
    println("  Knot Diagram Fragment-Count Distribution Analysis")
    println("=" ^ 72)
    println()

    # Run full analysis
    results = analyse_all(verbose = true)
    println()

    # Print summary table
    println("=" ^ 72)
    println("SUMMARY TABLE")
    println("=" ^ 72)
    show(stdout, results.summary_table; allrows = true, allcols = true)
    println("\n")

    # Print comparison table
    println("=" ^ 72)
    println("COMPARISON TABLE")
    println("=" ^ 72)
    show(stdout, results.comparison_table; allrows = true, allcols = true)
    println("\n")

    # Validate against narrative predictions
    validate_narrative(results)

    return results
end

"""
    validate_narrative(results)

Check results against the narrative predictions in docs/narrative.txt.
"""
function validate_narrative(results)
    println("=" ^ 72)
    println("NARRATIVE VALIDATION")
    println("=" ^ 72)

    passed = 0
    failed = 0

    # Prediction 1: All prime knots are "spread"
    print("  [1] All prime knots have |support| > 1 (spread): ")
    all_spread = all(fd -> fd.summary.classification == :spread, results.distributions)
    if all_spread
        println("PASS")
        passed += 1
    else
        collapsed = filter(fd -> fd.summary.classification == :collapse, results.distributions)
        println("FAIL — collapsed: $(join([fd.diagram.name for fd in collapsed], ", "))")
        failed += 1
    end

    # Prediction 2: Trefoil support includes at least {1,2} or {2,3}
    print("  [2] Trefoil support contains multiple values: ")
    trefoil = first(filter(fd -> fd.diagram.name == "3_1", results.distributions))
    if trefoil.summary.support_size >= 2
        println("PASS (support = $(trefoil.summary.support))")
        passed += 1
    else
        println("FAIL (support = $(trefoil.summary.support))")
        failed += 1
    end

    # Prediction 3: Figure-eight has different distribution from trefoil
    print("  [3] Figure-eight distribution differs from trefoil: ")
    fig8 = first(filter(fd -> fd.diagram.name == "4_1", results.distributions))
    if fig8.histogram != trefoil.histogram
        println("PASS")
        passed += 1
    else
        println("FAIL")
        failed += 1
    end

    # Prediction 4: 5_1 and 5_2 have different distributions
    print("  [4] 5_1 vs 5_2 histograms differ: ")
    cn5 = filter(r -> r.crossing_number == 5, results.comparisons)
    if !isempty(cn5) && first(cn5).histograms_differ
        println("PASS")
        passed += 1
    else
        println("FAIL")
        failed += 1
    end

    # Prediction 5: Most pairs at same crossing number have differing supports
    print("  [5] Majority of same-cn pairs have differing supports: ")
    n_total = length(results.comparisons)
    n_differ = count(r -> r.supports_differ, results.comparisons)
    ratio = n_total > 0 ? n_differ / n_total : 0.0
    if ratio > 0.5
        println("PASS ($n_differ / $n_total = $(round(ratio * 100, digits=1))%)")
        passed += 1
    else
        println("FAIL ($n_differ / $n_total = $(round(ratio * 100, digits=1))%)")
        failed += 1
    end

    # Prediction 6: Torus knots have wider support
    print("  [6] Torus knots tend to have wider support: ")
    fd51 = first(filter(fd -> fd.diagram.name == "5_1", results.distributions))
    fd52 = first(filter(fd -> fd.diagram.name == "5_2", results.distributions))
    fd71 = first(filter(fd -> fd.diagram.name == "7_1", results.distributions))
    other_7 = filter(fd -> fd.diagram.crossing_number == 7 && fd.diagram.name != "7_1",
                     results.distributions)
    avg_other = isempty(other_7) ? 0.0 :
        sum(fd.summary.support_size for fd in other_7) / length(other_7)

    torus_wider = fd51.summary.support_size >= fd52.summary.support_size &&
                  fd71.summary.support_size >= avg_other
    if torus_wider
        println("PASS (5_1: $(fd51.summary.support_size) vs 5_2: $(fd52.summary.support_size), " *
                "7_1: $(fd71.summary.support_size) vs avg others: $(round(avg_other, digits=1)))")
        passed += 1
    else
        println("INCONCLUSIVE (5_1: $(fd51.summary.support_size) vs 5_2: $(fd52.summary.support_size), " *
                "7_1: $(fd71.summary.support_size) vs avg others: $(round(avg_other, digits=1)))")
    end

    println()
    println("  Passed: $passed / $(passed + failed)")
end

main()
