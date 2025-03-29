using LibImageQuant
using Test
using IndirectArrays, ColorTypes
using CairoMakie, PNGFiles
using Random

img_dir = joinpath(pkgdir(LibImageQuant), "test", "images")
mkpath(img_dir)
Random.seed!(1234)
fig = Figure()
ax = Axis(fig[1, 1]; title="test")
scatter!(ax, rand(100), rand(100) .* 10; marker=:rect, color=:red, label="red rect")
scatter!(ax, rand(100), rand(100) .* 10; marker=:x, color=:blue, label="blue x")
scatter!(ax, rand(100), rand(100) .* 10; marker=:star5, color=:green, label="green star")
axislegend(ax)

matrix = colorbuffer(fig)

# Save originals
CairoMakie.save(joinpath(img_dir, "test-cm.png"), fig)
output = quantize_image(matrix)
@test output isa IndirectArray
@test output.index isa Matrix{Int16}
@test output.values isa Vector{ColorTypes.ARGB32}
path = joinpath(img_dir, "test-iq.png")
PNGFiles.save(path, output)
# we could do some image testing here to automatically compare the two,
# but for now I will inspect them manually

@testset "Errors" begin
    @test_throws LibImageQuantError quantize_image(matrix; colors=0)
    @test_throws LibImageQuantError quantize_image(matrix; colors=257)
    @test_throws ArgumentError quantize_image([])
    @test_throws ArgumentError quantize_image(zeros(UInt32, 0, 0))
end

# this is more for seeing how quantization affects sizes
# than truly testing the wrapper, but we might as well call `quantize_image`
# in a few cases here in the tests
@testset "Quantization shrinks size in common case" begin
    orig_size = filesize(joinpath(img_dir, "test-cm.png"))
    for q in 1:8
        N = 2^q
        output = quantize_image(matrix; colors=N)
        @test output isa IndirectArray
        @test output.index isa Matrix{Int16}
        @test output.values isa Vector{ColorTypes.ARGB32}
        @test length(output.values) <= N
        @test size(output) == size(matrix)
        N_str = lpad(N, 3, "0")
        path = joinpath(img_dir, "test-iq-$N_str.png")
        PNGFiles.save(path, output)
        @test filesize(path) < orig_size
    end
end

uint32s = reshape(UInt32.([range(typemin(UInt32), typemax(UInt32); step=0x0000431c);
                           zero(UInt32)]), 500, 500)
matrix = reinterpret(ARGB32, uint32s)
PNGFiles.save(joinpath(img_dir, "test-gradient.png"), matrix)

output = quantize_image(matrix)
PNGFiles.save(joinpath(img_dir, "test-gradient-iq.png"), output)
