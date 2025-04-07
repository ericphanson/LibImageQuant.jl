# how does the compression ratio and runtime speed vary as we change the maximum number of colors used in image quantization?
import AlgebraOfGraphics as AoG
using AlgebraOfGraphics

function plot_color_sweep(color_results)
    colors = join(sort!(unique(color_results.colors)), ", ", ", or ")

    # Key figure 1: `speed` setting has big impact on runtime, and low impact on compression ratio, especially at higher color settings
    plt = AoG.data(color_results) *
          (mapping(:speed, [:runtime_ms, :compression_ratio];
                   row=dims(1) => renamer(["Runtime", "Compression ratio"]),
                   col=:colors => nonnumeric)) *
          (mapping(; marker=:image_type, color=:image_type) *
           visual(ScatterLines))
    fig = draw(plt;
               figure=(; size=(1200, 600),
                       title="Runtime & Compression ratio vs speed setting, for `colors` set to $colors"))

    save(joinpath(bench_dir, "color_sweep_speed.png"), fig)

    speeds = join(sort!(unique(color_results.speed)), ", ", ", or ")

    # Secondary figure: complicated relationship between number of colors and runtime; middle number of colors does the best, small and high can be slower. For compression, smaller colors is also better of course.
    plt = AoG.data(color_results) *
          (mapping(:colors, [:runtime_ms, :compression_ratio];
                   row=dims(1) => renamer(["Runtime", "Compression ratio"]),
                   col=:speed => nonnumeric)) *
          (mapping(; marker=:image_type, color=:image_type) *
           visual(ScatterLines))
    fig = draw(plt;
               figure=(; size=(1200, 600),
                       title="Runtime & Compression ratio vs speed setting, for `speed` set to $speeds"))
    save(joinpath(bench_dir, "color_sweep_color.png"), fig)
    return nothing
end

function plot_quality_sweep(quality_results)
    max_quality = join(sort!(unique(quality_results.max_quality)), ", ", ", or ")

    plt = AoG.data(quality_results) *
          (mapping(:speed, [:runtime_ms, :compression_ratio];
                   row=dims(1) => renamer(["Runtime", "Compression ratio"]),
                   col=:max_quality => nonnumeric)) *
          (mapping(; marker=:image_type, color=:image_type) *
           visual(ScatterLines))
    fig = draw(plt;
               figure=(; size=(1200, 600),
                       title="Runtime & Compression ratio vs speed setting, for `max_quality` set to $max_quality"))

    save(joinpath(bench_dir, "max_quality_speed.png"), fig)

    speeds = join(sort!(unique(quality_results.speed)), ", ", ", or ")

    plt = AoG.data(quality_results) *
          (mapping(:max_quality, [:runtime_ms, :compression_ratio];
                   row=dims(1) => renamer(["Runtime", "Compression ratio"]),
                   col=:speed => nonnumeric)) *
          (mapping(; marker=:image_type, color=:image_type) *
           visual(ScatterLines))
    fig = draw(plt;
               figure=(; size=(1200, 600),
                       title="Runtime & Compression ratio vs speed setting, for `speed` set to $speeds"))
    save(joinpath(bench_dir, "max_quality_quality.png"), fig)

    return nothing
end

function plot_pareto_front(df, title)
    fig = Figure()
    ax = Axis(fig[1, 1];
              xlabel="Runtime (ms)",
              ylabel="Compression Ratio",
              title=title)

    for img_type in unique(df.image_type)
        img_data = filter(r -> r.image_type == img_type && r.quality_ok, df)
        pareto = get_pareto_front(img_data)
        lines!(ax, pareto.runtime_ms, pareto.compression_ratio;
               label=string(img_type))
        scatter!(ax, pareto.runtime_ms, pareto.compression_ratio)
    end
    axislegend(ax; position=:rt)
    return fig
end

function plot_min_quality(results)
    fig = Figure(; size=(1200, 800))

    for (i, min_q) in enumerate([30, 70])
        data = filter(r -> r.min_quality == min_q, results)

        ax = Axis(fig[i, 1];
                  xlabel="Runtime (ms)",
                  ylabel="Compression Ratio",
                  title="Min Quality = $min_q (Pareto)")

        for img_type in unique(data.image_type)
            img_data = filter(r -> r.image_type == img_type && r.quality_ok, data)
            pareto = get_pareto_front(img_data)
            lines!(ax, pareto.runtime_ms, pareto.compression_ratio;
                   label=string(img_type))
            scatter!(ax, pareto.runtime_ms, pareto.compression_ratio)
        end
        axislegend(ax; position=:rt)

        # Add a separate axis to show all data points
        ax2 = Axis(fig[i, 2];
                   xlabel="Runtime (ms)",
                   ylabel="Compression Ratio",
                   title="Min Quality = $min_q (All Points)")
        scatter!(ax2, data.runtime_ms, data.compression_ratio;
                 label=data.image_type)

        axislegend(ax2; position=:rt)
    end

    save(joinpath(bench_dir, "min_quality_pareto.png"), fig)
    return fig
