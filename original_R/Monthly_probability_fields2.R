# Libraries
#install.packages("raster")
library(raster)
#install.packages("dplyr")
library(dplyr)
#install.packages("sf")
library(sf)
#install.packages("readr")
library(readr)
##pour les graphes
#install.packages("ggplot2")
#install.packages("sp")
library(sp)
#install.packages("rgdal")
library(rgdal)
#install.packages("maps")
library(maps)
library(ggplot2)
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
#install.packages('terra')
library(terra)
library(ncdf4)


monthly_products_binaire_all <- stack("G:/Gap filling 1/monthly_products_binaire_all.nc")
plot(monthly_products_binaire_all[[1]])

Names_monthly <- c("X1984.12.01", "X1985.01.01", "X1985.02.01", "X1985.03.01", "X1985.04.01", "X1985.05.01",
                   "X1985.06.01", "X1985.07.01", "X1985.08.01", "X1985.09.01", "X1985.10.01", "X1985.11.01",
                   "X1985.12.01", "X1986.01.01", "X1986.02.01", "X1986.03.01", "X1986.04.01", "X1986.05.01",
                   "X1986.06.01", "X1986.07.01", "X1986.08.01", "X1986.09.01", "X1986.10.01", "X1986.11.01",
                   "X1986.12.01", "X1987.02.01", "X1987.03.01", "X1987.04.01", "X1987.05.01", "X1987.06.01",
                   "X1987.07.01", "X1987.08.01", "X1987.09.01", "X1987.10.01", "X1987.11.01", "X1987.12.01",
                   "X1988.01.01", "X1988.02.01", "X1988.03.01", "X1988.04.01", "X1988.05.01", "X1988.06.01",
                   "X1988.07.01", "X1988.08.01", "X1988.09.01", "X1988.10.01", "X1988.11.01", "X1988.12.01",
                   "X1989.01.01", "X1989.02.01", "X1989.03.01", "X1989.04.01", "X1989.05.01", "X1989.06.01",
                   "X1989.07.01", "X1989.08.01", "X1989.09.01", "X1989.10.01", "X1989.11.01", "X1989.12.01",
                   "X1990.01.01", "X1990.02.01", "X1990.03.01", "X1990.04.01", "X1990.05.01", "X1990.06.01",
                   "X1990.07.01", "X1990.08.01", "X1990.09.01", "X1990.10.01", "X1990.11.01", "X1990.12.01",
                   "X1991.01.01", "X1991.02.01", "X1991.03.01", "X1991.04.01", "X1991.05.01", "X1991.06.01",
                   "X1991.07.01", "X1991.08.01", "X1991.09.01", "X1991.10.01", "X1991.11.01", "X1991.12.01",
                   "X1992.01.01", "X1992.02.01", "X1992.03.01", "X1992.04.01", "X1992.05.01", "X1992.06.01",
                   "X1992.07.01", "X1992.08.01", "X1992.09.01", "X1992.10.01", "X1992.11.01", "X1992.12.01",
                   "X1993.01.01", "X1993.02.01", "X1993.03.01", "X1993.04.01", "X1993.05.01", "X1993.06.01",
                   "X1993.07.01", "X1993.08.01", "X1993.09.01", "X1993.10.01", "X1993.11.01", "X1993.12.01",
                   "X1994.01.01", "X1994.02.01", "X1994.03.01", "X1994.04.01", "X1994.05.01", "X1994.06.01",
                   "X1994.07.01", "X1994.08.01", "X1994.09.01", "X1994.10.01", "X1994.11.01", "X1994.12.01",
                   "X1995.01.01", "X1995.02.01", "X1995.03.01", "X1995.04.01", "X1995.05.01", "X1995.06.01",
                   "X1995.07.01", "X1995.08.01", "X1995.09.01", "X1995.10.01", "X1995.11.01", "X1995.12.01",
                   "X1996.01.01", "X1996.02.01", "X1996.03.01", "X1996.04.01", "X1996.05.01", "X1996.06.01",
                   "X1996.07.01", "X1996.08.01", "X1996.09.01", "X1996.10.01", "X1996.11.01", "X1996.12.01",
                   "X1997.01.01", "X1997.02.01", "X1997.03.01", "X1997.04.01", "X1997.05.01", "X1997.06.01",
                   "X1997.07.01", "X1997.08.01", "X1997.09.01", "X1997.10.01", "X1997.11.01", "X1997.12.01",
                   "X1998.01.01", "X1998.02.01", "X1998.03.01", "X1998.04.01", "X1998.05.01", "X1998.06.01",
                   "X1998.07.01", "X1998.08.01", "X1998.09.01", "X1998.10.01", "X1998.11.01", "X1998.12.01",
                   "X1999.01.01", "X1999.02.01", "X1999.03.01", "X1999.04.01", "X1999.05.01", "X1999.06.01",
                   "X1999.07.01", "X1999.08.01", "X1999.09.01", "X1999.10.01", "X1999.11.01", "X1999.12.01",
                   "X2000.01.01", "X2000.02.01", "X2000.03.01", "X2000.04.01", "X2000.05.01", "X2000.06.01",
                   "X2000.07.01", "X2000.08.01", "X2000.09.01", "X2000.10.01", "X2000.11.01", "X2000.12.01",
                   "X2001.01.01", "X2001.02.01", "X2001.03.01", "X2001.04.01", "X2001.05.01", "X2001.06.01",
                   "X2001.07.01", "X2001.08.01", "X2001.09.01", "X2001.10.01", "X2001.11.01", "X2001.12.01",
                   "X2002.01.01", "X2002.02.01", "X2002.03.01", "X2002.04.01", "X2002.05.01", "X2002.06.01",
                   "X2002.07.01", "X2002.08.01", "X2002.09.01", "X2002.10.01", "X2002.11.01", "X2002.12.01",
                   "X2003.01.01", "X2003.02.01", "X2003.03.01", "X2003.04.01", "X2003.05.01", "X2003.06.01",
                   "X2003.07.01", "X2003.08.01", "X2003.09.01", "X2003.10.01", "X2003.11.01", "X2003.12.01",
                   "X2004.01.01", "X2004.02.01", "X2004.03.01", "X2004.04.01", "X2004.05.01", "X2004.06.01",
                   "X2004.07.01", "X2004.08.01", "X2004.09.01", "X2004.10.01", "X2004.11.01", "X2004.12.01",
                   "X2005.01.01", "X2005.02.01", "X2005.03.01", "X2005.04.01", "X2005.05.01", "X2005.06.01",
                   "X2005.07.01", "X2005.08.01", "X2005.09.01", "X2005.10.01", "X2005.11.01", "X2005.11.01",
                   "X2006.01.01", "X2006.02.01", "X2006.03.01", "X2006.04.01", "X2006.05.01", "X2006.06.01",
                   "X2006.07.01", "X2006.08.01", "X2006.09.01", "X2006.10.01", "X2006.11.01", "X2006.12.01",
                   "X2007.01.01", "X2007.02.01", "X2007.03.01", "X2007.04.01", "X2007.05.01", "X2007.06.01",
                   "X2007.07.01", "X2007.08.01", "X2007.09.01", "X2007.10.01", "X2007.11.01", "X2007.12.01",
                   "X2008.01.01", "X2008.02.01", "X2008.03.01", "X2008.04.01", "X2008.05.01", "X2008.06.01",
                   "X2008.07.01", "X2008.08.01", "X2008.09.01", "X2008.10.01", "X2008.11.01", "X2008.12.01",
                   "X2009.01.01", "X2009.02.01", "X2009.03.01", "X2009.04.01", "X2009.05.01", "X2009.06.01",
                   "X2009.07.01", "X2009.08.01", "X2009.09.01", "X2009.10.01", "X2009.11.01", "X2009.12.01",
                   "X2010.01.01", "X2010.02.01", "X2010.03.01", "X2010.04.01", "X2010.05.01", "X2010.06.01",
                   "X2010.07.01", "X2010.08.01", "X2010.09.01", "X2010.10.01", "X2010.11.01", "X2010.12.01",
                   "X2011.01.01", "X2011.02.01", "X2011.03.01", "X2011.04.01", "X2011.05.01", "X2011.06.01",
                   "X2011.07.01", "X2011.08.01", "X2011.09.01", "X2011.10.01", "X2011.11.01", "X2011.12.01",
                   "X2013.03.01", "X2013.04.01", "X2013.05.01", "X2013.06.01", "X2013.07.01", "X2013.08.01",
                   "X2013.09.01", "X2013.10.01", "X2013.11.01", "X2013.12.01", "X2014.01.01", "X2014.02.01",
                   "X2014.03.01", "X2014.04.01", "X2014.05.01", "X2014.06.01", "X2014.07.01", "X2014.08.01",
                   "X2014.09.01", "X2014.10.01", "X2014.11.01", "X2014.12.01", "X2015.01.01", "X2015.02.01",
                   "X2015.03.01", "X2015.04.01", "X2015.05.01", "X2015.06.01", "X2015.07.01", "X2015.08.01",
                   "X2015.09.01", "X2015.10.01", "X2015.11.01", "X2015.12.01", "X2016.01.01", "X2016.02.01",
                   "X2016.03.01", "X2016.04.01", "X2016.05.01", "X2016.06.01", "X2016.07.01", "X2016.08.01",
                   "X2016.09.01", "X2016.10.01", "X2016.11.01", "X2016.12.01", "X2017.01.01", "X2017.02.01",
                   "X2017.03.01", "X2017.04.01", "X2017.05.01", "X2017.06.01", "X2017.07.01", "X2017.08.01",
                   "X2017.09.01", "X2017.10.01", "X2017.11.01", "X2017.12.01", "X2018.01.01", "X2018.02.01",
                   "X2018.03.01", "X2018.04.01", "X2018.05.01", "X2018.06.01", "X2018.07.01", "X2018.08.01",
                   "X2018.09.01", "X2018.10.01", "X2018.11.01", "X2018.12.01", "X2019.01.01", "X2019.02.01",
                   "X2019.03.01", "X2019.04.01", "X2019.05.01", "X2019.06.01", "X2019.07.01", "X2019.08.01",
                   "X2019.09.01", "X2019.10.01", "X2019.11.01", "X2019.12.01", "X2020.01.01", "X2020.02.01",
                   "X2020.03.01", "X2020.04.01", "X2020.05.01", "X2020.06.01", "X2020.07.01", "X2020.08.01",
                   "X2020.09.01", "X2020.10.01", "X2020.11.01", "X2020.12.01", "X2021.01.01", "X2021.02.01",
                   "X2021.03.01", "X2021.04.01", "X2021.05.01", "X2021.06.01", "X2021.07.01", "X2021.08.01",
                   "X2021.09.01", "X2021.10.01", "X2021.11.01", "X2021.12.01")

