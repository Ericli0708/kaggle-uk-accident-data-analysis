######### Loading libraries ############
library(readr)     #Reading in data with custom constraints
library(fpc)       #DBSCAN algorithm
library(ggplot2)   #Plotting
library(mice)      #Imputation of missing values
library(rgdal)     #Working with geospatial data
library(klaR)      #k-modes algorithm
library(cluster)   #Distance metrics for categorical data

############ Reading in the data ############
data1 <- read_csv("data/accidents_2009_to_2011.csv", 
                  col_types = cols(`1st_Road_Class` = col_character(), 
                                   `1st_Road_Number` = col_character(), 
                                   `2nd_Road_Class` = col_character(), 
                                   `2nd_Road_Number` = col_character(), 
                                   Date = col_skip(), Day_of_Week = col_skip(), 
                                   Junction_Detail = col_skip(), LSOA_of_Accident_Location = col_skip(), 
                                   Latitude = col_skip(), `Local_Authority_(District)` = col_character(), 
                                   `Local_Authority_(Highway)` = col_character(), 
                                   Location_Easting_OSGR = col_skip(), 
                                   Location_Northing_OSGR = col_skip(), 
                                   Longitude = col_skip(), Time = col_skip(), 
                                   Urban_or_Rural_Area = col_character(), 
                                   Year = col_skip()))

data2 <- read_csv("data/accidents_2012_to_2014.csv", 
                  col_types = cols(`1st_Road_Class` = col_character(), 
                                   `1st_Road_Number` = col_character(), 
                                   `2nd_Road_Class` = col_character(), 
                                   `2nd_Road_Number` = col_character(), 
                                   Date = col_skip(), Day_of_Week = col_skip(), 
                                   Junction_Detail = col_skip(), LSOA_of_Accident_Location = col_skip(), 
                                   Latitude = col_skip(), `Local_Authority_(District)` = col_character(), 
                                   `Local_Authority_(Highway)` = col_character(), 
                                   Location_Easting_OSGR = col_skip(), 
                                   Location_Northing_OSGR = col_skip(), 
                                   Longitude = col_skip(), Time = col_skip(), 
                                   Urban_or_Rural_Area = col_character(), 
                                   Year = col_skip()))

full_data <- rbind.data.frame(data1, data2)

londonEN1 <- read_csv("data/accidents_2009_to_2011.csv",
                      col_types = cols_only(Location_Easting_OSGR = col_guess(),
                                            Location_Northing_OSGR = col_guess()))

londonEN2 <- read_csv("data/accidents_2012_to_2014.csv",
                      col_types = cols_only(Location_Easting_OSGR = col_guess(),
                                            Location_Northing_OSGR = col_guess()))

londonEN <- rbind.data.frame(londonEN1,londonEN2)

latlon1 <- read_csv("data/accidents_2009_to_2011.csv",
                    col_types = cols_only(Latitude = col_guess(),
                                          Longitude = col_guess()))

latlon2 <- read_csv("data/accidents_2012_to_2014.csv",
                    col_types = cols_only(Latitude = col_guess(),
                                          Longitude = col_guess()))

latlons <- rbind.data.frame(latlon1,latlon2)
aaaaa <- cbind.data.frame(full_data,latlons)

years1 <- read_csv("data/accidents_2009_to_2011.csv",
                   col_types = cols_only(Year = col_guess()))

years2 <- read_csv("data/accidents_2012_to_2014.csv",
                   col_types = cols_only(Year = col_guess()))

full_years <- rbind.data.frame(years1, years2)

EN1 <- read_csv("data/accidents_2009_to_2011.csv",
                col_types = cols_only(Location_Easting_OSGR = col_guess(),
                                      Location_Northing_OSGR = col_guess()))
                
EN2 <- read_csv("data/accidents_2012_to_2014.csv",
                col_types = cols_only(Location_Easting_OSGR = col_guess(),
                                      Location_Northing_OSGR = col_guess()))

full_EN <- rbind.data.frame(EN1, EN2)



rm(data1,data2,latlon1,latlon2,years1,years2, EN1, EN2)
######################################
######################################

############################# SUBSET BY LOCATION SHAPEFILE #############################

### UK ###
lnd2 <- readOGR(dsn = "data", 
                layer = "ne_50m_admin_0_countries")
UK <- lnd2[lnd2$NAME=="United Kingdom",]
plot(UK)
lnd1 <- readOGR(dsn = "data", 
               layer = "Areas")
