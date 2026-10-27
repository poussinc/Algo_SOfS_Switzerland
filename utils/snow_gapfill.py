"""
Gap-filling of the monthly binary snow products (steps 3 to 7), numpy version of the notebooks
Step/Step3_Summer_mask, Step4_Monthly proba fields, Step5_SL, STEP6_4nb and STEP7_8nb.

Codes of the snow rasters (uint8):
    0   = no snow (land)                 1   = snow
    2   = cloud / no data                100 = snow filled by a gap-filling step
    200 = land filled by a gap-filling step
    255 = NA (lakes, outside Switzerland)  (NaN in the original notebooks)

The rules are those of the original notebooks; only the implementation changes:
whole Switzerland at once (no a/b halves), and the iterative neighbour steps only re-examine
the cloud pixels next to the pixels changed in the previous iteration (same result as
re-scanning the whole raster, much faster).
"""

import numpy as np

NA = 255


def is_snow(a):
    return (a == 1) | (a == 100)


def is_land(a):
    return (a == 0) | (a == 200)


def percentages(a):
    """cloud, snow and land percentages of the valid pixels (as compute_*percent_b/_a)."""
    tot = np.count_nonzero(a != NA)
    return (round(100 * np.count_nonzero(a == 2) / tot, 2),
            round(100 * np.count_nonzero(is_snow(a)) / tot, 2),
            round(100 * np.count_nonzero(is_land(a)) / tot, 2))


def stats_row(step, before, after, extra=None):
    """One line of the statistics table of a step (as the df_step* Excel files)."""
    cb, sb, lb = percentages(before)
    ca, sa, la = percentages(after)
    nb = np.count_nonzero(before == 2)
    na = np.count_nonzero(after == 2)
    row = {'Step': step,
           'Cloud Percent Before': cb, 'Snow Percent Before': sb, 'Land Percent Before': lb,
           'Cloud Percent After': ca, 'Snow Percent After': sa, 'Land Percent After': la,
           'Cloud Reduction (%)': round(cb - ca, 2),
           'Cloud Reduction After (%)': round(100 * (nb - na) / nb, 2) if nb else 0.0}
    if extra:
        row.update(extra)
    return row


# ------------------------------------------------------------------ step 2: false snow at low elevation
def step2_low_snow(snow, dem100, max_alt, low_snow_pct=1):
    """
    DEM100 bands <= max_alt (600 m in DJF) with < 1 % of snow (1) -> this snow becomes 0.
    The percentage is computed on all the pixels of the band that have an elevation (lakes
    included), as (snow == 1).groupby(DEM100).mean() in the original notebook.
    Checked against snow_final3 of NDSI_DJF_monthlyproba_a (44 months, 0 pixel of difference).
    """
    out = snow.copy()
    dv = np.isfinite(dem100)
    bands, inv = np.unique(dem100[dv], return_inverse=True)
    n = np.bincount(inv)
    k = np.bincount(inv, weights=(snow[dv] == 1))
    low = bands[(100 * k / n < low_snow_pct) & (bands <= max_alt)]
    out[(snow == 1) & np.isin(dem100, low)] = 0
    return out, {'Bands snow->0': ', '.join('%d' % b for b in low)}


# ------------------------------------------------------------------ step 3: summer mask
def step3_summer_mask(snow, summer_mask, value=1):
    """Cloud pixels where the summer mask is 1 (snow every summer) -> snow.
    value = 1 as in snow_final3 of the original products (the notebook Step3 wrote 100)."""
    out = snow.copy()
    out[(summer_mask == 1) & (snow == 2)] = value
    return out, {}


