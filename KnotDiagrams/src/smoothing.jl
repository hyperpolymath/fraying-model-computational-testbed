# SPDX-License-Identifier: PMPL-1.0-or-later
#
# State enumeration and circle counting via smoothing.
#
# For an n-crossing diagram there are 2^n "resolution states", one per
# binary choice at each crossing.  At crossing c (over-strand at position
# p, under-strand at position q in the Gauss code):
#
#   Smoothing 0 — pair incoming-over with outgoing-under and vice-versa:
#       union(arc[p-1], arc[q])   and   union(arc[q-1], arc[p])
#
#   Smoothing 1 — pair incoming-over with incoming-under and outgoing-over
#       with outgoing-under:
#       union(arc[p-1], arc[q-1]) and   union(arc[p], arc[q])
#
# Arc indexing: for a Gauss code of length 2n there are 2n arcs.  Arc i
# (1-indexed) is the strand segment from position i to position i+1
# (wrapping around: arc 2n goes from position 2n back to position 1).

"""
    count_circles(gc::GaussCode, state::UInt) -> Int

Given a `GaussCode` and a resolution state (an unsigned integer whose
i-th bit selects smoothing 0 or 1 at crossing i), return the number
of disjoint circles in the fully-smoothed diagram.
"""
function count_circles(gc::GaussCode, state::UInt)
    m = gc.num_arcs  # = 2n
    uf = UnionFind(m)

    for crossing in gc.crossings
        p = crossing.over_pos
        q = crossing.under_pos

        # Arc indices (1-indexed, wrapping)
        arc_before_p = mod1(p - 1, m)  # arc entering position p
        arc_after_p  = p                # arc leaving position p  (= arc index p)
        arc_before_q = mod1(q - 1, m)
        arc_after_q  = q

        bit = (state >> (crossing.label - 1)) & 1
        if bit == 0
            # Smoothing 0: cross-connect
            uf_merge!(uf, arc_before_p, arc_after_q)
            uf_merge!(uf, arc_before_q, arc_after_p)
        else
            # Smoothing 1: parallel-connect
            uf_merge!(uf, arc_before_p, arc_before_q)
            uf_merge!(uf, arc_after_p, arc_after_q)
        end
    end

    return num_components(uf)
end

"""
    enumerate_states(gc::GaussCode) -> Vector{Tuple{UInt, Int}}

Enumerate all 2^n resolution states for the given Gauss code.
Returns a vector of `(state, num_circles)` pairs.
"""
function enumerate_states(gc::GaussCode)
    n = gc.num_crossings
    total = 1 << n  # 2^n
    results = Vector{Tuple{UInt,Int}}(undef, total)

    for s in UInt(0):UInt(total - 1)
        circles = count_circles(gc, s)
        results[s + 1] = (s, circles)
    end

    return results
end