names(monthly_products_binaire_all) <- Names_monthly
Names_monthly_dates <- as.Date(gsub("X", "", names(monthly_products_binaire_all)), format = "%Y.%m.%d")
names(monthly_products_binaire_all) <- Names_monthly_dates

#########################je vais créer une liste de ratser stack par mois ###################################
#######################  Attention ici le 12 est le premier de la liste et on commence par 2021 et ensuite on va vers 1985

# Créer une liste vide pour stocker les stack par mois
stacks_par_mois <- list()
# Extraire les noms des rasters dans le stack
noms_rasters <- names(monthly_products_binaire_all)

# Boucler à travers les noms de raster
for (nom_raster in noms_rasters) {
  # Extraire le mois du nom du raster
  mois <- substr(nom_raster, 7, 8)
  
  # Si le mois est déjà présent dans la liste, ajouter le raster au stack correspondant
  if (mois %in% names(stacks_par_mois)) {
    stacks_par_mois[[mois]] <- stack(monthly_products_binaire_all[[nom_raster]], stacks_par_mois[[mois]])
  } else { # Sinon, créer une nouvelle entrée dans la liste pour ce mois
    stacks_par_mois[[mois]] <- monthly_products_binaire_all[[nom_raster]]
  }
}


stacks_par_mois
###snow #############
rasters_resume_par_mois_80_snow <- list()

