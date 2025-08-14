# save_periode_data.R
# Function to save period data to RDS file

save_periode_data <- function(data) {
  if (!dir.exists("data")) dir.create("data")
  saveRDS(data, "data/periode_data.rds")
}