plot(lnd2)

### London ###
lnd <- readOGR(dsn = "data", 
               layer = "London_Borough_Excluding_MHW")
EN_spatial <- SpatialPoints(cbind(full_EN$Location_Easting_OSGR,full_EN$Location_Northing_OSGR), CRS(proj4string(lnd)))
ENsub <- spTransform(EN_spatial, CRS(proj4string(lnd))) # transform CRS

plot(lnd)
points(ENsub[lnd,], col=rgb(0, 0, 1, 0.1))

rownames(ENsub@coords) <- c(1:nrow(ENsub@coords))
london_EN <- ENsub[lnd,]
london_data <- full_data[as.integer(rownames(london_EN@coords)),]

london_years <- full_years[as.integer(rownames(london_EN@coords)),]

london_pca <- pca_data[as.integer(rownames(london_EN@coords)),]
london_pca_2009 <- london_pca[london_years == 2009,]
london_pca_2010 <- london_pca[london_years == 2010,]
london_pca_2011 <- london_pca[london_years == 2011,]
london_pca_2012 <- london_pca[london_years == 2012,]
london_pca_2013 <- london_pca[london_years == 2013,]
london_pca_2014 <- london_pca[london_years == 2014,]
######################################
######################################

for( i in 2:ncol(full_data) ) {
  if( class(full_data[[i]]) == "character" ) {
    full_data[[i]] <- as.factor(full_data[[i]])
  }
}

str(full_data)
names(full_data)

pca_data <- full_data[c(2,3,4,5,11,22,23)]
pca_data[[6]] <- as.integer(pca_data[[6]])
pca_data[[7]] <- as.integer(pca_data[[7]])

summary(pca_data)
pca_data_imputed <- complete(mice(pca_data))

### PCA ###
pca_results <- prcomp(pca_data_imputed, scale. = T)

summary(pca_results)
plot(pca_results,type='l')

plot((summary(pca_results))$importance[3,],type='b',
     xlab = "Component", ylab = "Cumulative Variance")

full_data[-c(names(pca_data))]




scaled_pca_data <- scale(pca_data_imputed[c(1,2,3,5)])

db <- dbscan(scaled_pca_data, eps = 2, MinPts = 300)

unique(db$cluster)

table(db$cluster,pca_data[[7]])

################################################
################################################
#DBSCAN LONDON MAIN
################################################
################################################
dbs <- function(database, e = 2, m = 300) {
  
  scaled_london_pca <- scale(database[c(1,2,3,5)])
  db <<- dbscan(scaled_london_pca, eps = e, MinPts = m)
  
  n_clusters <<- length(unique(db$cluster))-1
  print(paste("Clusters:", n_clusters))
  print(table(db$cluster,database[[7]]))
}

km <- kmeans(scaled_london_pca[,-1], 2, nstart = 40)
################################################
################################################
################################################
################################################

a <- 2
while(n_clusters != 2) {
  a <- a + 1
  dbs(london_pca_2009, a, 300) 
}

set.seed(314159)
scaled_london_pca <- scale(london_pca_2009[c(1,2,3,5)])
km <- kmeans(scaled_london_pca, 2, nstart = 20)
print(table(km$cluster,london_pca_2009[[7]]))
print(prop.table(table(km$cluster,london_data_2009[[22]]),1))

london_data_2009 <- london_data[london_years == 2009,]

print(prop.table(table(london_data_2009[[8]],
                       london_data_2009[[22]]),1))

############################################
############################################
scaled_london_pca <- scale(london_pca_2009[c(1,2,3,5,7)])
km <- kmeans(scaled_london_pca, 2, nstart = 20)

plot(lnd)
points(ENsub[lnd,][1:100], col=c(km$cluster[1:100]))
############################################
############################################


plot(lnd)
points(ENsub[lnd,], col=london_data$Road_Surface_Conditions)

london <- cbind.data.frame(london_data,london_EN@coords)
london <- cbind.data.frame(london, london_years)

london$Accident_Severity <- as.factor(london$Accident_Severity)

fort <- fortify(lnd)
ggplot() + geom_path(aes(long,lat, group = group),data = fort) + 
  geom_point(aes(long, lat, col = Accident_Severity),
             data = london, alpha = 1, size = 0.0001) + 
  theme_bw() +
  theme(axis.line = element_blank(),
        axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank()) +
  coord_fixed() + 
  guides(colour = guide_legend(override.aes = list(size=4))) +
  scale_color_brewer(palette="Set1")

