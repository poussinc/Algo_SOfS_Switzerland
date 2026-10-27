##### Snow coverage prediction using NDSI and a generalized linear mixed model #####
##### P. Timoner and C. Poussin, 2021 #####

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


addline_format <- function(x,...){
  gsub('\\s','\n',x)
}
################################################## Load data ############################################
#########################################################################################################
df <- readRDS("dfCP.rds")
head(df)

getwd()

### Load CH Shapfile ###
### Si je veux faire des cartes avec des données geospatial pour avoir le fond de la suisse

#Suisse <-readOGR("E:/Article NDWI/Corrélations/Suisse.shp")
#plot(Suisse)
#coords <- df[c("Lon","Lat")]

### Making sure we are working with rows that don't have any blanks
#coords <- coords[complete.cases(coords),]

### Letting R know that these are specifically spatial coordinates
#sp <- SpatialPoints(coords)
#plot(Suisse)
#plot(sp, col="black", add=TRUE,pch=20)
#summary(sp)


################################################## Prepare Data ############################################
#########################################################################################################
### Reclassify NDSI> 1 et NDSI< -1 car le NDSI varie entre -1 et 1 ici n'est pas fait dans le SDC
df$NDSI[df$NDSI>1] <- NA
df$NDSI[df$NDSI< -1] <- NA

###garder unqiuement les valeurs qui sont plus grande que 0 et qui sont susceptible d'etre de la neige
###que pour ne pas avoir des valeurs entre 0 et 1
#df$NDSI[df$NDSI < 0] <- NA

dim(df)

###pour prendre uniquement les station avec toutes les informations complètes
df <- df[complete.cases(df),]

df$annee=c(format(df$Time, format = "%Y"))

   
########################################## Ordonne nos données ###################################################
###Nous avons remarqué que les sparsely forested agisse comme les non forested
#df$Landcover[df$Landcover=="Sparsely forested"] <- "non forested"
###on crée des catégories pour nos altitudes
      
### Elevation categories
df$AltC <- cut(df$Alt,breaks=c(0,500,1000,1500,2000,2500,Inf),labels=c(1,2,3,4,5,6))

### CRéer des categories pour les snow depth
##to create boxplot distribution of the NDSI values by snow depth
df$Snow_depthC <- cut(df$Snow, breaks = c(-Inf,0,1,5,10,50,100,Inf))
df$Snow_depthC

#ordonner les saisons
df$Saisons <- factor(df$Saisons , levels=c("DJF", "MAM", "JJA", "SON"))
df$Saisons <- factor(df$Saisons, labels=c(1,2,3,4))

#pour order la classe landcover
df$Landcover <- factor(df$Landcover,levels=c("non forested","Sparsely forested","forested"))
df$Landcover <- factor(df$Landcover,labels=c(1,2,3))
      

      
################################################ Partie 3 Model calibration and evaluation --------------------------
# Genealized mixed model with random intercepts and slopes for stations and the other variables --------------------------
# Model for different snow depth threshold
##Ici on va prendre uniquement un snow thr de 1

thrSnow = 1
modLst <- list()
nr <- 0
for(i in 1:length(thrSnow)){
  message(i)
  outLst <- list()
  df$ThrX <- ifelse(df$Snow>=thrSnow[i],1,0)
  glmm2 <- glmer(ThrX~(NDSI|Stations)+NDSI+(NDSI|AltC)+(NDSI|Landcover)+(NDSI|Saisons),data=df,family = binomial("logit"),
                  control=glmerControl(optimizer="nloptwrap",optCtrl=list(maxfun=2e5)))
        
  # Save model
  outLst[["Model"]] <- glmm2 
  # Model summary
  outLst[["Summary"]] <- summary(glmm2)
  # Category effects (intercept and slope)
  outLst[["RandomEffects"]] <- ranef(glmm2)
        
  # Rsquared, marginal and conditional
  # outLst[["R2"]] <- performance::r2(glmm1,tolerance = 1e-05)
  outLst[["R2bis"]] <- r.squaredGLMM(glmm2)
        
        
  # Prediction only without random effect of stations
  #ici l'effet fixe est déjà pris en compte on a pas besoins de le rajouter
  pr <- predict(glmm2,type="response",re.form=~(NDSI|AltC)+(NDSI|Landcover)+(NDSI|Saisons))
  outLst[["Predictions"]] <- pr
        
  # Evaluation
  tss <- Find.Optim.Stat("TSS",Fit=pr,Obs=df$ThrX,Fixed.thresh = seq(0,1,0.05))
  acc <- Find.Optim.Stat("ACCURACY",Fit=pr,Obs=df$ThrX,Fixed.thresh = seq(0,1,0.05))
  outLst[["PerfGLMM"]] <- list(tss,acc)

  # Plot
  pp <- plot_model(glmm2, type = "pred", terms = c("NDSI","Landcover","Saisons","AltC"),line.size=1,alpha=0,pred.type = "re",show.legend = TRUE)
  outLst[["Plots"]] <- pp
        
  ## Comparison with threshold method
  ##C'est le TSS qui va nous permettre de transformer les données en binaire avec le cutoff (0.45)
  tss <- Find.Optim.Stat("TSS",df$NDSI,df$ThrX,Fixed.thresh = 0.4)
  acc <- Find.Optim.Stat("ACCURACY",df$NDSI,df$ThrX,Fixed.thresh = 0.4)
  outLst[["PerfMethThr"]] <- list(tss,acc)
  modLst[[i]] <- outLst
}
      
