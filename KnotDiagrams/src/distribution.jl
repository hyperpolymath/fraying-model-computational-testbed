# SPDX-License-Identifier: MPL-2.0
#
# Fragment-count distribution L_D(k) and tropical summary.

"""
    fragment_distribution(diagram::KnotDiagram) -> FragmentDistribution

Compute the fragment-count distribution for a knot diagram.  This enumerates
all 2^n resolution states, counts the number of circles (fragments) in each
state, and builds a histogram mapping fragment count k to the number of states
that produce exactly k fragments.
"""
function fragment_distribution(diagram::KnotDiagram)
    states = enumerate_states(diagram.gauss_code)
    histogram = Dict{Int,Int}()

    for (_, circles) in states
        histogram[circles] = get(histogram, circles, 0) + 1
    end

    summary = tropical_summary(histogram)
    total = 1 << diagram.gauss_code.num_crossings

    return FragmentDistribution(diagram, histogram, total, summary)
end

"""
    tropical_summary(histogram::Dict{Int,Int}) -> TropicalSummary

Compute the tropical summary of a fragment-count histogram:
support, min, max, |support|, and classification (spread vs collapse).
"""
function tropical_summary(histogram::Dict{Int,Int})
    support = sort(collect(keys(histogram)))
    min_k = first(support)
    max_k = last(support)
    support_size = length(support)
    classification = support_size > 1 ? :spread : :collapse

    return TropicalSummary(support, min_k, max_k, support_size, classification)
end

"""
    Base.show(io::IO, fd::FragmentDistribution)

Pretty-print a fragment-count distribution.
"""
function Base.show(io::IO, fd::FragmentDistribution)
    println(io, "FragmentDistribution: $(fd.diagram.name)")
    println(io, "  Crossing number: $(fd.diagram.crossing_number)")
    println(io, "  Total states: $(fd.total_states)")
    println(io, "  Histogram (k => count):")
    for k in sort(collect(keys(fd.histogram)))
        println(io, "    k=$k : $(fd.histogram[k]) states")
    end
    s = fd.summary
    println(io, "  Tropical summary:")
    println(io, "    support    = $(s.support)")
    println(io, "    min(supp)  = $(s.min_k)")
    println(io, "    max(supp)  = $(s.max_k)")
    println(io, "    |support|  = $(s.support_size)")
    print(io,   "    class      = $(s.classification)")
end

"""
    distribution_table(fds::AbstractVector{FragmentDistribution}) -> DataFrame

Build a summary DataFrame from a collection of fragment distributions.
Requires DataFrames.jl.
"""
function distribution_table(fds::AbstractVector{FragmentDistribution})
    rows = map(fds) do fd
        s = fd.summary
        (
            name = fd.diagram.name,
            crossing_number = fd.diagram.crossing_number,
            total_states = fd.total_states,
            histogram = join(["$k=>$(fd.histogram[k])" for k in sort(collect(keys(fd.histogram)))], ", "),
            support = string(s.support),
            min_k = s.min_k,
            max_k = s.max_k,
            support_size = s.support_size,
            classification = string(s.classification),
        )
    end
    return DataFrame(rows)
end
