# 2024DroneLidar

Code for 2024 drone lidar data processing and analyses. Does conversions from TIFF format to FUSION's .dtm format.
One odd thing with the rasters from Chris is that the terra package reports that they are rotated and that you need to
run rectify() on the rasters to fix this. I did this but I'm not sure what Chris did with these to make them rotated.


