# LibImageQuant Benchmark Results

## 1. Color Count Analysis

Here, we assume the user is going to use a fixed number of colors to control the quality of the quantization. How does setting the `speed` affect the compression ratio and runtime speed?

First, we find that the speed has a large impact on the runtime, and a smaller impact on the compression ratio, at each set of fixed number of colors.

![Color Analysis](color_sweep_speed.png)

The second figure shows the complicated relationship between the number of colors and runtime. The middle number of colors does the best, while small and high can be slower. For compression, smaller colors is also better of course.

![Color Analysis](color_sweep_color.png)

Pareto-optimal configurations (best compression for given runtime for each number of colors):

### scatter

| Runtime (ms) | Compression | Colors | Speed | Dither |
|--------------|-------------|--------|-------|--------|
|         18.4 |        2.15 |      8 |     8 |    1.0 |
|         32.6 |        2.76 |      8 |     6 |    1.0 |
|         17.9 |        2.43 |     32 |    10 |    1.0 |
|         17.9 |        2.48 |     64 |     8 |    1.0 |
|         38.0 |        2.49 |     64 |     1 |    1.0 |
|         17.6 |        2.33 |    128 |    10 |    1.0 |
|         33.0 |        2.35 |    128 |     6 |    1.0 |
|         33.4 |        2.36 |    128 |     4 |    1.0 |
|         37.9 |        2.37 |    128 |     1 |    1.0 |
|         18.0 |        2.21 |    256 |    10 |    1.0 |
|         33.8 |        2.23 |    256 |     6 |    1.0 |
|         35.7 |        2.23 |    256 |     4 |    1.0 |
|         40.4 |        2.23 |    256 |     1 |    1.0 |

### heatmap

| Runtime (ms) | Compression | Colors | Speed | Dither |
|--------------|-------------|--------|-------|--------|
|         32.2 |         0.2 |      8 |     8 |    1.0 |
|         19.3 |        1.88 |     32 |     8 |    1.0 |
|         33.7 |        2.27 |     32 |     6 |    1.0 |
|         38.6 |         2.3 |     32 |     1 |    1.0 |
|         18.7 |        2.55 |     64 |     8 |    1.0 |
|         33.9 |        2.69 |     64 |     6 |    1.0 |
|         35.0 |         2.7 |     64 |     4 |    1.0 |
|         38.3 |        2.71 |     64 |     1 |    1.0 |
|         18.4 |        2.49 |    128 |    10 |    1.0 |
|         33.0 |        2.57 |    128 |     6 |    1.0 |
|         34.1 |        2.58 |    128 |     4 |    1.0 |
|         18.6 |        2.43 |    256 |     8 |    1.0 |
|         33.9 |         2.5 |    256 |     6 |    1.0 |

### lines

| Runtime (ms) | Compression | Colors | Speed | Dither |
|--------------|-------------|--------|-------|--------|
|         23.6 |        3.88 |      8 |    10 |    1.0 |
|         37.3 |        4.33 |      8 |     6 |    1.0 |
|         44.7 |        4.34 |      8 |     1 |    1.0 |
|         22.4 |        3.02 |     32 |    10 |    1.0 |
|         37.0 |        3.47 |     32 |     6 |    1.0 |
|         38.5 |        3.47 |     32 |     4 |    1.0 |
|         44.9 |        3.47 |     32 |     1 |    1.0 |
|         22.4 |        2.89 |     64 |    10 |    1.0 |
|         37.5 |        2.96 |     64 |     6 |    1.0 |
|         40.3 |        2.97 |     64 |     4 |    1.0 |
|         46.7 |        2.98 |     64 |     1 |    1.0 |
|         22.9 |        2.67 |    128 |     8 |    1.0 |
|         38.4 |        2.69 |    128 |     6 |    1.0 |
|         40.8 |         2.7 |    128 |     4 |    1.0 |
|         23.2 |        2.53 |    256 |    10 |    1.0 |
|         38.8 |        2.58 |    256 |     6 |    1.0 |
|         44.1 |        2.59 |    256 |     4 |    1.0 |

## 2. Quality target Impact

Here we repeat the analysis above, but this time assuming the user will fix the quality target instead of the number of colors. Reducing the target quality has a similar impact to reducing the number of colors, but allows `libimagequant` more flexibility.

As for the number of colors case, we find that the speed has a large impact on the runtime, and a smaller impact on the compression ratio, at each set of target qualities. Interestingly, we see for the heatmap the compression ratio actually seems to go down with the quality target, suggesting that there may be issues with the heuristics in `libimagequant` for this image type.

![Quality Analysis](max_quality_speed.png)


![Color Analysis](max_quality_quality.png)


Pareto-optimal configurations (best compression for given runtime for each quality target):

### scatter

