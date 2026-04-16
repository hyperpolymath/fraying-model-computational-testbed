# SPDX-License-Identifier: PMPL-1.0-or-later
#
# Core types for knot diagram analysis.

"""
    Crossing

A crossing in a knot diagram, identified by its two positions in the
Gauss code: `over_pos` (where the strand passes over) and `under_pos`
(where it passes under). Positions are 1-indexed.
"""
struct Crossing
    label::Int
    over_pos::Int
    under_pos::Int
end

"""
    GaussCode

A signed Gauss code representation of a knot diagram.

Convention: the code is a vector of signed integers. Positive `+c` means
the strand passes **over** crossing `c`; negative `-c` means it passes
**under** crossing `c`. Each crossing label appears exactly twice — once
positive, once negative.

# Examples
```julia
trefoil = GaussCode([1, -2, 3, -1, 2, -3])
figure_eight = GaussCode([1, -2, 3, -4, 2, -1, 4, -3])
```
"""
struct GaussCode
    code::Vector{Int}
    crossings::Vector{Crossing}
    num_crossings::Int
    num_arcs::Int

    function GaussCode(code::Vector{Int})
        n = length(code)
        @assert iseven(n) "Gauss code must have even length"

        num_crossings = n ÷ 2
        labels = sort(unique(abs.(code)))
        @assert length(labels) == num_crossings "Each crossing must appear exactly twice"
        @assert labels == collect(1:num_crossings) "Crossing labels must be 1:n"

        # Find over/under positions for each crossing
        over_pos = zeros(Int, num_crossings)
        under_pos = zeros(Int, num_crossings)

        for (pos, val) in enumerate(code)
            c = abs(val)
            if val > 0
                @assert over_pos[c] == 0 "Crossing $c has two overcrossings"
                over_pos[c] = pos
            else
                @assert under_pos[c] == 0 "Crossing $c has two undercrossings"
                under_pos[c] = pos
            end
        end

        crossings = [Crossing(c, over_pos[c], under_pos[c]) for c in 1:num_crossings]

        for cr in crossings
            @assert cr.over_pos != 0 && cr.under_pos != 0 "Crossing $(cr.label) missing over or under"
        end

        new(code, crossings, num_crossings, n)
    end
end

"""
    KnotDiagram

A named knot diagram with its Gauss code and crossing number.
"""
struct KnotDiagram
    name::String
    crossing_number::Int
    gauss_code::GaussCode
end

"""
    TropicalSummary

Summary statistics for a fragment-count distribution.
"""
struct TropicalSummary
    support::Vector{Int}
    min_k::Int
    max_k::Int
    support_size::Int
    classification::Symbol  # :spread or :collapse
end

"""
    FragmentDistribution

The fragment-count distribution L_D(k) for a knot diagram: a histogram
mapping fragment count k to the number of states producing k fragments.
"""
struct FragmentDistribution
    diagram::KnotDiagram
    histogram::Dict{Int,Int}     # k => count of states with k fragments
    total_states::Int
    summary::TropicalSummary
end
