# SPDX-License-Identifier: PMPL-1.0-or-later
#
# Compare fragment-count distributions across diagrams.

"""
    ComparisonResult

Result of comparing two knot diagrams with the same crossing number.
"""
struct ComparisonResult
    diagram_a::String
    diagram_b::String
    crossing_number::Int
    support_a::Vector{Int}
    support_b::Vector{Int}
    supports_differ::Bool
    histograms_differ::Bool
end

"""
    compare_pair(fd_a::FragmentDistribution, fd_b::FragmentDistribution) -> ComparisonResult

Compare the fragment-count distributions of two diagrams.
"""
function compare_pair(fd_a::FragmentDistribution, fd_b::FragmentDistribution)
    sa = fd_a.summary.support
    sb = fd_b.summary.support

    ComparisonResult(
        fd_a.diagram.name,
        fd_b.diagram.name,
        fd_a.diagram.crossing_number,
        sa, sb,
        sa != sb,
        fd_a.histogram != fd_b.histogram,
    )
end

"""
    compare_by_crossing_number(fds::AbstractVector{FragmentDistribution}) -> Vector{ComparisonResult}

Group diagrams by crossing number, then compare every pair within each group.
Returns a vector of `ComparisonResult` for all pairs.
"""
function compare_by_crossing_number(fds::AbstractVector{FragmentDistribution})
    # Group by crossing number
    groups = Dict{Int,Vector{FragmentDistribution}}()
    for fd in fds
        cn = fd.diagram.crossing_number
        push!(get!(Vector{FragmentDistribution}, groups, cn), fd)
    end

    results = ComparisonResult[]
    for cn in sort(collect(keys(groups)))
        group = groups[cn]
        for i in 1:length(group), j in (i+1):length(group)
            push!(results, compare_pair(group[i], group[j]))
        end
    end

    return results
end

"""
    comparison_table(results::Vector{ComparisonResult}) -> DataFrame

Build a comparison DataFrame.
"""
function comparison_table(results::Vector{ComparisonResult})
    rows = map(results) do r
        (
            diagram_a = r.diagram_a,
            diagram_b = r.diagram_b,
            crossing_number = r.crossing_number,
            support_a = string(r.support_a),
            support_b = string(r.support_b),
            supports_differ = r.supports_differ,
            histograms_differ = r.histograms_differ,
        )
    end
    return DataFrame(rows)
end

"""
    Base.show(io::IO, r::ComparisonResult)

Pretty-print a comparison result.
"""
function Base.show(io::IO, r::ComparisonResult)
    verdict = r.supports_differ ? "DIFFER" : "SAME"
    print(io, "$(r.diagram_a) vs $(r.diagram_b) [n=$(r.crossing_number)]: ")
    print(io, "support $(verdict)  ")
    print(io, "$(r.support_a) vs $(r.support_b)")
end
