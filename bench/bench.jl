using BenchmarkTools, DataFrames, LibImageQuant, CairoMakie
using Random, Printf, CSV
using ColorTypes
using PrettyTables

using LibImageQuant: LibImageQuantError
using LibImageQuant.LibImageQuantWrapper: LIQ_QUALITY_TOO_LOW

# change default for `seconds` to 1.0 so it doesn't take so long
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 1.0

# Create temporary directory for test files
bench_dir = joinpath(pkgdir(LibImageQuant), "bench", "results")
isdir(bench_dir) && rm(bench_dir; recursive=true)
mkpath(bench_dir)

# Helper function to create test images
function make_test_image(type::Symbol)
    fig = Figure()
    ax = Axis(fig[1, 1])
    if type == :scatter
        xs = range(0, 10; length=30)
        ys = 0.5 .* sin.(xs)
        points = Point2f.(xs, ys)

        scatter!(ax, points; color=1:30, markersize=range(5, 30; length=30),
                 colormap=:thermal)
    elseif type == :heatmap
        # from https://docs.makie.org/stable/reference/plots/heatmap#heatmap
        borders_x = [1, 2, 4, 7, 11, 16]
        borders_y = [6, 7, 9, 12, 16, 21]
        data = reshape(1:25, 5, 5)

        heatmap!(ax, borders_x, borders_y, data)
        scatter!(ax, [(x, y) for x in borders_x for y in borders_y]; color=:white,
                 strokecolor=:black, strokewidth=1)
    elseif type == :lines
        # from https://docs.makie.org/v0.22/reference/plots/lines#lines
        lines!(ax, 1:9, iseven.(1:9) .- 0; color=:tomato)
        lines!(ax, 1:9, iseven.(1:9) .- 1; color=(:tomato, 0.5))
        lines!(ax, 1:9, iseven.(1:9) .- 2; color=1:9)
        lines!(ax, 1:9, iseven.(1:9) .- 3; color=1:9, colormap=:plasma)
        lines!(ax, 1:9, iseven.(1:9) .- 4; color=RGBf.(0, (0:8) ./ 8, 0))
    end
    return fig
end

MIN_QUALITY = 30

# Benchmark parameter sets for each analysis
function get_color_sweep_params()
    return Dict(:colors => [8, 32, 64, 128, 256],  # updated range
                :speed => [1, 4, 6, 8, 10],
                :dither => [1.0],  # fixed at default
                :posterize => [0],  # fixed at default
                :quality => (0, 100))
end

function get_max_quality_sweep_params()
    return Dict(:colors => [256],  # fixed at 256
                :speed => [1, 4, 6, 8, 10],
                :dither => [1.0],  # fixed at default
                :posterize => [0],  # fixed at default
                :max_quality => [0, 20, 40, 60, 80, 100])
end

function get_fixed_min_quality_params()
    return Dict(:colors => [8, 32, 128, 256],
                :max_quality => [0, 20, 40, 60, 80, 100],
                :speed => [1, 4, 6, 8, 10],
                :dither => [0.0, 0.5, 1.0],
                :posterize => [0, 1, 2, 3, 4],
                :min_qualities => [30, 70])
end

function get_filesize(img, filename)
    path = joinpath(bench_dir, filename)
    save(path, img)
    return filesize(path)
end

function run_single_benchmark(img, settings, name, bench_dir; quick=true)
    quality_ok = true
    local compressed_size, t

    try
        quantized, t1, _ = @timed quantize_image(img; settings...)
        if quick
            t2 = @elapsed quantize_image(img; settings...)
            t3 = @elapsed quantize_image(img; settings...)
            t = min(t1, t2, t3) * 1e3  # convert to ms
        else
            b = @benchmarkable quantize_image($(img); $(settings)...)
            trial = run(b)
            t = minimum(trial.times) / 1e6 # convert to ms
        end

        # Save the quantized version for size comparison
        compressed_size = get_filesize(quantized, joinpath(bench_dir, "$(name).png"))

    catch e
        if e isa LibImageQuantError && e.code == LIQ_QUALITY_TOO_LOW
            quality_ok = false
            t = nothing
            compressed_size = 0
        else
            rethrow()
        end
    end

    return quality_ok, t, compressed_size
end

