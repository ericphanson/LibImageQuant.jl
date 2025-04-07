
# Main execution
test_images = Dict(:scatter => make_test_image(:scatter),
                   :heatmap => make_test_image(:heatmap),
                   :lines => make_test_image(:lines))

color_results = run_color_sweep(test_images)
CSV.write(joinpath(bench_dir, "color_sweep.csv"), color_results)

quality_results = run_quality_sweep(test_images)
CSV.write(joinpath(bench_dir, "quality_sweep.csv"), quality_results)

min_quality_results = run_fixed_min_quality(test_images)
CSV.write(joinpath(bench_dir, "min_quality_sweep.csv"), min_quality_results)

# Generate all plots
plot_color_sweep(color_results)
plot_quality_sweep(quality_results)
plot_pareto_front(color_results, "Pareto Front - Color Sweep")
plot_pareto_front(quality_results, "Pareto Front - Quality Sweep")

plot_pareto_front(min_quality_results, "Pareto Front - Min-quality Sweep")

plot_pareto_front(subset(min_quality_results, :min_quality => ByRow(==(30))),
                  "Min Quality = 30")

plot_pareto_front(subset(min_quality_results, :min_quality => ByRow(==(70))),
                  "Min Quality = 70")

sdf = subset(min_quality_results, :quality_ok, :min_quality => ByRow(==(70)),
             :image_type => ByRow(==("heatmap")))

pareto_settings = get_pareto_front(sdf)[:,
                                        [:image_type, :min_quality, :max_quality, :colors,
                                         :speed, :dither, :posterize]]
pareto_settings.pareto_optimal .= true
leftjoin!(sdf, pareto_settings;
          on=[:image_type, :min_quality, :max_quality, :colors, :speed, :dither,
              :posterize])
@. sdf.pareto_optimal = coalesce(sdf.pareto_optimal, false)
for setting in [:speed, :max_quality, :colors, :dither, :posterize]
    if setting == :colors
        ssdf = subset(sdf, :max_quality => ByRow(==(100)))
    elseif setting == :max_quality
        ssdf = subset(sdf, :colors => ByRow(==(256)))
    else
        ssdf = sdf
    end

    plt = data(ssdf) * mapping(:runtime_ms, :compression_ratio; color=setting) *
          visual(Scatter)
    fig = draw(plt;
               figure=(; size=(1200, 800),
                       title="Pareto Front - Min Quality = 70"))
    path = joinpath(bench_dir, "..", "plots")
    mkpath(path)
    save(joinpath(path, "pareto_front_$(setting).png"), fig)
end

generate_report(color_results, quality_results, min_quality_results)
