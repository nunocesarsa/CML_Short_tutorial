
s2.raster <- raster("S2B_MSIL2A_T31UFU_2019-12-27_RDNew.tif")

s2.raster = s2.raster*0
grid <- rasterToPolygons(s2.raster)


writePolyShape(grid,"s2_20m_grid_OVP.shp")
