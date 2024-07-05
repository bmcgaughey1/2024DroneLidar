# Code to prepare 2024 drone lidar data
#
# converts ground models and DSMs. Data are in NAD83 UTM zone 10 meters (EPSG:26910)
library(terra)
library(fusionwrapr)

# function to convert model formats. Some options are hardwired.
convertFile <- function(
    inputName,
    outputName
    )
{
  # read file
  m <- rast(inputName)
  
  # fix rotation
  m <- rectify(m)
  
  # write .dtm format
  writeDTM(m, outputName, 
           xyunits = "M", 
           zunits = "M",
           coordsys = 1,
           zone = 10,
           horizdatum = 2,
           vertdatum = 2)
  
}

folder <- "H:/2024_DroneLidar/Aldericious/raster/"

# read tiff models and convert to FUSION .dtm format
convertFile(paste0(folder, "Aldericious_1ft_DTM.tif"), paste0(folder, "Aldericious_1ft_DTM.dtm"))
convertFile(paste0(folder, "Aldericious_1ft_DSM.tif"), paste0(folder, "Aldericious_1ft_DSM.dtm"))

convertFile(paste0(folder, "Aldericious_3ft_DTM.tif"), paste0(folder, "Aldericious_3ft_DTM.dtm"))
convertFile(paste0(folder, "Aldericious_3ft_DSM.tif"), paste0(folder, "Aldericious_3ft_DSM.dtm"))

folder <- "H:/2024_DroneLidar/Sprawl/raster/"

# read tiff models and convert to FUSION .dtm format
convertFile(paste0(folder, "Sprawl_1ft_DTM.tif"), paste0(folder, "Sprawl_1ft_DTM.dtm"))
convertFile(paste0(folder, "Sprawl_1ft_DSM.tif"), paste0(folder, "Sprawl_1ft_DSM.dtm"))

convertFile(paste0(folder, "Sprawl_3ft_DTM.tif"), paste0(folder, "Sprawl_3ft_DTM.dtm"))
convertFile(paste0(folder, "Sprawl_3ft_DSM.tif"), paste0(folder, "Sprawl_3ft_DSM.dtm"))

