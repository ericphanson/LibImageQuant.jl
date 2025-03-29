module LibImageQuantWrapper

# using LibImageQuant_jll
# export LibImageQuant_jll
const libimagequant = "/Users/eph/libimagequant/imagequant-sys/usr/local/lib/libimagequant.dylib"

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

"""
    liq_attr_create()

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT liq_attr* liq_attr_create(void);
```
"""
function liq_attr_create()
    @ccall libimagequant.liq_attr_create()::Ptr{liq_attr}
end

"""
    liq_attr_create_with_allocator(removed, unsupported)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT liq_attr* liq_attr_create_with_allocator(void* removed, void *unsupported);
```
"""
function liq_attr_create_with_allocator(removed, unsupported)
    @ccall libimagequant.liq_attr_create_with_allocator(removed::Ptr{Cvoid}, unsupported::Ptr{Cvoid})::Ptr{liq_attr}
end

"""
    liq_attr_copy(orig)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT liq_attr* liq_attr_copy(const liq_attr *orig) LIQ_NONNULL;
```
"""
function liq_attr_copy(orig)
    @ccall libimagequant.liq_attr_copy(orig::Ptr{liq_attr})::Ptr{liq_attr}
end

"""
    liq_attr_destroy(attr)

### Prototype
```c
LIQ_EXPORT void liq_attr_destroy(liq_attr *attr) LIQ_NONNULL;
```
"""
function liq_attr_destroy(attr)
    @ccall libimagequant.liq_attr_destroy(attr::Ptr{liq_attr})::Cvoid
end

"""
    liq_histogram_create(attr)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT liq_histogram* liq_histogram_create(const liq_attr* attr);
```
"""
function liq_histogram_create(attr)
    @ccall libimagequant.liq_histogram_create(attr::Ptr{liq_attr})::Ptr{liq_histogram}
end

"""
    liq_histogram_add_image(hist, attr, image)

### Prototype
```c
LIQ_EXPORT liq_error liq_histogram_add_image(liq_histogram *hist, const liq_attr *attr, liq_image* image) LIQ_NONNULL;
```
"""
function liq_histogram_add_image(hist, attr, image)
    @ccall libimagequant.liq_histogram_add_image(hist::Ptr{liq_histogram}, attr::Ptr{liq_attr}, image::Ptr{liq_image})::liq_error
end

"""
    liq_histogram_add_colors(hist, attr, entries, num_entries::Cint, gamma::Cdouble)

### Prototype
```c
LIQ_EXPORT liq_error liq_histogram_add_colors(liq_histogram *hist, const liq_attr *attr, const liq_histogram_entry entries[], int num_entries, double gamma) LIQ_NONNULL;
```
"""
function liq_histogram_add_colors(hist, attr, entries, num_entries::Cint, gamma::Cdouble)
    @ccall libimagequant.liq_histogram_add_colors(hist::Ptr{liq_histogram}, attr::Ptr{liq_attr}, entries::Ptr{liq_histogram_entry}, num_entries::Cint, gamma::Cdouble)::liq_error
end

"""
    liq_histogram_add_fixed_color(hist, color::liq_color, gamma::Cdouble)

### Prototype
```c
LIQ_EXPORT liq_error liq_histogram_add_fixed_color(liq_histogram *hist, liq_color color, double gamma) LIQ_NONNULL;
```
"""
function liq_histogram_add_fixed_color(hist, color::liq_color, gamma::Cdouble)
    @ccall libimagequant.liq_histogram_add_fixed_color(hist::Ptr{liq_histogram}, color::liq_color, gamma::Cdouble)::liq_error
end

"""
    liq_histogram_destroy(hist)

### Prototype
```c
LIQ_EXPORT void liq_histogram_destroy(liq_histogram *hist) LIQ_NONNULL;
```
"""
function liq_histogram_destroy(hist)
    @ccall libimagequant.liq_histogram_destroy(hist::Ptr{liq_histogram})::Cvoid
end

"""
    liq_set_max_colors(attr, colors::Cint)

### Prototype
```c
LIQ_EXPORT liq_error liq_set_max_colors(liq_attr* attr, int colors) LIQ_NONNULL;
```
"""
function liq_set_max_colors(attr, colors::Cint)
    @ccall libimagequant.liq_set_max_colors(attr::Ptr{liq_attr}, colors::Cint)::liq_error
end

