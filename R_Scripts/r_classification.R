library(raster)
library(sp)
library(rgdal)
library(rgeos)
library(maptools)

setwd("C:/OVP_Reeds/")
list.files()

rst.stack <- stack("AP_2018_RGB_SmallAOI_S2Grid.tif")
names(rst.stack)<-c("R","G","B")


#creating a point shapefile #this can create a massive point set
#sel.rst <- rst.stack$R
#shp.rst <- rasterToPoints(sel.rst,spatial = T)
#shp.rst$Class <- NA
#writePointsShape(shp.rst,"Points_Small_Aoi.shp")

#alternatively, you generate random points in QGIS, reclassify them there and then bring them here

shp.samples = readShapePoints("250_RandPts_SmallAOI.shp")

#confirm everything overlays
plot(rst.stack$R)
points(shp.samples)
unique(shp.samples$Class)

#ok, now we are ready to go

#lets use the commonly used Random Forest
#https://cran.r-project.org/web/packages/randomForest/randomForest.pdf
library(randomForest)

#first thing we need to do, is to get the vaues of the raster into a table with the values of of the shae file
pts <- extract(rst.stack,shp.samples,sp=T)

#now we create a table (data.frame)
pts.df <- as.data.frame(pts)

#lets see how many samples we got of each class
table(pts.df$Class)

#ok now we need to divide tem into two groups - one we use to train our model, the other we use to test it
#the simpler way is using the inbuilt function CreateDataPArtition
#creating a subset for validation and then 2 subset
library(caret)
trainIndex <- createDataPartition(pts.df$Class,
                                  p = .7,
                                  list=FALSE,
                                  time=1)
#what trainIndex is, is a list of the rows that were selected randomly. Now we can use that to select the rows for each set of training and validatoin

tr.df = pts.df[trainIndex,]
vl.df = pts.df[-trainIndex,]

table(tr.df$Class)
table(vl.df$Class)

#lets train the RF model
rf.mdl <- randomForest(Class~R+G+B,data=tr.df)
#there are  many options within the RandomForest model that can (and should), be explored -> it's called hyperparmeter tunning.
#But for this example we just run it like it is

plot(rf.mdl)
summary(rf.mdl)

#We can now just predict the model back into our training data
vl.df$rf.pred <- predict(rf.mdl,vl.df)

#now we have to use the confusion matrix approach to test our classification
library(e1071)
confusionMatrix(vl.df$rf.pred,vl.df$Class)

#so, seems we got some pretty high accuraccy -> doubtfull, we used few points to that can play an inflating role
#lets create a classified raster

rst.class <- predict(rst.stack,rf.mdl) #notice, the bigger the raster.. the more memory it consumes from your PC

#lets see them side by side
par(mfrow=c(1,1))
plotRGB(rst.stack)
plot(rst.class)

#nhecs... these visualizations in R are bad.. lets save the output and explore in QGIS/ARCGIS
writeRaster(rst.class,
            filename="rf_SmallAOI_20mGRID.tif",
            options=c("COMPRESS=LZW"),
            overwrite=TRUE)



## OK- lets say ow we want to convert the data to a "ratio of %" of x land cover" based on the sentinel-2 pixel size

#first we create a 1/0 rst for each class
rst.frag = rst.class$layer == 1
rst.reed = rst.class$layer == 2
rst.wate = rst.class$layer == 3

par(mfrow=c(1,3))
plot(rst.frag)
plot(rst.reed)
plot(rst.wate)

#ok now, we have to count the total number of 0.25cm cells, we would have in 20 by 20m
20/.25 #cool, we ahve a pretty straightforwad value

rst.agg.frag = aggregate(rst.frag,fun=sum,fact=80)

par(mfrow=c(1,1))
plot(rst.agg.frag) #but now, thevalue is actually the "Sum" of 1's. We need to divide it by the total number of cells in a 20 by 20m area
plot(rst.agg.frag/(80*80))

#lets do the same for all:
ncells=80*80
rst.agg.frag = aggregate(rst.frag,fun=sum,fact=80)/ncells
rst.agg.reed = aggregate(rst.reed,fun=sum,fact=80)/ncells
rst.agg.wate = aggregate(rst.wate,fun=sum,fact=80)/ncells

par(mfrow=c(1,3))
plot(rst.agg.frag)
plot(rst.agg.reed)
plot(rst.agg.wate)

writeRaster(rst.agg.frag,"Class_Frag_s2Res.tif")
writeRaster(rst.agg.reed,"Class_Reed_s2Res.tif")
writeRaster(rst.agg.wate,"Class_Wate_s2Res.tif")

#one simple trick to align the rasters is the following -> this is not recommended on a final model
#the lack of aligment is happening before, probably on the ressampling of the data.
s2.raster <- raster("S2B_MSIL2A_T31UFU_2019-12-27_RDNew.tif") 

rst.agg.frag.res = resample(rst.agg.frag,s2.raster)
rst.agg.reed.res = resample(rst.agg.reed,s2.raster)
rst.agg.wate.res = resample(rst.agg.wate,s2.raster)


writeRaster(rst.agg.frag.res,"Class_Frag_s2Res_res.tif")
writeRaster(rst.agg.reed.res,"Class_Reed_s2Res_res.tif")
writeRaster(rst.agg.wate.res,"Class_Wate_s2Res_res.tif")