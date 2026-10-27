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

#install.packages("writexl")
#library("writexl")
library(openxlsx)
#install.packages("openxlsx")

addline_format <- function(x,...){
  gsub('\\s','\n',x)
}

############################# Préparation des données pour le model ################
#########################################################################################
df <- readRDS("E:/charlotte/Model/dfCP.rds")
head(df)

### Reclassify NDSI> 1 et NDSI< -1 car le NDSI varie entre -1 et 1 ici n'est pas fait dans le SDC
df$NDSI[df$NDSI>1] <- NA
df$NDSI[df$NDSI< -1] <- NA
dim(df)

###pour prendre uniquement les station avec toutes les informations complètes
df <- df[complete.cases(df),]
df$annee=c(format(df$Time, format = "%Y"))
dim(df) ## doit etre 13100

########################################## Ordonne nos données ###################################################
##################################### glmm2 ###################################################
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
head(df)


############################ ON va faire la même chose mais pour chaque saison #######################
######################### séparement comme cela on va voir comment varie les autre varibles #####################################
count(filter(df[(df$Saison == 1),]))
count(filter(df[(df$Saison == 2),]))
count(filter(df[(df$Saison == 3),]))
count(filter(df[(df$Saison == 4),]))

df_DJF <- filter(df[(df$Saison == 1),])
dim(df_DJF)
df_MAM <- filter(df[(df$Saison == 2),])
dim(df_MAM)
df_JJA <- filter(df[(df$Saison == 3),])
dim(df_JJA)
df_SON <- filter(df[(df$Saison == 4),])
dim(df_SON)

################################################ Partie 3 Model calibration and evaluation --------------------------
# Genealized mixed model with random intercepts and slopes for stations and the other variables --------------------------
# Model for different snow depth threshold
# Model for the four seasons
## thrSnow DJF 1
## thrSnow MAM 5
## thrSnow JJA 15
## thrSnow SON 15
dir()
NDSI_SON <- stack("E:/charlotte/Model/NDSI_SON.tif")
NDSI_DJF <- stack("E:/charlotte/Model/NDSI_DJF.tif")
NDSI_MAM <- stack("E:/charlotte/Model/NDSI_MAM.tif")
NDSI_JJA <- stack("E:/charlotte/Model/NDSI_JJA.tif")