"""
    liq_get_max_colors(attr)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT int liq_get_max_colors(const liq_attr* attr) LIQ_NONNULL;
```
"""
function liq_get_max_colors(attr)
    @ccall libimagequant.liq_get_max_colors(attr::Ptr{liq_attr})::Cint
end

"""
    liq_set_speed(attr, speed::Cint)

### Prototype
```c
LIQ_EXPORT liq_error liq_set_speed(liq_attr* attr, int speed) LIQ_NONNULL;
```
"""
function liq_set_speed(attr, speed::Cint)
    @ccall libimagequant.liq_set_speed(attr::Ptr{liq_attr}, speed::Cint)::liq_error
end

"""
    liq_get_speed(attr)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT int liq_get_speed(const liq_attr* attr) LIQ_NONNULL;
```
"""
function liq_get_speed(attr)
    @ccall libimagequant.liq_get_speed(attr::Ptr{liq_attr})::Cint
end

"""
    liq_set_min_opacity(attr, min::Cint)

### Prototype
```c
LIQ_EXPORT liq_error liq_set_min_opacity(liq_attr* attr, int min) LIQ_NONNULL;
```
"""
function liq_set_min_opacity(attr, min::Cint)
    @ccall libimagequant.liq_set_min_opacity(attr::Ptr{liq_attr}, min::Cint)::liq_error
end

"""
    liq_get_min_opacity(attr)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT int liq_get_min_opacity(const liq_attr* attr) LIQ_NONNULL;
```
"""
function liq_get_min_opacity(attr)
    @ccall libimagequant.liq_get_min_opacity(attr::Ptr{liq_attr})::Cint
end

"""
    liq_set_min_posterization(attr, bits::Cint)

### Prototype
```c
LIQ_EXPORT liq_error liq_set_min_posterization(liq_attr* attr, int bits) LIQ_NONNULL;
```
"""
function liq_set_min_posterization(attr, bits::Cint)
    @ccall libimagequant.liq_set_min_posterization(attr::Ptr{liq_attr}, bits::Cint)::liq_error
end

"""
    liq_get_min_posterization(attr)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT int liq_get_min_posterization(const liq_attr* attr) LIQ_NONNULL;
```
"""
function liq_get_min_posterization(attr)
    @ccall libimagequant.liq_get_min_posterization(attr::Ptr{liq_attr})::Cint
end

"""
    liq_set_quality(attr, minimum::Cint, maximum::Cint)

### Prototype
```c
LIQ_EXPORT liq_error liq_set_quality(liq_attr* attr, int minimum, int maximum) LIQ_NONNULL;
```
"""
function liq_set_quality(attr, minimum::Cint, maximum::Cint)
    @ccall libimagequant.liq_set_quality(attr::Ptr{liq_attr}, minimum::Cint, maximum::Cint)::liq_error
end

"""
    liq_get_min_quality(attr)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT int liq_get_min_quality(const liq_attr* attr) LIQ_NONNULL;
```
"""
function liq_get_min_quality(attr)
    @ccall libimagequant.liq_get_min_quality(attr::Ptr{liq_attr})::Cint
end

"""
    liq_get_max_quality(attr)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT int liq_get_max_quality(const liq_attr* attr) LIQ_NONNULL;
```
"""
function liq_get_max_quality(attr)
    @ccall libimagequant.liq_get_max_quality(attr::Ptr{liq_attr})::Cint
end

"""
    liq_set_last_index_transparent(attr, is_last::Cint)

### Prototype
```c
LIQ_EXPORT void liq_set_last_index_transparent(liq_attr* attr, int is_last) LIQ_NONNULL;
```
"""
function liq_set_last_index_transparent(attr, is_last::Cint)
    @ccall libimagequant.liq_set_last_index_transparent(attr::Ptr{liq_attr}, is_last::Cint)::Cvoid
end

# typedef void liq_log_callback_function ( const liq_attr * , const char * message , void * user_info )
const liq_log_callback_function = Cvoid

# typedef void liq_log_flush_callback_function ( const liq_attr * , void * user_info )
const liq_log_flush_callback_function = Cvoid

"""
    liq_set_log_callback(arg1, arg2, user_info)

### Prototype
```c
LIQ_EXPORT void liq_set_log_callback(liq_attr*, liq_log_callback_function*, void* user_info);
```
"""
function liq_set_log_callback(arg1, arg2, user_info)
    @ccall libimagequant.liq_set_log_callback(arg1::Ptr{liq_attr}, arg2::Ptr{liq_log_callback_function}, user_info::Ptr{Cvoid})::Cvoid
