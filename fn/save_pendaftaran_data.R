# save_pendaftaran_data.R
# Function to save registration data to RDS file

save_pendaftaran_data <- function(data) {
  if (!dir.exists("data")) dir.create("data")
  saveRDS(data, "data/pendaftaran_data.rds")
}