# save_lokasi_data_mongo.R
# Function to save lokasi data to MongoDB

source("fn/mongodb_config.R")

save_lokasi_data_mongo <- function(data) {
  
  # Validate required columns exist
  required_cols <- c("id_lokasi", "nama_lokasi", "deskripsi_lokasi", "kategori_lokasi", 
                     "isu_strategis", "kuota_mahasiswa", "alamat_lokasi", "map_lokasi", "timestamp")
  missing_cols <- required_cols[!required_cols %in% names(data)]
  if(length(missing_cols) > 0) {
    stop(paste("SAFETY ABORT: Missing required columns:", paste(missing_cols, collapse=", ")))
  }
  
  # Add debug information for large datasets
  if(nrow(data) > 10) {
    cat("INFO: Saving large dataset with", nrow(data), "locations\n")
  }
  
  # Attempt to save with full error handling
  tryCatch({
    lokasi_conn <- get_mongo_connection("lokasi")
    
    # Clear existing data and insert new data (replace all)
    # This ensures deletions are properly handled
    lokasi_conn$drop()
    use_bulk_insert <- TRUE
    
    if (nrow(data) > 0) {
      # Convert data for MongoDB storage
      mongo_data <- data
      
      # Ensure timestamp is properly formatted
      mongo_data$timestamp <- as.character(mongo_data$timestamp)
      
      # Handle optional columns with default values and proper data type conversion
      if(!"alamat_lokasi" %in% names(mongo_data)) {
        mongo_data$alamat_lokasi <- rep("", nrow(mongo_data))
        cat("DEBUG: Added missing alamat_lokasi column\n")
      } else {
        # Ensure alamat_lokasi is character and handle NA/NULL values
        mongo_data$alamat_lokasi <- as.character(ifelse(is.na(mongo_data$alamat_lokasi) | is.null(mongo_data$alamat_lokasi), "", mongo_data$alamat_lokasi))
        cat("DEBUG: alamat_lokasi values being saved:", paste(mongo_data$alamat_lokasi, collapse=", "), "\n")
      }
      if(!"map_lokasi" %in% names(mongo_data)) {
        mongo_data$map_lokasi <- rep("", nrow(mongo_data))
        cat("DEBUG: Added missing map_lokasi column\n")
      } else {
        # Ensure map_lokasi is character and handle NA/NULL values  
        mongo_data$map_lokasi <- as.character(ifelse(is.na(mongo_data$map_lokasi) | is.null(mongo_data$map_lokasi), "", mongo_data$map_lokasi))
        cat("DEBUG: map_lokasi values being saved:", paste(mongo_data$map_lokasi, collapse=", "), "\n")
      }
      if(!"foto_lokasi" %in% names(mongo_data)) {
        mongo_data$foto_lokasi <- ""
      }
      
      # Handle list columns (program_studi and foto_lokasi_list) with robust validation
      if(!"program_studi" %in% names(mongo_data)) {
        mongo_data$program_studi <- replicate(nrow(mongo_data), list(), simplify = FALSE)
      } else {
        # Ensure all program_studi entries are properly formatted for MongoDB
        for(i in 1:nrow(mongo_data)) {
          # program_studi should remain as character vectors, not nested lists
          if(is.character(mongo_data$program_studi[[i]])) {
            # Keep character vectors as-is - MongoDB can handle them
            # No conversion needed
          } else if(is.list(mongo_data$program_studi[[i]]) && length(mongo_data$program_studi[[i]]) > 0) {
            # If it's already a list, flatten it to character vector
            mongo_data$program_studi[[i]] <- as.character(unlist(mongo_data$program_studi[[i]]))
          } else {
            # Empty case
            mongo_data$program_studi[[i]] <- character(0)
          }
        }
      }
      
      if(!"foto_lokasi_list" %in% names(mongo_data)) {
        mongo_data$foto_lokasi_list <- replicate(nrow(mongo_data), list(), simplify = FALSE)
      } else {
        # Ensure all foto_lokasi_list entries are properly formatted 
        for(i in 1:nrow(mongo_data)) {
          # Only convert NULL entries to empty list, preserve character vectors and lists
          if(is.null(mongo_data$foto_lokasi_list[[i]])) {
            mongo_data$foto_lokasi_list[[i]] <- list()
          }
          # Keep character vectors and existing lists as-is (MongoDB can handle both)
        }
      }
      
      # Bulk insert for complete replacement (handles deletions)
      if(nrow(mongo_data) > 20) {
        cat("INFO: Using batch processing for", nrow(mongo_data), "locations\n")
        batch_size <- 10
        for(start_idx in seq(1, nrow(mongo_data), by = batch_size)) {
          end_idx <- min(start_idx + batch_size - 1, nrow(mongo_data))
          batch_data <- mongo_data[start_idx:end_idx, ]
          lokasi_conn$insert(batch_data)
          cat("INFO: Inserted batch", start_idx, "to", end_idx, "\n")
        }
      } else {
        lokasi_conn$insert(mongo_data)
      }
    }
    
    # Verify the save was successful by reading it back
    test_read <- lokasi_conn$find()
    
    # Comprehensive verification with detailed error messages
    if(nrow(test_read) != nrow(data)) {
      lokasi_conn$disconnect()
      stop(paste("Row count verification failed. Expected:", nrow(data), "rows, but found:", nrow(test_read), "rows"))
    }
    if(nrow(data) > 0) {
      # Verify all IDs match (order may differ so use %in%)
      if(!all(data$id_lokasi %in% test_read$id_lokasi) || !all(test_read$id_lokasi %in% data$id_lokasi)) {
        lokasi_conn$disconnect()
        stop(paste("Lokasi ID verification failed. Some IDs don't match between data and database"))
      }
      
      # Verify alamat_lokasi and map_lokasi fields are properly saved
      for(i in 1:nrow(data)) {
        saved_row <- test_read[test_read$id_lokasi == data$id_lokasi[i], ]
        if(nrow(saved_row) == 1) {
          # Check alamat_lokasi
          if("alamat_lokasi" %in% names(data) && !is.na(data$alamat_lokasi[i])) {
            if(is.na(saved_row$alamat_lokasi) || saved_row$alamat_lokasi != data$alamat_lokasi[i]) {
              lokasi_conn$disconnect()
              stop(paste("alamat_lokasi verification failed for lokasi ID:", data$id_lokasi[i]))
            }
          }
          # Check map_lokasi
          if("map_lokasi" %in% names(data) && !is.na(data$map_lokasi[i])) {
            if(is.na(saved_row$map_lokasi) || saved_row$map_lokasi != data$map_lokasi[i]) {
              lokasi_conn$disconnect()
              stop(paste("map_lokasi verification failed for lokasi ID:", data$id_lokasi[i]))
            }
          }
        }
      }
    }
    
    lokasi_conn$disconnect()
    
  }, error = function(e) {
    stop(paste("MongoDB save operation failed:", e$message))
  })
}