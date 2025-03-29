using CairoMakie, PNGFiles, LibImageQuant

plot = scatter(rand(1000), rand(1000) .* 10)

matrix = colorbuffer(plot)

@show typeof(matrix), summary(matrix), size(matrix)

PNGFiles.save("test-mat.png", matrix)
CairoMakie.save("test-cm.png", plot)

output = quantize_image(matrix)

PNGFiles.save("test-iq.png", output)
unique(output)
