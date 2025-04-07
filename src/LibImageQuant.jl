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
                             liq_get_palette,
                             liq_set_quality,
                             liq_set_speed,
                             liq_set_min_posterization,
                             liq_set_dithering_level

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

function _quantize_image_matrix(matrix; colors, quality, speed, dither, posterize)
    height, width = size(matrix)
    input_data = jl_to_c(matrix)

    # Create attribute handle
    # NOTE: we need to free it from every return path including errors
    attr = liq_attr_create()
    if attr == C_NULL
        throw(ErrorException("`liq_attr_create` failed, potentially out of memory"))
    end

    try
        # Configure the attributes
        ret = liq_set_max_colors(attr, Cint(colors))
        ret != LIQ_OK && throw(LibImageQuantError("`liq_set_max_colors` failed", ret))

        ret = liq_set_quality(attr, Cint(quality[1]), Cint(quality[2]))
        ret != LIQ_OK && throw(LibImageQuantError("`liq_set_quality` failed", ret))

        ret = liq_set_speed(attr, Cint(speed))
        ret != LIQ_OK && throw(LibImageQuantError("`liq_set_speed` failed", ret))

        if posterize > 0
            ret = liq_set_min_posterization(attr, Cint(posterize))
            ret != LIQ_OK &&
                throw(LibImageQuantError("`liq_set_min_posterization` failed", ret))
        end

        # Create image handle
        image_handle = liq_image_create_rgba(attr, input_data, Cint(width), Cint(height),
                                             0.0)
        image_handle == C_NULL && throw(ErrorException("`liq_image_create_rgba` failed"))

        try
            # Create result object and quantize
            res = Ref{Ptr{liq_result}}(C_NULL)
            ret = liq_image_quantize(image_handle, attr, res)
            ret != LIQ_OK && throw(LibImageQuantError("`liq_image_quantize` failed", ret))

            try
                # Set dithering level (0 to 1)
                ret = liq_set_dithering_level(res[], Float32(dither))
                ret != LIQ_OK &&
                    throw(LibImageQuantError("`liq_set_dithering_level` failed", ret))

                # Get remapped image
                output_data = Matrix{Cuchar}(undef, width, height)
                pixel_size = width * height
                ret = liq_write_remapped_image(res[],
                                               image_handle,
                                               output_data,
                                               UInt(pixel_size))
                ret != LIQ_OK &&
                    throw(LibImageQuantError("`liq_write_remapped_image` failed", ret))

                # Get palette
                palette_ptr = liq_get_palette(res[])
                palette = unsafe_load(palette_ptr)

                return output_data, palette
            finally
                liq_result_destroy(res[])
            end
        finally
            liq_image_destroy(image_handle)
        end
    finally
        liq_attr_destroy(attr)
    end
end

to_N0f8(c::UInt8) = reinterpret(ColorTypes.N0f8, c)

# this provides a hook where can add dispaches to convert e.g. Makie figures
# to matrices in extensions
to_matrix(val) = val

# the outer function just calls `to_matrix` then dispaches to `quantize_image_matrix`
"""
    quantize_image(val; colors=256, quality=(0,100), speed=4, dither=1.0, posterize=0)

Uses libimagequant to quantize an image to a limited number of colors.
Returns an `IndirectArray`, which is saved efficiently by PNGFiles.jl (used by default with CairoMakie when saving `.png` files).

## Arguments

- `colors::Int=256`: number of colors (2-256)
- `quality::Tuple{Int,Int}=(0,100)`: don't save below min, use fewer colors below max quality
- `speed::Int=4`: speed/quality trade-off. 1=slow, 4=default, 10=fast
- `dither::Number=1.0`: dithering level between 0 (none) and 1 (full)
- `posterize::Int=0`: output lower-precision color (0=default, 1-4 for lower precision)

## Example

```julia
using CairoMakie, LibImageQuant
fig = scatter(rand(1000), rand(1000))
save("test-original.png", fig)
save("test-256.png", quantize_image(fig))
save("test-8.png", quantize_image(fig; colors=8))
```

"""
quantize_image(val::Any; kw...) = quantize_image_matrix(to_matrix(val); kw...)

function quantize_image_matrix(matrix::AbstractMatrix{T};
                               colors::Integer=256,
                               quality::Tuple{Integer,Integer}=(0, 100),
                               speed::Integer=4,
                               dither::Number=1.0,
                               posterize::Integer=0) where {T}

    # Parameter validation
    isempty(matrix) && throw(ArgumentError("matrix is empty"))
    !(2 <= colors <= 256) && throw(ArgumentError("colors must be between 2 and 256"))
    !(1 <= speed <= 10) && throw(ArgumentError("speed must be between 1 and 10"))
    !(0 <= dither <= 1) && throw(ArgumentError("dither must be between 0 and 1"))
    !(0 <= posterize <= 4) && throw(ArgumentError("posterize must be between 0 and 4"))
    quality_min, quality_max = quality
    !(0 <= quality_min <= 100 && 0 <= quality_max <= 100) &&
        throw(ArgumentError("quality values must be between 0 and 100"))
    quality_min > quality_max &&
        throw(ArgumentError("minimum quality cannot be greater than maximum"))

    output_data, palette = _quantize_image_matrix(matrix; colors, quality, speed, dither,
                                                  posterize)
    output_data = permutedims(output_data)

    color_vec = to_argb32.(collect(palette.entries)[1:(palette.count)])
    # we need our indices to be 1-based, so we have to promote from UInt8 to Int16 to get the range 1:256.
    return IndirectArray(output_data .+ Int16(1), color_vec)
end

end
