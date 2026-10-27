"""
STAC replacements of the SDC utilities used by CP_NDSI_CH_Basic.ipynb
(utils.data_cube_utilities and swiss_utils.data_cube_utilities, no longer installed).

Same function names and arguments as the datacube versions, so that the notebook
CP_NDSI_CH_STAC.ipynb keeps the structure of CP_NDSI_CH_Basic.ipynb:

  open_catalog                  -> replaces datacube.Datacube() (dc)
  stac_load_product             -> replaces dc.load (one product, one chunk, one period)
  ls_qa_clean                   -> Landsat Collection 2 QA_PIXEL version
  create_slc_clean_mask         -> Sentinel-2 SCL (unchanged)
  create_geographic_chunks      -> as utils.data_cube_utilities.dc_chunker
  combine_geographic_chunks     -> as utils.data_cube_utilities.dc_chunker
  printandlog, write_geotiff_from_xr, display_map

Products (SDC STAC collections) and generic band names:
  landsat_tm_c2_l2  (Landsat 5)   green = SR_B2, swir1 = SR_B5, pixel_qa = QA_PIXEL
  landsat_etm_c2_l2 (Landsat 7)   green = SR_B2, swir1 = SR_B5, pixel_qa = QA_PIXEL
  landsat_ot_c2_l2  (Landsat 8/9) green = SR_B3, swir1 = SR_B6, pixel_qa = QA_PIXEL
  s2_l2             (Sentinel-2)  green = B03,   swir1 = B11,   slc = SCL
Reflectance is returned as surface reflectance (0-1):
  Landsat C2: DN * 0.0000275 - 0.2 ; Sentinel-2: DN / 10000 (no +1000 offset in the SDC).
"""

import sys
import math
import logging
import calendar
from datetime import datetime

import numpy as np
import xarray as xr
import rasterio

STAC_URL = "https://explorer.swissdatacube.org/stac"

PRODUCTS = {
    "landsat_tm_c2_l2":  {"platform": "LANDSAT_5", "green": "SR_B2", "swir1": "SR_B5", "nir": "SR_B4", "red": "SR_B3", "pixel_qa": "QA_PIXEL"},
    "landsat_etm_c2_l2": {"platform": "LANDSAT_7", "green": "SR_B2", "swir1": "SR_B5", "nir": "SR_B4", "red": "SR_B3", "pixel_qa": "QA_PIXEL"},
    "landsat_ot_c2_l2":  {"platform": "LANDSAT_8_9", "green": "SR_B3", "swir1": "SR_B6", "nir": "SR_B5", "red": "SR_B4", "pixel_qa": "QA_PIXEL"},
    "s2_l2":             {"platform": "SENTINEL_2", "green": "B03", "swir1": "B11", "nir": "B08", "red": "B04", "slc": "SCL"},
}
MASK_BANDS = ("pixel_qa", "slc")


# ------------------------------------------------------------------ catalogue (replaces dc)
def _rewrite(obj):
    """Some SDC STAC assets still expose the internal :8080 host."""
    if hasattr(obj, "assets"):
        for a in obj.assets.values():
            if a.href:
                a.href = a.href.replace("http://explorer.swissdatacube.org:8080",
                                        "https://explorer.swissdatacube.org")


def open_catalog():
    import pystac_client
    return pystac_client.Client.open(STAC_URL, modifier=_rewrite)


def get_platform(products):
    return [PRODUCTS[p]["platform"] for p in products]


def _period(time):
    """[start_date, end_date] (datetime or str) -> STAC datetime string, both days included."""
    t0, t1 = [t.strftime("%Y-%m-%d") if hasattr(t, "strftime") else str(t)[:10] for t in time]
    return "%s/%s" % (t0, t1)


def national_geobox(min_lon, max_lon, min_lat, max_lat, resolution):
    """GeoBox of the whole area (EPSG:4326) with the given (x, y) resolution in degrees."""
    from odc.geo.geobox import GeoBox
    from rasterio.transform import from_origin
    rx, ry = abs(resolution[0]), abs(resolution[1])
    w = int(round((max_lon - min_lon) / rx))
    h = int(round((max_lat - min_lat) / ry))
    return GeoBox((h, w), from_origin(min_lon, max_lat, rx, ry), "EPSG:4326")


def _sub_geobox(gbox, lon, lat):
    """Part of the national GeoBox covering the lon/lat chunk (same pixel grid)."""
    inv = ~gbox.affine
    c0, r0 = inv * (min(lon), max(lat))
    c1, r1 = inv * (max(lon), min(lat))
    c0, r0 = max(int(math.floor(c0 + 1e-6)), 0), max(int(math.floor(r0 + 1e-6)), 0)
    c1, r1 = min(int(math.ceil(c1 - 1e-6)), gbox.shape[1]), min(int(math.ceil(r1 - 1e-6)), gbox.shape[0])
    return gbox[r0:r1, c0:c1], (r0, r1, c0, c1)


