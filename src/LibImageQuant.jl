module LibImageQuant

using ColorTypes
using IndirectArrays

export quantize_image, LibImageQuantError

# TODO- jll
const libimagequant = "/Users/eph/libimagequant/imagequant-sys/usr/local/lib/libimagequant.dylib"

include("../gen/libimagequant.jl")

# objects
using .LibImageQuantWrapper: liq_color, liq_palette, liq_result, liq_error, LIQ_OK

# functions
using .LibImageQuantWrapper: liq_attr_create,
                             liq_image_create_rgba,
                             liq_image_quantize, liq_write_remapped_image,
                             liq_set_max_colors,
                             liq_get_palette

# cleanup
using .LibImageQuantWrapper: liq_attr_destroy,
                             liq_result_destroy, liq_image_destroy

struct LibImageQuantError <: Exception
    prefix::String
    code::liq_error
end
function Base.showerror(io::IO, e::LibImageQuantError)
    return print(io, "LibImageQuantError: ", e.prefix, " with code ", e.code)
end

function jl_to_c(matrix)
    matrix = permutedims(matrix)
    matrix = ColorTypes.RGBA.(matrix)
    ret = collect(reinterpret(reshape, UInt8, matrix))
    size(ret, 1) == 4 || throw(ArgumentError("expected 4 color channels"))
    return ret
end

function to_argb32(c::liq_color)
    # why this order? it works...
    return ARGB32(to_N0f8(c.r), to_N0f8(c.g), to_N0f8(c.b), to_N0f8(c.a))
end

function _quantize_image_matrix(matrix; colors)
    height, width = size(matrix)
    input_data = jl_to_c(matrix)

    # Create attribute handle
    # NOTE: we need to free it from every return path including errors
    attr = liq_attr_create()
    if attr == C_NULL
        throw(ErrorException("`liq_attr_create` failed, potentially out of memory"))
    end

    ret = liq_set_max_colors(attr, Cint(colors))
    if ret != LIQ_OK
        liq_attr_destroy(attr)
        throw(LibImageQuantError("`liq_set_max_colors` failed", ret))
    end

    # Create image handle
    # NOTE: we need to free it from every return path including errors
    image_handle = liq_image_create_rgba(attr, input_data, Cint(width), Cint(height), 0.0)

    if image_handle == C_NULL
        liq_attr_destroy(attr)
        throw(ErrorException("`liq_image_create_rgba` failed, potentially out of memory"))
    end

    # Create result object
    # NOTE: we need to free it from every return path including errors
    res = Ref{Ptr{liq_result}}(C_NULL)

    # Perform quantization
    ret = liq_image_quantize(image_handle, attr, res)
    if ret != LIQ_OK
        liq_image_destroy(image_handle)
        liq_attr_destroy(attr)
        throw(LibImageQuantError("`liq_image_quantize` failed", ret))
    end

    # set dithering? other settings?

    # Get the remapped image data
    output_data = Matrix{Cuchar}(undef, width, height)
    pixel_size = width * height
    ret = liq_write_remapped_image(res[],
                                   image_handle,
                                   output_data,
                                   UInt(pixel_size))
    if ret != LIQ_OK
        liq_result_destroy(res[])
        liq_image_destroy(image_handle)
        liq_attr_destroy(attr)
        throw(LibImageQuantError("`liq_write_remapped_image` failed", ret))
    end

    # Get the palette
    palette_ptr = liq_get_palette(res[])
    palette = unsafe_load(palette_ptr)

    # safety ? do we need this before we free the C memory?
    # palette = deepcopy(palette)
    # output_data = deepcopy(output_data)

    # Clean up
    liq_result_destroy(res[])
    liq_image_destroy(image_handle)
    liq_attr_destroy(attr)

    return output_data, palette
end

to_N0f8(c::UInt8) = reinterpret(ColorTypes.N0f8, c)

# this provides a hook where can add dispaches to convert e.g. Makie figures
# to matrices in extensions
to_matrix(val) = val

# the outer function just calls `to_matrix` then dispaches to `quantize_image_matrix`
"""
    quantize_image(image; colors=256)

Uses libimagequant to quantize an image to a limited number of colors between 2 and 256,
with 256 as the default. This can reduce the image size when saving as a PNG.

Returns an `IndirectArray`, which is saved efficiently by PNGFiles.jl (used by default
with CairoMakie when saving `.png` files).

## Example

```julia
using CairoMakie, LibImageQuant

fig = scatter(rand(1000), rand(1000))
save("test-256.png", quantize_image(fig))
save("test-8.png", quantize_image(fig; colors=8))
save("test-original.png", fig)
```
"""
quantize_image(val::Any; kw...) = quantize_image_matrix(to_matrix(val); kw...)

function quantize_image_matrix(matrix::AbstractMatrix{T}; colors=256) where {T}
    # we will get more confusing errors from the C library so better to throw here
    isempty(matrix) && throw(ArgumentError("matrix is empty"))
    # TODO- support the options pngquant supports
    output_data, palette = _quantize_image_matrix(matrix; colors)
    output_data = permutedims(output_data)
    color_vec = to_argb32.(collect(palette.entries)[1:(palette.count)])
    # we need our indices to be 1-based, so we have to promote from UInt8 to Int16 to get the range 1:256.
    return IndirectArray(output_data .+ Int16(1), color_vec)
end

end
