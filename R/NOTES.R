# notes
#
# eigenvalue process
#   list of points
#   for each point build list of k nearest neighbors
#   use princomp to do priciple components decomposition
#   save eigenvalues (stddev) and eigenvectors (rotation) (don't really need eigenvectors)
#   compare eigenvalues using rules for various geometries
#   a1, a2, a3 are the eigenvalues in ascending order (princomp returns them in descending order)
#   th1, th2, th3 are thresholds
#   linear if th1 * a2 < a3 AND th1 * a1 < a3
#
# This code is really slow. I ran it on a subsample from the layering.R code
# and it takes 20-30 minutes. In the end it found some linear points but not as
# many as found in the lidR package segment_shapes() function. Plotting the points
# revealse that they are linear so I think the code is working.
#
# Important note: the eigenvalues from princomp are in descending order. In the rule
# above, a1, a2, a3 are in ascending order.

library(terra)
library(stats)

folder <- "H:/2024_DroneLidar/Sprawl/"
radius <- 1
th1 <- 10

# read points
pts <- read.table(paste0(folder, "layerXYZ.xyz"), col.names = c("X", "Y", "Z"))

# create spatial points
tpts <- vect(pts, geom = c("X", "Y"), crs = "EPSG:26910", keepgeom = TRUE)

tpts$Z <- pts$Z
tpts$id <- seq(1, nrow(tpts))

# buffer points
bufferedPts <- buffer(tpts, radius, quadsegs = 4)
names(bufferedPts) <- c("buff.X", "buff.Y", "buff.Z", "buff.id")

# intersect to get points close in XY
i <- intersect(bufferedPts, tpts)

# walk through points
tpts$status <- FALSE
#pt <- 1000
for (pt in 1:nrow(tpts)) {
#for (pt in 1000:2000) {
    # get close points
  closePts <- i[i$id == pt, ]
  
  # filter on height
  closePts <- closePts[abs(closePts$buff.Z - closePts$Z) <= radius, ]
  
  if (nrow(closePts) > 3) {
    # do PCA
    pc <- princomp(data.frame(closePts$buff.X, closePts$buff.Y, closePts$buff.Z))
    
    # test
    if (th1 * pc$sdev[[2]] < pc$sdev[[1]] && th1 * pc$sdev[[3]] < pc$sdev[[1]])
      tpts$status[pt] <- TRUE
  }
}

linpts <- tpts[tpts$status, ]
linpts
library(rgl)
plot3d(data.frame(linpts$X, linpts$Y, linpts$Z))


# =============================================================================
# =============================================================================

# test pTrees method in lidR
# link is to article but it is not freely available
# https://www.sciencedirect.com/science/article/abs/pii/S0303243414001135
#
# *****Unfortunately, lidRplugins is not maintained and doesn't work with 
# the current version of lidR (rgeos, rgdal, and raster dependencies)
#
library(lidR)
remotes::install_version("rgeos", version = "0.6-4")
remotes::install_version("rgdal", version = "1.6-7")
remotes::install_github("Jean-Romain/lidRplugins")

install.packages('lasR', repos = 'https://r-lidar.r-universe.dev')
library(lasR)

LASfile <- system.file("extdata", "MixedConifer.laz", package="lidR")
las = readLAS(LASfile, select = "xyz")

k = c(30,15)
ttops = find_trees(las, ptrees(k))
las   = segment_trees(las, ptrees(k))






# testing for Travis Axe
library(fusionwrapr)

setGlobalCommandOptions(runCmd = FALSE, saveCmd = FALSE)

t <- CanopyModel("test.dtm", 1.0, "m", "m", 1, 10, 2, 2, "H:/2024_DroneLidar/Sprawl/Sprawl_002.las", )


library(lidR)
las <- readLAS("H:/2024_DroneLidar/Sprawl/ITM/Off-ground points.las")
