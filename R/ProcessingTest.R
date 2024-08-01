# code to test TreeISO/CloudCompare tree segmentation approach
#
# Does data prep in R, then calls TreeISO/CC to do segmentation, then post processes
# segmented point cloud
#
# TreeISO does not require normalization but does want only points associated with 
# tree so we can remove points close to the ground. Remaining points from low vegetation 
# will produce segments but these will be eliminated in post-processing.
#
library(lidR)
library(fusionwrapr)
library(terra)
library(data.table)

# Setup -------------------------------------------------------------------
folder <- "H:/2024_DroneLidar/Sprawl/"
file <- "Sprawl_002.las"
outputFolder <- "Trees/"
outputFile <- "Sample.las"
groundModel <- "raster/Sprawl_1ft_DTM.dtm"
extent <- c(486030, 5125160, 486060, 5125190)
shrubHeight <- 1.5

# cloudcompare stuff
CC <- "\"C:/Program Files/CloudCompare/CloudCompare.exe\""
CCCommandFile <- paste0(folder, outputFolder, "CC_Cmd.txt")
CCCmd <- paste0(" -SILENT -COMMAND_FILE ", CCCommandFile)

# Pre-process point cloud -------------------------------------------------
# clip a small area from one of the tiles from sprawl
ClipData(paste0(folder, file),
         paste0(folder, outputFolder, outputFile),
         minx = extent[1],
         miny = extent[2],
         maxx = extent[3],
         maxy = extent[4],
         ground = paste0(folder, groundModel),
         zmin = shrubHeight,
         class = "~2"
#         , height = TRUE
         )

# Build command line for Cloudcompare -------------------------------------
# Default output file naming is pretty wonky and presents some problems for post-
# processing. Using the FILE option on the -SAVE_CLOUDS command allows you 
# to specify the output file. However, CC seems to add an extra forward slash.
# this might be because it expects backslashes on windows. Regardless, the fill
# is written with the desired file name.
#
# default values for parameters:
# write(paste("-TREEISO", 
#             "-LAMBDA1 1.0", 
#             "-K1 5", 
#             "-DECIMATE_RESOLUTION1 0.05",
#             "-LAMBDA2 20",
#             "-K2 20",
#             "-MAX_GAP 2.0",
#             "-DECIMATE_RESOLUTION2 0.1",
#             "-RHO 0.5",
#             "-VERTICAL_OVERLAP_WEIGHT 0.5"),
#       file = CCCommandFile, append = TRUE)
#
# references for command line syntax
# https://www.cloudcompare.org/doc/wiki/index.php/Command_line_mode
# https://github.com/truebelief/cc-treeiso-plugin
write(paste("-O -GLOBAL_SHIFT AUTO", paste0(folder, outputFolder, outputFile), "-C_EXPORT_FMT LAS"), file = CCCommandFile)
write(paste("-TREEISO", 
            "-LAMBDA1 1.0", 
            "-K1 5", 
            "-DECIMATE_RESOLUTION1 0.05",
            "-LAMBDA2 20",
            "-K2 20",
            "-MAX_GAP 4.0",
            "-DECIMATE_RESOLUTION2 0.1",
            "-RHO 0.5",
            "-VERTICAL_OVERLAP_WEIGHT 0.5"),
      file = CCCommandFile, append = TRUE)
write(paste("-SAVE_CLOUDS",
            "FILE",
            paste0(folder, outputFolder, "TreeISO_output.las")),
      file = CCCommandFile, append = TRUE)

system(paste(CC, CCCmd))

# Post-process segmented point cloud --------------------------------------
# sample area has ~29 trees (manually counting stems)

# read points
las <- readLAS(paste0(folder, outputFolder, "TreeISO_output.las"))
treeCount <- length(unique(las$final_segs))
plot(las, color = "final_segs")

# sort to make sure we have continuous set of identifiers...we do!!
#sort(unique(unlist(las$final_segs, use.names = FALSE)))

# create a dataframe for results
status <- data.frame(ID = seq(1, treeCount), 
                     ExpFactor = rep(0.0, treeCount), 
                     Test1 = rep(FALSE, treeCount),
                     Test2 = rep(FALSE, treeCount),
                     Test3 = rep(FALSE, treeCount)
)

# find average XY of each segment and interpolate a ground elevation
#aggregate(X~final_segs, las@data, FUN=mean)
#aggregate(Y~final_segs, las@data, FUN=mean)

aveX <- las@data[, list(aveX=mean(X)), final_segs]
aveY <- las@data[, list(aveY=mean(Y)), final_segs]

# join and create input for SurfaceSample
ave <- merge(aveX, aveY, by = "final_segs")
write.table(ave, file = paste0(folder, outputFolder, "SegmentAveXY.txt"),
            row.names = FALSE,
            col.names = FALSE)

# get ground elevation
SurfaceSample(paste0(folder, groundModel),
              paste0(folder, outputFolder, "SegmentAveXY.txt"),
              paste0(folder, outputFolder, "SegmentAveXYZ.txt"),
              id = TRUE)

# read output...sorted
groundZ <- read.csv(paste0(folder, outputFolder, "SegmentAveXYZ.txt"), stringsAsFactors = FALSE)

# test if points in segment start close to our height threshold
minZ <- las@data[, list(minZ=min(Z)), final_segs]

# sort
minZ <- minZ[order(final_segs), ]

# test
htThreshold <- shrubHeight + 2.5
status$Test1 <- (minZ$minZ - groundZ$Value) < htThreshold

selectList <- status$ID[status$Test1]

las2 <- las[las$final_segs %in% selectList, ]
plot(las2, color = "final_segs")

library(concaveman)
library(sf)
i <- 22
bufDist <- 0.1

#polys <- vector("list", treeCount)
havePolys <- FALSE
for (i in 1:treeCount) {
  #pts <- matrix(c(las@data$X[las@data$final_segs == i], las@data$Y[las@data$final_segs == i]), ncol = 2)
  #points <- st_as_sf(las@data[las@data$final_segs == i], coords = c("X", "Y"), remove = FALSE, crs = 26910)
  li <- las[las@data$final_segs == i]
  if (li@header$`Number of point records` >= 3) {
    poly <- lidR::st_concave_hull(li)
    #poly$ID <- i
    if (!havePolys) {
      polys <- poly
      havePolys <- TRUE
    }
    else
      polys <- rbind(polys, poly, deparse.level = 0)
  }
  
  #polys[i] <- concaveman(points)
  #plot(st_geometry(points))
  #plot(polygons, add = TRUE, col = "cyan", type = "l")
  
  #bp <- st_buffer(points, bufDist, nQuadSegs = 4) 
  
  # union buffered points
  #clusters <- st_cast(st_union(bp), "POLYGON")
  
  #clusters <-  sf::st_as_sf(clusters)
  #clusters$id <- 1:nrow(clusters)
  
  #shrunkClusters <- st_buffer(clusters, -bufDist, nQuadSegs = 4)
  #plot(st_geometry(points))
  #plot(shrunkClusters, add = TRUE, col = "red", type = "l")
  #plot(st_geometry(points), add = T)
  #plot(st_geometry(bp), add = T)
}

plot(st_sfc(polys))
plot(st_combine(unlist(polys)))
unlist[polys[[1]]]
polys
st_sfc(unlist(polys))
bind(polys)
sf::st_as_sf(data.table::rbindlist(polys))
aggregate.sf(polys, do_union = FALSE)
str(polys[1])

# fast row bind
sf <- rbindlist(polys)

# back to st
sf <- st_as_sf(sf, coords = c("V1", "V2"))