def _clip_period(time, period):
    """Intersection of [start, end] with the period of use of a product, or None."""
    t0, t1 = [t.strftime("%Y-%m-%d") if hasattr(t, "strftime") else str(t)[:10] for t in time]
    if period is not None:
        t0, t1 = max(t0, period[0]), min(t1, period[1])
    return None if t0 > t1 else [t0, t1]


def stac_load_product(catalog, product, time, lon, lat, measurements, gbox, resampling,
                      period=None, platforms_keep=None):
    """
    Equivalent of dc.load(product=..., time=..., lon=..., lat=..., measurements=...,
    resolution=..., resampling=...) on the national pixel grid `gbox`.
    Returns an xarray.Dataset (time, latitude, longitude) with generic band names
    (green, swir1, ..., pixel_qa or slc), reflectance scaled to 0-1, or an empty Dataset.
    """
    from odc.stac import stac_load
    bmap = PRODUCTS[product]
    # period of use of the product (e.g. Landsat 7 only before the SLC failure)
    time = _clip_period(time, period)
    if time is None:
        return xr.Dataset()
    items = list(catalog.search(collections=[product],
                                bbox=(min(lon), min(lat), max(lon), max(lat)),
                                datetime=_period(time)).items())
    # platforms to keep inside a collection (e.g. landsat-8 but not landsat-9)
    if platforms_keep is not None:
        items = [i for i in items if i.properties.get("platform") in platforms_keep]
    if not items:
        return xr.Dataset()
    sub, (r0, r1, c0, c1) = _sub_geobox(gbox, lon, lat)
    bands = [bmap[m] for m in measurements]
    rs = {bmap[m]: resampling.get(m, resampling.get("*", "nearest")) for m in measurements}
    kw = dict(bands=bands, geobox=sub, groupby="solar_day", resampling=rs,
              chunks={"time": 1, "latitude": 2048, "longitude": 2048})
    try:
        ds = stac_load(items, **kw).load()
    except Exception as e:
        # a file listed in the STAC catalogue but missing on the storage (HTTP 404): skip the
        # missing files (they are read as no data) instead of stopping the whole month
        if "404" not in str(e):
            raise
        print("\nWARNING %s %s: missing file on the SDC storage (HTTP 404), the missing scene(s) are skipped"
              % (product, _period(time)), flush=True)
        ds = stac_load(items, fail_on_error=False, **kw).load()
    ds = ds.rename({bmap[m]: m for m in measurements})
    # exact coordinates of the national grid, so that chunks combine without shifts
    ds = ds.assign_coords(latitude=gbox.coords["latitude"].values[r0:r1],
                          longitude=gbox.coords["longitude"].values[c0:c1])
    for m in measurements:
        if m in MASK_BANDS:
            continue
        v = ds[m].where(ds[m] > 0).astype("float32")      # 0 = no data
        ds[m] = v * 0.0000275 - 0.2 if product.startswith("landsat") else v / 10000.0
    return ds


# ------------------------------------------------------------------ cloud masks
# old Landsat Collection 1 pixel_qa bit -> Landsat Collection 2 QA_PIXEL bit
C1_TO_C2_BIT = {0: 0, 1: 6, 2: 7, 3: 4, 4: 5, 5: 3}


def ls_qa_clean(dc_qa, valid_bits=[1, 2, 4]):
    """
    Clean mask of a Landsat Collection 2 dataset from the QA_PIXEL band.
    Same rule as the Collection 1 version of swiss_utils:
      - cloud confidence <= low (and cirrus confidence <= low), no cloud, no dilated
        cloud, no cirrus, no cloud shadow, no fill
      - and at least one of the valid_bits, given with the OLD pixel_qa numbering:
        1 = clear, 2 = water, 4 = snow (default), 3 = cloud shadow, 5 = cloud
    QA_PIXEL (Collection 2) bits: 0 fill, 1 dilated cloud, 2 cirrus, 3 cloud, 4 cloud
      shadow, 5 snow, 6 clear, 7 water, 8-9 cloud confidence, 10-11 cloud shadow
      confidence, 12-13 snow/ice confidence, 14-15 cirrus confidence (00 none, 01 low,
      10 medium, 11 high).
    Output: clean_mask (boolean numpy array)
    """
    qa = np.nan_to_num(np.asarray(dc_qa.values, dtype="float64"), nan=1).astype("uint16")
    bit = lambda b: (qa >> b) & 1
    cloud_conf = (qa >> 8) & 3
    cirrus_conf = (qa >> 14) & 3
    ok = ((bit(0) == 0) & (bit(1) == 0) & (bit(2) == 0) & (bit(3) == 0) & (bit(4) == 0)
          & (cloud_conf <= 1) & (cirrus_conf <= 1))
    valid = np.zeros(qa.shape, bool)
    for c in valid_bits:
        valid |= bit(C1_TO_C2_BIT[c]) == 1
    return ok & valid