raster_names_SON <- c(
  'NDSI_1985_09_01', 'NDSI_1985_10_01', 'NDSI_1985_11_01',
  'NDSI_1986_09_01', 'NDSI_1986_10_01', 'NDSI_1986_11_01',
  'NDSI_1987_09_01', 'NDSI_1987_10_01', 'NDSI_1987_11_01',
  'NDSI_1988_09_01', 'NDSI_1988_10_01', 'NDSI_1988_11_01',
  'NDSI_1989_09_01', 'NDSI_1989_10_01', 'NDSI_1989_11_01',
  'NDSI_1990_09_01', 'NDSI_1990_10_01', 'NDSI_1990_11_01',
  'NDSI_1991_09_01', 'NDSI_1991_10_01', 'NDSI_1991_11_01',
  'NDSI_1992_09_01', 'NDSI_1992_10_01', 'NDSI_1992_11_01',
  'NDSI_1993_09_01', 'NDSI_1993_10_01', 'NDSI_1993_11_01',
  'NDSI_1994_09_01', 'NDSI_1994_10_01', 'NDSI_1994_11_01',
  'NDSI_1995_09_01', 'NDSI_1995_10_01', 'NDSI_1995_11_01',
  'NDSI_1996_09_01', 'NDSI_1996_10_01', 'NDSI_1996_11_01',
  'NDSI_1997_09_01', 'NDSI_1997_10_01', 'NDSI_1997_11_01',
  'NDSI_1998_09_01', 'NDSI_1998_10_01', 'NDSI_1998_11_01',
  'NDSI_1999_09_01', 'NDSI_1999_10_01', 'NDSI_1999_11_01',
  'NDSI_2000_09_01', 'NDSI_2000_10_01', 'NDSI_2000_11_01',
  'NDSI_2001_09_01', 'NDSI_2001_10_01', 'NDSI_2001_11_01',
  'NDSI_2002_09_01', 'NDSI_2002_10_01', 'NDSI_2002_11_01',
  'NDSI_2003_09_01', 'NDSI_2003_10_01', 'NDSI_2003_11_01',
  'NDSI_2004_09_01', 'NDSI_2004_10_01', 'NDSI_2004_11_01',
  'NDSI_2005_09_01', 'NDSI_2005_10_01', 'NDSI_2005_11_01',
  'NDSI_2005_11_1', 'NDSI_2006_09_01', 'NDSI_2006_10_01',
  'NDSI_2006_11_01', 'NDSI_2007_09_01', 'NDSI_2007_10_1',
  'NDSI_2007_11_1', 'NDSI_2008_09_01', 'NDSI_2008_10_01',
  'NDSI_2008_11_1', 'NDSI_2009_09_01', 'NDSI_2009_10_01',
  'NDSI_2009_11_01', 'NDSI_2010_09_01', 'NDSI_2010_10_01',
  'NDSI_2010_11_01', 'NDSI_2011_09_01', 'NDSI_2011_10_01',
  'NDSI_2011_11_01', 'NDSI_2013_09_01', 'NDSI_2013_10_01',
  'NDSI_2013_11_01', 'NDSI_2014_09_01', 'NDSI_2014_10_01',
  'NDSI_2014_11_01', 'NDSI_2015_09_01', 'NDSI_2015_10_1',
  'NDSI_2015_11_01', 'NDSI_2016_09_01', 'NDSI_2016_10_01',
  'NDSI_2016_11_01', 'NDSI_2017_09_01', 'NDSI_2017_10_01',
  'NDSI_2017_11_01', 'NDSI_2018_09_01', 'NDSI_2018_10_01',
  'NDSI_2018_11_01', 'NDSI_2019_09_01', 'NDSI_2019_10_01',
  'NDSI_2019_11_1', 'NDSI_2020_09_01', 'NDSI_2020_10_01',
  'NDSI_2020_11_01', 'NDSI_2021_09_01', 'NDSI_2021_10_01',
  'NDSI_2021_11_01'
)

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
  'NDSI_2009_02_01', 'NDSI_2009_12_01', 'NDSI_2010_01_01',
  'NDSI_2010_02_01', 'NDSI_2010_12_01', 'NDSI_2011_01_01', 
  'NDSI_2011_02_01', 'NDSI_2011_12_1', 'NDSI_2013_12_01', 
  'NDSI_2014_01_01', 'NDSI_2014_02_01', 'NDSI_2014_12_01', 
  'NDSI_2015_01_01', 'NDSI_2015_02_01', 'NDSI_2015_12_01', 
  'NDSI_2016_01_01', 'NDSI_2016_02_01', 'NDSI_2016_12_01', 
  'NDSI_2017_01_01', 'NDSI_2017_02_01', 'NDSI_2017_12_01', 
  'NDSI_2018_01_01', 'NDSI_2018_02_01', 'NDSI_2018_12_01', 
  'NDSI_2019_01_01', 'NDSI_2019_02_01', 'NDSI_2019_12_01', 
  'NDSI_2020_01_01', 'NDSI_2020_02_1', 'NDSI_2020_12_1', 
  'NDSI_2021_01_01', 'NDSI_2021_02_01', 'NDSI_2021_12_01'
)

raster_names_DJF[1:73]

raster_names_MAM <- c(
  '1985_03_01', '1985_04_01', '1985_05_01',
  '1986_03_01', '1986_04_01', '1986_05_01',
  '1987_03_01', '1987_04_01', '1987_05_01',
  '1988_03_01', '1988_04_01', '1988_05_01',
  '1989_03_01', '1989_04_01', '1989_05_01',
  '1990_03_01', '1990_04_01', '1990_05_01',
  '1991_03_01', '1991_04_01', '1991_05_01',
  '1992_03_01', '1992_04_01', '1992_05_01', 
  '1993_03_01', '1993_04_01', '1993_05_01', 
  '1994_03_01', '1994_04_01', '1994_05_01', 
  '1995_03_01', '1995_04_01', '1995_05_01',
  '1996_03_01', '1996_04_01', '1996_05_01',
  '1997_03_01', '1997_04_01', '1997_05_01',
  '1998_03_01', '1998_04_01', '1998_05_01',
  '1999_03_01', '1999_04_01', '1999_05_01',
  '2000_03_01', '2000_04_01', '2000_05_01', 
  '2001_03_01', '2001_04_01', '2001_05_01', 
  '2002_03_01', '2002_04_01', '2002_05_01', 
  '2003_03_01', '2003_04_01', '2003_05_01', 
  '2004_03_01', '2004_04_01', '2004_05_01',
  '2005_03_01', '2005_04_01', '2005_05_01',
  '2006_03_01', '2006_04_01', '2006_05_01',
  '2007_03_01', '2007_04_01', '2007_05_01',
  '2008_03_01', '2008_04_01', '2008_05_01',
  '2009_03_01', '2009_04_01', '2009_05_01', 
  '2010_03_01', '2010_04_01', '2010_05_1', 
  '2011_03_01', '2011_04_01', '2011_05_01', 
  '2013_03_1', '2013_04_01', '2013_05_01',
  '2014_03_01', '2014_04_01', '2014_05_01', 
  '2015_03_01', '2015_04_01', '2015_05_01', 
  '2016_03_01', '2016_04_01', '2016_05_01', 
  '2017_03_01', '2017_04_01', '2017_05_01', 
  '2018_03_01', '2018_04_01', '2018_05_01', 
  '2019_03_01', '2019_04_01', '2019_05_01', 
  '2020_03_01', '2020_04_01', '2020_05_01', 
  '2021_03_01', '2021_04_01', '2021_05_01'
)

