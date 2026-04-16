# SPDX-License-Identifier: PMPL-1.0-or-later
#
# Union-Find (Disjoint Set Union) data structure for counting connected
# components after smoothing a knot diagram. This is the same algorithmic
# core used by bracket_polynomial in Skein.jl/src/polynomials.jl.

"""
    UnionFind

Weighted union-find with path compression.
Tracks the number of distinct components for efficient fragment counting.
"""
mutable struct UnionFind
    parent::Vector{Int}
    rank::Vector{Int}
    num_components::Int
end

"""
    UnionFind(n::Int) -> UnionFind

Create a union-find structure with `n` elements (1-indexed), each in its own set.
"""
function UnionFind(n::Int)
    UnionFind(collect(1:n), zeros(Int, n), n)
end

"""
    find!(uf::UnionFind, x::Int) -> Int

Find the root representative of the set containing `x`, with path compression.
"""
function find!(uf::UnionFind, x::Int)
    while uf.parent[x] != x
        uf.parent[x] = uf.parent[uf.parent[x]]  # path halving
        x = uf.parent[x]
    end
    return x
end

"""
    uf_merge!(uf::UnionFind, x::Int, y::Int) -> Bool

Merge the sets containing `x` and `y`. Returns `true` if they were in
different sets (i.e., a merge actually occurred).

Named `uf_merge!` rather than `union!` to avoid shadowing `Base.union!`.
"""
function uf_merge!(uf::UnionFind, x::Int, y::Int)
    rx = find!(uf, x)
    ry = find!(uf, y)
    rx == ry && return false
    if uf.rank[rx] < uf.rank[ry]
        uf.parent[rx] = ry
    elseif uf.rank[rx] > uf.rank[ry]
        uf.parent[ry] = rx
    else
        uf.parent[ry] = rx
        uf.rank[rx] += 1
    end
    uf.num_components -= 1
    return true
end

"""
    num_components(uf::UnionFind) -> Int

Return the current number of disjoint sets.
"""
num_components(uf::UnionFind) = uf.num_components
