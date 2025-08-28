# save_kategori_data.R
# Function to save category data to RDS file (fallback only)

save_kategori_data <- function(data) {
  if (!dir.exists("data")) dir.create("data")
  
  # Validate required columns exist
  required_cols <- c("id_kategori", "nama_kategori", "deskripsi_kategori", "isu_strategis", "timestamp")
  missing_cols <- required_cols[!required_cols %in% names(data)]
  if(length(missing_cols) > 0) {
    stop(paste("Missing required columns:", paste(missing_cols, collapse=", ")))
  }
  
  # Save to RDS file
  tryCatch({
    saveRDS(data, "data/kategori_data.rds")
  }, error = function(e) {
    stop(paste("RDS save operation failed:", e$message))
  })
}