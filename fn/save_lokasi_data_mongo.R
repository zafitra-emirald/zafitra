# save_lokasi_data_mongo.R
# Function to save lokasi data to MongoDB

source("fn/mongodb_config.R")

save_lokasi_data_mongo <- function(data) {
  
  # Validate required columns exist
  required_cols <- c("id_lokasi", "nama_lokasi", "deskripsi_lokasi", "kategori_lokasi", 
                     "isu_strategis", "kuota_mahasiswa", "timestamp")
  missing_cols <- required_cols[!required_cols %in% names(data)]
  if(length(missing_cols) > 0) {
    stop(paste("SAFETY ABORT: Missing required columns:", paste(missing_cols, collapse=", ")))
  }
  
  # Attempt to save with full error handling
  tryCatch({
    lokasi_conn <- get_mongo_connection("lokasi")
    
    # Clear existing data and insert new data (replace all)
    lokasi_conn$drop()
    
    if (nrow(data) > 0) {
      # Convert data for MongoDB storage
      mongo_data <- data
      
      # Ensure timestamp is properly formatted
      mongo_data$timestamp <- as.character(mongo_data$timestamp)
      
      # Handle optional columns with default values
      if(!"alamat_lokasi" %in% names(mongo_data)) {
        mongo_data$alamat_lokasi <- ""
      }
      if(!"map_lokasi" %in% names(mongo_data)) {
        mongo_data$map_lokasi <- ""
      }
      if(!"foto_lokasi" %in% names(mongo_data)) {
        mongo_data$foto_lokasi <- ""
      }
      
      # Handle list columns (program_studi and foto_lokasi_list)
      if(!"program_studi" %in% names(mongo_data)) {
        mongo_data$program_studi <- replicate(nrow(mongo_data), list(), simplify = FALSE)
      }
      if(!"foto_lokasi_list" %in% names(mongo_data)) {
        mongo_data$foto_lokasi_list <- replicate(nrow(mongo_data), list(), simplify = FALSE)
      }
      
      lokasi_conn$insert(mongo_data)
    }
    
    # Verify the save was successful by reading it back
    test_read <- lokasi_conn$find()
    
    # Comprehensive verification
    if(nrow(test_read) != nrow(data)) {
      lokasi_conn$disconnect()
      stop("Row count verification failed")
    }
    if(nrow(data) > 0) {
      if(!all(test_read$id_lokasi == data$id_lokasi)) {
        lokasi_conn$disconnect()
        stop("Lokasi ID verification failed")
      }
      if(!all(test_read$nama_lokasi == data$nama_lokasi)) {
        lokasi_conn$disconnect()
        stop("Lokasi name verification failed")
      }
    }
    
    lokasi_conn$disconnect()
    
  }, error = function(e) {
    stop(paste("MongoDB save operation failed:", e$message))
  })
}