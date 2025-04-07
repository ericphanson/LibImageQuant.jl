# LibImageQuant benchmarking

Here we aim to answer three questions:

1. how does the compression ratio and runtime speed vary as we change the maximum number of colors used in image quantization? We can expect fewer colors may require more work to find the best palette, but achieve a better compression ratio. Depending on the plot, we also expect limiting the colors to compromise image quality, but we won't assess that here.
2. how does the compression ratio and runtime speed vary as we change the target quality used in image quantization? We can expect lower target quality may require more work to find the best palette, but achieve a better compression ratio.
3. given a fixed minimum quality, what is the pareto front of settings to achieve the best tradeoffs between runtime speed and compression ratio?

All three of these questions will depend on the plot type, so we will try scatter plots, line plots, and heatmaps.

For question (1), we will use minimum quality 0, so that we don't reject plots for bad quality, and leave the maximum quality at 100 so we are optimizing based on number of colors only. We will assess by a line plot showing speed vs number of colors, one showing compression ratio vs number of colors, and one showing the pareto front of speed vs compression ratio. We will also show the settings used for each plot in a table. We will use 8, 16, 32, 64, 128, and 256 colors. The dither setting will be set to 1.0 (the default) and posterize to 0 (the default).

For question (2), we will leave the number of colors at 256, and the minimum quality at 0, only changing the maximum quality. We will assess by a line plot showing speed vs maximum quality, one showing compression ratio vs maximum quality, and one showing the pareto front of speed vs compression ratio. We will also show the settings used for each plot in a table. We will use 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, and 100 as maximum qualities. The dither setting will be set to 1.0 (the default) and posterize to 0 (the default).

For (3), we will fix the minimum quality at either 30 or 70. Then we will vary either the maximum quality OR the number of colors, as well as the other settings, to see the effect on speed and compression ratio. We will modify both dithering and posterization settings as well, and jointly assess the effect of all four settings on speed and compression ratio. We will show the pareto front of speed vs compression ratio, and a table showing the settings used for each plot. We will use 8, 16, 32, 64, 128, and 256 colors. The dither setting will be set to 0.0, 0.5, or 1.0 (the default) and posterize to 0, 1, 2, 3, or 4.
