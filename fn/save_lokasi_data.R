# save_lokasi_data.R
# Function to save lokasi data to RDS file (fallback only)

save_lokasi_data <- function(data) {
  if (!dir.exists("data")) dir.create("data")
  
  # Validate required columns exist
  required_cols <- c("id_lokasi", "nama_lokasi", "deskripsi_lokasi", "kategori_lokasi", 
                     "isu_strategis", "kuota_mahasiswa", "alamat_lokasi", "map_lokasi", "timestamp")
  missing_cols <- required_cols[!required_cols %in% names(data)]
  if(length(missing_cols) > 0) {
    stop(paste("Missing required columns:", paste(missing_cols, collapse=", ")))
  }
  
  # Save to RDS file
  tryCatch({
    saveRDS(data, "data/lokasi_data.rds")
  }, error = function(e) {
    stop(paste("RDS save operation failed:", e$message))
  })
}