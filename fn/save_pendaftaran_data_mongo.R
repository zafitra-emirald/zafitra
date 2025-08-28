# save_pendaftaran_data_mongo.R
# Function to save pendaftaran data to MongoDB

source("fn/mongodb_config.R")

save_pendaftaran_data_mongo <- function(data) {
  
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
  
  # Attempt to save with full error handling
  tryCatch({
    pendaftaran_conn <- get_mongo_connection("pendaftaran")
    
    # Clear existing data and insert new data (replace all)
    pendaftaran_conn$drop()
    
    if (nrow(data) > 0) {
      # Convert data for MongoDB storage
      mongo_data <- data
      
      # Ensure timestamp is properly formatted
      mongo_data$timestamp <- as.character(mongo_data$timestamp)
      
      # Handle optional columns with default values
      optional_cols <- c("letter_of_interest_path", "cv_mahasiswa_path", 
                        "form_rekomendasi_prodi_path", "form_komitmen_mahasiswa_path", 
                        "transkrip_nilai_path", "alasan_penolakan")
      for(col in optional_cols) {
        if(!col %in% names(mongo_data)) {
          mongo_data[[col]] <- ""
        } else {
          # Replace NA values with empty strings
          mongo_data[[col]][is.na(mongo_data[[col]])] <- ""
        }
      }
      
      # Ensure status_pendaftaran has default value
      if(!"status_pendaftaran" %in% names(mongo_data)) {
        mongo_data$status_pendaftaran <- "Pending"
      } else {
        mongo_data$status_pendaftaran[is.na(mongo_data$status_pendaftaran)] <- "Pending"
      }
      
      pendaftaran_conn$insert(mongo_data)
    }
    
    # Verify the save was successful by reading it back
    test_read <- pendaftaran_conn$find()
    
    # Comprehensive verification
    if(nrow(test_read) != nrow(data)) {
      pendaftaran_conn$disconnect()
      stop("Row count verification failed")
    }
    if(nrow(data) > 0) {
      if(!all(test_read$id_pendaftaran == data$id_pendaftaran)) {
        pendaftaran_conn$disconnect()
        stop("Pendaftaran ID verification failed")
      }
      if(!all(test_read$nim_mahasiswa == data$nim_mahasiswa)) {
        pendaftaran_conn$disconnect()
        stop("NIM verification failed")
      }
    }
    
    pendaftaran_conn$disconnect()
    
  }, error = function(e) {
    stop(paste("MongoDB save operation failed:", e$message))
  })
}