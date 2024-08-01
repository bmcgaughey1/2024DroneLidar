# thoughts on layering the clustering approach
#
# it seems like you could slice the data into narrow vertical bands, run the clustering on each band,
# build an aggregate layer of the cluster centroids, and analyze the "stack" of cluster centroids.
# The goal is to track objects as you move up and compare the size of each object so we can tell when 
# we hit the base of the crown. The size will also help determine if an object is a tree or shrub.
# You should also be able to look at the edge to area ratio to identify down logs but the vertical
# slices might need to be thicker/taller. Logs can be sloped so they may "move" as you go up.

source("R/slicing.R")
source("R/clustering.R")

layerStart <- 0.5
layerStop <- 3.0
layerStep <- 0.1
layerCount <- (layerStop - layerStart) / layerStep - 1

pointBufferDistance <- 0.2

folder <- "H:/2024_DroneLidar/Sprawl/"
file <- "Sprawl_002_normalized.las"
fileBase <- "Sprawl_002_normalized_"

doSlices <- TRUE

#minx <- -1000000000
#miny <- -1000000000
#maxx <- 1000000000
#maxy <- 1000000000
minx <- 486025
miny <- 5125110
maxx <- 486075
maxy <- 5125185

unlink(paste0(folder, "layerXYZ.xyz"))

for (slice in 0:layerCount) {
  # build input name
  inName <- paste0(folder, file)
  
  # build output name
  sliceBase <- layerStart + slice * layerStep
  title <- paste0(fileBase, round(sliceBase, 2), "_to_", round(sliceBase + layerStep, 2))
  
  # replace periods with "p"
  outName <- paste0(folder, gsub("\\.", "p", title), ".las")
  
  # do the slice of points
  if (doSlices) {
    doSlice(inName, outName, sliceBase, sliceBase + layerStep, minx = minx, miny = miny, maxx = maxx, maxy = maxy)
  }
  
  # do clustering
  c <- doCluster(fileName = outName, crs = 26910, bufferDistance = pointBufferDistance)
  
  print(
    ggplot() +
    geom_sf(data=c$clusters) +
    #  geom_point(data = points, aes(x = X, y = Y), color = points$group, size=1) +
    theme_bw()
  )

  cent <- c$centroids
  
  # drop bad centroids
  cent <- cent[cent$area > set_units(0.0001, "m^2"), ]
  
  # drop clusters based on area
  #cent <- cent[cent$area < set_units(0.25, "m^2"), ]
  #cent <- cent[cent$area > set_units(0.000314159, "m^2"), ]
  
  # add slice number
  cent$slice <- slice * 1
  
  # add XY to columns for centroids
  cent <- cbind(cent, st_coordinates(cent))
  
  # add Z
  cent$Z <- sliceBase + layerStep / 2.0

  # accumulate centroids
  if (slice == 0) {
    allCentroids <- cent
  }
  else {
    allCentroids <- rbind(allCentroids, cent)
  }
  
  # write centroids
  #st_write(cent, paste0(folder, "layer", slice, ".shp"))

  # write XYZ file
  write.table(data.frame(cent$X, cent$Y, cent$Z), paste0(folder, "layerXYZ.xyz"), append = TRUE, col.names = F, row.names = F)
}

# experiment with the "synthetic" point cloud made up of the cluster centroids
# the problem with this is that there are lots of small clusters related to shrubs and branches so
# we need to thin the points out so we only have stems

# read layer points file converted from ASCII XYZ to LDA to LAS in FUSION
# assign projection so units stuff in doClusters() works correctly
if (FALSE) {
  pts <- readLAS(paste0(folder, "pts.las"), filter = 'xyz')
  projection(pts) <- 26910
  writeLAS(pts, paste0(folder, "pts.las"))
  
  # values for k around 4-5 seem to work well with the test data
  pts <- segment_shapes(pts, shp_line(th1 = 10, k = 5), "Linear")
  
  lp <- pts[pts@data$Linear, ]
  np <- pts[!pts@data$Linear, ]
  
  writeLAS(lp, paste0(folder, "linear_pts.las"))
  writeLAS(np, paste0(folder, "nonlinear_pts.las"))
  
  plot(lp)
  plot(np)
  plot(pts, color = "Linear")
  
  # do clustering on the centroid points...don't need them to be LAS format
  blobs <- doCluster(fileName = paste0(folder, "linear_pts.las"), bufferDistance = pointBufferDistance, wantPoints = TRUE)
}

# read point data
pts <- read.table(paste0(folder, "layerXYZ.xyz"), col.names = c("X", "Y", "Z"))

# convert to LAS
pts$ReturnNumber <- as.integer(1)
pts$NumberOfReturns <- as.integer(1)
pts$Classification <- as.integer(0)

las <- LAS(pts, crs = st_crs("EPSG:26910"))

# compute eigenvalues and test for linear features
lasShapes <- segment_shapes(las, shp_line(th1 = 10, k = layerCount / 4), "Line")
lp <- lasShapes[lasShapes@data$Line, ]
nlp <- lasShapes[!lasShapes@data$Line, ]

