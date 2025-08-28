# save_pendaftaran_data.R
# Function to save pendaftaran data to RDS file (fallback only)

save_pendaftaran_data <- function(data) {
  if (!dir.exists("data")) dir.create("data")
  
  # Validate required columns exist
  required_cols <- c("id_pendaftaran", "timestamp", "nim_mahasiswa", "nama_mahasiswa", "program_studi", 
                     "kontak", "pilihan_lokasi", "letter_of_interest_path",
                     "cv_mahasiswa_path", "form_rekomendasi_prodi_path", 
                     "form_komitmen_mahasiswa_path", "transkrip_nilai_path", 
                     "status_pendaftaran", "alasan_penolakan")
  missing_cols <- required_cols[!required_cols %in% names(data)]
  if(length(missing_cols) > 0) {
    stop(paste("Missing required columns:", paste(missing_cols, collapse=", ")))
  }
  
  # Save to RDS file
  tryCatch({
    saveRDS(data, "data/pendaftaran_data.rds")
  }, error = function(e) {
    stop(paste("RDS save operation failed:", e$message))
  })
}