# Provided data
raster_names_JJA <- c(
  '1985_06_01', '1985_07_01', '1985_08_01',
  '1986_06_01', '1986_07_01', '1986_08_01',
  '1987_06_1', '1987_07_01', '1987_08_01',
  '1988_06_01', '1988_07_01', '1988_08_01',
  '1989_06_01', '1989_07_01', '1989_08_01',
  '1990_06_01', '1990_07_01', '1990_08_01', 
  '1991_06_01', '1991_07_01', '1991_08_01',
  '1992_06_01', '1992_07_01', '1992_08_01',
  '1993_06_01', '1993_07_01', '1993_08_01',
  '1994_06_01', '1994_07_01', '1994_08_01', 
  '1995_06_01', '1995_07_01', '1995_08_01', 
  '1996_06_01', '1996_07_01', '1996_08_01', 
  '1997_06_01', '1997_07_01', '1997_08_01', 
  '1998_06_01', '1998_07_01', '1998_08_01', 
  '1999_06_01', '1999_07_01', '1999_08_01',
  '2000_06_01', '2000_07_01', '2000_08_01',
  '2001_06_01', '2001_07_01', '2001_08_01',
  '2002_06_01', '2002_07_01', '2002_08_01', 
  '2003_06_01', '2003_07_01', '2003_08_01', 
  '2004_06_01', '2004_07_01', '2004_08_01', 
  '2005_06_01', '2005_07_01', '2005_08_01', 
  '2006_06_01', '2006_07_01', '2006_08_01', 
  '2007_06_01', '2007_07_01', '2007_08_01', 
  '2008_06_01', '2008_07_01', '2008_08_01', 
  '2009_06_01', '2009_07_01', '2009_08_01', 
  '2010_06_01', '2010_07_01', '2010_08_01', 
  '2011_06_01', '2011_07_01', '2011_08_01', 
  '2013_06_01', '2013_07_01', '2013_08_01', 
  '2014_06_01', '2014_07_01', '2014_08_01', 
  '2015_06_01', '2015_07_01', '2015_08_01', 
  '2016_06_01', '2016_07_01', '2016_08_01', 
  '2017_06_01', '2017_07_01', '2017_08_01', 
  '2018_06_01', '2018_07_01', '2018_08_01', 
  '2019_06_01', '2019_07_01', '2019_08_01', 
  '2020_06_01', '2020_07_01', '2020_08_01', 
  '2021_06_01', '2021_07_01', '2021_08_01'
)

# Print the list of raster names
names(NDSI_SON) <- raster_names_SON
names(NDSI_DJF) <- raster_names_DJF
names(NDSI_MAM) <- raster_names_MAM
names(NDSI_JJA) <- raster_names_JJA

