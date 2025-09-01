# save_single_lokasi_mongo.R
# Function to save a single lokasi record to MongoDB without affecting others

source("fn/mongodb_config.R")

save_single_lokasi_mongo <- function(lokasi_data) {
  
  # Validate required columns exist
  required_cols <- c("id_lokasi", "nama_lokasi", "deskripsi_lokasi", "kategori_lokasi", 
                     "isu_strategis", "kuota_mahasiswa", "alamat_lokasi", "map_lokasi", "timestamp")
  missing_cols <- required_cols[!required_cols %in% names(lokasi_data)]
  if(length(missing_cols) > 0) {
    stop(paste("SAFETY ABORT: Missing required columns:", paste(missing_cols, collapse=", ")))
  }
  
  if(nrow(lokasi_data) != 1) {
    stop("save_single_lokasi_mongo expects exactly one row of data")
  }
  
  # Attempt to save with full error handling
  tryCatch({
    lokasi_conn <- get_mongo_connection("lokasi")
    
    # Convert single row data for MongoDB storage
    doc <- lokasi_data[1, ]
    
    # Ensure timestamp is properly formatted
    doc$timestamp <- as.character(doc$timestamp)
    
    # Handle optional columns with default values
    if(!"alamat_lokasi" %in% names(doc) || is.na(doc$alamat_lokasi)) {
      doc$alamat_lokasi <- ""
    }
    if(!"map_lokasi" %in% names(doc) || is.na(doc$map_lokasi)) {
      doc$map_lokasi <- ""
    }
    if(!"foto_lokasi" %in% names(doc) || is.na(doc$foto_lokasi)) {
      doc$foto_lokasi <- ""
    }
    
    # Handle list columns properly
    if(!"program_studi" %in% names(doc)) {
      doc$program_studi <- list(character(0))
    }
    if(!"foto_lokasi_list" %in% names(doc)) {
      doc$foto_lokasi_list <- list(list())
    }
    
    # Convert row to list for MongoDB
    doc_list <- list(
      id_lokasi = doc$id_lokasi,
      nama_lokasi = doc$nama_lokasi,
      deskripsi_lokasi = doc$deskripsi_lokasi,
      kategori_lokasi = doc$kategori_lokasi,
      isu_strategis = doc$isu_strategis,
      kuota_mahasiswa = doc$kuota_mahasiswa,
      alamat_lokasi = doc$alamat_lokasi,
      map_lokasi = doc$map_lokasi,
      foto_lokasi = doc$foto_lokasi,
      timestamp = doc$timestamp,
      program_studi = doc$program_studi[[1]],
      foto_lokasi_list = doc$foto_lokasi_list[[1]]
    )
    
    # Use upsert to update specific document
    lokasi_conn$update(
      query = sprintf('{"id_lokasi": %d}', doc$id_lokasi),
      update = sprintf('{"$set": %s}', jsonlite::toJSON(doc_list, auto_unbox = TRUE)),
      upsert = TRUE
    )
    
    # Verify the save was successful
    verify_query <- sprintf('{"id_lokasi": %d}', doc$id_lokasi)
    test_read <- lokasi_conn$find(verify_query)
    
    if(nrow(test_read) != 1) {
      lokasi_conn$disconnect()
      stop(paste("Verification failed for lokasi ID:", doc$id_lokasi))
    }
    
    if(test_read$nama_lokasi != doc$nama_lokasi) {
      lokasi_conn$disconnect()
      stop(paste("Name verification failed for lokasi ID:", doc$id_lokasi))
    }
    
    # Verify alamat_lokasi and map_lokasi fields are properly saved
    if("alamat_lokasi" %in% names(doc) && !is.na(doc$alamat_lokasi)) {
      if(is.na(test_read$alamat_lokasi) || test_read$alamat_lokasi != doc$alamat_lokasi) {
        lokasi_conn$disconnect()
        stop(paste("alamat_lokasi verification failed for lokasi ID:", doc$id_lokasi))
      }
    }
    if("map_lokasi" %in% names(doc) && !is.na(doc$map_lokasi)) {
      if(is.na(test_read$map_lokasi) || test_read$map_lokasi != doc$map_lokasi) {
        lokasi_conn$disconnect()
        stop(paste("map_lokasi verification failed for lokasi ID:", doc$id_lokasi))
      }
    }
    
    lokasi_conn$disconnect()
    cat("INFO: Successfully updated lokasi ID", doc$id_lokasi, "\n")
    
  }, error = function(e) {
    stop(paste("MongoDB single location save failed:", e$message))
  })
}