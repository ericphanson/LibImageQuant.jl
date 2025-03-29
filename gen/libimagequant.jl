module LibImageQuant

using LibImageQuant_jll
export LibImageQuant_jll

using CEnum

mutable struct liq_attr end

mutable struct liq_image end

mutable struct liq_result end

mutable struct liq_histogram end

struct liq_color
    r::Cuchar
    g::Cuchar
    b::Cuchar
    a::Cuchar
end

struct liq_palette
    count::Cuint
    entries::NTuple{256, liq_color}
end

@cenum liq_error::UInt32 begin
    LIQ_OK = 0
    LIQ_QUALITY_TOO_LOW = 99
    LIQ_VALUE_OUT_OF_RANGE = 100
    LIQ_OUT_OF_MEMORY = 101
    LIQ_ABORTED = 102
    LIQ_BITMAP_NOT_AVAILABLE = 103
    LIQ_BUFFER_TOO_SMALL = 104
    LIQ_INVALID_POINTER = 105
    LIQ_UNSUPPORTED = 106
end

@cenum liq_ownership::UInt32 begin
    LIQ_OWN_ROWS = 4
    LIQ_OWN_PIXELS = 8
    LIQ_COPY_PIXELS = 16
end

struct liq_histogram_entry
    color::liq_color
    count::Cuint
end

function liq_attr_create()
    ccall((:liq_attr_create, libimagequant), Ptr{liq_attr}, ())
end

function liq_attr_create_with_allocator(removed, unsupported)
    ccall((:liq_attr_create_with_allocator, libimagequant), Ptr{liq_attr}, (Ptr{Cvoid}, Ptr{Cvoid}), removed, unsupported)
end

function liq_attr_copy(orig)
    ccall((:liq_attr_copy, libimagequant), Ptr{liq_attr}, (Ptr{liq_attr},), orig)
end

function liq_attr_destroy(attr)
    ccall((:liq_attr_destroy, libimagequant), Cvoid, (Ptr{liq_attr},), attr)
end

function liq_histogram_create(attr)
    ccall((:liq_histogram_create, libimagequant), Ptr{liq_histogram}, (Ptr{liq_attr},), attr)
end

function liq_histogram_add_image(hist, attr, image)
    ccall((:liq_histogram_add_image, libimagequant), liq_error, (Ptr{liq_histogram}, Ptr{liq_attr}, Ptr{liq_image}), hist, attr, image)
end

function liq_histogram_add_colors(hist, attr, entries, num_entries, gamma)
    ccall((:liq_histogram_add_colors, libimagequant), liq_error, (Ptr{liq_histogram}, Ptr{liq_attr}, Ptr{liq_histogram_entry}, Cint, Cdouble), hist, attr, entries, num_entries, gamma)
end

function liq_histogram_add_fixed_color(hist, color, gamma)
    ccall((:liq_histogram_add_fixed_color, libimagequant), liq_error, (Ptr{liq_histogram}, liq_color, Cdouble), hist, color, gamma)
end

function liq_histogram_destroy(hist)
    ccall((:liq_histogram_destroy, libimagequant), Cvoid, (Ptr{liq_histogram},), hist)
end

function liq_set_max_colors(attr, colors)
    ccall((:liq_set_max_colors, libimagequant), liq_error, (Ptr{liq_attr}, Cint), attr, colors)
end

function liq_get_max_colors(attr)
    ccall((:liq_get_max_colors, libimagequant), Cint, (Ptr{liq_attr},), attr)
end

function liq_set_speed(attr, speed)
    ccall((:liq_set_speed, libimagequant), liq_error, (Ptr{liq_attr}, Cint), attr, speed)
end

function liq_get_speed(attr)
    ccall((:liq_get_speed, libimagequant), Cint, (Ptr{liq_attr},), attr)
end

function liq_set_min_opacity(attr, min)
    ccall((:liq_set_min_opacity, libimagequant), liq_error, (Ptr{liq_attr}, Cint), attr, min)
end

function liq_get_min_opacity(attr)
    ccall((:liq_get_min_opacity, libimagequant), Cint, (Ptr{liq_attr},), attr)
end

