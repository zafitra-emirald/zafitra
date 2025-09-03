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
        # Safely convert id_pendaftaran to numeric, handling list types
        ids <- existing_data$id_pendaftaran
        if (is.list(ids)) {
          ids <- unlist(ids, recursive = TRUE)
        }
        ids <- as.integer(ids)
        new_id <- max(ids, na.rm = TRUE) + 1
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
    
    
    # Prepare data for MongoDB insertion - safely convert data.frame to list
    mongo_data <- list()
    
    # Manually extract each column to ensure proper type conversion
    for(col in names(registration_data)) {
      value <- registration_data[[col]][1]  # Get first element
      
      
      # Handle different data types safely
      if (is.null(value)) {
        mongo_data[[col]] <- ""
      } else if (is.list(value)) {
        # If it's a list, extract the first element and convert to character
        mongo_data[[col]] <- as.character(unlist(value, recursive = TRUE)[1])
      } else if (is.factor(value)) {
        mongo_data[[col]] <- as.character(value)
      } else if (length(value) > 1) {
        # If it's a vector with multiple elements, take the first
        mongo_data[[col]] <- as.character(value[1])
      } else {
        mongo_data[[col]] <- as.character(value)
      }
      
      # Ensure no NA values
      if (is.na(mongo_data[[col]]) || mongo_data[[col]] == "NA") {
        mongo_data[[col]] <- ""
      }
      
    }
    
    # Add metadata
    mongo_data$id_pendaftaran <- as.integer(new_id)
    mongo_data$timestamp <- as.character(Sys.time())
    
    # Final safety check for any remaining list types
    for(col in names(mongo_data)) {
      if (is.list(mongo_data[[col]])) {
        # Force convert to character - handle nested lists properly
        if (length(mongo_data[[col]]) > 0) {
          if (is.list(mongo_data[[col]][[1]])) {
            # Handle nested lists
            mongo_data[[col]] <- as.character(unlist(mongo_data[[col]], recursive = TRUE)[1])
          } else {
            mongo_data[[col]] <- as.character(mongo_data[[col]][[1]])
          }
        } else {
          mongo_data[[col]] <- ""
        }
      }
    }
    
    # Handle optional columns with default values
    optional_cols <- c("letter_of_interest_path", "cv_mahasiswa_path", 
                      "form_rekomendasi_prodi_path", "form_komitmen_mahasiswa_path", 
                      "transkrip_nilai_path", "alasan_penolakan")
    for(col in optional_cols) {
      if(!col %in% names(mongo_data)) {
        mongo_data[[col]] <- ""
      }
    }
    
    # Ensure status_pendaftaran has default value
    if(!"status_pendaftaran" %in% names(mongo_data)) {
      mongo_data$status_pendaftaran <- "Diajukan"
    } else {
      mongo_data$status_pendaftaran[is.na(mongo_data$status_pendaftaran)] <- "Diajukan"
    }
    
    # Final type safety check before insertion
    for(field in names(mongo_data)) {
      val <- mongo_data[[field]]
      if (is.list(val) || is.data.frame(val) || (!is.atomic(val))) {
        cat("CRITICAL: Field", field, "has invalid type:", class(val), "\n")
        mongo_data[[field]] <- as.character(val)
      }
      # Ensure single values only
      if (length(mongo_data[[field]]) > 1) {
        mongo_data[[field]] <- mongo_data[[field]][1]
      }
    }
    
    # Convert to proper format for MongoDB - ensure it's a single-row data.frame
    mongo_df <- data.frame(mongo_data, stringsAsFactors = FALSE)
    
    # Insert single document atomically
    insert_result <- pendaftaran_conn$insert(mongo_df)
    
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
    
    return(new_id)
    
  }, error = function(e) {
    stop(paste("MongoDB atomic save operation failed:", e$message))
  })
}