# ------------------------------------------------------------------ step 4: monthly probability fields
def step4_monthly_proba(snow, proba_mask, dem, use_land=True):
    """
    proba_mask of the calendar month: 1 = snow probable, 2 = no snow probable.
    Snow: cloud & mask == 1 & DEM > min(DEM of mask==1) + 500 m -> 100
    Land: cloud & mask == 2 & DEM < max(DEM of mask==2) - 500 m -> 200
    """
    out = snow.copy()
    info = {}
    m1 = proba_mask == 1
    if m1.any():
        hs = np.nanmin(dem[m1]) + 500
        out[(snow == 2) & (dem > hs) & m1] = 100
        info['HSmin500'] = float(hs)
    m2 = proba_mask == 2
    if use_land and m2.any():
        hl = np.nanmax(dem[m2]) - 500
        out[(out == 2) & (dem < hl) & m2] = 200
        info['HLmax500'] = float(hl)
    return out, info


# ------------------------------------------------------------------ step 5: snowline
def _band_percent(cond, dem100, valid):
    """percentage of pixels verifying cond in each DEM100 band (as groupby(DEM100).mean() * 100)."""
    bands, inv = np.unique(dem100[valid], return_inverse=True)
    n = np.bincount(inv)
    k = np.bincount(inv, weights=cond[valid])
    return bands, 100 * k / n


def step5_snowline(snow, dem100, max_cloud=40, min_snow=1, low_alt=1000, low_snow_pct=1, low_bands=False,
                   snow_band_pct=0.1):
    """
    a) (only if low_bands=True, otherwise done in step 2) DEM100 bands <= 1000 m with < 1 % of snow -> 0
    b) only if cloud <= 40 % and snow >= 1 %:
       HSmin = lowest DEM100 band with snow, among bands with > 10 % clear pixels and > 0.1 % snow
               -> cloud & DEM100 < HSmin -> 200
       HSmax = lowest DEM100 band with snow above the highest no-snow pixel (bands > 10 % clear)
               -> cloud & DEM100 > HSmax -> 100
    """
    # percentages per band on the pixels with an elevation and a value (lakes excluded): checked against
    # the HS Min / HS Max of the original Excel files (2020-2021, 40/46 HS Min and 46/46 HS Max identical;
    # the 6 others are JJA east half, reproduced with snow_band_pct = 1)
    valid = np.isfinite(dem100) & (snow != NA)
    a = snow.copy()
    info = {}
    # a) snow_final5 (optional: this rule is now step 2)
    if low_bands:
        bands, pct = _band_percent(a == 1, dem100, valid)
        low = bands[(pct < low_snow_pct) & (bands <= low_alt)]
        a[(a == 1) & np.isin(dem100, low) & valid] = 0
        info['Low bands snow->0'] = len(low)

    cloud_b, snow_b, _ = percentages(a)
    info['Cloud Condition'] = bool(cloud_b <= max_cloud)
    if not (cloud_b <= max_cloud and snow_b >= min_snow):
        info.update({'HS Min': None, 'HS Max': None})
        return a, info

    out = a.copy()
    # HSmin
    bands, ps = _band_percent(is_snow(out), dem100, valid)
    _, pl = _band_percent(is_land(out), dem100, valid)
    clear_bands = bands[(ps + pl) > 10]
    snow_bands = bands[ps > snow_band_pct]
    sel = is_snow(out) & np.isin(dem100, clear_bands) & np.isin(dem100, snow_bands) & valid
    hs_min = float(dem100[sel].min()) if sel.any() else None
    if hs_min is not None:
        out[(out == 2) & (dem100 < hs_min)] = 200
    # HSmax (computed after the HSmin filling, as in the notebook)
    bands, ps = _band_percent(is_snow(out), dem100, valid)
    _, pl = _band_percent(is_land(out), dem100, valid)
    clear_bands = bands[(ps + pl) > 10]
    land_px = is_land(out) & valid
    hs_max = None
    if land_px.any():
        elev_max_nosnow = np.nanmax(dem100[land_px])
        sel = is_snow(out) & (dem100 >= elev_max_nosnow) & np.isin(dem100, clear_bands) & valid
        hs_max = float(dem100[sel].min()) if sel.any() else None
    if hs_max is not None:
        out[(out == 2) & (dem100 > hs_max)] = 100
    info.update({'HS Min': hs_min, 'HS Max': hs_max})
    return out, info


