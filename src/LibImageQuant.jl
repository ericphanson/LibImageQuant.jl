module LibImageQuant

using ColorTypes
using IndirectArrays

export quantize_image

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

function jl_to_c(image)
    image = permutedims(image)

    #TODO- somehow this is the wrong type, but I'm close...
    
    image = ColorTypes.ABGR.(image)
    # we collect now since `cconvert` will have to copy anyway
    input_data = collect(reinterpret(reshape, UInt8, image))
    # input_data = permutedims(input_data, (3, 2, 1)) # width×height×4
    return input_data
end

# TODO defaults
function _quantize_image(matrix; colors::Int=256, limit=0, target=100)
    height, width = size(matrix)
    input_data = jl_to_c(matrix)

    # Create attribute handle
    attr = @ccall libimagequant.liq_attr_create()::Ptr{Cvoid}
    # SAFETY: Need to ensure this handle is freed even if subsequent calls fail
    if attr == C_NULL
        throw(OutOfMemoryError())
    end

    ret = @ccall libimagequant.liq_set_max_colors(attr::Ptr{Cvoid}, colors::Cint)::Cint;
    if ret != 0
        @ccall libimagequant.liq_attr_destroy(attr::Ptr{Cvoid})::Cvoid
        throw(ErrorException("`liq_set_max_colors` failed error code $ret"))
    end

    # ret = @ccall libimagequant.liq_set_quality(attr::Ptr{Cvoid}, limit::Cint, target::Cint)::Cint;
    # if ret != 0
        # @ccall libimagequant.liq_attr_destroy(attr::Ptr{Cvoid})::Cvoid
        # throw(ErrorException("`liq_set_quality` failed error code $ret"))
    # end




    # Create image handle
    # SAFETY: input_data must be preserved until after liq_image_create_rgba returns
    image = GC.@preserve input_data @ccall libimagequant.liq_image_create_rgba(attr::Ptr{Cvoid},
                                                                               input_data::Ptr{Cuchar},
                                                                               width::Cint,
                                                                               height::Cint,
                                                                               0::Cint)::Ptr{Cvoid}

    if image == C_NULL
        @ccall libimagequant.liq_attr_destroy(attr::Ptr{Cvoid})::Cvoid
        throw(OutOfMemoryError())
    end

    # Perform quantization
    res = Ref{Ptr{Cvoid}}()
    ret = @ccall libimagequant.liq_image_quantize(image::Ptr{Cvoid},
                                                  attr::Ptr{Cvoid},
                                                  res::Ptr{Ptr{Cvoid}})::Cint
    if ret != 0
        @ccall libimagequant.liq_image_destroy(image::Ptr{Cvoid})::Cvoid
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
        @ccall libimagequant.liq_image_destroy(image::Ptr{Cvoid})::Cvoid
        @ccall libimagequant.liq_attr_destroy(attr::Ptr{Cvoid})::Cvoid
        throw(ErrorException("Failed to quantize image with error code $ret"))
    end

    ret = GC.@preserve output_data @ccall libimagequant.liq_write_remapped_image(res[]::Ptr{Cvoid},
                                                                                 image::Ptr{Cvoid},
                                                                                 output_data::Ref{Cuchar},
                                                                                 pixel_size::Cint)::Cint
    if ret != 0
        @ccall libimagequant.liq_result_destroy(res[]::Ptr{Cvoid})::Cvoid
        @ccall libimagequant.liq_image_destroy(image::Ptr{Cvoid})::Cvoid
        @ccall libimagequant.liq_attr_destroy(attr::Ptr{Cvoid})::Cvoid
        throw(ErrorException("Failed to remap image with error code $ret"))
    end

    # Get the palette
    palette_ptr = @ccall libimagequant.liq_get_palette(res[]::Ptr{Cvoid})::Ptr{LiqPalette}
    palette = unsafe_load(palette_ptr)

    # safety ? do we need this before we free the C memory?
    palette = deepcopy(palette)

    # Clean up
    @ccall libimagequant.liq_result_destroy(res[]::Ptr{Cvoid})::Cvoid
    @ccall libimagequant.liq_image_destroy(image::Ptr{Cvoid})::Cvoid
    @ccall libimagequant.liq_attr_destroy(attr::Ptr{Cvoid})::Cvoid

    return output_data, palette
end

to_N0f8(c::UInt8) = reinterpret(ColorTypes.N0f8, c)
to_argb32(c::LiqColor) = ARGB32(to_N0f8(c.a), to_N0f8(c.r), to_N0f8(c.g), to_N0f8(c.b))

# to_argb32(c::LiqColor) = ARGB32(to_N0f8(c.a), to_N0f8(c.b), to_N0f8(c.g), to_N0f8(c.r))

function quantize_image(matrix)
    output_data, palette = _quantize_image(matrix)
    output_data = permutedims(output_data)
    colors = to_argb32.(collect(palette.entries)[1:(palette.count)]) # Convert to RGBA
    # there's gotta be a better way that this +1
    return IndirectArray(output_data .+ 1, colors)
end

end
