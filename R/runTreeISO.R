# function to run TreeISO in CC and collect segment output information
#
runTreeISO <- function(
    pointFile = NULL,
    outputPointFile = NULL,
    commandFile = NULL,
    lambda1 = 1.0,
    k1 = 5,
    decimateResolution1 = 0.05,
    lambda2 = 20.0,
    k2 = 20,
    maxGap = 4.0,
    decimateResolution2 = 0.1,
    rho = 0.5,
    verticalOverlapWeight = 0.5
)
{
  # check rewquired parameters
  if (is.null(pointFile) || is.null(outputPointFile) || is.null(commandFile))
    stop("Missing required parameters!!")
  
  CCCmd <- paste0(" -SILENT -COMMAND_FILE ", CCCommandFile)
  CC <- "\"C:/Program Files/CloudCompare/CloudCompare.exe\""

  write(paste("-O -GLOBAL_SHIFT AUTO", pointFile, "-C_EXPORT_FMT LAS"), file = commandFile)
  write(paste("-TREEISO", 
              "-LAMBDA1", lambda1, 
              "-K1", k1, 
              "-DECIMATE_RESOLUTION1", decimateResolution1,
              "-LAMBDA2", lambda2,
              "-K2", k2,
              "-MAX_GAP", maxGap,
              "-DECIMATE_RESOLUTION2", decimateResolution2,
              "-RHO", rho,
              "-VERTICAL_OVERLAP_WEIGHT", verticalOverlapWeight),
        file = CCCommandFile, append = TRUE)
  write(paste("-SAVE_CLOUDS", "FILE", outputPointFile),
        file = CCCommandFile, append = TRUE)
  
  # run CC
  system(paste(CC, CCCmd))
  
  # read points and get counts
  las <- readLAS(paste0(folder, outputFolder, "TreeISO_output.las"))
  initialSegmentCount <- length(unique(las$init_segs))
  intermediateSegmentCount <- length(unique(las$intermediate_segs))
  finalSegmentCount <- length(unique(las$final_segs))
  
  return(invisible(data.frame(
    pointFile,
    outputPointFile,
    commandFile,
    lambda1,
    k1,
    decimateResolution1,
    lambda2,
    k2,
    maxGap,
    decimateResolution2,
    rho,
    verticalOverlapWeight,
    initialSegmentCount,
    intermediateSegmentCount,
    finalSegmentCount
  )))
}