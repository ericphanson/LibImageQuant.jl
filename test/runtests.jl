using LibImageQuant
using Test

using CairoMakie, PNGFiles
using Random

img_dir = joinpath(pkgdir(LibImageQuant), "test", "images")
Random.seed!(1234)
fig = Figure()
ax = Axis(fig[1, 1]; title="test")
scatter!(ax, rand(100), rand(100) .* 10; marker=:rect, color=:red, label="red rect")
scatter!(ax, rand(100), rand(100) .* 10; marker=:x, color=:blue, label="blue x")
scatter!(ax, rand(100), rand(100) .* 10; marker=:star5, color=:green, label="green star")
axislegend(ax)

matrix = colorbuffer(fig)

# Save originals
PNGFiles.save(joinpath(img_dir, "test-mat.png"), matrix)
CairoMakie.save(joinpath(img_dir, "test-cm.png"), fig)

output = quantize_image(matrix)
PNGFiles.save(joinpath(img_dir, "test-iq.png"), output)

for n in 1:8
    N = 2^n
    output = quantize_image(matrix; colors=N)
    N_str = lpad(N, 3, "0")
    for level in 0:9
        PNGFiles.save(joinpath(img_dir, "test-iq-$N_str-compressed-$level.png"), output;
                  compression_level=level)
    end
end
