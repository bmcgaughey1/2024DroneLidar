# code to normalize data and do some vertical slices. Goal is to explore stem detection
# using simple clustering on the slices
library(fusionwrapr)

folder <- "H:/2024_DroneLidar/Sprawl/"
file <- "Sprawl_002.laz"

groundFile <- paste0(folder, "raster/Sprawl_1ft_DTM.dtm")

# clip data to normalize
ClipData(paste0(folder, file),
         paste0(folder, "Sprawl_002_normalized.las"),
         ground = groundFile,
         height = TRUE
         )

# clip 1m slices from normalized data...omit ground points (shouldn't be needed)
ClipData(paste0(folder, "Sprawl_002_normalized.las"),
         paste0(folder, "Sprawl_002_normalized_0to1m.las"),
         class = "~2",
         zmin = 0.0,
         zmax = 1.0
)

ClipData(paste0(folder, "Sprawl_002_normalized.las"),
         paste0(folder, "Sprawl_002_normalized_0p5to1m.las"),
         class = "~2",
         zmin = 0.5,
         zmax = 1.0
)

ClipData(paste0(folder, "Sprawl_002_normalized.las"),
         paste0(folder, "Sprawl_002_normalized_1to2m.las"),
         class = "~2",
         zmin = 1.0,
         zmax = 2.0
)

ClipData(paste0(folder, "Sprawl_002_normalized.las"),
         paste0(folder, "Sprawl_002_normalized_2to3m.las"),
         class = "~2",
         zmin = 2.0,
         zmax = 3.0
)

ClipData(paste0(folder, "Sprawl_002_normalized.las"),
         paste0(folder, "Sprawl_002_normalized_3to4m.las"),
         class = "~2",
         zmin = 3.0,
         zmax = 4.0
)

ClipData(paste0(folder, "Sprawl_002_normalized.las"),
         paste0(folder, "Sprawl_002_normalized_4to5m.las"),
         class = "~2",
         zmin = 4.0,
         zmax = 5.0
)