end

function format_pareto_table(pareto_results)
    # Round numeric columns for display
    c = "colors" in names(pareto_results) ? :colors => "Colors" :
        :max_quality => "Max Quality"
    cols = [:runtime_ms => ByRow(x -> round(x; digits=1)) => "Runtime (ms)",
            :compression_ratio => ByRow(x -> round(x; digits=2)) => "Compression",
            c,
            :speed => "Speed",
            :dither => ByRow(x -> round(x; digits=2)) => "Dither"]
    if "posterize" in names(pareto_results)
        push!(cols, :posterize => "Posterize")
    end
    display_df = select(pareto_results, cols...)

    io = IOBuffer()
    pretty_table(io, display_df; tf=tf_markdown, show_subheader=false)
    return String(take!(io))
end

function generate_report(color_results, quality_results, min_quality_results)
    report = """
    # LibImageQuant Benchmark Results

    ## 1. Color Count Analysis

    Here, we assume the user is going to use a fixed number of colors to control the quality of the quantization. How does setting the `speed` affect the compression ratio and runtime speed?

    First, we find that the speed has a large impact on the runtime, and a smaller impact on the compression ratio, at each set of fixed number of colors.

    ![Color Analysis](color_sweep_speed.png)

    The second figure shows the complicated relationship between the number of colors and runtime. The middle number of colors does the best, while small and high can be slower. For compression, smaller colors is also better of course.

    ![Color Analysis](color_sweep_color.png)

    Pareto-optimal configurations (best compression for given runtime for each number of colors):
    """

    for img_type in unique(color_results.image_type)
        report *= "\n### $img_type\n\n"
        img_data = subset(color_results, :quality_ok, :image_type => ByRow(==(img_type)))
        pareto = combine(get_pareto_front, groupby(img_data, :colors))
        report *= format_pareto_table(pareto)
    end

    report *= """

    ## 2. Quality target Impact

    Here we repeat the analysis above, but this time assuming the user will fix the quality target instead of the number of colors. Reducing the target quality has a similar impact to reducing the number of colors, but allows `libimagequant` more flexibility.

    As for the number of colors case, we find that the speed has a large impact on the runtime, and a smaller impact on the compression ratio, at each set of target qualities. Interestingly, we see for the heatmap the compression ratio actually seems to go down with the quality target, suggesting that there may be issues with the heuristics in `libimagequant` for this image type.

    ![Quality Analysis](max_quality_speed.png)

    As before, we can look at how runtime and compression vary with `max_quality` at each `speed` setting. Here we see the runtime and compression ratio vary mostly "as expected" with high `max_qualty` associated with lower compression ratio and higher quality, except for the `heatmap` image type, in which reducing max quality also reduces the compression ratio significantly below 1.

    ![Color Analysis](max_quality_quality.png)

    Pareto-optimal configurations (best compression for given runtime for each quality target):
    """

    for img_type in unique(quality_results.image_type)
        report *= "\n### $img_type\n\n"
        img_data = subset(quality_results, :quality_ok, :image_type => ByRow(==(img_type)))
        pareto = combine(get_pareto_front, groupby(img_data, :max_quality))
        report *= format_pareto_table(pareto)
    end


    report *= """

    ## 3. Optimal Parameters for Fixed Minimum Quality

    Here, we wish to to fix a minimum acceptable quality, and then find the optimal parameters to optimize both runtime and compression ratio jointly in order to meet that minimum quality. Therefore in this section we vary all parameters jointly, at two fixed thresholds of minimum quality.

    ![Minimum Quality Analysis](min_quality_pareto.png)

    """

    for min_q in [30, 70]
        report *= "\n### Minimum Quality = $min_q\n\n"
        for img_type in unique(min_quality_results.image_type)
            report *= "\n#### $img_type\n\n"
            data = filter(r -> r.image_type == img_type &&
                                   r.min_quality == min_q && r.quality_ok,
                          min_quality_results)
            pareto = get_pareto_front(data)
            report *= format_pareto_table(pareto)
        end
    end

    return write(joinpath(bench_dir, "REPORT.md"), report)
end