def create_slc_clean_mask(slc, valid_cats, cloud_buffer=0):
    """
    Clean mask from a list of valid Sentinel-2 scene classification (SCL) categories:
      0 no data, 1 saturated or defective, 2 dark area pixels, 3 cloud shadows,
      4 vegetation, 5 not vegetated, 6 water, 7 unclassified, 8 cloud medium probability,
      9 cloud high probability, 10 thin cirrus, 11 snow
    Output: clean_mask (boolean numpy array)
    """
    clean = xr.apply_ufunc(np.isin, slc, valid_cats).values
    # optional buffer (in pixels) around cloud shadows, clouds and cirrus (3, 8, 9, 10),
    # like the dilated cloud bit of Landsat; 0 = no buffer (as the datacube version)
    if cloud_buffer > 0:
        from scipy.ndimage import binary_dilation
        cloud = np.isin(slc.values, [3, 8, 9, 10])
        st = np.ones((2 * cloud_buffer + 1, 2 * cloud_buffer + 1), bool)
        for t in range(cloud.shape[0]):
            if cloud[t].any():
                clean[t] &= ~binary_dilation(cloud[t], structure=st)
    return clean


# ------------------------------------------------------------------ chunker
def create_geographic_chunks(longitude=None, latitude=None, geographic_chunk_size=0.5):
    """
    Split an area into chunks of at most geographic_chunk_size square degrees
    (split across latitudes, as utils.data_cube_utilities.dc_chunker).
    """
    square_area = (latitude[1] - latitude[0]) * (longitude[1] - longitude[0])
    n = math.ceil(square_area / geographic_chunk_size)
    edges = np.linspace(latitude[0], latitude[1], n + 1)
    return [{"longitude": tuple(longitude), "latitude": (edges[i], edges[i + 1])} for i in range(n)]


def combine_geographic_chunks(chunks):
    """
    Combine chunks loaded on the same national pixel grid into one Dataset.
    (Chunks may share a border row; values are identical there.)
    """
    ds = xr.concat(chunks, dim="latitude")
    ds = ds.isel(latitude=~ds.get_index("latitude").duplicated())
    return ds.sortby("latitude", ascending=False)


# ------------------------------------------------------------------ misc
def printandlog(msg, logname="default.log", started=False, reset=False):
    """Print a message and write it in a log file (same as swiss_utils)."""
    logging.basicConfig(filename=logname, level=logging.INFO,
                        format="%(asctime)s | %(message)s", datefmt="%Y-%m-%d %H:%M:%S")
    if reset:
        open(logname, "w").close()
    if started:
        msg = "%s (done in %s)" % (msg, datetime.now() - started)
    print("%s | %s" % (datetime.now(), msg))
    logging.info(msg)


def write_geotiff_from_xr(tif_path, dataset, bands, no_data=-9999, crs="EPSG:4326", compr=""):
    """
    Write a GeoTIFF from an xarray Dataset (latitude, longitude), one band per variable,
    band names written as band descriptions (same as swiss_utils).
    """
    from rasterio.transform import from_bounds
    lon, lat = dataset.longitude.values, dataset.latitude.values
    pw = abs(lon[-1] - lon[0]) / (len(lon) - 1)
    ph = abs(lat[-1] - lat[0]) / (len(lat) - 1)
    tr = from_bounds(lon[0] - pw / 2, lat[-1] - ph / 2, lon[-1] + pw / 2, lat[0] + ph / 2, len(lon), len(lat))
    dtype = np.result_type(*[dataset[b].dtype for b in bands])
    kw = dict(compress=compr) if compr else {}
    with rasterio.open(tif_path, "w", driver="GTiff", height=len(lat), width=len(lon), count=len(bands),
                       dtype=dtype, crs=crs, transform=tr, nodata=no_data, tiled=True,
                       BIGTIFF="IF_SAFER", **kw) as dst:
        for i, b in enumerate(bands, start=1):
            dst.write(dataset[b].fillna(no_data).values.astype(dtype), i)
            dst.set_band_description(i, b)


def display_map(latitude=None, longitude=None):
    """Map of the area of interest (folium)."""
    import folium
    m = folium.Map(location=[np.mean(latitude), np.mean(longitude)], zoom_start=7)
    folium.Rectangle(bounds=[[latitude[0], longitude[0]], [latitude[1], longitude[1]]],
                     color="red", fill=False).add_to(m)
    return m


def zone_coords(gbox, lon, lat):
    """latitude / longitude coordinates of the national grid inside the lon/lat zone."""
    _, (r0, r1, c0, c1) = _sub_geobox(gbox, lon, lat)
    return gbox.coords["latitude"].values[r0:r1], gbox.coords["longitude"].values[c0:c1]


def geobox_from_grid(origin, res, size):
    """
    GeoBox (EPSG:4326) from the top-left corner origin=(lon, lat), pixel size res=(x, y) in
    degrees and size=(columns, rows), e.g. the grid of the former datacube products.
    """
    from odc.geo.geobox import GeoBox
    from rasterio.transform import from_origin
    return GeoBox((size[1], size[0]), from_origin(origin[0], origin[1], abs(res[0]), abs(res[1])), "EPSG:4326")