end

"""
    liq_set_log_flush_callback(arg1, arg2, user_info)

### Prototype
```c
LIQ_EXPORT void liq_set_log_flush_callback(liq_attr*, liq_log_flush_callback_function*, void* user_info);
```
"""
function liq_set_log_flush_callback(arg1, arg2, user_info)
    @ccall libimagequant.liq_set_log_flush_callback(arg1::Ptr{liq_attr}, arg2::Ptr{liq_log_flush_callback_function}, user_info::Ptr{Cvoid})::Cvoid
end

# typedef int liq_progress_callback_function ( float progress_percent , void * user_info )
const liq_progress_callback_function = Cvoid

"""
    liq_attr_set_progress_callback(arg1, arg2, user_info)

### Prototype
```c
LIQ_EXPORT void liq_attr_set_progress_callback(liq_attr*, liq_progress_callback_function*, void* user_info);
```
"""
function liq_attr_set_progress_callback(arg1, arg2, user_info)
    @ccall libimagequant.liq_attr_set_progress_callback(arg1::Ptr{liq_attr}, arg2::Ptr{liq_progress_callback_function}, user_info::Ptr{Cvoid})::Cvoid
end

"""
    liq_result_set_progress_callback(arg1, arg2, user_info)

### Prototype
```c
LIQ_EXPORT void liq_result_set_progress_callback(liq_result*, liq_progress_callback_function*, void* user_info);
```
"""
function liq_result_set_progress_callback(arg1, arg2, user_info)
    @ccall libimagequant.liq_result_set_progress_callback(arg1::Ptr{liq_result}, arg2::Ptr{liq_progress_callback_function}, user_info::Ptr{Cvoid})::Cvoid
end

"""
    liq_image_create_rgba_rows(attr, rows, width::Cint, height::Cint, gamma::Cdouble)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT liq_image *liq_image_create_rgba_rows(const liq_attr *attr, void *const rows[], int width, int height, double gamma) LIQ_NONNULL;
```
"""
function liq_image_create_rgba_rows(attr, rows, width::Cint, height::Cint, gamma::Cdouble)
    @ccall libimagequant.liq_image_create_rgba_rows(attr::Ptr{liq_attr}, rows::Ptr{Ptr{Cvoid}}, width::Cint, height::Cint, gamma::Cdouble)::Ptr{liq_image}
end

"""
    liq_image_create_rgba(attr, bitmap, width::Cint, height::Cint, gamma::Cdouble)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT liq_image *liq_image_create_rgba(const liq_attr *attr, const void *bitmap, int width, int height, double gamma) LIQ_NONNULL;
```
"""
function liq_image_create_rgba(attr, bitmap, width::Cint, height::Cint, gamma::Cdouble)
    @ccall libimagequant.liq_image_create_rgba(attr::Ptr{liq_attr}, bitmap::Ptr{Cvoid}, width::Cint, height::Cint, gamma::Cdouble)::Ptr{liq_image}
end

# typedef void liq_image_get_rgba_row_callback ( liq_color row_out [ ] , int row , int width , void * user_info )
const liq_image_get_rgba_row_callback = Cvoid

"""
    liq_image_create_custom(attr, row_callback, user_info, width::Cint, height::Cint, gamma::Cdouble)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT liq_image *liq_image_create_custom(const liq_attr *attr, liq_image_get_rgba_row_callback *row_callback, void* user_info, int width, int height, double gamma);
```
"""
function liq_image_create_custom(attr, row_callback, user_info, width::Cint, height::Cint, gamma::Cdouble)
    @ccall libimagequant.liq_image_create_custom(attr::Ptr{liq_attr}, row_callback::Ptr{liq_image_get_rgba_row_callback}, user_info::Ptr{Cvoid}, width::Cint, height::Cint, gamma::Cdouble)::Ptr{liq_image}
end

"""
    liq_image_set_memory_ownership(image, ownership_flags::Cint)

### Prototype
```c
LIQ_EXPORT liq_error liq_image_set_memory_ownership(liq_image *image, int ownership_flags) LIQ_NONNULL;
```
"""
function liq_image_set_memory_ownership(image, ownership_flags::Cint)
    @ccall libimagequant.liq_image_set_memory_ownership(image::Ptr{liq_image}, ownership_flags::Cint)::liq_error
