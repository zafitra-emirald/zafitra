# mongodb_config.R
# MongoDB connection and configuration functions

library(mongolite)

# MongoDB Configuration
get_mongodb_config <- function() {
  # Get environment variables with fallback defaults
  username <- Sys.getenv("MONGODB_USERNAME", "zafitraem_db_user")
  password <- Sys.getenv("MONGODB_PASSWORD", "WL7Ya3Q8aOgwwPvM")
  host <- Sys.getenv("MONGODB_HOST", "cluster0.ccqv2dn.mongodb.net")
  database <- Sys.getenv("MONGODB_DATABASE", "labsos-v1")
  
  # Build connection string
  connection_string <- paste0("mongodb+srv://", username, ":", password, "@", host, "/", database, "?retryWrites=true&w=majority")
  
  return(list(
    username = username,
    password = password,
    host = host,
    database = database,
    connection_string = connection_string
  ))
}

# Collection names mapping
MONGODB_COLLECTIONS <- list(
  kategori = "kategori_data",
  periode = "periode_data", 
  lokasi = "lokasi_data",
  pendaftaran = "pendaftaran_data"
)

# Function to get MongoDB connection for a specific collection
get_mongo_connection <- function(collection_name) {
  if (!collection_name %in% names(MONGODB_COLLECTIONS)) {
    stop(paste("Invalid collection name:", collection_name))
  }
  
  collection_full_name <- MONGODB_COLLECTIONS[[collection_name]]
  config <- get_mongodb_config()
  
  tryCatch({
    conn <- mongo(
      collection = collection_full_name,
      db = config$database,
      url = config$connection_string
    )
    return(conn)
  }, error = function(e) {
    stop(paste("Failed to connect to MongoDB:", e$message))
  })
}

# Function to test MongoDB connection
test_mongo_connection <- function() {
  tryCatch({
    # Try to connect to a test collection
    conn <- get_mongo_connection("kategori")
    
    # Try a simple count operation
    count <- conn$count()
    
    conn$disconnect()
    
    return(list(
      success = TRUE, 
      message = paste("Successfully connected to MongoDB. Kategori collection has", count, "documents.")
    ))
  }, error = function(e) {
    return(list(
      success = FALSE,
      message = paste("MongoDB connection failed:", e$message)
    ))
  })
}

# Function to ensure indexes exist
ensure_mongo_indexes <- function() {
  tryCatch({
    # Kategori collection indexes
    kategori_conn <- get_mongo_connection("kategori")
    kategori_conn$index('{"id_kategori": 1}')
    kategori_conn$disconnect()
    
    # Periode collection indexes
    periode_conn <- get_mongo_connection("periode")
    periode_conn$index('{"id_periode": 1}')
    periode_conn$disconnect()
    
    # Lokasi collection indexes
    lokasi_conn <- get_mongo_connection("lokasi")
    lokasi_conn$index('{"id_lokasi": 1}')
    lokasi_conn$disconnect()
    
    # Pendaftaran collection indexes
    pendaftaran_conn <- get_mongo_connection("pendaftaran")
    pendaftaran_conn$index('{"id_pendaftaran": 1}')
    pendaftaran_conn$index('{"nim_mahasiswa": 1}')
    pendaftaran_conn$disconnect()
    
    return(TRUE)
  }, error = function(e) {
    warning(paste("Failed to create indexes:", e$message))
    return(FALSE)
  })
}