thrSnow <- c(1)
modLst <- list()
nr <- 0
for(i in 1:length(thrSnow)){
  message(i)
  outLst <- list()
  df$ThrX <- ifelse(df$Snow>=thrSnow[i],1,0)
  glmm1 <- glmer(ThrX~(NDSI|Stations)+NDSI+(NDSI|AltC)+(NDSI|Landcover),data=df,family = binomial("logit"),
                 control=glmerControl(optimizer="nloptwrap",optCtrl=list(maxfun=2e5)))
  
  # Save model
  outLst[["Model"]] <- glmm1 
  # Model summary
  outLst[["Summary"]] <- summary(glmm1)
  # Category effects (intercept and slope)
  outLst[["RandomEffects"]] <- ranef(glmm1)
  
  # Rsquared, marginal and conditional
  # outLst[["R2"]] <- performance::r2(glmm1,tolerance = 1e-05)
  outLst[["R2bis"]] <- r.squaredGLMM(glmm1)
  
  
  # Prediction only without random effect of stations
  #ici l'effet fixe est d?j? pris en compte on a pas besoins de le rajouter
  pr <- predict(glmm1,type="response",re.form=~(NDSI|AltC)+(NDSI|Landcover))
  outLst[["Predictions"]] <- pr
  
  # Evaluation
  tss <- bm_FindOptimStat(metric.eval="TSS",fit=pr,obs=df$ThrX,threshold = seq(0,1,0.05))
  #acc <- bm_FindOptimStat(metric.eval="ACCURACY",fit=pr,obs=df_DJF$ThrX,threshold = seq(0,1,0.05))
  #outLst[["PerfGLMM"]] <- list(tss,acc)
  outLst[["PerfGLMM"]] <- list(tss)
  
  ## Comparison with threshold method
  tss <- bm_FindOptimStat(metric.eval="TSS",obs=df$ThrX,fit=df$NDSI,threshold = 0.4)
  #acc <- bm_FindOptimStat(metric.eval="ACCURACY",obs=df_SON$ThrX,fit=df_SON$NDSI,threshold = 0.4)
  outLst[["PerfMethThr"]] <- list(tss)
  modLst[[i]] <- outLst
}

glmm1

modLst[[1]]$PerfMethThr
modLst[[1]]$PerfGLMM


################################## prédiction ###################################################
###Ce qui nous intéresse est le cut_off
cut_off <- as.double(outLst$PerfGLMM[[1]][2])
cut_off

NDSI_JJA
plot(NDSI_MAM[[1]])

# Créer deux listes pour stocker les moitiés 1 et 2
NDSI_SON_b <- list()
NDSI_JJA_b <- list()

############### Découper mes ratser en deux pour aller plus vite ####################
####################### Boucle sur tous les rasters dans votre stack
for (i in 1:nlayers(NDSI_SON)) {
  
  # Afficher l'indice de l'itération
  print(paste("Processing raster index", i))
  # Extraire le raster actuel
  current_raster <- NDSI_SON[[i]]
  
  # Calculer la moitié de la largeur
  half_width <- ncol(current_raster) %/% 2
  
  # Obtenir l'extent du raster actuel
  ext_current <- extent(current_raster)
  
  # Créer deux nouveaux extents pour les moitiés
  #ext_half1 <- extent(ext_current@xmin, ext_current@xmin + (half_width * res(current_raster)[1]), ext_current@ymin, ext_current@ymax)
  ext_half2 <- extent(ext_current@xmin + (half_width * res(current_raster)[1]), ext_current@xmax, ext_current@ymin, ext_current@ymax)
  
  # Couper le raster actuel en deux moitiés
  #raster_half1 <- crop(current_raster, ext_half1)
  raster_half2 <- crop(current_raster, ext_half2)
  
  # Ajouter les moitiés aux listes respectives
  #NDSI_SON_a[[i]] <- raster_half1
  NDSI_SON_b[[i]] <- raster_half2
}

NDSI_SON_b
NDSI_SON_b <- stack(NDSI_SON_b)
NDSI_JJA_bb <- stack(NDSI_JJA_b)
plot(NDSI_JJA_bb[[2]])

rm("df","modLst","NDSI_SON","outLst","raster_half2","df_SON")
gc()

###################### charger le stack NDSI ############################
###########################################################################
predStack <- stack("E:/charlotte/Model/predstack_saison.tif")

predStack[[1]]
predStack[[2]]

#### Il faut également couper en deux le predstack
# Créer deux listes pour stocker les moitiés 1 et 2
predStack_a <- list()
predStack_b <- list()

