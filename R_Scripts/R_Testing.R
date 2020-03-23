library(raster)
library(sp)
library(rgdal)
library(rgeos)
library(maptools)

setwd("C:/OVP_Reeds/")
list.files()

rst.stack <- stack("AP_2018_RGB_SmallAOI.tif")
names(rst.stack)<-c("R","G","B")




####

my.rgb = rst.stack
#saturation component
min.rst <- min(my.rgb)
S <- 1 - (3/(raster(my.rgb,layer=1)+raster(my.rgb,layer=2)+raster(my.rgb,layer=3)))*min.rst

#Hue component

#Step 1 - conditional areas
Cond1.rst <- raster(my.rgb,layer=3) <= raster(my.rgb,layer=2)
Cond2.rst <- Cond1.rst<1

#Angle of vector HUE
theta.up <- (1/2)*((raster(my.rgb,layer=1)-raster(my.rgb,layer=2))+((raster(my.rgb,layer=1)-raster(my.rgb,layer=3))))

theta.do <- sqrt( (raster(my.rgb,layer=1)-raster(my.rgb,layer=2))^2 + (raster(my.rgb,layer=1)-raster(my.rgb,layer=3))* (raster(my.rgb,layer=2)-raster(my.rgb,layer=3)))

#theta
theta <- ((cos((theta.up/theta.do)*pi/180))^1)*180/pi

#Hue component
H.Cond1 <- Cond1.rst*theta
H.Cond2 <- Cond2.rst*(360 - theta)

H <- H.Cond1+H.Cond2






#######


library(wvtool)

#converting image to grayscale
#gray_eq = (rst.stack$R+rst.stack$G+rst.stack$B)/3
#gray_bl = rst.stack$R-.3+rst.stack$G*.59+rst.stack$B*11 #kinda of random balance

gray_eq = rgb2gray(rst.stack,c(0.33, 0.33, 0.33))
gray_bl = rgb2gray(rst.stack) #kinda of random balance

par(mfrow=c(1,2))
plot(gray_eq)
plot(gray_bl)

bb <- edge.detect(gray_eq)



data(cryptomeria)
cryptomeria <- rgb2gray(cryptomeria)

plot(cryptomeria)
