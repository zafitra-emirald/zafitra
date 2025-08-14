# save_kategori_data.R
# Function to save category data to RDS file

save_kategori_data <- function(data) {
  if (!dir.exists("data")) dir.create("data")
  saveRDS(data, "data/kategori_data.rds")
}