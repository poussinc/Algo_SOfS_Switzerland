
# Load libraries --------------------------
#install.packages('lme4')
library(lme4)
#install.packages('lmerTest')
library(lmerTest)
#install.packages('MuMIn')
library(MuMIn)
#install.packages('biomod2')
library(biomod2)
#install.packages('sjPlot')
library(sjPlot)
#install.packages('sjmisc')
library(sjmisc)
#install.packages('ffects')
library(effects)
#install.packages('performance')
library(performance)
library(egg)
library(grid)
library(dplyr)
library(ggplot2)
#install.packages('raster')
library(raster)
#install.packages('terra')
library(terra)
library(openxlsx)


dir()


test <- stack("E:/charlotte/STEP1 GF/NDSI_SON_a_step1.tif")
test

test2 <- stack("E:/charlotte/STEP1 GF/NDSI_SON_b_step1.tif")
test2

raster_stack_predi_DJF_a <- stack("raster_stack_predi_DJF_a.tif")
Lacs_WGS <- stack("E:/charlotte/Mask/LACS_WGS.tif")
plot(Lacs_WGS)

###masque lacs
Lacs_raster <- raster("E:/charlotte/Mask/Lacs_raster.tif")
plot(Lacs_raster)

# Provided data
raster_names_DJF <- c(
  'NDSI_1984_12_01', 'NDSI_1985_01_01', 'NDSI_1985_02_01', 
  'NDSI_1985_12_01', 'NDSI_1986_01_01', 'NDSI_1986_02_01', 
  'NDSI_1986_12_01', 'NDSI_1987_02_01', 'NDSI_1987_12_1', 
  'NDSI_1988_01_01', 'NDSI_1988_02_01', 'NDSI_1988_12_01', 
  'NDSI_1989_01_01', 'NDSI_1989_02_01', 'NDSI_1989_12_01', 
  'NDSI_1990_01_01', 'NDSI_1990_02_01', 'NDSI_1990_12_01', 
  'NDSI_1991_01_01', 'NDSI_1991_02_01', 'NDSI_1991_12_01', 
  'NDSI_1992_01_01', 'NDSI_1992_02_01', 'NDSI_1992_12_1', 
  'NDSI_1993_01_01', 'NDSI_1993_02_01', 'NDSI_1993_12_1', 
  'NDSI_1994_01_1', 'NDSI_1994_02_01', 'NDSI_1994_12_01', 
  'NDSI_1995_01_01', 'NDSI_1995_02_01', 'NDSI_1995_12_1', 
  'NDSI_1996_01_01', 'NDSI_1996_02_01', 'NDSI_1996_12_1', 
  'NDSI_1997_01_01', 'NDSI_1997_02_01', 'NDSI_1997_12_1', 
  'NDSI_1998_01_01', 'NDSI_1998_02_01', 'NDSI_1998_12_01', 
  'NDSI_1999_01_01', 'NDSI_1999_02_01', 'NDSI_1999_12_01', 
  'NDSI_2000_01_01', 'NDSI_2000_02_01', 'NDSI_2000_12_01', 
  'NDSI_2001_01_01', 'NDSI_2001_02_01', 'NDSI_2001_12_01', 
  'NDSI_2002_01_01', 'NDSI_2002_02_01', 'NDSI_2002_12_01', 
  'NDSI_2003_01_01', 'NDSI_2003_02_01', 'NDSI_2003_12_01', 
  'NDSI_2004_01_01', 'NDSI_2004_02_01', 'NDSI_2004_12_01', 
  'NDSI_2005_01_01', 'NDSI_2005_02_01', 'NDSI_2006_01_1', 
  'NDSI_2006_02_01', 'NDSI_2006_12_01', 'NDSI_2007_01_01', 
  'NDSI_2007_02_01', 'NDSI_2007_12_1', 'NDSI_2008_01_1', 
  'NDSI_2008_02_1', 'NDSI_2008_12_1', 'NDSI_2009_01_01', 
  'NDSI_2009_02_01')

