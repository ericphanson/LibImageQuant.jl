using Test
using DataFrames

function get_pareto_front(df)
    isempty(df) && return df
    # Sort by runtime (ascending) and compression ratio (descending)
    sorted = sort(df, [:runtime_ms, :compression_ratio]; rev=[false, true])

    # Initialize Pareto front with first point
    pareto = sorted[1:1, :]

    # Add points that have better compression than all previous points
    foreach(row -> row.compression_ratio > pareto.compression_ratio[end] &&
                push!(pareto, row),
            eachrow(sorted))

    # Sort by runtime for display
    sort!(pareto, :runtime_ms)
    return pareto
end

@testset "Pareto front calculation" begin
    # Test 1: Simple domination cases
    df1 = DataFrame(; runtime_ms=[1, 2, 2, 3],
                    compression_ratio=[1, 2, 1, 3])
    pareto1 = get_pareto_front(df1)
    @test nrow(pareto1) == 3
    @test pareto1.runtime_ms == [1, 2, 3]
    @test pareto1.compression_ratio == [1, 2, 3]

    df2 = DataFrame(; runtime_ms=[1, 2, 3],
                    compression_ratio=[3, 2, 1])
    pareto2 = get_pareto_front(df2)
    @test nrow(pareto2) == 1  # only the first point (1,3) is optimal
    @test pareto2.runtime_ms == [1]
    @test pareto2.compression_ratio == [3]

    # Test 3: Duplicate points
    df3 = DataFrame(; runtime_ms=[1, 1, 2, 2],
                    compression_ratio=[1, 1, 2, 2])
    pareto3 = get_pareto_front(df3)
    @test nrow(pareto3) == 2
    @test pareto3.runtime_ms == [1, 2]
    @test pareto3.compression_ratio == [1, 2]

    # Test 4: Single point
    df4 = DataFrame(; runtime_ms=[1],
                    compression_ratio=[1])
    pareto4 = get_pareto_front(df4)
    @test nrow(pareto4) == 1
    @test pareto4.runtime_ms == [1]
    @test pareto4.compression_ratio == [1]

    df5 = DataFrame(; runtime_ms=[1, 1, 2, 2, 3, 3, 4],
                    compression_ratio=[1, 2, 2, 3, 3, 4, 4])
    for i in 1:5
        df5_shuffled = shuffle(df5)
        pareto5 = get_pareto_front(df5_shuffled)
        @test nrow(pareto5) == 3
        @test pareto5.runtime_ms == [1, 2, 3]
        @test pareto5.compression_ratio == [2, 3, 4]
    end
    # Test 6: Empty dataframe
    df6 = DataFrame(; runtime_ms=Int[], compression_ratio=Int[])
    @test nrow(get_pareto_front(df6)) == 0
end