function liq_set_min_posterization(attr, bits)
    ccall((:liq_set_min_posterization, libimagequant), liq_error, (Ptr{liq_attr}, Cint), attr, bits)
end

function liq_get_min_posterization(attr)
    ccall((:liq_get_min_posterization, libimagequant), Cint, (Ptr{liq_attr},), attr)
end

function liq_set_quality(attr, minimum, maximum)
    ccall((:liq_set_quality, libimagequant), liq_error, (Ptr{liq_attr}, Cint, Cint), attr, minimum, maximum)
end

function liq_get_min_quality(attr)
    ccall((:liq_get_min_quality, libimagequant), Cint, (Ptr{liq_attr},), attr)
end

function liq_get_max_quality(attr)
    ccall((:liq_get_max_quality, libimagequant), Cint, (Ptr{liq_attr},), attr)
end

function liq_set_last_index_transparent(attr, is_last)
    ccall((:liq_set_last_index_transparent, libimagequant), Cvoid, (Ptr{liq_attr}, Cint), attr, is_last)
end

# typedef void liq_log_callback_function ( const liq_attr * , const char * message , void * user_info )
const liq_log_callback_function = Cvoid

# typedef void liq_log_flush_callback_function ( const liq_attr * , void * user_info )
const liq_log_flush_callback_function = Cvoid

function liq_set_log_callback(arg1, arg2, user_info)
    ccall((:liq_set_log_callback, libimagequant), Cvoid, (Ptr{liq_attr}, Ptr{liq_log_callback_function}, Ptr{Cvoid}), arg1, arg2, user_info)
end

function liq_set_log_flush_callback(arg1, arg2, user_info)
    ccall((:liq_set_log_flush_callback, libimagequant), Cvoid, (Ptr{liq_attr}, Ptr{liq_log_flush_callback_function}, Ptr{Cvoid}), arg1, arg2, user_info)
end

# typedef int liq_progress_callback_function ( float progress_percent , void * user_info )
const liq_progress_callback_function = Cvoid

function liq_attr_set_progress_callback(arg1, arg2, user_info)
    ccall((:liq_attr_set_progress_callback, libimagequant), Cvoid, (Ptr{liq_attr}, Ptr{liq_progress_callback_function}, Ptr{Cvoid}), arg1, arg2, user_info)
end

function liq_result_set_progress_callback(arg1, arg2, user_info)
    ccall((:liq_result_set_progress_callback, libimagequant), Cvoid, (Ptr{liq_result}, Ptr{liq_progress_callback_function}, Ptr{Cvoid}), arg1, arg2, user_info)
end

function liq_image_create_rgba_rows(attr, rows, width, height, gamma)
    ccall((:liq_image_create_rgba_rows, libimagequant), Ptr{liq_image}, (Ptr{liq_attr}, Ptr{Ptr{Cvoid}}, Cint, Cint, Cdouble), attr, rows, width, height, gamma)
end

function liq_image_create_rgba(attr, bitmap, width, height, gamma)
    ccall((:liq_image_create_rgba, libimagequant), Ptr{liq_image}, (Ptr{liq_attr}, Ptr{Cvoid}, Cint, Cint, Cdouble), attr, bitmap, width, height, gamma)
end

# typedef void liq_image_get_rgba_row_callback ( liq_color row_out [ ] , int row , int width , void * user_info )
const liq_image_get_rgba_row_callback = Cvoid

function liq_image_create_custom(attr, row_callback, user_info, width, height, gamma)
    ccall((:liq_image_create_custom, libimagequant), Ptr{liq_image}, (Ptr{liq_attr}, Ptr{liq_image_get_rgba_row_callback}, Ptr{Cvoid}, Cint, Cint, Cdouble), attr, row_callback, user_info, width, height, gamma)
end

function liq_image_set_memory_ownership(image, ownership_flags)
    ccall((:liq_image_set_memory_ownership, libimagequant), liq_error, (Ptr{liq_image}, Cint), image, ownership_flags)
end

function liq_image_set_background(img, background_image)
    ccall((:liq_image_set_background, libimagequant), liq_error, (Ptr{liq_image}, Ptr{liq_image}), img, background_image)
end

