using CairoMakie, LibImageQuant, Random

CairoMakie.activate!(; px_per_unit=4, pt_per_unit=4)
Random.seed!(1)
fig = scatter(rand(1000), rand(1000))

results = []
tmp = mktempdir()
for n in 2:256
    save("$tmp/test-$n.png", quantize_image(fig; colors=n))
    push!(results, (; n, bytes=stat("$tmp/test-$n.png").size))
end

plt = Figure();
ax = Axis(plt[1, 1]; xlabel="Number of colors", ylabel="Number of bytes")
lines!(ax, [row.n for row in results], [row.bytes for row in results])
save("colors_vs_size.png", quantize_image(plt))