# Parcourir chaque stack de la liste stacks_par_mois
for (i in 1:length(stacks_par_mois)) {
  print(i)
  # Extraire le stack pour ce mois
  stack_mois_80_snow1 <- stacks_par_mois[[i]]
  
  # Effectuer le calcul pour chaque pixel
  resultat_80_snow1 <- calc(stack_mois_80_snow1, function(x) {
    if (sum(x %in% c(0, 1), na.rm = FALSE) < 29) {
      return(5)
    } else {
      return(sum(x == 1, na.rm = FALSE) / sum(x %in% c(0, 1), na.rm = FALSE))
    }
  })
  
  # Ajouter le raster de résumé à la liste
  rasters_resume_par_mois_80_snow[[i]] <- resultat_80_snow1
}

rasters_resume_par_mois_80_snow

# Initialiser une liste pour stocker les nombres de pixels égaux à 1
pixels_egaux_1_80_snow <- numeric(length(rasters_resume_par_mois_80_snow))

# Parcourir chaque raster dans la liste
for (i in seq_along(rasters_resume_par_mois_80_snow)) {
  # Remplacer les valeurs différentes de 1 par NA dans le raster actuel
  rasters_resume_par_mois_80_snow[[i]][rasters_resume_par_mois_80_snow[[i]] != 1] <- NA
  
  # Compter le nombre de pixels égaux à 1 dans le raster actuel
  pixels_egaux_1_80_snow[i] <- sum(getValues(rasters_resume_par_mois_80_snow[[i]]) == 1, na.rm = TRUE)
}
plot(rasters_resume_par_mois_80_snow[[1]])

