# save_periode_data_mongo.R
# Function to save periode data to MongoDB

source("fn/mongodb_config.R")

save_periode_data_mongo <- function(data) {
  
  # Validate required columns exist
  required_cols <- c("id_periode", "nama_periode", "waktu_mulai", "waktu_selesai", "status", "timestamp")
  missing_cols <- required_cols[!required_cols %in% names(data)]
  if(length(missing_cols) > 0) {
    stop(paste("SAFETY ABORT: Missing required columns:", paste(missing_cols, collapse=", ")))
  }
  
  # Attempt to save with full error handling
  tryCatch({
    periode_conn <- get_mongo_connection("periode")
    
    # Clear existing data and insert new data (replace all)
    periode_conn$drop()
    
    if (nrow(data) > 0) {
      # Convert data for MongoDB storage
      mongo_data <- data
      # Ensure dates and timestamps are properly formatted
      mongo_data$waktu_mulai <- as.character(mongo_data$waktu_mulai)
      mongo_data$waktu_selesai <- as.character(mongo_data$waktu_selesai)
      mongo_data$timestamp <- as.character(mongo_data$timestamp)
      
      periode_conn$insert(mongo_data)
    }
    
    # Verify the save was successful by reading it back
    test_read <- periode_conn$find()
    
    # Comprehensive verification
    if(nrow(test_read) != nrow(data)) {
      periode_conn$disconnect()
      stop("Row count verification failed")
    }
    if(nrow(data) > 0) {
      if(!all(test_read$id_periode == data$id_periode)) {
        periode_conn$disconnect()
        stop("Periode ID verification failed")
      }
      if(!all(test_read$nama_periode == data$nama_periode)) {
        periode_conn$disconnect()
        stop("Periode name verification failed")
      }
    }
    
    periode_conn$disconnect()
    
  }, error = function(e) {
    stop(paste("MongoDB save operation failed:", e$message))
  })
}