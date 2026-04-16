# SPDX-License-Identifier: PMPL-1.0-or-later
"""
    KnotDiagrams

Compute fragment-count distributions L_D(k) for knot diagrams represented
as signed Gauss codes.

For an n-crossing diagram, the package enumerates all 2^n global resolution
states (one binary smoothing choice per crossing), counts the resulting
closed-curve fragments via union-find, and builds a histogram mapping
fragment count k to the number of states producing k fragments.

Tropical summaries (support, min, max, spread vs. collapse) and pairwise
comparisons across diagrams with the same crossing number are provided to
test whether topology predicts the fragment-count distribution.

# Quick start
```julia
using KnotDiagrams

# Analyse all prime knots up to 7 crossings
results = analyse_all()

# Single diagram
trefoil = KnotDiagram("3_1", 3, GaussCode([1, -2, 3, -1, 2, -3]))
fd = fragment_distribution(trefoil)
println(fd)
```
"""
module KnotDiagrams

using DataFrames

include("union_find.jl")
include("types.jl")
include("smoothing.jl")
include("distribution.jl")
include("comparison.jl")
include("knot_table.jl")

# --- Public API ---

export GaussCode, KnotDiagram, Crossing
export FragmentDistribution, TropicalSummary, ComparisonResult
export UnionFind, find!, uf_merge!, num_components
export count_circles, enumerate_states
export fragment_distribution, tropical_summary
export distribution_table
export compare_pair, compare_by_crossing_number, comparison_table
export prime_knots_up_to_7, torus_knot_gauss, dt_to_gauss
export analyse_all

"""
    analyse_all(; verbose::Bool = true) -> NamedTuple

Run the full analysis pipeline on all prime knots up to 7 crossings:
1. Compute fragment-count distributions
2. Build summary table
3. Compare pairs within each crossing number
4. Return all results

Returns a `NamedTuple` with fields:
- `diagrams`: the KnotDiagram vector
- `distributions`: the FragmentDistribution vector
- `summary_table`: DataFrame of per-diagram summaries
- `comparisons`: vector of ComparisonResult
- `comparison_table`: DataFrame of pairwise comparisons
"""
function analyse_all(; verbose::Bool = true)
    diagrams = prime_knots_up_to_7()

    verbose && println("Computing fragment-count distributions for $(length(diagrams)) diagrams...")
    distributions = [fragment_distribution(d) for d in diagrams]

    if verbose
        println()
        for fd in distributions
            println(fd)
            println()
        end
    end

    summary_df = distribution_table(distributions)
    comparisons = compare_by_crossing_number(distributions)
    comparison_df = comparison_table(comparisons)

    if verbose
        println("=" ^ 72)
        println("PAIRWISE COMPARISONS (same crossing number)")
        println("=" ^ 72)
        for r in comparisons
            println("  ", r)
        end
        println()

        n_pairs = length(comparisons)
        n_differ_support = count(r -> r.supports_differ, comparisons)
        n_differ_hist = count(r -> r.histograms_differ, comparisons)
        println("Total pairs compared: $n_pairs")
        println("Pairs with differing supports: $n_differ_support / $n_pairs")
        println("Pairs with differing histograms: $n_differ_hist / $n_pairs")
    end

    return (
        diagrams = diagrams,
        distributions = distributions,
        summary_table = summary_df,
        comparisons = comparisons,
        comparison_table = comparison_df,
    )
end

end # module KnotDiagrams
