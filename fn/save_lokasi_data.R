# save_lokasi_data.R
# Function to save location data to RDS file

save_lokasi_data <- function(data) {
  if (!dir.exists("data")) dir.create("data")
  saveRDS(data, "data/lokasi_data.rds")
}