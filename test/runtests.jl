using LibImageQuant
using Test
using IndirectArrays, ColorTypes
using CairoMakie
using Random

# Setup test environment
img_dir = joinpath(pkgdir(LibImageQuant), "test", "images")
isdir(img_dir) && rm(img_dir; force=true, recursive=true)
mkpath(img_dir)

# Create test figure
Random.seed!(1234)
fig = Figure()
ax = Axis(fig[1, 1]; title="test")
scatter!(ax, rand(100), rand(100) .* 10; marker=:rect, color=:red, label="red rect")
scatter!(ax, rand(100), rand(100) .* 10; marker=:x, color=:blue, label="blue x")
scatter!(ax, rand(100), rand(100) .* 10; marker=:star5, color=:green, label="green star")
axislegend(ax)
matrix = colorbuffer(fig)

@testset "LibImageQuant.jl" begin
    @testset "Basic functionality" begin
        save(joinpath(img_dir, "test-cm.png"), fig)
        output = quantize_image(fig)
        @test output isa IndirectArray
        @test output.index isa Matrix{Int16}
        @test output.values isa Vector{ColorTypes.ARGB32}
        @test size(output) == size(matrix)
        save(joinpath(img_dir, "test-iq.png"), output)
    end

    @testset "Invalid inputs" begin
        @test_throws ArgumentError quantize_image(fig; colors=0)
        @test_throws ArgumentError quantize_image(fig; colors=1)
        @test_throws ArgumentError quantize_image(fig; colors=257)
        @test_throws ArgumentError quantize_image(fig; speed=0)
        @test_throws ArgumentError quantize_image(fig; speed=11)
        @test_throws ArgumentError quantize_image(fig; dither=-0.1)
        @test_throws ArgumentError quantize_image(fig; dither=1.1)
        @test_throws ArgumentError quantize_image(fig; posterize=-1)
        @test_throws ArgumentError quantize_image(fig; posterize=5)
        @test_throws ArgumentError quantize_image(fig; quality=(-1, 100))
        @test_throws ArgumentError quantize_image(fig; quality=(0, 101))
        @test_throws ArgumentError quantize_image(fig; quality=(50, 40))
        @test_throws MethodError quantize_image([])
        @test_throws ArgumentError quantize_image(reshape([], 0, 0))
        @test_throws ArgumentError quantize_image(zeros(UInt32, 0, 0))
    end

    @testset "Parameter ranges" begin
        @testset "Color count" begin
            for colors in [2, 8, 16, 128, 256]
                output = quantize_image(fig; colors)
                @test output isa IndirectArray
                @test length(output.values) <= colors
            end
        end

        @testset "Speed settings" begin
            for speed in [1, 4, 10]
                output = quantize_image(fig; speed)
                @test output isa IndirectArray
            end
        end

        @testset "Dithering levels" begin
            for dither in [0.0, 0.5, 1.0]
                output = quantize_image(fig; dither)
                @test output isa IndirectArray
            end
        end

        @testset "Posterization levels" begin
            for posterize in [0, 1, 2, 3, 4]
                output = quantize_image(fig; posterize)
                @test output isa IndirectArray
            end
        end

        @testset "Quality ranges" begin
            for quality in [(0, 100), (20, 80), (50, 50)]
                output = quantize_image(fig; quality)
                @test output isa IndirectArray
            end
        end
    end

    @testset "Combined parameters" begin
        output = quantize_image(fig;
                               colors=16,
                               speed=4,
                               dither=0.5,
                               posterize=2,
                               quality=(30, 70))
        @test output isa IndirectArray
        @test length(output.values) <= 16
    end

    @testset "File size reduction" begin
        orig_size = filesize(joinpath(img_dir, "test-cm.png"))
        for q in 1:8
            N = 2^q
            output = quantize_image(fig; colors=N)
            @test output isa IndirectArray
            @test output.index isa Matrix{Int16}
            @test output.values isa Vector{ColorTypes.ARGB32}
            @test length(output.values) <= N
            @test size(output) == size(matrix)
            N_str = lpad(N, 3, "0")
            path = joinpath(img_dir, "test-iq-$N_str.png")
            save(path, output)
            @test filesize(path) < orig_size
        end
    end

    @testset "Gradient image" begin
        uint32s = reshape(UInt32.([range(typemin(UInt32), typemax(UInt32); step=0x0000431c);
                                  zero(UInt32)]), 500, 500)
        matrix = reinterpret(ARGB32, uint32s)
        save(joinpath(img_dir, "test-gradient.png"), matrix)
        output = quantize_image(matrix)
        save(joinpath(img_dir, "test-gradient-iq.png"), output)
        @test output isa IndirectArray
    end
end
