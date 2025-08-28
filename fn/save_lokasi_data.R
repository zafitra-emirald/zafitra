# save_lokasi_data.R
# Function to save location data to RDS file

save_lokasi_data <- function(data) {
  if (!dir.exists("data")) dir.create("data")
  
  # PRODUCTION SAFETY: Create backup before any save operation
  if(file.exists("data/lokasi_data.rds")) {
    backup_filename <- paste0("data/lokasi_data_save_backup_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".rds")
    file.copy("data/lokasi_data.rds", backup_filename)
  }
  
  # Keep original data for rollback
  original_data <- data
  
  # Validate and CAREFULLY fix program_studi structure before saving (NEVER delete existing data)
  if("program_studi" %in% names(data) && nrow(data) > 0) {
    # Ensure program_studi is a proper list column
    if(!is.list(data$program_studi)) {
      # SAFETY: Don't wipe existing data, convert it properly
      old_program_studi <- data$program_studi
      data$program_studi <- vector("list", nrow(data))
      
      for(i in seq_len(nrow(data))) {
        if(i <= length(old_program_studi) && !is.na(old_program_studi[i]) && old_program_studi[i] != "") {
          # Preserve existing data by converting to proper format
          if(grepl(",", old_program_studi[i])) {
            data$program_studi[[i]] <- trimws(strsplit(old_program_studi[i], ",")[[1]])
          } else {
            data$program_studi[[i]] <- as.character(old_program_studi[i])
          }
        } else {
          data$program_studi[[i]] <- character(0)
        }
      }
    } else {
      # Ensure each entry is a character vector, but preserve existing valid data
      for(i in seq_len(nrow(data))) {
        if(length(data$program_studi) >= i && !is.character(data$program_studi[[i]])) {
          # Try to preserve data by conversion, only reset if completely broken
          if(!is.null(data$program_studi[[i]]) && length(data$program_studi[[i]]) > 0) {
            tryCatch({
              data$program_studi[[i]] <- as.character(data$program_studi[[i]])
            }, error = function(e) {
              data$program_studi[[i]] <- character(0)
            })
          } else {
            data$program_studi[[i]] <- character(0)
          }
        }
      }
    }
  }
  
  # Final safety check before saving
  required_cols <- c("id_lokasi", "nama_lokasi", "deskripsi_lokasi", "kategori_lokasi", 
                     "isu_strategis", "kuota_mahasiswa", "foto_lokasi", "timestamp")
  missing_cols <- required_cols[!required_cols %in% names(data)]
  if(length(missing_cols) > 0) {
    stop(paste("SAFETY ABORT: Missing required columns:", paste(missing_cols, collapse=", ")))
  }
  
  if(nrow(data) != nrow(original_data) || 
     !all(data$id_lokasi == original_data$id_lokasi) ||
     !all(data$nama_lokasi == original_data$nama_lokasi)) {
    stop("SAFETY ABORT: Data integrity check failed, save aborted to prevent data loss")
  }
  
  # Attempt to save with full error handling and rollback capability
  tryCatch({
    saveRDS(data, "data/lokasi_data.rds")
    
    # Verify the save was successful by reading it back
    test_read <- readRDS("data/lokasi_data.rds")
    
    # Comprehensive verification
    if(nrow(test_read) != nrow(data)) {
      stop("Row count verification failed")
    }
    if(!all(test_read$id_lokasi == data$id_lokasi)) {
      stop("ID verification failed")
    }
    if("program_studi" %in% names(test_read) && !is.list(test_read$program_studi)) {
      stop("Program studi structure verification failed")
    }
    
  }, error = function(e) {
    # Rollback: restore original file if backup exists
    backup_files <- list.files("data", pattern = "lokasi_data_save_backup_.*\\.rds", full.names = TRUE)
    if(length(backup_files) > 0) {
      latest_backup <- backup_files[order(file.info(backup_files)$mtime, decreasing = TRUE)[1]]
      file.copy(latest_backup, "data/lokasi_data.rds", overwrite = TRUE)
      warning(paste("Save failed, restored from backup:", basename(latest_backup)))
    }
    stop(paste("Save operation failed:", e$message))
  })
}