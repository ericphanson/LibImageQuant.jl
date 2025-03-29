module LibImageQuant

using ColorTypes
using IndirectArrays

export quantize_image

# TODO- jll
const libimagequant = "/Users/eph/libimagequant/imagequant-sys/usr/local/lib/libimagequant.dylib"

include("../gen/libimagequant.jl")
using .LibImageQuantWrapper: liq_color, liq_palette, liq_result, liq_image_create_rgba,
                             liq_image_quantize, liq_write_remapped_image, liq_get_palette,
                             liq_attr_create, liq_set_max_colors, liq_attr_destroy,
                             liq_result_destroy, liq_image_destroy

function jl_to_c(matrix)
    matrix = permutedims(matrix)
    matrix = ColorTypes.RGBA.(matrix)
    input_data = collect(reinterpret(reshape, UInt8, matrix))
    return copy(input_data)
end

function to_argb32(c::liq_color)
    return ARGB32(to_N0f8(c.r), to_N0f8(c.g), to_N0f8(c.b), to_N0f8(c.a))
end

function _quantize_image(matrix; colors::Int=256, limit=0, target=100)
    height, width = size(matrix)
    input_data = jl_to_c(matrix)

    # Create attribute handle
    attr = liq_attr_create()
    # SAFETY: Need to ensure this handle is freed even if subsequent calls fail
    if attr == C_NULL
        throw(OutOfMemoryError())
    end

    ret = liq_set_max_colors(attr, Cint(colors))
    if ret != 0
        liq_attr_destroy(attr)
        throw(ErrorException("`liq_set_max_colors` failed error code $ret"))
    end

    input_data2 = similar(input_data)
    copyto!(input_data2, input_data)
    @show summary(input_data2)
    # Create image handle
    # SAFETY: input_data must be preserved until after liq_image_create_rgba returns
    image_handle = liq_image_create_rgba(attr, input_data2, Cint(width), Cint(height), 0.0)

    if image_handle == C_NULL
        liq_attr_destroy(attr)
        println("Error: liq_image_create_rgba failed")
        throw(OutOfMemoryError())
    end

    # Perform quantization
    # res = liq_result()
    # res_ref = Ref{liq_result}(Ptr{liq_result}(res))
    res = Ref{Ptr{liq_result}}(C_NULL)
    ret = liq_image_quantize(image_handle, attr, res)
    if ret != 0
        liq_image_destroy(image_handle)
        liq_attr_destroy(attr)
        throw(ErrorException("Quantization failed with error code $ret"))
    end

    # Get the remapped image data
    output_data = Matrix{Cuchar}(undef, width, height)
    pixel_size = width * height

    # size_t pixels_size = width * height;
    # unsigned char *raw_8bit_pixels = malloc(pixels_size);
    # ret = @ccall libimagequant.liq_set_dithering_level(res[]::Ptr{Cvoid}, 1.0::Cfloat)::Cint;
    if ret != 0
        liq_result_destroy(res[])
        liq_image_destroy(image_handle)
        liq_attr_destroy(attr)
        throw(ErrorException("Failed to quantize image with error code $ret"))
    end

    ret = liq_write_remapped_image(res[],
                                   image_handle,
                                   output_data,
                                   UInt(pixel_size))
    if ret != 0
        liq_result_destroy(res[])
        liq_image_destroy(image_handle)
        liq_attr_destroy(attr)
        throw(ErrorException("Failed to remap image with error code $ret"))
    end

    # Get the palette
    palette_ptr = liq_get_palette(res[])
    palette = unsafe_load(palette_ptr)
    println(palette.count)

    # safety ? do we need this before we free the C memory?
    palette = deepcopy(palette)
    output_data = deepcopy(output_data)
    # Clean up
    liq_result_destroy(res[])
    liq_image_destroy(image_handle)
    liq_attr_destroy(attr)
    println(palette.count)

    return output_data, palette
end

to_N0f8(c::UInt8) = reinterpret(ColorTypes.N0f8, c)

function quantize_image(matrix)
    output_data, palette = _quantize_image(matrix)
    output_data = permutedims(output_data)
    colors = to_argb32.(collect(palette.entries)[1:(palette.count)])
    return IndirectArray(output_data .+ 1, colors)
end

end