# Diviser chaque valeur par 40483368 et multiplier par 100
pixels_egaux_1_percentage_80_snow <- sapply(pixels_egaux_1_80_snow, function(x) {
  if (!is.na(x)) {
    x <- (x / 40483368) * 100
  }
  return(x)
})

print(pixels_egaux_1_percentage_80_snow)


########land ###################
rasters_resume_par_mois_80_land <- list()

# Parcourir chaque stack de la liste stacks_par_mois
for (i in 1:length(stacks_par_mois)) {
  print(i)
  # Extraire le stack pour ce mois
  stack_mois_80_land <- stacks_par_mois[[i]]
  
  # Effectuer le calcul pour chaque pixel
  resultat_80_land <- calc(stack_mois_80_land, function(x) {
    if (sum(x %in% c(0, 1), na.rm = FALSE) < 29) {
      return(5)
    } else {
      return(sum(x == 0, na.rm = FALSE) / sum(x %in% c(0, 1), na.rm = FALSE))
    }
  })
  
  # Ajouter le raster de résumé à la liste
  rasters_resume_par_mois_80_land[[i]] <- resultat_80_land
}

rasters_resume_par_mois_80_land[[i]]
plot(rasters_resume_par_mois_80_land[[4]])

# Initialiser une liste pour stocker les nombres de pixels égaux à 1
pixels_egaux_1_80_land <- numeric(length(rasters_resume_par_mois_80_land))

# Parcourir chaque raster dans la liste
for (i in seq_along(rasters_resume_par_mois_80_land)) {
  # Remplacer les valeurs différentes de 1 par NA dans le raster actuel
  rasters_resume_par_mois_80_land[[i]][rasters_resume_par_mois_80_land[[i]] != 1] <- NA
  
  # Compter le nombre de pixels égaux à 1 dans le raster actuel
  pixels_egaux_1_80_land[i] <- sum(getValues(rasters_resume_par_mois_80_land[[i]]) == 1, na.rm = TRUE)
}