end

"""
    liq_image_set_background(img, background_image)

### Prototype
```c
LIQ_EXPORT liq_error liq_image_set_background(liq_image *img, liq_image *background_image) LIQ_NONNULL;
```
"""
function liq_image_set_background(img, background_image)
    @ccall libimagequant.liq_image_set_background(img::Ptr{liq_image}, background_image::Ptr{liq_image})::liq_error
end

"""
    liq_image_set_importance_map(img, buffer, buffer_size::Csize_t, memory_handling::liq_ownership)

### Prototype
```c
LIQ_EXPORT liq_error liq_image_set_importance_map(liq_image *img, unsigned char buffer[], size_t buffer_size, enum liq_ownership memory_handling) LIQ_NONNULL;
```
"""
function liq_image_set_importance_map(img, buffer, buffer_size::Csize_t, memory_handling::liq_ownership)
    @ccall libimagequant.liq_image_set_importance_map(img::Ptr{liq_image}, buffer::Ptr{Cuchar}, buffer_size::Csize_t, memory_handling::liq_ownership)::liq_error
end

"""
    liq_image_add_fixed_color(img, color::liq_color)

### Prototype
```c
LIQ_EXPORT liq_error liq_image_add_fixed_color(liq_image *img, liq_color color) LIQ_NONNULL;
```
"""
function liq_image_add_fixed_color(img, color::liq_color)
    @ccall libimagequant.liq_image_add_fixed_color(img::Ptr{liq_image}, color::liq_color)::liq_error
end

"""
    liq_image_get_width(img)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT int liq_image_get_width(const liq_image *img) LIQ_NONNULL;
```
"""
function liq_image_get_width(img)
    @ccall libimagequant.liq_image_get_width(img::Ptr{liq_image})::Cint
end

"""
    liq_image_get_height(img)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT int liq_image_get_height(const liq_image *img) LIQ_NONNULL;
```
"""
function liq_image_get_height(img)
    @ccall libimagequant.liq_image_get_height(img::Ptr{liq_image})::Cint
end

"""
    liq_image_destroy(img)

### Prototype
```c
LIQ_EXPORT void liq_image_destroy(liq_image *img) LIQ_NONNULL;
```
"""
function liq_image_destroy(img)
    @ccall libimagequant.liq_image_destroy(img::Ptr{liq_image})::Cvoid
end

"""
    liq_histogram_quantize(input_hist, options, result_output)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT liq_error liq_histogram_quantize(liq_histogram *const input_hist, liq_attr *const options, liq_result **result_output) LIQ_NONNULL;
```
"""
function liq_histogram_quantize(input_hist, options, result_output)
    @ccall libimagequant.liq_histogram_quantize(input_hist::Ptr{liq_histogram}, options::Ptr{liq_attr}, result_output::Ptr{Ptr{liq_result}})::liq_error
end

"""
    liq_image_quantize(input_image, options, result_output)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT liq_error liq_image_quantize(liq_image *const input_image, liq_attr *const options, liq_result **result_output) LIQ_NONNULL;
```
"""
function liq_image_quantize(input_image, options, result_output)
    @ccall libimagequant.liq_image_quantize(input_image::Ptr{liq_image}, options::Ptr{liq_attr}, result_output::Ptr{Ptr{liq_result}})::liq_error
end

"""
    liq_set_dithering_level(res, dither_level::Cfloat)

### Prototype
```c
LIQ_EXPORT liq_error liq_set_dithering_level(liq_result *res, float dither_level) LIQ_NONNULL;
```
"""
function liq_set_dithering_level(res, dither_level::Cfloat)
    @ccall libimagequant.liq_set_dithering_level(res::Ptr{liq_result}, dither_level::Cfloat)::liq_error
end

"""
    liq_set_output_gamma(res, gamma::Cdouble)

### Prototype
```c
LIQ_EXPORT liq_error liq_set_output_gamma(liq_result* res, double gamma) LIQ_NONNULL;
```
"""
function liq_set_output_gamma(res, gamma::Cdouble)
    @ccall libimagequant.liq_set_output_gamma(res::Ptr{liq_result}, gamma::Cdouble)::liq_error
end

"""
    liq_get_output_gamma(result)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT double liq_get_output_gamma(const liq_result *result) LIQ_NONNULL;
```
"""
function liq_get_output_gamma(result)
    @ccall libimagequant.liq_get_output_gamma(result::Ptr{liq_result})::Cdouble
