using CairoMakie, PNGFiles, LibImageQuant

plot = scatter(rand(1000), rand(1000))

matrix = colorbuffer(plot)

@show typeof(matrix), summary(matrix), size(matrix)

PNGFiles.save("test-mat.png", matrix)
CairoMakie.save("test-cm.png", plot)
PNGFiles.save("test-iq.png", quantize_image(matrix))