# Afficher le nombre de pixels égaux à 1 pour chaque raster
print(pixels_egaux_1_80_land)
plot(rasters_resume_par_mois_80_land[[6]])

# Diviser chaque valeur par 40483368 et multiplier par 100
pixels_egaux_1_percentage_80_land <- sapply(pixels_egaux_1_80_land, function(x) {
  if (!is.na(x)) {
    x <- (x / 40483368) * 100
  }
  return(x)
})

print(pixels_egaux_1_percentage_80_snow)

########### mettre ensemble par mois land et snow ###########
Suisse <-readOGR("E:/charlotte/Suisse.shp")
plot(Suisse)
# Définir un CRS (WGS 84)
crs_wgs84 <- CRS("+proj=longlat +datum=WGS84 +no_defs")
# Attribuer le CRS à votre shapefile
proj4string(Suisse) <- crs_wgs84
plot(Suisse)

plot(rasters_resume_par_mois_80_land[[4]])
plot(Suisse, border="gray45", lwd=.5, add=TRUE)

plot(rasters_resume_par_mois_80_snow[[4]])
plot(Suisse, border="gray45", lwd=.5, add=TRUE)

# Créer une liste pour stocker les rasters combinés
rasters_combines <- list()

# Parcourir chaque mois
for (i in 1:length(rasters_resume_par_mois_80_land)) {
  # Récupérer les rasters de terrain et de neige pour ce mois
  land_raster <- rasters_resume_par_mois_80_land[[i]]
  snow_raster <- rasters_resume_par_mois_80_snow[[i]]
  
  # Remplacer les valeurs de 1 dans le raster de terrain par 2
  land_raster[land_raster == 1] <- 2
  
  # Remplacer les valeurs NA dans le raster de neige par les valeurs correspondantes dans le raster de terrain
  snow_raster[is.na(snow_raster)] <- land_raster[is.na(snow_raster)]
  
  # Ajouter le raster combiné à la liste
  rasters_combines[[i]] <- snow_raster
}

# Vérifier les rasters combinés
plot(rasters_combines[[1]])
plot(Suisse, border="gray45", lwd=.5, add=TRUE)

######plot############
# Définir une palette de couleurs personnalisée
my_colors <- c("cadetblue2", "darkolivegreen2")

# Générer une palette de couleurs
my_palette <- colorRampPalette(my_colors)

# Noms des mois
noms_mois <- c("December", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November")

for (i in 1:12) {
  # Plotter le raster avec la palette de couleurs générée et un titre différent à chaque fois
  plot(rasters_combines[[i]], col = my_palette(2), main = noms_mois[i], cex.main = 1)
  plot(Suisse, border="gray45", lwd=.5, add=TRUE)
}

##### POur faire un graph des % de pixel par mois #####################
# Création des données
Land <- c(1.827911e-04, 5.785092e-03, 3.804772e-02, 1.089507e+00, 2.723145e+00, 1.831320e+01, 3.186041e+01, 4.370062e+01, 4.993906e+01, 3.172566e+01, 6.598915e+00, 3.548840e-01)
snow <- c(0.2680903,0.8121286,10.0396143,7.4514205,2.8339613,0.6216158,0.3365012,0.2492085,0.2236622,0.2211797,0.3184542,0.1151757)
mois <- c("Dec.", "Jan.", "Feb.", "Mar.", "Apr.", "May", "Jun.", "Jul.", "Aug.", "Sep.", "Oct.", "Nov.")

# Création du dataframe
df <- data.frame(Mois = mois, Land = Land, Snow=snow)

# Affichage du dataframe
print(df)

# Créer un vecteur de couleurs pour les valeurs snow et land
my_colors <- c("cadetblue2", "darkolivegreen2")

# Créer un facteur pour les mois avec l'ordre correct
df$Mois <- factor(df$Mois, levels = c("Dec.", "Jan.", "Feb.", "Mar.", "Apr.", "May", "Jun.", "Jul.", "Aug.", "Sep.", "Oct.", "Nov."))

ggplot(df, aes(x = Mois)) +
  geom_bar(aes(y = Snow), stat = "identity", fill = my_colors[1], color = "gray46",lwd = 0.5) +
  geom_bar(aes(y = Land), stat = "identity", fill = my_colors[2], color = "gray46",lwd = 0.5) +
  theme(axis.title = element_text(size = 12,face="bold"))+
  labs(title = "",
       x = "",
       y = "% of pixel") +
  theme(axis.title.y = element_text(margin = margin(t = 0, r = 5, b = 0, l = 0)),axis.text.y = element_text(size=12))+
  theme(axis.title.x = element_text(margin = margin(t = 5, r = 0, b = 0, l = 0)),axis.text.x = element_text(size=12))+
  theme_light()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1))



