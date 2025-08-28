# save_kategori_data_mongo.R
# Function to save category data to MongoDB

source("fn/mongodb_config.R")

save_kategori_data_mongo <- function(data) {
  
  # Validate required columns exist
  required_cols <- c("id_kategori", "nama_kategori", "deskripsi_kategori", "isu_strategis", "timestamp")
  missing_cols <- required_cols[!required_cols %in% names(data)]
  if(length(missing_cols) > 0) {
    stop(paste("SAFETY ABORT: Missing required columns:", paste(missing_cols, collapse=", ")))
  }
  
  # Attempt to save with full error handling
  tryCatch({
    kategori_conn <- get_mongo_connection("kategori")
    
    # Clear existing data and insert new data (replace all)
    kategori_conn$drop()
    
    if (nrow(data) > 0) {
      # Convert data for MongoDB storage
      mongo_data <- data
      # Ensure timestamp is properly formatted
      mongo_data$timestamp <- as.character(mongo_data$timestamp)
      
      kategori_conn$insert(mongo_data)
    }
    
    # Verify the save was successful by reading it back
    test_read <- kategori_conn$find()
    
    # Comprehensive verification
    if(nrow(test_read) != nrow(data)) {
      kategori_conn$disconnect()
      stop("Row count verification failed")
    }
    if(nrow(data) > 0) {
      if(!all(test_read$id_kategori == data$id_kategori)) {
        kategori_conn$disconnect()
        stop("Category ID verification failed")
      }
      if(!all(test_read$nama_kategori == data$nama_kategori)) {
        kategori_conn$disconnect()
        stop("Category name verification failed")
      }
    }
    
    kategori_conn$disconnect()
    
  }, error = function(e) {
    stop(paste("MongoDB save operation failed:", e$message))
  })
}