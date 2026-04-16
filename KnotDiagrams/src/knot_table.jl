# SPDX-License-Identifier: PMPL-1.0-or-later
#
# Hardcoded Gauss codes for prime knots up to 7 crossings.
#
# Convention: signed Gauss code where +c = overcrossing at crossing c,
# -c = undercrossing at crossing c.  Each crossing label appears exactly
# once positive and once negative.
#
# Sources:
#   - 3_1, 4_1, 5_1: specified in project requirements
#   - Others: derived from Dowker-Thistlethwaite notation via
#     standard conversion (see `dt_to_gauss` below).
#
# DT notation reference (all prime knots up to 7 crossings):
#   3_1: [4, 6, 2]           5_1: [6, 8, 10, 2, 4]
#   4_1: [4, 6, 8, 2]        5_2: [4, 8, 10, 2, 6]
#   6_1: [4, 8, 12, 2, 10, 6]    6_2: [4, 8, 10, 12, 2, 6]
#   6_3: [4, 8, 10, 2, 12, 6]
#   7_1: [8, 10, 12, 14, 2, 4, 6]    7_2: [4, 10, 14, 12, 2, 8, 6]
#   7_3: [4, 10, 12, 14, 2, 6, 8]    7_4: [6, 10, 12, 14, 2, 4, 8]
#   7_5: [4, 8, 12, 2, 14, 6, 10]    7_6: [4, 8, 12, 14, 2, 10, 6]
#   7_7: [4, 8, 10, 14, 2, 12, 6]

"""
    dt_to_gauss(dt::Vector{Int}) -> Vector{Int}

Convert a Dowker-Thistlethwaite notation to a signed Gauss code.

In DT notation for an n-crossing knot, `dt[i]` is the even position
paired with odd position `2i - 1`.  If `dt[i] > 0`, the odd-numbered
encounter is the overcrossing; if `dt[i] < 0`, the even-numbered
encounter is the overcrossing.

Returns a signed Gauss code (1-indexed crossing labels).
"""
function dt_to_gauss(dt::Vector{Int})
    n = length(dt)

    # Build position → (crossing_label, is_over) map
    pos_to_crossing = Dict{Int, Tuple{Int, Bool}}()
    for i in 1:n
        odd_pos = 2i - 1
        even_pos = abs(dt[i])
        is_positive = dt[i] > 0

        # Crossing label = i
        # If dt[i] > 0: odd position is over, even is under
        # If dt[i] < 0: even position is over, odd is under
        pos_to_crossing[odd_pos] = (i, is_positive)       # odd: over if positive
        pos_to_crossing[even_pos] = (i, !is_positive)     # even: under if positive
    end

    # Traverse positions 1..2n and build signed Gauss code
    gauss = Vector{Int}(undef, 2n)
    for pos in 1:2n
        label, is_over = pos_to_crossing[pos]
        gauss[pos] = is_over ? label : -label
    end

    return gauss
end

"""
    prime_knots_up_to_7() -> Vector{KnotDiagram}

Return `KnotDiagram`s for all prime knots up to 7 crossings.
"""
function prime_knots_up_to_7()
    diagrams = KnotDiagram[]

    # --- 3 crossings ---
    push!(diagrams, KnotDiagram("3_1", 3, GaussCode([1, -2, 3, -1, 2, -3])))

    # --- 4 crossings ---
    push!(diagrams, KnotDiagram("4_1", 4, GaussCode([1, -2, 3, -4, 2, -1, 4, -3])))

    # --- 5 crossings ---
    push!(diagrams, KnotDiagram("5_1", 5, GaussCode([1, -2, 3, -4, 5, -1, 2, -3, 4, -5])))
    push!(diagrams, KnotDiagram("5_2", 5, GaussCode(dt_to_gauss([4, 8, 10, 2, 6]))))

    # --- 6 crossings ---
    push!(diagrams, KnotDiagram("6_1", 6, GaussCode(dt_to_gauss([4, 8, 12, 2, 10, 6]))))
    push!(diagrams, KnotDiagram("6_2", 6, GaussCode(dt_to_gauss([4, 8, 10, 12, 2, 6]))))
    push!(diagrams, KnotDiagram("6_3", 6, GaussCode(dt_to_gauss([4, 8, 10, 2, 12, 6]))))

    # --- 7 crossings ---
    push!(diagrams, KnotDiagram("7_1", 7, GaussCode(dt_to_gauss([8, 10, 12, 14, 2, 4, 6]))))
    push!(diagrams, KnotDiagram("7_2", 7, GaussCode(dt_to_gauss([4, 10, 14, 12, 2, 8, 6]))))
    push!(diagrams, KnotDiagram("7_3", 7, GaussCode(dt_to_gauss([4, 10, 12, 14, 2, 6, 8]))))
    push!(diagrams, KnotDiagram("7_4", 7, GaussCode(dt_to_gauss([6, 10, 12, 14, 2, 4, 8]))))
    push!(diagrams, KnotDiagram("7_5", 7, GaussCode(dt_to_gauss([4, 8, 12, 2, 14, 6, 10]))))
    push!(diagrams, KnotDiagram("7_6", 7, GaussCode(dt_to_gauss([4, 8, 12, 14, 2, 10, 6]))))
    push!(diagrams, KnotDiagram("7_7", 7, GaussCode(dt_to_gauss([4, 8, 10, 14, 2, 12, 6]))))

    return diagrams
end

"""
    torus_knot_gauss(q::Int) -> Vector{Int}

Generate a signed Gauss code for the torus knot T(2, q) where q is odd.
These follow a regular alternating pattern: the first q entries alternate
`+1, -2, +3, ...` and the second q entries alternate `-1, +2, -3, ...`.
"""
function torus_knot_gauss(q::Int)
    @assert isodd(q) && q >= 3 "q must be odd and >= 3"
    n = q  # number of crossings

    code = Vector{Int}(undef, 2n)
    # First half: 1, -2, 3, -4, ..., ±n
    for i in 1:n
        code[i] = iseven(i) ? -i : i
    end
    # Second half: -1, 2, -3, 4, ..., ∓n
    for i in 1:n
        code[n + i] = iseven(i) ? i : -i
    end

    return code
end