######### Pour enregistrer les ratser en.nc ###############
# Noms des mois
noms_mois <- c("December", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November")

# Parcourir chaque raster
for (i in 1:12) {
  # Définir le nom du fichier .nc en fonction du mois
  print(i)
  nom_fichier <- paste(noms_mois[i], ".nc", sep = "")
  
  # Enregistrer le raster en tant que fichier .nc avec le nom spécifié
  writeRaster(rasters_combines[[i]], filename = nom_fichier, format = "CDF")
}
DEM <- raster("E:/charlotte/DEM/DEM_final.tif")
DEM
writeRaster(DEM, filename = "E:/charlotte/DEM/DEM_final.tif", format = "CDF")


#####################################################découper tt les montgly product en 2 ################
# Liste des noms de mois
noms_mois <- c("December", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November")

# Initialiser deux listes vides pour stocker les moitiés de chaque raster
monthly_prob_a_list <- list()
monthly_prob_b_list <- list()

# Boucle sur chaque raster dans la liste rasters_combines
for (i in seq_along(rasters_combines)) {
  # Prendre le raster actuel
  current_raster <- rasters_combines[[i]]
  
  # Calculer la moitié de la largeur
  half_width <- ncol(current_raster) %/% 2
  
  # Obtenir l'extent du raster actuel
  ext_current <- extent(current_raster)
  
  # Créer deux nouveaux extents pour les moitiés
  ext_half1 <- extent(ext_current@xmin, ext_current@xmin + (half_width * res(current_raster)[1]), ext_current@ymin, ext_current@ymax)
  ext_half2 <- extent(ext_current@xmin + (half_width * res(current_raster)[1]), ext_current@xmax, ext_current@ymin, ext_current@ymax)
  
  # Couper le raster actuel en deux moitiés
  raster_half1 <- crop(current_raster, ext_half1)
  raster_half2 <- crop(current_raster, ext_half2)
  
  # Ajouter les moitiés aux listes respectives
  monthly_prob_a_list[[i]] <- raster_half1
  monthly_prob_b_list[[i]] <- raster_half2
}

# Convertir les listes en stack
monthly_prob_a <- stack(monthly_prob_a_list)
monthly_prob_a <- stack(monthly_prob_a_list)

plot(rasters_combines[[1]])
plot(rasters_combines[[2]])
plot(rasters_combines[[4]])
plot(monthly_prob_b_list[[4]])
plot(monthly_prob_a_list[[4]])
plot(summer_mask)
plot(summer_mask_b)
dir()

###### sauver els partie a et b #############
# Noms des mois
noms_mois <- c("December", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November")

# Parcourir chaque raster
for (i in 1:12) {
  print(i)
  # Définir le nom du fichier .nc en fonction du mois
  nom_fichier <- paste(noms_mois[i],"_b", ".nc", sep = "")
  
  # Enregistrer le raster en tant que fichier .nc avec le nom spécifié
  writeRaster(monthly_prob_b_list[[i]], filename = nom_fichier, format = "CDF")
}

writeRaster(summer_mask_a,"E:/charlotte/Mask/summer_mask_a_80.nc", format = "CDF", overwrite = TRUE)
writeRaster(summer_mask_b,"E:/charlotte/Mask/summer_mask_b_80.nc", format = "CDF", overwrite = TRUE)


