| Runtime (ms) | Compression | Max Quality | Speed | Dither |
|--------------|-------------|-------------|-------|--------|
|         19.0 |        2.64 |           0 |    10 |    1.0 |
|         43.3 |        4.12 |           0 |     6 |    1.0 |
|         18.5 |        1.67 |          20 |    10 |    1.0 |
|         33.0 |        2.66 |          20 |     6 |    1.0 |
|         18.3 |        1.74 |          40 |    10 |    1.0 |
|         33.1 |        2.54 |          40 |     6 |    1.0 |
|         33.5 |        2.54 |          40 |     4 |    1.0 |
|         38.4 |        2.55 |          40 |     1 |    1.0 |
|         17.9 |        1.89 |          60 |     8 |    1.0 |
|         32.5 |        2.01 |          60 |     6 |    1.0 |
|         36.9 |        2.02 |          60 |     1 |    1.0 |
|         17.8 |        2.25 |          80 |    10 |    1.0 |
|         18.2 |        2.21 |         100 |     8 |    1.0 |
|         33.8 |        2.23 |         100 |     6 |    1.0 |
|         35.4 |        2.23 |         100 |     4 |    1.0 |
|         40.7 |        2.23 |         100 |     1 |    1.0 |

### heatmap

| Runtime (ms) | Compression | Max Quality | Speed | Dither |
|--------------|-------------|-------------|-------|--------|
|         30.7 |        0.26 |           0 |    10 |    1.0 |
|         45.5 |        0.46 |           0 |     6 |    1.0 |
|         28.7 |         0.3 |          20 |    10 |    1.0 |
|         42.3 |        0.32 |          20 |     6 |    1.0 |
|         42.9 |        0.32 |          20 |     4 |    1.0 |
|         27.5 |        0.25 |          40 |     8 |    1.0 |
|         40.9 |        0.27 |          40 |     6 |    1.0 |
|         41.2 |        0.27 |          40 |     4 |    1.0 |
|         26.0 |        0.29 |          60 |    10 |    1.0 |
|         40.7 |        0.32 |          60 |     6 |    1.0 |
|         42.4 |        0.32 |          60 |     4 |    1.0 |
|         24.3 |         0.4 |          80 |    10 |    1.0 |
|         38.5 |        0.43 |          80 |     4 |    1.0 |
|         18.5 |        2.43 |         100 |     8 |    1.0 |
|         33.7 |         2.5 |         100 |     6 |    1.0 |

### lines

| Runtime (ms) | Compression | Max Quality | Speed | Dither |
|--------------|-------------|-------------|-------|--------|
|         34.1 |        4.14 |           0 |     8 |    1.0 |
|         45.9 |        7.74 |           0 |     6 |    1.0 |
|         23.4 |        3.37 |          20 |     8 |    1.0 |
|         36.8 |        3.58 |          20 |     6 |    1.0 |
|         38.6 |        3.66 |          20 |     4 |    1.0 |
|         22.6 |        2.98 |          40 |    10 |    1.0 |
|         36.9 |        3.47 |          40 |     6 |    1.0 |
|         39.3 |         3.5 |          40 |     4 |    1.0 |
|         22.2 |        2.84 |          60 |     8 |    1.0 |
|         37.7 |        3.22 |          60 |     6 |    1.0 |
|         22.7 |        2.75 |          80 |    10 |    1.0 |
|         38.0 |        2.75 |          80 |     6 |    1.0 |
|         40.7 |        2.77 |          80 |     4 |    1.0 |
|         23.2 |        2.53 |         100 |    10 |    1.0 |
|         39.6 |        2.58 |         100 |     6 |    1.0 |
|         43.1 |        2.59 |         100 |     4 |    1.0 |

## 3. Optimal Parameters for Fixed Minimum Quality

This section identifies the Pareto-optimal configurations when requiring minimum
quality thresholds. These represent the best achievable compression ratios for
different runtime targets while maintaining quality requirements.

![Minimum Quality Analysis](min_quality_pareto.png)


### Minimum Quality = 30


#### scatter

| Runtime (ms) | Compression | Colors | Speed | Dither | Posterize |
|--------------|-------------|--------|-------|--------|-----------|
|         22.5 |        3.34 |     16 |     1 |    0.0 |         4 |
|         22.6 |        3.78 |      8 |     1 |    0.0 |         4 |

#### heatmap

| Runtime (ms) | Compression | Colors | Speed | Dither | Posterize |
|--------------|-------------|--------|-------|--------|-----------|
|         23.9 |        3.39 |     32 |     1 |    0.0 |         3 |
|         23.9 |        3.59 |     16 |     1 |    0.0 |         3 |
|         24.5 |         3.6 |     16 |     1 |    0.0 |         2 |

#### lines

| Runtime (ms) | Compression | Colors | Speed | Dither | Posterize |
|--------------|-------------|--------|-------|--------|-----------|
|         27.2 |        3.27 |     64 |     1 |    0.0 |         4 |
|         27.3 |        3.66 |     32 |     1 |    0.0 |         4 |

### Minimum Quality = 70


#### scatter

| Runtime (ms) | Compression | Colors | Speed | Dither | Posterize |
|--------------|-------------|--------|-------|--------|-----------|
|         22.9 |        3.12 |     64 |     1 |    0.0 |         4 |
|         23.3 |        3.34 |     16 |     1 |    0.0 |         4 |

#### heatmap

| Runtime (ms) | Compression | Colors | Speed | Dither | Posterize |
|--------------|-------------|--------|-------|--------|-----------|
|         24.8 |         3.4 |     32 |     1 |    0.0 |         4 |

#### lines

| Runtime (ms) | Compression | Colors | Speed | Dither | Posterize |
|--------------|-------------|--------|-------|--------|-----------|
|         27.8 |        3.27 |     64 |     1 |    0.0 |         4 |