function format_benchmark_name(img_name, test_type, settings)
    if test_type == "colors"
        "$(img_name)_colors_c$(settings.colors)_s$(settings.speed)_d$(settings.dither)_p$(settings.posterize)"
    else
        "$(img_name)_quality_q$(settings.quality[1])-$(settings.quality[2])_s$(settings.speed)_d$(settings.dither)_p$(settings.posterize)"
    end
end

function run_color_sweep(test_images; kw...)
    params = get_color_sweep_params()
    results = DataFrame(; image_type=String[], colors=Int[], speed=Int[],
                        dither=Float64[], runtime_ms=Float64[],
                        compression_ratio=Float64[], quality_ok=Bool[])

    for (img_name, img) in test_images,
        colors in params[:colors],
        speed in params[:speed],
        dither in params[:dither]

        orig_size = get_filesize(img, joinpath(bench_dir, "$(img_name)_orig.png"))
        settings = (; colors, speed, dither, posterize=0, quality=params[:quality])
        name = format_benchmark_name(img_name, "colors", settings)
        quality_ok, t, compressed_size = run_single_benchmark(img, settings, name,
                                                              bench_dir; kw...)

        push!(results,
              (string(img_name), colors, speed, dither,
               quality_ok ? t : NaN,
               quality_ok ? orig_size / compressed_size : 0,
               quality_ok); promote=true)
    end
    return results
end

function run_quality_sweep(test_images; kw...)
    params = get_max_quality_sweep_params()
    results = DataFrame(; image_type=String[], max_quality=Int[], speed=Int[],
                        dither=Float64[], runtime_ms=Float64[],
                        compression_ratio=Float64[], quality_ok=Bool[])

    for (img_name, img) in test_images,
        max_q in params[:max_quality],
        speed in params[:speed],
        dither in params[:dither]

        colors = only(params[:colors])  # extract integer
        orig_size = get_filesize(img, joinpath(bench_dir, "$(img_name)_orig.png"))
        settings = (; colors, speed, dither, posterize=0, quality=(0, max_q))
        name = format_benchmark_name(img_name, "quality", settings)
        quality_ok, t, compressed_size = run_single_benchmark(img, settings, name,
                                                              bench_dir; kw...)

        push!(results,
              (string(img_name), max_q, speed, dither,
               quality_ok ? t : NaN,
               quality_ok ? orig_size / compressed_size : 0,
               quality_ok); promote=true)
    end
    return results
end

function run_fixed_min_quality(test_images; kw...)
    params = get_fixed_min_quality_params()
    results = DataFrame(; image_type=String[], min_quality=Int[], max_quality=Int[],
                        colors=Int[], speed=Int[], dither=Float64[],
                        posterize=Int[], runtime_ms=Float64[],
                        compression_ratio=Float64[], quality_ok=Bool[])

    for (img_name, img) in test_images,
        min_quality in params[:min_qualities],
        colors in params[:colors],
        speed in params[:speed],
        dither in params[:dither],
        posterize in params[:posterize]

        max_quality = 100
        orig_size = get_filesize(img, joinpath(bench_dir, "$(img_name)_orig.png"))
        settings = (; colors, speed, dither, posterize,
                    quality=(min_quality, max_quality))
        name = format_benchmark_name(img_name, "colors", settings)
        quality_ok, t, compressed_size = run_single_benchmark(img, settings, name,
                                                              bench_dir; kw...)

        push!(results,
              (; image_type=string(img_name), min_quality, max_quality, colors, speed,
               dither, posterize,
               runtime_ms=quality_ok ? t : NaN,
               compression_ratio=quality_ok ? orig_size / compressed_size : 0,
               quality_ok); promote=true)
    end

    for (img_name, img) in test_images,
        min_quality in params[:min_qualities],
        max_quality in params[:max_quality],
        speed in params[:speed],
        dither in params[:dither],
        posterize in params[:posterize]

        if max_quality < min_quality
            continue
        end
        colors = 256
        orig_size = get_filesize(img, joinpath(bench_dir, "$(img_name)_orig.png"))
        settings = (; colors, speed, dither, posterize,
                    quality=(min_quality, max_quality))
        name = format_benchmark_name(img_name, "quality", settings)
        quality_ok, t, compressed_size = run_single_benchmark(img, settings, name,
                                                              bench_dir)

        push!(results,
              (; image_type=string(img_name), min_quality, max_quality, colors, speed,
               dither, posterize,
               runtime_ms=quality_ok ? t : NaN,
               compression_ratio=quality_ok ? orig_size / compressed_size : 0,
               quality_ok); promote=true)
    end

    return results
end
