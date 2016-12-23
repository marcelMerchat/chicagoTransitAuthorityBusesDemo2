# Information about data source at:

# Data reference:
# https://developers.google.com/transit/gtfs/reference?csw=1

# Information
# http://www.transitchicago.com/developers/bustracker.aspx

# http://www.transitchicago.com/assets/1/developer_center/
# cta_Bus_Tracker_API_Developer_Guide_and_Documentation_20160929.pdf

urlcta1 <- "http://www.transitchicago.com/downloads/sch_data/google_transit.zip"
# Download the ZIP file you see listed. Only one package is posted at any given
# time, typically representing CTA service from now until a couple of months in
# the future. Use the Calendar table to see on which days and dates service in
# the Trips table are effective.

download.file(urlcta1,"google_transit.zip")

#unzip("google_transit.zip", exdir = "raw") 
unlink("google_transit.zip")

# =============================================================================
# Download and unzip data
# =============================================================================

dir.create("raw", showWarnings = FALSE)
unzip("google_transit.zip", exdir = "raw", files = datafiles) 

# =============================================================================
# Read in each of the data objects and save to an RDS file
# =============================================================================
# Clean out old files
unlink("rds", recursive = TRUE)

# Extract only these specified data files
datafiles <- c("shapes.txt", "trips.txt")
dir.create("rds", showWarnings = FALSE)

for (datafile in datafiles) {
  infile <- file.path("raw", datafile)
  outfile <- file.path("rds", sub("\\.txt$", ".rds", datafile))
  cat("Converting ", infile, " to ", outfile, ".\n", sep = "")
  obj <- read.csv(infile, stringsAsFactors = FALSE)
  saveRDS(obj, outfile)
}

# Remove raw data files
unlink("raw", recursive = TRUE)
