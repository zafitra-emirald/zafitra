# save_single_pendaftaran_mongo.R
# Function to atomically save a single pendaftaran to MongoDB

source("fn/mongodb_config.R")

save_single_pendaftaran_mongo <- function(registration_data) {
  
  # Validate required columns exist
  required_cols <- c("nim_mahasiswa", "nama_mahasiswa", "program_studi", 
                     "kontak", "pilihan_lokasi", "letter_of_interest_path",
                     "cv_mahasiswa_path", "form_rekomendasi_prodi_path", 
                     "form_komitmen_mahasiswa_path", "transkrip_nilai_path", 
                     "status_pendaftaran", "alasan_penolakan")
  missing_cols <- required_cols[!required_cols %in% names(registration_data)]
  if(length(missing_cols) > 0) {
    stop(paste("SAFETY ABORT: Missing required columns:", paste(missing_cols, collapse=", ")))
  }
  
  tryCatch({
    pendaftaran_conn <- get_mongo_connection("pendaftaran")
    
    # Use file-based locking for atomic ID generation
    lock_file <- "data/registration_id.lock"
    counter_file <- "data/registration_counter.txt"
    
    # Create data directory if it doesn't exist
    if (!dir.exists("data")) dir.create("data", recursive = TRUE)
    
    # Wait for lock to be available (maximum 5 seconds)
    max_wait <- 50  # 50 * 0.1 = 5 seconds maximum wait
    wait_count <- 0
    
    while (file.exists(lock_file) && wait_count < max_wait) {
      Sys.sleep(0.1)
      wait_count <- wait_count + 1
    }
    
    if (file.exists(lock_file)) {
      # Force remove stale lock if it exists too long
      file.remove(lock_file)
    }
    
    # Create lock file
    writeLines("locked", lock_file)
    
    tryCatch({
      # Get current max ID from database
      existing_data <- pendaftaran_conn$find(fields = '{"id_pendaftaran": 1}')
      
      if (nrow(existing_data) == 0) {
        new_id <- 1
      } else {
        new_id <- max(existing_data$id_pendaftaran, na.rm = TRUE) + 1
      }
      
      # Also check file-based counter for additional safety
      if (file.exists(counter_file)) {
        file_counter <- as.integer(readLines(counter_file, n = 1))
        if (!is.na(file_counter)) {
          new_id <- max(new_id, file_counter + 1)
        }
      }
      
      # Update file counter
      writeLines(as.character(new_id), counter_file)
      
    }, finally = {
      # Always remove lock
      if (file.exists(lock_file)) file.remove(lock_file)
    })
    
    # Prepare data for MongoDB insertion
    mongo_data <- registration_data
    mongo_data$id_pendaftaran <- as.integer(new_id)
    mongo_data$timestamp <- as.character(Sys.time())
    
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
      mongo_data$status_pendaftaran <- "Diajukan"
    } else {
      mongo_data$status_pendaftaran[is.na(mongo_data$status_pendaftaran)] <- "Diajukan"
    }
    
    # Insert single document atomically
    insert_result <- pendaftaran_conn$insert(mongo_data)
    
    # Verify the insertion was successful
    if (is.null(insert_result) || length(insert_result) == 0) {
      pendaftaran_conn$disconnect()
      stop("Insert operation returned no result")
    }
    
    # Double-check by finding the inserted record
    verification <- pendaftaran_conn$find(paste0('{"nim_mahasiswa": "', mongo_data$nim_mahasiswa, '", "id_pendaftaran": ', new_id, '}'))
    
    if (nrow(verification) != 1) {
      pendaftaran_conn$disconnect()
      stop("Verification failed: inserted record not found")
    }
    
    pendaftaran_conn$disconnect()
    
    cat("✅ Single registration saved atomically with ID:", new_id, "\n")
    return(new_id)
    
  }, error = function(e) {
    stop(paste("MongoDB atomic save operation failed:", e$message))
  })
}