names(raster_stack_predi_DJF_a) <- raster_names_DJF
plot(raster_stack_predi_DJF_a[[1]])
unique(Lacs_WGS)
###On va enlever les lac WGS de tt les rasters
###d'abord il faut mettre les lacs à la m^me extent et resolution que mon ratser NDSI
#Lacs_WGS <- resample(Lacs_WGS, raster_stack_predi_DJF_a[[1]], method = "ngb")
plot(Lacs_WGS)
writeRaster(Lacs_WGS,"E:/charlotte/Mask/Lacs_WGS_final.tif",filetype = "GTiff", overwrite = TRUE)
Suisse_raster <-raster("E:/charlotte/Mask/Mask_CH.tif")
plot(Suisse_raster)
# Remplacez les valeurs différentes de 1 (y compris les NA) par 0
#Lacs_WGS <- reclassify(Lacs_WGS, cbind(NA, 0))
plot(Lacs_WGS)
Lacs_WGS[Lacs_WGS>0]<-NA
plot(Lacs_WGS)

##enlever le new mask d'eau
raster_stack_predi_DJF_a[[1]] <- mask(raster_stack_predi_DJF_a[[1]], Lacs_WGS)

###juste pour vérifier que tt est bon
#sum(is.na(values(test1)))
#sum(is.na(values(raster_stack_predi_DJF_a[[1]])))



#####on va enlever les cloud en NA et les mettre en 205
### On veut mtn avoir 205 pour les cloud et -999 pour les NA
#Dire que toute les NA sont égal à 205
# replacing NA's by zero
raster_stack_predi_DJF_a[[1]][is.na(raster_stack_predi_DJF_a[[1]][])] <- 2
plot(raster_stack_predi_DJF_a[[1]])

Lacs_ratser_NA <- Lacs_raster[Lacs_raster>0]<-NA
plot(Lacs_ratser_NA)

Suisse_raster[Suisse_raster==0] <- NA
plot(Suisse_raster)
Suisse_raster_NA <- Suisse_raster

plot(Lacs_raster)

###pour faire les mask d'un coup
mask1 <- mask(Suisse_raster_NA, Lacs_ratser_NA)
plot(mask1)
maks2 <- mask(mask1, Lacs_WGS)
plot(maks2)
writeRaster(maks2,"E:/charlotte/Mask/Mask_all.tif",filetype = "GTiff", overwrite = TRUE)
sum(is.na(values(Suisse_raster)))#nombre de pixel hors suisse
length(which(getValues(Lacs_raster) == 1))
length(which(getValues(Lacs_WGS) == 1))
######################################################################################################
################ A faire pour toute les couches raster qui sortent du modèle! #########################
##ON a alors 2 pour les nuages, 1 pour la niege, 0 pour la non neige, et NA pour le reste
#### attention utiliser comme mask mask_all
raster_stack_predi_DJF_a[[1]] <- mask(raster_stack_predi_DJF_a[[1]], maks2)
plot(raster_stack_predi_DJF_a[[1]])

###pour savoir les stats
##nombre de NA dans le raster
sum(!is.na(values(prB3.mask)))#nombre de pixel qui recouvre la suisse
sum(is.na(values(prB3.mask)))## pixel pas pris en compte dans l'analyse lac ou hors suisse
length(which(getValues(prB3.mask) == 2)) #ici on a 24% de cloud 
length(which(getValues(prB3.mask) == 1))
length(which(getValues(prB3.mask) == 0))

#### A faire après chauqe gapfilling
no_snow <- (length(which(getValues(raster_stack_predi_DJF_a[[1]]) == 0))/sum(!is.na(values(raster_stack_predi_DJF_a[[1]]))))*100
snow <- (length(which(getValues(raster_stack_predi_DJF_a[[1]]) == 1))/sum(!is.na(values(raster_stack_predi_DJF_a[[1]]))))*100
cloud <- (length(which(getValues(raster_stack_predi_DJF_a[[1]]) == 2))/sum(!is.na(values(raster_stack_predi_DJF_a[[1]]))))*100

######## début de la boucle pour masquer tt et changer les valeurs #######################
NDSI_DJF_a_step1_list <- list()
for (i in 1:nlayers(raster_stack_predi_DJF_a)) {
  # Afficher l'indice de l'itération
  print(paste("Processing raster index", i))
  raster_stack_predi_DJF_a[[i]][is.na(raster_stack_predi_DJF_a[[i]])] <- 2
  NDSI_DJF_a_step1_list[[i]] <- mask(raster_stack_predi_DJF_a[[i]], maks2)
  gc()
}
NDSI_DJF_a_step1 <- stack(                                                                                                                                                                                                                                                                                     [[i]])