function liq_image_set_importance_map(img, buffer, buffer_size, memory_handling)
    ccall((:liq_image_set_importance_map, libimagequant), liq_error, (Ptr{liq_image}, Ptr{Cuchar}, Csize_t, liq_ownership), img, buffer, buffer_size, memory_handling)
end

function liq_image_add_fixed_color(img, color)
    ccall((:liq_image_add_fixed_color, libimagequant), liq_error, (Ptr{liq_image}, liq_color), img, color)
end

function liq_image_get_width(img)
    ccall((:liq_image_get_width, libimagequant), Cint, (Ptr{liq_image},), img)
end

function liq_image_get_height(img)
    ccall((:liq_image_get_height, libimagequant), Cint, (Ptr{liq_image},), img)
end

function liq_image_destroy(img)
    ccall((:liq_image_destroy, libimagequant), Cvoid, (Ptr{liq_image},), img)
end

function liq_histogram_quantize(input_hist, options, result_output)
    ccall((:liq_histogram_quantize, libimagequant), liq_error, (Ptr{liq_histogram}, Ptr{liq_attr}, Ptr{Ptr{liq_result}}), input_hist, options, result_output)
end

function liq_image_quantize(input_image, options, result_output)
    ccall((:liq_image_quantize, libimagequant), liq_error, (Ptr{liq_image}, Ptr{liq_attr}, Ptr{Ptr{liq_result}}), input_image, options, result_output)
end

function liq_set_dithering_level(res, dither_level)
    ccall((:liq_set_dithering_level, libimagequant), liq_error, (Ptr{liq_result}, Cfloat), res, dither_level)
end

function liq_set_output_gamma(res, gamma)
    ccall((:liq_set_output_gamma, libimagequant), liq_error, (Ptr{liq_result}, Cdouble), res, gamma)
end

function liq_get_output_gamma(result)
    ccall((:liq_get_output_gamma, libimagequant), Cdouble, (Ptr{liq_result},), result)
end

function liq_get_palette(result)
    ccall((:liq_get_palette, libimagequant), Ptr{liq_palette}, (Ptr{liq_result},), result)
end

function liq_write_remapped_image(result, input_image, buffer, buffer_size)
    ccall((:liq_write_remapped_image, libimagequant), liq_error, (Ptr{liq_result}, Ptr{liq_image}, Ptr{Cvoid}, Csize_t), result, input_image, buffer, buffer_size)
end

function liq_write_remapped_image_rows(result, input_image, row_pointers)
    ccall((:liq_write_remapped_image_rows, libimagequant), liq_error, (Ptr{liq_result}, Ptr{liq_image}, Ptr{Ptr{Cuchar}}), result, input_image, row_pointers)
end

function liq_get_quantization_error(result)
    ccall((:liq_get_quantization_error, libimagequant), Cdouble, (Ptr{liq_result},), result)
end

function liq_get_quantization_quality(result)
    ccall((:liq_get_quantization_quality, libimagequant), Cint, (Ptr{liq_result},), result)
end

function liq_get_remapping_error(result)
    ccall((:liq_get_remapping_error, libimagequant), Cdouble, (Ptr{liq_result},), result)
end

function liq_get_remapping_quality(result)
    ccall((:liq_get_remapping_quality, libimagequant), Cint, (Ptr{liq_result},), result)
end

function liq_result_destroy(arg1)
    ccall((:liq_result_destroy, libimagequant), Cvoid, (Ptr{liq_result},), arg1)
end

function liq_version()
    ccall((:liq_version, libimagequant), Cint, ())
end

function liq_quantize_image(options, input_image)
    ccall((:liq_quantize_image, libimagequant), Ptr{liq_result}, (Ptr{liq_attr}, Ptr{liq_image}), options, input_image)
end

# Skipping MacroDefinition: LIQ_EXPORT extern

const LIQ_VERSION = 40003

const LIQ_VERSION_STRING = "4.0.3"

# Skipping MacroDefinition: LIQ_PRIVATE __attribute__ ( ( visibility ( "hidden" ) ) )

# Skipping MacroDefinition: LIQ_NONNULL __attribute__ ( ( nonnull ) )

# Skipping MacroDefinition: LIQ_USERESULT __attribute__ ( ( warn_unused_result ) )

# exports
const PREFIXES = ["CX", "clang_"]
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end

end # module
