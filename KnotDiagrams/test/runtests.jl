# SPDX-License-Identifier: PMPL-1.0-or-later
using Test
using KnotDiagrams

@testset "KnotDiagrams" begin

    @testset "UnionFind" begin
        uf = UnionFind(6)
        @test num_components(uf) == 6

        @test uf_merge!(uf, 1, 2)
        @test num_components(uf) == 5
        @test find!(uf, 1) == find!(uf, 2)

        @test uf_merge!(uf, 3, 4)
        @test num_components(uf) == 4

        @test uf_merge!(uf, 1, 3)
        @test num_components(uf) == 3
        @test find!(uf, 2) == find!(uf, 4)

        # Merging already-connected elements should not change count
        @test !uf_merge!(uf, 2, 3)
        @test num_components(uf) == 3
    end

    @testset "GaussCode construction" begin
        # Valid Gauss code (trefoil)
        gc = GaussCode([1, -2, 3, -1, 2, -3])
        @test gc.num_crossings == 3
        @test gc.num_arcs == 6

        # Crossing positions
        c1 = gc.crossings[1]
        @test c1.over_pos == 1 && c1.under_pos == 4

        c2 = gc.crossings[2]
        @test c2.over_pos == 5 && c2.under_pos == 2

        c3 = gc.crossings[3]
        @test c3.over_pos == 3 && c3.under_pos == 6

        # Figure-eight
        gc4 = GaussCode([1, -2, 3, -4, 2, -1, 4, -3])
        @test gc4.num_crossings == 4
        @test gc4.num_arcs == 8

        # Invalid: odd length
        @test_throws AssertionError GaussCode([1, -2, 3])
    end

    @testset "Trefoil circle counts" begin
        gc = GaussCode([1, -2, 3, -1, 2, -3])

        # Manually verified state (0,0,0) -> 2 circles
        @test count_circles(gc, UInt(0b000)) == 2

        # Manually verified state (1,1,1) -> 3 circles
        @test count_circles(gc, UInt(0b111)) == 3

        # Enumerate all 8 states
        states = enumerate_states(gc)
        @test length(states) == 8

        # Collect circle counts
        circle_counts = sort([c for (_, c) in states])
        # Manually verified: [1, 1, 1, 2, 2, 2, 2, 3]
        @test circle_counts == [1, 1, 1, 2, 2, 2, 2, 3]
    end

    @testset "Trefoil fragment distribution" begin
        diagram = KnotDiagram("3_1", 3, GaussCode([1, -2, 3, -1, 2, -3]))
        fd = fragment_distribution(diagram)

        @test fd.total_states == 8
        @test fd.histogram[1] == 3
        @test fd.histogram[2] == 4
        @test fd.histogram[3] == 1

        s = fd.summary
        @test s.support == [1, 2, 3]
        @test s.min_k == 1
        @test s.max_k == 3
        @test s.support_size == 3
        @test s.classification == :spread
    end

    @testset "Figure-eight fragment distribution" begin
        diagram = KnotDiagram("4_1", 4, GaussCode([1, -2, 3, -4, 2, -1, 4, -3]))
        fd = fragment_distribution(diagram)

        @test fd.total_states == 16

        s = fd.summary
        # Figure-eight should be spread
        @test s.classification == :spread
        @test s.support_size > 1
        # Should have support different from trefoil (different crossing number,
        # but verify it's nontrivial)
        @test s.min_k >= 1
    end

    @testset "Cinquefoil fragment distribution" begin
        diagram = KnotDiagram("5_1", 5, GaussCode([1, -2, 3, -4, 5, -1, 2, -3, 4, -5]))
        fd = fragment_distribution(diagram)

        @test fd.total_states == 32

        s = fd.summary
        @test s.classification == :spread
        @test s.support_size > 1
    end

    @testset "DT to Gauss conversion" begin
        # Trefoil: DT [4, 6, 2]
        gauss = dt_to_gauss([4, 6, 2])
        gc = GaussCode(gauss)
        @test gc.num_crossings == 3

        # The converted code should produce the same fragment distribution
        # as the hand-coded trefoil
        d1 = KnotDiagram("3_1_dt", 3, gc)
        d2 = KnotDiagram("3_1", 3, GaussCode([1, -2, 3, -1, 2, -3]))
        fd1 = fragment_distribution(d1)
        fd2 = fragment_distribution(d2)
        @test fd1.histogram == fd2.histogram

        # Figure-eight: DT [4, 6, 8, 2]
        gauss4 = dt_to_gauss([4, 6, 8, 2])
        gc4 = GaussCode(gauss4)
        @test gc4.num_crossings == 4

        d3 = KnotDiagram("4_1_dt", 4, gc4)
        d4 = KnotDiagram("4_1", 4, GaussCode([1, -2, 3, -4, 2, -1, 4, -3]))
        fd3 = fragment_distribution(d3)
        fd4 = fragment_distribution(d4)
        @test fd3.histogram == fd4.histogram
    end

    @testset "Torus knot Gauss code generator" begin
        # T(2,3) = trefoil
        code3 = torus_knot_gauss(3)
        @test code3 == [1, -2, 3, -1, 2, -3]

        # T(2,5) = cinquefoil
        code5 = torus_knot_gauss(5)
        @test code5 == [1, -2, 3, -4, 5, -1, 2, -3, 4, -5]

        # T(2,7)
        code7 = torus_knot_gauss(7)
        gc7 = GaussCode(code7)
        @test gc7.num_crossings == 7
    end

    @testset "Knot table validity" begin
        diagrams = prime_knots_up_to_7()
        @test length(diagrams) == 14  # 1 + 1 + 2 + 3 + 7

        # All diagrams should have valid Gauss codes
        for d in diagrams
            @test d.gauss_code.num_crossings == d.crossing_number
        end
    end

    @testset "Compare by crossing number" begin
        diagrams = prime_knots_up_to_7()
        distributions = [fragment_distribution(d) for d in diagrams]
        comparisons = compare_by_crossing_number(distributions)

        # Should have comparisons for crossing numbers with > 1 knot
        @test length(comparisons) > 0

        # 5-crossing: 1 pair (5_1 vs 5_2)
        cn5_pairs = filter(r -> r.crossing_number == 5, comparisons)
        @test length(cn5_pairs) == 1

        # 6-crossing: 3 pairs (6_1 vs 6_2, 6_1 vs 6_3, 6_2 vs 6_3)
        cn6_pairs = filter(r -> r.crossing_number == 6, comparisons)
        @test length(cn6_pairs) == 3

        # 7-crossing: C(7,2) = 21 pairs
        cn7_pairs = filter(r -> r.crossing_number == 7, comparisons)
        @test length(cn7_pairs) == 21
    end

    @testset "Distribution and comparison tables" begin
        diagrams = prime_knots_up_to_7()
        distributions = [fragment_distribution(d) for d in diagrams]

        df = distribution_table(distributions)
        @test size(df, 1) == length(diagrams)
        @test "name" in names(df)
        @test "support" in names(df)

        comparisons = compare_by_crossing_number(distributions)
        cdf = comparison_table(comparisons)
        @test size(cdf, 1) == length(comparisons)
        @test "supports_differ" in names(cdf)
    end

    @testset "Spread vs collapse — all prime knots are spread" begin
        diagrams = prime_knots_up_to_7()
        for d in diagrams
            fd = fragment_distribution(d)
            @test fd.summary.classification == :spread
        end
    end

    @testset "Different knot types have different distributions" begin
        # 5_1 vs 5_2 should differ
        d51 = KnotDiagram("5_1", 5, GaussCode([1, -2, 3, -4, 5, -1, 2, -3, 4, -5]))
        d52 = KnotDiagram("5_2", 5, GaussCode(dt_to_gauss([4, 8, 10, 2, 6])))
        fd51 = fragment_distribution(d51)
        fd52 = fragment_distribution(d52)
        result = compare_pair(fd51, fd52)
        @test result.histograms_differ
    end

end
