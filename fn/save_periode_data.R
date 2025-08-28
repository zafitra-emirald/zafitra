# save_periode_data.R
# Function to save periode data to RDS file (fallback only)

save_periode_data <- function(data) {
  if (!dir.exists("data")) dir.create("data")
  
  # Validate required columns exist
  required_cols <- c("id_periode", "nama_periode", "waktu_mulai", "waktu_selesai", "status", "timestamp")
  missing_cols <- required_cols[!required_cols %in% names(data)]
  if(length(missing_cols) > 0) {
    stop(paste("Missing required columns:", paste(missing_cols, collapse=", ")))
  }
  
  # Save to RDS file
  tryCatch({
    saveRDS(data, "data/periode_data.rds")
  }, error = function(e) {
    stop(paste("RDS save operation failed:", e$message))
  })
}