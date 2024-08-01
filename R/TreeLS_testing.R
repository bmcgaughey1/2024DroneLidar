# testing TreeLS package...unfortuntely, package hasn't been updated to drop use of raster
# also relies on lidR version that used raster

library(TreeLS)

# open sample plot file
file = system.file("extdata", "pine_plot.laz", package="TreeLS")
tls = readTLS(file)

# normalize the point cloud
tls = tlsNormalize(tls, keep_ground = F)
x = plot(tls)

# extract the tree map from a thinned point cloud
thin = tlsSample(tls, smp.voxelize(0.02))
map = treeMap(thin, map.hough(min_density = 0.1), 0)
add_treeMap(x, map, color='yellow', size=2)

# classify tree regions
tls = treePoints(tls, map, trp.crop())
add_treePoints(x, tls, size=4)
add_treeIDs(x, tls, cex = 2, col='yellow')

# classify stem points
tls = stemPoints(tls, stm.hough())
add_stemPoints(x, tls, color='red', size=8)

# make the plot's inventory
inv = tlsInventory(tls, d_method=shapeFit(shape='circle', algorithm = 'irls'))
add_tlsInventory(x, inv)

# extract stem measures
seg = stemSegmentation(tls, sgt.ransac.circle(n = 20))
add_stemSegments(x, seg, color='white', fast=T)

# plot everything once
tlsPlot(tls, map, inv, seg, fast=T)

# check out only one tree
tlsPlot(tls, inv, seg, tree_id = 11)

#------------------------------------------#
### overview of some new methods on v2.0 ###
#------------------------------------------#

file = system.file("extdata", "pine.laz", package="TreeLS")
tls = readTLS(file) %>% tlsNormalize()

# calculate some point metrics
tls = fastPointMetrics(tls, ptm.knn())
x = plot(tls, color='Verticality')

# get its stem points
tls = stemPoints(tls, stm.eigen.knn(voxel_spacing = .02))
add_stemPoints(x, tls, size=3, color='red')

# get dbh and height
dbh_algo = shapeFit(shape='cylinder', algorithm = 'bf', n=15, inliers=.95, z_dev=10)
inv = tlsInventory(tls, hp = .95, d_method = dbh_algo)
add_tlsInventory(x, inv)

# segment the stem usind 3D cylinders and getting their directions
seg = stemSegmentation(tls, sgt.irls.cylinder(n=300))
add_stemSegments(x, seg, color='blue')

# check out a specific tree segment
tlsPlot(seg, tls, segment = 3)