fort1 <- fortify(lnd1)
fort_UK <- fortify(UK)
aaaaa <- cbind.data.frame(full_data,latlons)

ggplot() + geom_path(aes(long,lat, group = group),data = fort) + 
  geom_point(aes(long, lat),
             data = london[london$Accident_Severity == 3,],
             size = 0.4, alpha = 1, color = 'cyan2') + 
  geom_point(aes(long, lat),
             data = london[london$Accident_Severity == 2,],
             size = 0.4, alpha = 1, color = 'yellow') + 
  geom_point(aes(long, lat),
             data = london[london$Accident_Severity == 1,],
             size = 0.4, alpha = 1, color = 'red') + 
  theme_bw() +
  theme(axis.line = element_blank(),
        axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank()) + 
  coord_fixed()

ggplot() + geom_bar(aes(as.factor(1:3), 
                        fill = as.factor(unique(aaaaa$Accident_Severity)))) +
  scale_fill_manual(name = 'Accident Severity',
                      values = c("1" = 'red',
                                 "2" = 'yellow',
                                 "3" = 'cyan2'))

########################################
########################################
aaaaa_2011 <- aaaaa[full_years == 2011,]

scaled_pca_2011 <- scale(pca_data[full_years$Year=='2011' ,c(1,2,3,5,7)])
km <- kmeans(scaled_pca_2011, 2, nstart = 40)

ggplot() + geom_path(aes(long,lat, group = group),data = fort_UK) + 
  geom_point(aes(Longitude, Latitude),
             data = aaaaa_2011[km$cluster == 1,],
             size = 0.0001, alpha = 1, color = 'cyan2') + 
  geom_point(aes(Longitude, Latitude),
             data = aaaaa_2011[km$cluster == 2,],
             size = 0.0001, alpha = 0.5, color = 'yellow') + 
  theme_bw() +
  theme(axis.line = element_blank(),
        axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank())

table(as.factor(km$cluster))

ROU_2011 <- full_data$Urban_or_Rural_Area[full_years == 2011]
prop.table(table(ROU_2011,as.factor(km$cluster)),1)

i <- 1
tablea <- table(ROU_2011)
clus <- km$cluster

# Taking approximately equal observations of accidents in rural and urban 
while( tablea[["2"]]/tablea[["1"]] < 0.95 ) {
  if (ROU_2011[i] == "1") {
    ROU_2011 <- ROU_2011[-i]
    clus <- clus[-i]
    tablea <- table(ROU_2011)
  } else {
    i <- i + 1
  }
}

tablea <- table(ROU_2011)
tablea[["2"]]/tablea[["1"]]

ggplot() + geom_path(aes(long,lat, group = group),data = fort_UK) + 
  geom_point(aes(Longitude, Latitude),
             data = aaaaa_2011[km$cluster == 1,],
             size = 0.0001, alpha = 1, color = 'cyan2') + 
  geom_point(aes(Longitude, Latitude),
             data = aaaaa_2011[km$cluster == 2,],
             size = 0.0001, alpha = 0.5, color = 'yellow') + 
  theme_bw() +
  theme(axis.line = element_blank(),
        axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank())

table(clus, ROU_2011)

##########
##########
balanced <- na.omit(aaaaa_2011)
tablea <- table(balanced$Urban_or_Rural_Area)

for( i in 1:nrow(balanced)) {
  if (balanced$Urban_or_Rural_Area[i] == "1") {
    balanced <- balanced[-i,]
    tablea <- table(balanced$Urban_or_Rural_Area)
  }
}

tablea[["1"]]/tablea[["2"]]

balanced$Did_Police_Officer_Attend_Scene_of_Accident <- as.integer(balanced$Did_Police_Officer_Attend_Scene_of_Accident)
scaled_pca_2011 <- scale(balanced[c(2,3,4,5,11,23)])
km <- kmeans(scaled_pca_2011, 2, nstart = 40)


ggplot() + geom_path(aes(long,lat, group = group),data = fort_UK) + 
  geom_point(aes(Longitude, Latitude),
             data = balanced[km$cluster == 2,],
             size = 0.0001, alpha = 1, color = 'cyan2') + 
  geom_point(aes(Longitude, Latitude),
             data = aaaaa_2011[km$cluster == 1,],
             size = 0.0001, alpha = 0.5, color = 'yellow') + 
  theme_bw() +
  theme(axis.line = element_blank(),
        axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank())

