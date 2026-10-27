# SnowCH-monthly – Monthly snow cover maps of Switzerland from Landsat and Sentinel-2

Code and auxiliary data to produce **monthly binary snow cover maps of Switzerland at ~30 m resolution**
from all Landsat (5, 7, 8, 9) and Sentinel-2 observations of the [Swiss Data Cube (SDC)](https://www.swissdatacube.org).

The method was developed for the period **1984–2021** with the Open Data Cube version of the SDC.
This repository reproduces it in Python and continues the series **from 2022 to today**, reading the SDC
through its **STAC** catalogue. Each step was checked against the original products (see [Validation](#validation)).

> Large files (DEM, original binary stacks 1984–2021, monthly products 2022–) are on Zenodo:
> **DOI: [to be completed]** – see [Data](#data).

---

## Method in short

For each month:

1. **Monthly NDSI** (`01`) – all clear Landsat and Sentinel-2 observations of the month,
   NDSI = (green − SWIR1) / (green + SWIR1); monthly **max**, min, mean, count and qual.
2. **Snow / no snow / cloud** (`02`, `03`) – a **generalized linear mixed model (GLMM)**, one per season, calibrated with
   snow depth at meteorological stations, converts the monthly **max NDSI** into a probability of snow
   (instead of a fixed NDSI > 0.4 threshold). The probability is made binary with the cutoff that maximizes the TSS.
   Pixels without any clear observation are coded as cloud.
3. **Gap-filling** (`04`, `05`) – six successive steps fill the cloud pixels from elevation, a summer snow mask,
   monthly probability fields, the regional snow line and the neighbouring pixels.

```
SDC (STAC)  ──01──▶  NDSI_<year>_<month>.tif  ──03──▶  Snow_<year>_<month>.tif  ──05──▶  Snow_gapfilled_<year>_<month>.tif
                                                 ▲                                ▲
                       02 (R, lme4): GLMM coefficients          04: monthly probability fields (1984–2021)
```

---

## Repository structure

```
notebooks/
  01_NDSI_monthly_STAC.ipynb            monthly NDSI max/min/mean/count/qual from the SDC STAC catalogue
  02_fit_snow_GLMM.R                    fit of the 4 seasonal GLMMs (lme4) -> data/model/glmm_R_coefs_saisons.csv
  03_snow_GLMM_monthly.ipynb            binary monthly product (0 / 1 / 2) with the GLMM coefficients
  04_monthly_probability_fields.ipynb   monthly probability fields from the 1984–2021 binary products (run once)
  05_gapfilling_steps2-7.ipynb          gap-filling steps 2 to 7 -> final monthly product
utils/
  sdc_stac_utilities.py                 STAC loading, Landsat C2 / Sentinel-2 cloud masks, chunking, GeoTIFF writing
  snow_gapfill.py                       gap-filling steps 2 to 7
data/
  stations/dfCP.rds                     station data used to fit the GLMM (NDSI at the stations + snow depth)
  model/glmm_R_coefs_saisons.csv        GLMM coefficients and cutoffs (output of 02)
  aux/                                  layers on the NDSI grid: Switzerland / lake masks, land cover, elevation classes,
                                        summer snow mask, 12 monthly probability fields
  sources/                              Switzerland border (swissBOUNDARIES3D), lakes, Mask_all, predstack_saison
original_R/                             original R scripts and Python notebooks of the 1984–2021 products (reference)
outputs/                                created by the notebooks
```

The notebooks are run from the `notebooks/` folder; all paths are relative to it.
The text of the notebooks is in French; code and comments are in English.

---

## Data

| In this repository (`data/`) | |
|---|---|
| `stations/dfCP.rds` | 14,010 station observations 2014–2020 (510 stations): date, NDSI, snow depth (cm), elevation, land cover, season |
| `model/glmm_R_coefs_saisons.csv` | fixed and random effects (AltC, Landcover) of the 4 seasonal GLMMs, TSS-optimal cutoff |
| `aux/mask_all_ndsi_grid.tif` | 1 = Switzerland without lakes (the original `Mask_all`) |
| `aux/landcover_ndsi_grid.tif`, `aux/altc_ndsi_grid.tif` | land cover (1 non forested, 2 sparsely forested, 3 forested) and elevation classes (1: < 500 m … 6: ≥ 2500 m) |
| `aux/summer_mask_80.tif` | 1 = snow every summer (glaciers, permanent snow) |
| `aux/proba_field_MM.tif` | monthly probability field of calendar month MM: 1 = snow in 100 % of the clear years, 2 = no snow in 100 % of the clear years (≥ 29 clear years, 1984–2021) |
| `aux/mask_suisse_*.tif`, `aux/mask_lacs_*.tif` | Switzerland and lake masks used for the NDSI products |

| On Zenodo (DOI: to be completed) | |
|---|---|
| `DEM/DEM_final_corrected.tif` | DEM used by the gap-filling (to put in `data/DEM/`) |
| `original_binary_stacks/raster_stack_predi_*.tif` | binary products 1984–2021 of the original series, per season (to put in `data/original_binary_stacks/`, needed only by `04`) |
| `products/Snow_monthly_binary/` | binary monthly products 2022– (output of `03`) |
| `products/Snow_monthly_gapfilled/` | final gap-filled monthly products 2022– (output of `05`) and their statistics |

The monthly NDSI products (~0.5 GB per month) are not archived: they can be recomputed with `01`.

---

## Workflow

### Installation

```bash
conda env create -f environment.yml
conda activate snowch
```

Download the Zenodo files into `data/DEM/` and (optionally) `data/original_binary_stacks/`.

### 01 – Monthly NDSI from the SDC STAC catalogue

* **Catalogue:** `https://explorer.swissdatacube.org/stac`.
* **Sensors and periods:**

  | Collection | Sensor | Period used |
  |---|---|---|
  | `landsat_tm_c2_l2` | Landsat 5 | 1984–2011 |
  | `landsat_etm_c2_l2` | Landsat 7 | until 30 May 2003 (SLC failure) |
  | `landsat_ot_c2_l2` | Landsat 8 and 9 | 2013– |
  | `s2_l2` | Sentinel-2 | June 2015– |
* **Reflectance and bands:**
  * Landsat Collection 2 surface reflectance = DN × 0.0000275 − 0.2;
  * Sentinel-2 = DN / 10,000;
  * green / SWIR1 = SR_B2 / SR_B5 (L5, L7), SR_B3 / SR_B6 (L8, L9), B03 / B11 (S2);
  * negative reflectances are removed.
* **Cloud masks:**
  * **Landsat** (`QA_PIXEL`): clear, water or snow pixels, with cloud and cirrus confidence ≤ low, and no fill, cloud, dilated cloud, cirrus or cloud shadow;
  * **Sentinel-2** (`SCL`): classes 4, 5, 6, 7, 11 (vegetation, not vegetated, water, unclassified, snow).
* **Grid:** EPSG:4326, 14234 × 6199 pixels of 0.00034074° × 0.00034047° (~30 m), the grid of the original products. Sentinel-2 is resampled with cubic interpolation, the masks with nearest neighbour. Switzerland is processed in latitude chunks of 0.5 square degrees.
* **Output:** `NDSI_<year>_<month>.tif`, 5 bands:
  * `max`, `min`, `mean`;
  * `count` = number of clear observations;
  * `qual` = count / number of dates × 100.

  Months already computed are skipped. Files listed in the catalogue but missing on the storage (HTTP 404) are skipped with a warning.

### 02 – GLMM (R)

One model per season, fitted with `lme4` on `data/stations/dfCP.rds`:

```
ThrX ~ NDSI + (NDSI | Stations) + (NDSI | AltC) + (NDSI | Landcover)
```

* **`ThrX`:** snow depth ≥ threshold of the season, which is **1 cm (DJF), 5 cm (MAM), 15 cm (JJA), 15 cm (SON)**.
* **Prediction:** fixed effect + random effects of elevation class and land cover (station effect excluded).
* **Cutoff:** the probability threshold (0, 0.05, …, 1) that maximizes the TSS, giving DJF 0.75, MAM 0.45, JJA 0.60, SON 0.05.

The coefficients are written to `data/model/glmm_R_coefs_saisons.csv` and used in Python.

### 03 – Binary monthly product

p = 1 / (1 + exp(−[(b0 + u_AltC + u_LC) + (b1 + v_AltC + v_LC) × NDSI_max])), with the model of the season of the month.

Output `Snow_<year>_<month>.tif` (uint8):

| Code | Meaning |
|---|---|
| 0 | no snow |
| 1 | snow (p ≥ cutoff) |
| 2 | cloud / no data |
| 255 | lake or outside Switzerland |

Statistics per month (probability min/median/mean/max, number of snow, no snow and cloud pixels) are written to an Excel file.

### 04 – Monthly probability fields (run once)

* **Input:** the binary products of 1984–2021 (Zenodo).
* **Rule:** for each calendar month, a pixel is set to
  * 1 if it is snow in 100 % of its clear years;
  * 2 if it is no snow in 100 % of its clear years;
  * with at least 29 clear years required.
* **Outputs:** `data/aux/proba_field_MM.tif`, and NetCDF files named as in the original R script (`January.nc`, `January_a.nc`, …).

### 05 – Gap-filling (steps 2 to 7)

| Step | Rule |
|---|---|
| 2 | in each 100 m elevation band ≤ 600 m (DJF) or ≤ 1000 m (other seasons) with < 1 % of snow, snow → 0 (false snow at low elevation) |
| 3 | cloud and summer mask = 1 → snow |
| 4 | cloud, field = 1 and elevation > min(elevation of field = 1) + 500 m → snow (100); cloud, field = 2 and elevation < max(elevation of field = 2) − 500 m → no snow (200) |
| 5 | snow line, only if cloud ≤ 40 % and snow ≥ 1 %: HSmin = lowest 100 m band with snow (bands with > 10 % clear pixels and > 0.1 % snow; > 1 % in summer for the eastern half); clouds below HSmin → 200. HSmax = lowest snow band above the highest no-snow pixel; clouds above HSmax → 100 |
| 6 | repeated until no change: cloud with ≥ 3 of its 4 neighbours snow → 100, ≥ 3 of 4 no snow → 200 |
| 7 | repeated until no change: cloud with a snow neighbour (8-connectivity) at a lower elevation → 100 |

**How the steps are computed:**
* As in the original products, steps 2 and 4 to 7 are computed separately for the **western and eastern halves** of the grid (columns 0–7116 and 7117–14233).
* Steps 6 and 7 do not fill the first and last rows and columns of each half.
* Steps 6 and 7 only re-examine the clouds next to the pixels changed in the previous iteration. The result is identical to re-scanning the whole raster, and a month takes ~20 s for all of Switzerland.

**DEM:** `DEM_final` of the original products. About 15,500 pixels that differ by more than 600 m from swissALTI3D (holes filled with 0–230 m in the Alps) are replaced by swissALTI3D (`DEM_final_corrected.tif`).

**Output:** `Snow_gapfilled_<year>_<month>.tif` (uint8):

| Code | Meaning |
|---|---|
| 0 | no snow |
| 1 | snow |
| 2 | cloud (not filled) |
| 100 | snow (filled) |
| 200 | no snow (filled) |
| 255 | lake or outside Switzerland |

`Snow_gapfilling_stats.xlsx` gives, for each month and step, the % of cloud, snow and no snow before and after the step, the cloud reduction, HSmin and HSmax.

### Updating the series

Run `01`, `03` and `05` again: only the new months are computed.
Recent months may be incomplete in the SDC (e.g. the Landsat scenes of September 2026 at the time of writing). Delete their files to recompute them later.

---

## Validation

The Python workflow was compared with the original products (R / Open Data Cube), using the **same inputs**:

| Step | Comparison | Result |
|---|---|---|
| GLMM + binary product | November 2020, Python with the R coefficients vs. the original R map | 98.9 % identical pixels (the difference comes from the 6199 vs. 6200 rows of the grids) |
| Monthly probability fields | % of pixels per month vs. the original R script | identical within 0.003 % |
| Step 2 | 44 months (DJF, western half) | identical pixel by pixel |
| Step 3 | 44 months | identical (cloud pixels identical pixel by pixel) |
| Steps 4–7 | 24 months × 2 halves (all seasons, 1985–2021) vs. the original statistics | cloud / snow / no-snow % identical within 0.01 % |
| Step 5 | HSmin / HSmax, 1985–2021 | identical (JJA: 90/90 months western half with 0.1 %, 85/85 eastern half with 1 %) |

The remaining 0.01 % differences come from the 100 m elevation bands (`DEM100`), which are 99.9 % identical to the original ones (the original file was lost).

**STAC vs. Open Data Cube** (November 2020):
* The STAC catalogue contains **more Sentinel-2 observations** than the former SDC: in the median, 4 clear observations per pixel vs. 2.
* The binary product therefore has fewer clouds: 7.6 % vs. 12.1 % (western half), 6.9 % vs. 12.6 % (eastern half).
* The monthly maximum is slightly higher, since there are more chances to observe snow.
* Sentinel-2 Scene Classification sometimes labels clouds as snow (class 11), which is kept as valid, as in the original method.

---

## Citation

If you use this code or the products, please cite:

* Poussin, C. et al. (to be completed) – article describing the method.
* Zenodo record of the data (DOI to be completed).

GLMM: P. Timoner and C. Poussin (2021). Swiss Data Cube: UNEP/GRID-Geneva and University of Geneva.

## License

Code: MIT (see `LICENSE`). Data: see the Zenodo record.