############### Découper mes ratser en deux pour aller plus vite ####################
####################### Boucle sur tous les rasters dans votre stack
for (i in 1:nlayers(predStack)) {
  
  # Afficher l'indice de l'itération
  print(paste("Processing raster index", i))
  # Extraire le raster actuel
  current_raster <- predStack[[i]]
  
  # Calculer la moitié de la largeur
  half_width <- ncol(current_raster) %/% 2
  
  # Obtenir l'extent du raster actuel
  ext_current <- extent(current_raster)
  
  # Créer deux nouveaux extents pour les moitiés
  #ext_half1 <- extent(ext_current@xmin, ext_current@xmin + (half_width * res(current_raster)[1]), ext_current@ymin, ext_current@ymax)
  ext_half2 <- extent(ext_current@xmin + (half_width * res(current_raster)[1]), ext_current@xmax, ext_current@ymin, ext_current@ymax)
  
  # Couper le raster actuel en deux moitiés
  #raster_half1 <- crop(current_raster, ext_half1)
  raster_half2 <- crop(current_raster, ext_half2)
  
  # Ajouter les moitiés aux listes respectives
  #predStack_a[[i]] <- raster_half1
  predStack_b[[i]] <- raster_half2
}

predStack_a <- stack(predStack_a)
predStack_b <- stack(predStack_b)
plot(predStack_b[[2]])
rm("predStack","raster_half2")
gc()

##creer un df pour mettre les résultats de la predi
df_resultats_predi_SON_b <- data.frame(Date = character(),                 # Create data frame
                                 Min = numeric(),
                                 Median = numeric(),
                                 Mean = numeric(),
                                 Max = numeric())

## creer un df pour mettre le nombre de snow et no snow
df_binaire_SON_b <- data.frame(Date = character(),                 # Create data frame
                         snow = numeric(),
                         no_snow = numeric(),
                         NoData = numeric() )


############# Exemple sur 1 raster #########################
##new stack
newStack <- c(predStack[[1]],predStack[[2]],NDSI_DJF[[1]])
names(newStack) <- c("Landcover","AltC","NDSI")
newStack_final <- stack(newStack)

#refaire avec les même categories et mettre allow.new.levels=F
predi <- terra::predict(newStack_final,glmm1,type="response",re.form=~(NDSI|AltC)+(NDSI|Landcover),allow.new.levels=F)

vv <- values(predi)
resultats <- summary(vv[!is.na(vv)])

#remplir le df
df_resultats_predi <- rbind(df_resultats_predi,c(names(NDSI_DJF[[1]]), as.double(resultats[c(1, 3, 4, 6)])))
colnames(df_resultats_predi) <- c("Date", "Min", "Median", "Mean", "Max")

###Pour rendre binaire on va prendre le cut off qui maximize le tss
valBin <- predi
valBin[valBin>=cut_off] <- 1
valBin[valBin<cut_off] <- 0

prB <- pr
prB <- valBin
plot(prB)

no_snow <- length(which(getValues(prB) == 0))
snow <- length(which(getValues(prB) == 1))
NoData <- sum(is.na(values(prB)))

df_binaire <- rbind(df_binaire, c(names(NDSI_DJF[[2]]), c(snow,no_snow,NoData)))
colnames(df_binaire) <- c("Date", "snow ", "no_snow", "NoData")

#df_prb <- as.data.frame(prB)
#sum(df_prb==0, na.rm = TRUE)
#sum(df_prb==1,na.rm = TRUE)
#writeRaster(prB,"E:/charlotte/Model/predi_raster_binaire_SON_2017_thr15.tif",filetype = "GTiff", overwrite = TRUE)

############################# pour itérer sur tt les raster ##################
#############################################################################
# Boucle pour itérer sur chaque raster dans NDSI_DJF
NDSI_MAM_a_a <- NDSI_MAM_a[[78:108]]

list_predi <- list()

# Boucle pour itérer sur chaque raster dans NDSI_DJF
for (i in 1:nlayers(NDSI_SON_b)) {
  # Afficher l'indice de l'itération
  print(paste("Processing raster index", i))
  # Créer un nouveau stack avec les rasters nécessaires
  newStack <- c(predStack_b[[1]], predStack_b[[2]], NDSI_SON_b[[i]])
  names(newStack) <- c("Landcover", "AltC", "NDSI")
  newStack_final <- stack(newStack)
  
  # Prédiction
  predi <- terra::predict(newStack_final, glmm1, type = "response", re.form = ~(NDSI | AltC) + (NDSI | Landcover), allow.new.levels = FALSE)
  
  # Résumé des prédictions
  vv <- values(predi)
  resultats <- summary(vv[!is.na(vv)])
  
  # Ajouter une ligne au dataframe des résultats
  df_resultats_predi_SON_b <- rbind(df_resultats_predi_SON_b, c(names(NDSI_SON_b[[i]]), as.double(resultats[c(1, 3, 4, 6)])))
  
  # Pour rendre binaire
  valBin <- predi
  valBin[valBin >= cut_off] <- 1
  valBin[valBin < cut_off] <- 0
  
  # Ajouter une ligne au dataframe binaire
  df_binaire_SON_b <- rbind(df_binaire_SON_b, c(names(NDSI_SON_b[[i]]), length(which(getValues(valBin) == 1)), length(which(getValues(valBin) == 0)), sum(is.na(values(valBin)))))
  
  # Ajouter le raster à la stack
  list_predi[[i]] <- valBin
  
  # Appel à gc() pour tenter de libérer de la mémoire
  gc()
}
gc()
raster_stack_predi_SON_b <- stack(list_predi)