ggplot() + geom_path(aes(long,lat, group = group),data = fort_UK) + 
  geom_point(aes(Longitude, Latitude),
             data = balanced,
             size = 0.0001, alpha = 1, color = 'red') + 
  theme_bw() +
  theme(axis.line = element_blank(),
        axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank())


##########################################
#LONDON DBSCAN
##########################################
londonENa <- londonENa[as.integer(rownames(london_EN@coords)),]
names(londonENa) <- c("Longitude","Latitude")

names(london_pca)

scaled_pca_london <- scale(london_pca[,c(2,3,4,5,6,7)])
km_london <- kmeans(scaled_pca_london, 6, nstart = 20)

ggplot() + geom_path(aes(long,lat, group = group),data = fort) + 
  geom_point(aes(long, lat, col = as.factor(km$cluster)),
             data = london[london_years=='2009',],
             size = 0.1, alpha = 1) + 
  theme_bw() +
  theme(axis.line = element_blank(),
        axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank()) + 
  coord_fixed() + 
  guides(colour = guide_legend(override.aes = list(size=4))) +
  scale_color_brewer(palette="Dark2")


table(km$cluster)

db <- dbscan(scaled_pca_data, eps = 2, MinPts = 300)

##########################################
#FULL
##########################################
scaled_pca_full <- scale(pca_data[,c(1,2,3,4,5,6,7)])
km <- kmeans(scaled_pca_full[,c(1,2,3,4,5,7)], 2, nstart = 20)

ggplot() + geom_path(aes(long,lat, group = group),data = fort_UK) + 
  geom_point(aes(Longitude, Latitude, col = as.factor(km$cluster)),
             data = latlons,
             size = 0.000000000000000000001, alpha = 1) + 
  ##geom_point(aes(Longitude, Latitude),
  #           data = londonENa[km$cluster == 3,],
  #           size = 0.0001, alpha = 0.35, color = 'cyan2') + 
  theme_bw() +
  theme(axis.line = element_blank(),
        axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank()) + 
  coord_fixed() + 
  guides(colour = guide_legend(override.aes = list(size=4)))


######################################################################################################
######################################################################################################
###### Distances for categorical columns #####

london_cat <- london_data[,c(10,19,21)]
london_data[[1]] <- as.factor(london_data[[1]])
london_data[[2]] <- as.factor(london_data[[2]])
london_data[[3]] <- as.factor(london_data[[3]])

london_roads <- cbind.data.frame(london_cat[,c(2,3)], london_data[,c(20,17)])
names(london_roads)
for( i in 1:4 ) {
  london_roads[[i]] <- as.factor(london_roads[[i]])
}

daze <- daisy(london_roads[london_years=='2011',], metric = 'gower')

pam2 <- pam(daze, diss = TRUE, k = 2)
sil_width <- c(pam2$silinfo$avg.width)

pam4$clustering[16:19]


#############################

for(i in 11:20){
  pam_fit <- pam(daze, diss = TRUE, k = i)
  sil_width[i-1] <- pam_fit$silinfo$avg.width
}

plot(2:20, sil_width,
     xlab = "Number of clusters",
     ylab = "Silhouette Width")
lines(2:20, sil_width)


pam4 <- pam(daze, diss = TRUE, k = 4)

pam4$silinfo$avg.width

#############################
ggplot() + geom_path(aes(long,lat, group = group),data = fort) + 
  geom_point(aes(long, lat, col = as.factor(pam4$clustering)),
             data = london[london_years=='2011',],
             size = 0.3, alpha = 1) + 
  theme_bw() +
  theme(axis.line = element_blank(),
        axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank()) + 
  coord_fixed() + 
  guides(color = guide_legend(title = 'Clustering', override.aes = list(size=4)))

pam4$clustering[16:19]

#############################

ggplot() + geom_path(aes(long,lat, group = group),data = fort) + 
  geom_point(aes(long, lat, col = as.factor(Speed_limit)),
             data = london[london_years=='2011',][london[london_years=='2011',]$Speed_limit != 30,],
             size = 1, alpha = 1) + 
  theme_bw() +
  theme(axis.line = element_blank(),
        axis.text.x=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank()) + 
  coord_fixed() + 
  guides(color = guide_legend(title = 'Speed Limit', override.aes = list(size=4)))
