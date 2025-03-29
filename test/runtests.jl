using LibImageQuant
using Test

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
PNGFiles.save(joinpath(img_dir, "test-iq.png"), output)

for i in [0, 1, 3]
    for n in [1, 4, 8]
        if n == 1
            i == 3 || continue
        end
        if i == 3
            n == 1 || continue
        end
        PNGFiles.save(joinpath(img_dir,
                               "test-mat-compression_strat_$i-compression_level_$n.png"),
                      matrix; compression_strategy=i, compression_level=n)

        for q in 1:8
            N = 2^q
            output = quantize_image(matrix; colors=N)
            N_str = lpad(N, 3, "0")

            PNGFiles.save(joinpath(img_dir,
                                   "test-iq-$N_str-compression_strat_$i-compression_level_$n.png"),
                          output; compression_strategy=i, compression_level=n)
        end
    end
end

# start 0, level 4 or 8
# start 1, level 4 or 8
# start 3, level 1


3,1