rm("newStack_final","NDSI_SON_b","list_predi","predi")
rm("df_binaire_SON_b","df_resultats_predi_SON_b","newStack")
rm("tss","df_SON","predStack_b","glmm1")
rm("ext_half2","ext_current","current_raster")

# Assurez-vous que les noms de colonnes sont corrects
colnames(df_resultats_predi_SON_b) <- c("Date", "Min", "Median", "Mean", "Max")

# Assurez-vous que les noms de colonnes sont corrects
colnames(df_binaire_SON_b) <- c("Date", "snow", "no_snow", "NoData")


writeRaster(raster_stack_predi_SON_b,"E:/charlotte/Model/raster_stack_predi_SON_b.tif",filetype = "GTiff", overwrite = TRUE)
writeRaster(NDSI_MAM_b,"E:/charlotte/Model/NDSI_MAM_b.tif",filetype = "GTiff", overwrite = TRUE)
write.xlsx(df_binaire_SON_b, "E:/charlotte/Model/df_binaire_SON_b.xlsx", rowNames = FALSE)
write.xlsx(df_resultats_predi_SON_b, "E:/charlotte/Model/df_resultats_predi_SON_b.xlsx", rowNames = FALSE)
t <- stack("E:/charlotte/Model/raster_stack_predi_MAM_a3.tif")
df_binaire_DJF_a <- df_binaire
df_resultats_predi_a <- df_resultats_predi
plot(t[[100]])
plot(NDSI_DJF[[3]])
gc()
rm("raster_stack_predi_SON_b")
#### Mettre les stack a et b ensemble
raster_stack_predi_DJF_a <- stack("E:/charlotte/Model/raster_stack_predi_DJF_a.tif")
raster_stack_predi_DJF_b <- stack("E:/charlotte/Model/raster_stack_predi_DJF_b.tif")
names(raster_stack_predi_DJF_a) <- raster_names_DJF[1:73]
names(raster_stack_predi_DJF_b) <- raster_names_DJF[73:105]
raster_stack_predi_DJF_a[[72]]
raster_stack_predi_DJF_a <- dropLayer(raster_stack_predi_DJF_a, 73)

raster_stack_predi_DJF <- stack(raster_stack_predi_DJF_a, raster_stack_predi_DJF_b)
names(raster_stack_predi_DJF)



#####on va enlever les cloud en NA et les mettre en 205
### On veut mtn avoir 205 pour les cloud et -999 pour les NA
#Dire que toute les NA sont égal à 205
# replacing NA's by zero
prB3 <- prB
prB3[is.na(prB3[])] <- 2
plot(prB3)

Lacs_raster[Lacs_raster>0]<-NA
plot(Lacs_raster)

Suisse_raster[Suisse_raster==0] <- NA
plot(Suisse_raster)

##on crée un mask pour enlever les lacs
prB3.mask <- mask(prB3, Lacs_raster)
plot(prB3.mask)

##on crée un mask pour enlever les zones hors suisse
prB3.mask <- mask(prB3.mask, Suisse_raster)
plot(prB3.mask)

###pour savoir les stats
##nombre de NA dans le raster
sum(!is.na(values(prB3.mask)))#nombre de pixel qui recouvre la suisse
sum(is.na(values(prB3.mask)))## pixel pas pris en compte dans l'analyse lac ou hors suisse
length(which(getValues(prB3.mask) == 2)) #ici on a 24% de cloud 
length(which(getValues(prB3.mask) == 1))
length(which(getValues(prB3.mask) == 0))

(length(which(getValues(prB3.mask) == 0))/sum(!is.na(values(prB3.mask))))*100
(length(which(getValues(prB3.mask) == 1))/sum(!is.na(values(prB3.mask))))*100
(length(which(getValues(prB3.mask) == 2))/sum(!is.na(values(prB3.mask))))*100
unique(values(prB3.mask),na.last=NA)

