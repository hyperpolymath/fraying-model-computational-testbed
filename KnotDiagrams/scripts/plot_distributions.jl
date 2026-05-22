#!/usr/bin/env julia
# SPDX-License-Identifier: MPL-2.0
#
# Generate histogram plots for fragment-count distributions.
# Requires CairoMakie.
#
# Usage:
#   julia --project=. scripts/plot_distributions.jl

using KnotDiagrams
using CairoMakie

function plot_all(fds::AbstractVector{FragmentDistribution};
                  output_dir::String = joinpath(@__DIR__, "..", "plots"))
    mkpath(output_dir)

    # Group by crossing number
    groups = Dict{Int,Vector{FragmentDistribution}}()
    for fd in fds
        cn = fd.diagram.crossing_number
        push!(get!(Vector{FragmentDistribution}, groups, cn), fd)
    end

    # Per-crossing-number overlaid histograms
    for cn in sort(collect(keys(groups)))
        group = groups[cn]
        plot_group(group, cn, output_dir)
    end

    # Per-diagram individual plots
    for fd in fds
        plot_single(fd, output_dir)
    end

    n_group = length(groups)
    n_single = length(fds)
    println("Saved $(n_group + n_single) plots to $output_dir")
end

function plot_group(group::Vector{FragmentDistribution}, cn::Int, output_dir::String)
    all_k = Set{Int}()
    for fd in group
        union!(all_k, keys(fd.histogram))
    end
    k_range = minimum(all_k):maximum(all_k)

    fig = Figure(size = (800, 500))
    ax = Axis(fig[1, 1],
        title = "Fragment-count distribution — $(cn)-crossing knots",
        xlabel = "Fragment count k",
        ylabel = "Number of states",
        xticks = collect(k_range),
    )

    n_diagrams = length(group)
    bar_width = 0.8 / n_diagrams
    offsets = range(-0.4 + bar_width / 2, step = bar_width, length = n_diagrams)

    for (i, fd) in enumerate(group)
        ks = collect(k_range)
        counts = [get(fd.histogram, k, 0) for k in ks]
        barplot!(ax, ks .+ offsets[i], counts,
            width = bar_width,
            label = fd.diagram.name,
            color = Cycled(i),
        )
    end

    axislegend(ax, position = :rt)
    save(joinpath(output_dir, "distribution_n$(cn).png"), fig, px_per_unit = 2)
end

function plot_single(fd::FragmentDistribution, output_dir::String)
    k_range = fd.summary.min_k:fd.summary.max_k
    ks = collect(k_range)
    counts = [get(fd.histogram, k, 0) for k in ks]

    fig = Figure(size = (600, 400))
    ax = Axis(fig[1, 1],
        title = "L_D(k) — $(fd.diagram.name)",
        xlabel = "Fragment count k",
        ylabel = "Number of states",
        xticks = ks,
    )
    barplot!(ax, ks, counts, color = :steelblue)

    save(joinpath(output_dir, "distribution_$(fd.diagram.name).png"), fig, px_per_unit = 2)
end

# Main
results = analyse_all(verbose = false)
plot_all(results.distributions)