end

"""
    liq_get_palette(result)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT const liq_palette *liq_get_palette(liq_result *result) LIQ_NONNULL;
```
"""
function liq_get_palette(result)
    @ccall libimagequant.liq_get_palette(result::Ptr{liq_result})::Ptr{liq_palette}
end

"""
    liq_write_remapped_image(result, input_image, buffer, buffer_size::Csize_t)

### Prototype
```c
LIQ_EXPORT liq_error liq_write_remapped_image(liq_result *result, liq_image *input_image, void *buffer, size_t buffer_size) LIQ_NONNULL;
```
"""
function liq_write_remapped_image(result, input_image, buffer, buffer_size::Csize_t)
    @ccall libimagequant.liq_write_remapped_image(result::Ptr{liq_result}, input_image::Ptr{liq_image}, buffer::Ptr{Cvoid}, buffer_size::Csize_t)::liq_error
end

"""
    liq_write_remapped_image_rows(result, input_image, row_pointers)

### Prototype
```c
LIQ_EXPORT liq_error liq_write_remapped_image_rows(liq_result *result, liq_image *input_image, unsigned char **row_pointers) LIQ_NONNULL;
```
"""
function liq_write_remapped_image_rows(result, input_image, row_pointers)
    @ccall libimagequant.liq_write_remapped_image_rows(result::Ptr{liq_result}, input_image::Ptr{liq_image}, row_pointers::Ptr{Ptr{Cuchar}})::liq_error
end

"""
    liq_get_quantization_error(result)

### Prototype
```c
LIQ_EXPORT double liq_get_quantization_error(const liq_result *result) LIQ_NONNULL;
```
"""
function liq_get_quantization_error(result)
    @ccall libimagequant.liq_get_quantization_error(result::Ptr{liq_result})::Cdouble
end

"""
    liq_get_quantization_quality(result)

### Prototype
```c
LIQ_EXPORT int liq_get_quantization_quality(const liq_result *result) LIQ_NONNULL;
```
"""
function liq_get_quantization_quality(result)
    @ccall libimagequant.liq_get_quantization_quality(result::Ptr{liq_result})::Cint
end

"""
    liq_get_remapping_error(result)

### Prototype
```c
LIQ_EXPORT double liq_get_remapping_error(const liq_result *result) LIQ_NONNULL;
```
"""
function liq_get_remapping_error(result)
    @ccall libimagequant.liq_get_remapping_error(result::Ptr{liq_result})::Cdouble
end

"""
    liq_get_remapping_quality(result)

### Prototype
```c
LIQ_EXPORT int liq_get_remapping_quality(const liq_result *result) LIQ_NONNULL;
```
"""
function liq_get_remapping_quality(result)
    @ccall libimagequant.liq_get_remapping_quality(result::Ptr{liq_result})::Cint
end

"""
    liq_result_destroy(arg1)

### Prototype
```c
LIQ_EXPORT void liq_result_destroy(liq_result *) LIQ_NONNULL;
```
"""
function liq_result_destroy(arg1)
    @ccall libimagequant.liq_result_destroy(arg1::Ptr{liq_result})::Cvoid
end

"""
    liq_version()

### Prototype
```c
LIQ_EXPORT int liq_version(void);
```
"""
function liq_version()
    @ccall libimagequant.liq_version()::Cint
end

"""
    liq_quantize_image(options, input_image)

### Prototype
```c
LIQ_EXPORT LIQ_USERESULT liq_result *liq_quantize_image(liq_attr *options, liq_image *input_image) LIQ_NONNULL;
```
"""
function liq_quantize_image(options, input_image)
    @ccall libimagequant.liq_quantize_image(options::Ptr{liq_attr}, input_image::Ptr{liq_image})::Ptr{liq_result}
end

# Skipping MacroDefinition: LIQ_EXPORT extern

const LIQ_VERSION = 40003

const LIQ_VERSION_STRING = "4.0.3"

# Skipping MacroDefinition: LIQ_PRIVATE __attribute__ ( ( visibility ( "hidden" ) ) )

# Skipping MacroDefinition: LIQ_NONNULL __attribute__ ( ( nonnull ) )

# Skipping MacroDefinition: LIQ_USERESULT __attribute__ ( ( warn_unused_result ) )

end # module
