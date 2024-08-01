# clustering with point slices
#
library(lidR)
library(sf)
library(lwgeom)
library(ggplot2)
library(units)
library(dplyr)

doCluster <- function (
    fileName = "",
    ptData = NULL,
    crs,
    bufferDistance,
    shrinkFactor = 0.01,
    wantPoints = FALSE,
    xLabel = "X",
    yLabel = "Y"
)
{
  # load points from LAS file if given
  if (file.exists(fileName)) {
    las <- readLAS(fileName)
    p <- las@data
  }
  else if (!is.null(ptData)) {
    p <- ptData
  }
  else
    stop("must provide either fileName or ptData")
  
  # convert points to sf point set...keep XY columns
  points <- st_as_sf(p, coords = c(xLabel, yLabel), remove = FALSE, crs = crs)
  
  # buffer points
  bp <- st_buffer(points, bufferDistance, nQuadSegs = 4) 
  
  # union buffered points
  clusters <- st_cast(st_union(bp), "POLYGON")
  
  clusters <-  sf::st_as_sf(clusters)
  clusters$id <- 1:nrow(clusters)
  
  if (wantPoints) {
    points.with.cluster.id <- st_join(points, clusters)
  
    # assign cluster ID to points
    points$group <- factor(points.with.cluster.id$id)
  }
  
  #ggplot() +
    #geom_sf(data=clusters) +
    ##  geom_point(data = points, aes(x = X, y = Y), color = points$group, size=1) +
    #theme_bw()
  
  # reduce the size of the area...causes some empty geometries unless you use a slightly smaller buffer distance
  shrunkClusters <- st_buffer(clusters, -(bufferDistance - shrinkFactor), nQuadSegs = 4)
  
  # compute area and equivalent diameter for reduced cluster polygons
  clusters$area <- st_area(clusters)
  clusters$perimeter <- lwgeom::st_perimeter_lwgeom(clusters)
  clusters$dia <- (sqrt(clusters$area / pi)) * 2.0
  
  # compute area and equivalent diameter for reduced cluster polygons
  shrunkClusters$area <- st_area(shrunkClusters)
  shrunkClusters$perimeter <- lwgeom::st_perimeter_lwgeom(shrunkClusters)
  shrunkClusters$dia <- (sqrt(shrunkClusters$area / pi) + set_units(shrinkFactor, "m")) * 2.0
  
  # convert diameters to cm
  units(shrunkClusters$dia) <- "cm"
  units(clusters$dia) <- "cm"
  
  # make attributes constant over geometries
  sf::st_agr(clusters) <- "constant"
  sf::st_agr(shrunkClusters) <- "constant"
  
  c <- st_centroid(clusters)

  if (wantPoints) {
    return(list(centroids = c, tightClusters = shrunkClusters, clusters = clusters, points = points))
  }
  else {
    return(list(centroids = c, tightClusters = shrunkClusters, clusters = clusters))
  }
}

if (FALSE) {
  folder <- "H:/2024_DroneLidar/Sprawl/"
  file <- "Sprawl_002_normalized_0p75_to_1.las"
  
  dist <- 0.1
  
  blobs <- doCluster(paste0(folder, file), dist)

#  c <- st_centroid(blobs[[2]])
  
  ggplot() +
    geom_sf(data = blobs$tightClusters) +
    geom_sf(data = blobs$centroids, color = blobs$centroids$id, size=1) +
    theme_bw()
}

if (FALSE) {
  # do clustering with dbscan...very slow but does a better job with grouped points (not stems?)
  # buffer clustering does about the same on individual trees.
  #
  # outpout from dbscan is a list of points so you still have to do something with each cluster of points
  # output from buffer clustering is a set of polygons, one for each cluster.
  library(fpc)
  
  DBSCAN <- dbscan(cbind(points$X, points$Y), eps = 0.5, MinPts = 3)
  plot(points$X, points$Y, col = DBSCAN$cluster, pch = 20)
}