writeLAS(lp, paste0(folder, "linear_pts.las"))
writeLAS(nlp, paste0(folder, "nonlinear_pts.las"))

plot(lp)
plot(lasShapes, color = "Line")

#vlas <- voxelize_points(lp, 0.1)
#plot(vlas)
#rm(vlas)

#blobs <- doCluster(paste0(folder, "pts.las"), pointBufferDistance, wantPoints = TRUE)

# do clustering using the layer centroids
blobs <- doCluster(ptData = pts, bufferDistance = 1, wantPoints = TRUE, crs = 26910)

if (FALSE) {
  ggplot() +
    geom_sf(data = blobs$clusters) +
    geom_point(data = blobs$points, aes(x = X, y = Y), color = blobs$points$group, size=0.5) +
    #geom_sf(data = blobs$centroids, color = blobs$centroids$id, size=1) +
    theme_bw()
  
  library(rgl)
  library(randomcoloR)
  plot3d(blobs$points$X, blobs$points$Y, blobs$points$Z, col=randomColor(length(unique(blobs$points$group)))[as.factor(blobs$points$group)])
}

# simplify data...not really needed when reading XYZ points
pts <- data.frame(X = blobs$points$X, Y = blobs$points$Y, Z = blobs$points$Z, group = as.numeric(blobs$points$group))

# drop groups fewer than 3 points
cnts <- pts %>% group_by(group) %>% summarize(n = n())
cnts <- cnts[cnts$n > 3, ]

pts <- pts[pts$group %in% cnts$group, ]

write.table(pts[, 1:3], paste0(folder, "clusters.xyz"), col.names = F, row.names = F)

plot(blobs$tightClusters$area)

# at this point, we have data sorted by group so we can build tree models
# we can create lines using the points but this doesn't buy anything

FUSIONtrees <- data.frame(
  "TreeID" = character(),
  "X" = double(),
  "Y" = double(),
  "Elevation" = double(),
  "Height_m" = double(),
  "CBH_m" = double(),
  "MinCrownDia_m" = double(),
  "MaxCrownDia_m" = double(),
  "rotation" = double(),
  "R" = integer(),
  "G" = integer(),
  "B" = integer(),
  "DBH_m" = double(),
  "LeanFromVertical" = double(),
  "LeanAzimuth" = double(),
  "StatusCode" = integer()
)

# walk through groups using cnts
for (i in 1:nrow(cnts)) {
  # get points
  tp <- pts[pts$group == cnts$group[i], ]
  
  # sort by Z
  tp <- tp[order(tp$Z), ]
  
  # check lowest point...must be less than 1m
  if (tp$Z[1] < 5) {
    # simple assumptions:
    #   tree base is XY of lowest point (1st in sorted list)
    #   tree height is highest point (not top of tree since slicing was only for part of the full height)
    
    # compute lean-related stuff
    topDistance <- sqrt((tp$X[nrow(tp)] - tp$X[1]) ^ 2 + ((tp$Y[nrow(tp)] - tp$Y[1]) ^ 2))
    leanAngle <- 90.0 - (atan2((tp$Z[nrow(tp)] - tp$Z[1]), topDistance) * 180.0 / pi)
    leanAzimuth <- (360.0 - (atan2(tp$Y[nrow(tp)] - tp$Y[1], tp$X[nrow(tp)] - tp$X[1]) * 180.0 / pi - 90.0)) %% 360.0
    
    # no crown
    FUSIONtree <- data.frame(
      "TreeID" = cnts$group[i],
      "X" = tp$X[1],
      "Y" = tp$Y[1],
      "Elevation" = tp$Z[1],
      "Height_m" = tp$Z[nrow(tp)],
      "CBH_m" = tp$Z[nrow(tp)],
      "MinCrownDia_m" = 0.01,
      "MaxCrownDia_m" = 0.01,
      "rotation" = 0.0,
      "R" = 0,
      "G" = 192,
      "B" = 0,
      "DBH_m" = 0.2,
      "LeanFromVertical" = leanAngle,
      "LeanAzimuth" = leanAzimuth,
      "StatusCode" = 0
    )
    
    FUSIONtrees <- rbind(FUSIONtrees, FUSIONtree)
  }
}

# write FUSION trees
write.csv(FUSIONtrees, paste0(folder, "FUSIONtrees.csv"), row.names = FALSE)

if (FALSE) {
  plot3d(pts$X, pts$Y, pts$Z, col=randomColor(length(unique(pts$group)))[as.factor(pts$group)])
  
  # make lines
  pts <- sf::st_as_sf(pts, coords = c("X","Y","Z"), remove = FALSE)
  sf::st_set_crs(pts, 26910)
  
  lines <- pts %>% group_by(group) %>% summarize(n = n(), do_union=FALSE) %>% st_cast("LINESTRING")
  plot(lines)
}