glmm2
      
modLst[[3]]$PerfMethThr
modLst[[3]]$PerfGLMM

      
########################################### ETAPE PREDICTION ############################
########################################## PREPARATION DES DONNEES ##########################################

##Dans ce stack on a une couche de landcover, une couche de NDSI et une couche de DEM
predStack <- rast("Stack_CS_model.tif")
plot(predStack)
      
summary(values(predStack[[2]]))
      
# Reclassify NDSI acr on avait pas enlever les données èplus grande et plus petite que 1 et -1
#ne pas faire si deja fait dans dc
predStack[[3]]
valNDSI <- values(predStack[[3]])[,1]
valNDSI[valNDSI > 1] <- NA
valNDSI[valNDSI < -1] <- NA
values(predStack[[3]])[,1] <- valNDSI
plot(predStack[[3]])
      
# Reclassify land cover
#ici on a toutes les valeurs de la couche corine allant de 2 à 41
unique(values(predStack[[1]]))
predStack[[1]]
rcl <- data.frame(From=c(2,3,11,12,15,16,18,21,23,24,25,26,27,29,31,32,34,41),To=c(NA))
rcl$To[rcl$From %in% c(23,24,25)] <- 3
rcl$To[rcl$From %in% c(2,3,11,12,15,16,18,21,26,27,29,31,34,41)] <- 1
rcl$To[rcl$From %in% c(32)] <- 2
class(rcl$From)
predStack[[1]] <- terra::classify(predStack[[1]],rcl)
plot(predStack[[1]])
writeRaster(predStack[[1]],"LC_CS.tif",filetype = "GTiff", overwrite = TRUE)
      
# Reclassify DEM
#il faut que l'on le classify en categorie comme dans le modèle
newValues <- as.integer(as.character(cut(values(predStack[[2]])[,1],breaks=c(0,500,1000,1500,2000,2500,Inf),labels=c(1,2,3,4,5,6))))
values(predStack[[2]])[,1] <- newValues
plot(predStack[[2]])
writeRaster(predStack[[2]],"Alt_CS.tif",filetype = "GTiff", overwrite = TRUE)
      
      
# New season raster
# ON a pas de raster saison donc on le crée et ici =1 car on est en DJF (14.02.2019)
saisonRast <- predStack[[2]]
values(saisonRast)[,1] <- 1
      
# New stack
newStack <- c(predStack[[1]],predStack[[2]],saisonRast,predStack[[3]])
names(newStack) <- c("Landcover","AltC","Saisons","NDSI")
      
################################## prédiction ###################################################

# V1 faux car on a pas les même catégories que dans le modèle
#predi2 <- terra::predict(newStack,glmm1,type="response",re.form=~(NDSI|AltC)+(NDSI|Landcover)+(NDSI|Saisons),allow.new.levels=T)

#ici va prendre que l'effet fixe NDSI
#predi <- terra::predict(newStack,glmm1,type="response",re.form=NA)

#refaire avec les même categories et mettre allow.new.levels=F
predi <- terra::predict(newStack,glmm2,type="response",re.form=~(NDSI|AltC)+(NDSI|Landcover)+(NDSI|Saisons),allow.new.levels=F)
      
vv <- values(predi)
summary(vv[!is.na(vv)])

plot(predi)
#plot(predi2)

## Comparaison des deux modèles
#tt <- predi - predi2
#plot(tt)
      
writeRaster(predi,"predi_raster.tif",filetype = "GTiff", overwrite = TRUE)
      
## Pour le rendre binaire basé sur la maximisation du tss

df_prob <- as.data.frame(predi)
      
valBin <- predi
valBin[valBin>=0.45] <- 1
valBin[valBin<0.45] <- 0

prB <- pr
prB <- valBin
plot(prB)
df_prb <- as.data.frame(prB)
sum(df_prb==0)/nrow((df_prb))
sum(df_prb==1)/nrow((df_prb))
writeRaster(prB,"predi_raster_binaire_bis.tif",filetype = "GTiff", overwrite = TRUE)

      