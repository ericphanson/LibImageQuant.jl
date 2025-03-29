module MakieExt

using Makie: FigureLike, colorbuffer
using LibImageQuant: LibImageQuant

LibImageQuant.to_matrix(fig::FigureLike) = colorbuffer(fig)

end # module MakieExt