# ------------------------------------------------------------------ steps 6 and 7: neighbours
OFF4 = [(0, -1), (-1, 0), (0, 1), (1, 0)]                                   # W, N, E, S
OFF8 = OFF4 + [(-1, -1), (-1, 1), (1, 1), (1, -1)]                          # + NW, NE, SE, SW


def _neighbours(a, r, c, dr, dc):
    """values of the neighbour (r+dr, c+dc) of the pixels (r, c); NA outside the raster."""
    rr, cc = r + dr, c + dc
    ok = (rr >= 0) & (rr < a.shape[0]) & (cc >= 0) & (cc < a.shape[1])
    v = np.full(r.shape, NA, a.dtype)
    v[ok] = a[rr[ok], cc[ok]]
    return v, rr, cc, ok


def _frontier(a, r, c, offsets):
    """cloud pixels next to the pixels (r, c) (candidates of the next iteration)."""
    rs, cs = [], []
    for dr, dc in offsets:
        _, rr, cc, ok = _neighbours(a, r, c, dr, dc)
        rs.append(rr[ok]); cs.append(cc[ok])
    rr, cc = np.concatenate(rs), np.concatenate(cs)
    keep = a[rr, cc] == 2
    idx = np.unique(rr[keep].astype(np.int64) * a.shape[1] + cc[keep])
    return idx // a.shape[1], idx % a.shape[1]


def _interior(r, c, shape):
    """keep only the pixels inside the array (the original notebooks work on [1:-1, 1:-1])."""
    k = (r > 0) & (r < shape[0] - 1) & (c > 0) & (c < shape[1] - 1)
    return r[k], c[k]


def step6_4nb(snow):
    """
    Repeat until no change: cloud pixel with at least 3 of its 4 neighbours (W, N, E, S)
    snow -> 100, with at least 3 of 4 neighbours land -> 200 (simultaneous update).
    The border rows / columns of the array are not filled (as [1:-1, 1:-1] in STEP6_4nb).
    """
    a = snow.copy()
    r, c = _interior(*np.nonzero(a == 2), a.shape)
    it = 0
    while r.size:
        ns = np.zeros(r.shape, np.int8); nl = np.zeros(r.shape, np.int8)
        for dr, dc in OFF4:
            v, *_ = _neighbours(a, r, c, dr, dc)
            ns += is_snow(v); nl += is_land(v)
        ms, ml = ns >= 3, nl >= 3
        if not (ms.any() or ml.any()):
            break
        a[r[ms], c[ms]] = 100
        a[r[ml], c[ml]] = 200
        ch = ms | ml
        r, c = _interior(*_frontier(a, r[ch], c[ch], OFF4), a.shape)
        it += 1
    return a, {'Iterations': it}


def step7_8nb(snow, dem100):
    """
    Repeat until no change: cloud pixel with at least one of its 8 neighbours snow AND
    a higher elevation (DEM100) than this neighbour -> 100 (snow spreads uphill).
    """
    a = snow.copy()
    d = np.where(np.isfinite(dem100), dem100, np.inf)     # no elevation -> never lower than a pixel
    r, c = _interior(*np.nonzero(a == 2), a.shape)         # border not filled, as [1:-1, 1:-1] in STEP7_8nb
    it = 0
    while r.size:
        m = np.zeros(r.shape, bool)
        h = d[r, c]
        for dr, dc in OFF8:
            v, rr, cc, ok = _neighbours(a, r, c, dr, dc)
            hn = np.full(r.shape, np.inf); hn[ok] = d[rr[ok], cc[ok]]
            m |= is_snow(v) & (h > hn)
        m &= np.isfinite(dem100[r, c])
        if not m.any():
            break
        a[r[m], c[m]] = 100
        r, c = _interior(*_frontier(a, r[m], c[m], OFF8), a.shape)
        it += 1
    return a, {'Iterations': it}
