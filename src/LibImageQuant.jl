module LibImageQuant

using ColorTypes
using IndirectArrays

export quantize_image
export COLOR_ORDERS

# TODO- jll
const libimagequant = "/Users/eph/libimagequant/imagequant-sys/usr/local/lib/libimagequant.dylib"

struct LiqColor
    r::Cuchar
    g::Cuchar
    b::Cuchar
    a::Cuchar
end

struct LiqPalette
    count::UInt32
    entries::NTuple{256,LiqColor}
end

const ColorOrder = Symbol
const COLOR_ORDERS = [:ARGB, :ABGR, :RGBA, :BGRA]

function jl_to_c(matrix, order::ColorOrder)
    @show order
    # order = :RGBA
    # order = Symbol(order)
    T = getproperty(ColorTypes, order)
    @show T
    @show T === ColorTypes.RGBA
    # T =ColorTypes.RGBA
    matrix = permutedims(matrix)
    matrix1 = ColorTypes.RGBA.(matrix)
    matrix2 = getproperty(ColorTypes, order).(matrix)
    @assert matrix1 == matrix2
    matrix = matrix2
    input_data = collect(reinterpret(reshape, UInt8, matrix))
    return copy(input_data)
end

function to_argb32(c::LiqColor, out_order::ColorOrder)
    return ARGB32(to_N0f8(c.r), to_N0f8(c.g), to_N0f8(c.b), to_N0f8(c.a))
end

function _quantize_image(matrix, in_order::ColorOrder; colors::Int=256, limit=0, target=100)
    height, width = size(matrix)
    input_data = jl_to_c(matrix, in_order)

    # Create attribute handle
    attr = @ccall libimagequant.liq_attr_create()::Ptr{Cvoid}
    # SAFETY: Need to ensure this handle is freed even if subsequent calls fail
    if attr == C_NULL
        throw(OutOfMemoryError())
    end

    ret = @ccall libimagequant.liq_set_max_colors(attr::Ptr{Cvoid}, colors::Cint)::Cint
    if ret != 0
        @ccall libimagequant.liq_attr_destroy(attr::Ptr{Cvoid})::Cvoid
        throw(ErrorException("`liq_set_max_colors` failed error code $ret"))
    end

    input_data2 = similar(input_data)
    copyto!(input_data2, input_data)
    @show summary(input_data2)
    # Create image handle
    # SAFETY: input_data must be preserved until after liq_image_create_rgba returns
    image_handle = @ccall libimagequant.liq_image_create_rgba(attr::Ptr{Cvoid},
                                                              input_data2::Ref{Cuchar},
                                                              width::Cint,
                                                              height::Cint,
                                                              0::Cint)::Ptr{Cvoid}

    if image_handle == C_NULL
        @ccall libimagequant.liq_attr_destroy(attr::Ptr{Cvoid})::Cvoid
        println("Error: liq_image_create_rgba failed")
        throw(OutOfMemoryError())
    end

    # Perform quantization
    res = Ref{Ptr{Cvoid}}()
    ret = @ccall libimagequant.liq_image_quantize(image_handle::Ptr{Cvoid},
                                                  attr::Ptr{Cvoid},
                                                  res::Ref{Ptr{Cvoid}})::Cint
    if ret != 0
        @ccall libimagequant.liq_image_destroy(image_handle::Ptr{Cvoid})::Cvoid
        @ccall libimagequant.liq_attr_destroy(attr::Ptr{Cvoid})::Cvoid
        throw(ErrorException("Quantization failed with error code $ret"))
    end

    # Get the remapped image data
    output_data = Matrix{Cuchar}(undef, width, height)
    pixel_size = width * height

    # size_t pixels_size = width * height;
    # unsigned char *raw_8bit_pixels = malloc(pixels_size);
    # ret = @ccall libimagequant.liq_set_dithering_level(res[]::Ptr{Cvoid}, 1.0::Cfloat)::Cint;
    if ret != 0
        @ccall libimagequant.liq_result_destroy(res[]::Ptr{Cvoid})::Cvoid
        @ccall libimagequant.liq_image_destroy(image_handle::Ptr{Cvoid})::Cvoid
        @ccall libimagequant.liq_attr_destroy(attr::Ptr{Cvoid})::Cvoid
        throw(ErrorException("Failed to quantize image with error code $ret"))
    end

    ret = @ccall libimagequant.liq_write_remapped_image(res[]::Ptr{Cvoid},
                                                        image_handle::Ptr{Cvoid},
                                                        output_data::Ref{Cuchar},
                                                        pixel_size::Cint)::Cint
    if ret != 0
        @ccall libimagequant.liq_result_destroy(res[]::Ptr{Cvoid})::Cvoid
        @ccall libimagequant.liq_image_destroy(image_handle::Ptr{Cvoid})::Cvoid
        @ccall libimagequant.liq_attr_destroy(attr::Ptr{Cvoid})::Cvoid
        throw(ErrorException("Failed to remap image with error code $ret"))
    end

    # Get the palette
    palette_ptr = @ccall libimagequant.liq_get_palette(res[]::Ptr{Cvoid})::Ptr{LiqPalette}
    palette = unsafe_load(palette_ptr)
    println(palette.count)
    # safety ? do we need this before we free the C memory?
    palette = deepcopy(palette)
    output_data = deepcopy(output_data)
    # Clean up
    @ccall libimagequant.liq_result_destroy(res[]::Ptr{Cvoid})::Cvoid
    @ccall libimagequant.liq_image_destroy(image_handle::Ptr{Cvoid})::Cvoid
    @ccall libimagequant.liq_attr_destroy(attr::Ptr{Cvoid})::Cvoid
    println(palette.count)

    return output_data, palette
end

to_N0f8(c::UInt8) = reinterpret(ColorTypes.N0f8, c)

function quantize_image(matrix, in_order::ColorOrder=:ABGR, out_order::ColorOrder=:ARGB)
    output_data, palette = _quantize_image(matrix, in_order)
    output_data = permutedims(output_data)
    colors = to_argb32.(collect(palette.entries)[1:(palette.count)], out_order)
    return IndirectArray(output_data .+ 1, colors)
end

end
