# save_pendaftaran_data.R
# Function to save registration data to RDS file

save_pendaftaran_data <- function(data) {
  if (!dir.exists("data")) dir.create("data")
  
  # PRODUCTION SAFETY: Create backup before any save operation
  if(file.exists("data/pendaftaran_data.rds")) {
    backup_filename <- paste0("data/pendaftaran_data_backup_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".rds")
    file.copy("data/pendaftaran_data.rds", backup_filename)
  }
  
  # Keep original data for rollback
  original_data <- data
  
  # Validate required columns exist
  required_cols <- c("id_pendaftaran", "timestamp", "nim_mahasiswa", "nama_mahasiswa", "program_studi", 
                     "kontak", "pilihan_lokasi", "letter_of_interest_path",
                     "cv_mahasiswa_path", "form_rekomendasi_prodi_path", 
                     "form_komitmen_mahasiswa_path", "transkrip_nilai_path", 
                     "status_pendaftaran", "alasan_penolakan")
  
  missing_cols <- required_cols[!required_cols %in% names(data)]
  if(length(missing_cols) > 0) {
    stop(paste("SAFETY ABORT: Missing required columns:", paste(missing_cols, collapse=", ")))
  }
  
  # Attempt to save with full error handling and rollback capability
  tryCatch({
    saveRDS(data, "data/pendaftaran_data.rds")
    
    # Verify the save was successful by reading it back
    test_read <- readRDS("data/pendaftaran_data.rds")
    
    # Comprehensive verification
    if(nrow(test_read) != nrow(data)) {
      stop("Row count verification failed")
    }
    if(nrow(data) > 0) {
      if(!all(test_read$id_pendaftaran == data$id_pendaftaran)) {
        stop("ID verification failed")
      }
      if(!all(test_read$nim_mahasiswa == data$nim_mahasiswa)) {
        stop("NIM verification failed")
      }
    }
    
  }, error = function(e) {
    # Rollback: restore original file if backup exists
    backup_files <- list.files("data", pattern = "pendaftaran_data_backup_.*\\.rds", full.names = TRUE)
    if(length(backup_files) > 0) {
      latest_backup <- backup_files[order(file.info(backup_files)$mtime, decreasing = TRUE)[1]]
      file.copy(latest_backup, "data/pendaftaran_data.rds", overwrite = TRUE)
      warning(paste("Save failed, restored from backup:", basename(latest_backup)))
    }
    stop(paste("Save operation failed:", e$message))
  })
}