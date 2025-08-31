# migrate_rds_to_mongodb.R
# Script to migrate existing RDS data to MongoDB Atlas

# Load required functions
source("fn/mongodb_config.R")
source("fn/load_or_create_data.R")  # For RDS loading

migrate_rds_to_mongodb <- function() {
  cat("=== Starting RDS to MongoDB Migration ===\n")
  
  # Test MongoDB connection first
  connection_test <- test_mongo_connection()
  if (!connection_test$success) {
    stop(paste("Cannot connect to MongoDB:", connection_test$message))
  }
  cat("✓ MongoDB connection verified\n")
  
  # Load data from RDS files
  cat("\nLoading data from RDS files...\n")
  load_or_create_data()  # This loads RDS data into global variables
  
  # Display current RDS data counts
  cat("RDS Data Summary:\n")
  cat("- Kategori:", nrow(kategori_data), "rows\n")
  cat("- Periode:", nrow(periode_data), "rows\n") 
  cat("- Lokasi:", nrow(lokasi_data), "rows\n")
  cat("- Pendaftaran:", nrow(pendaftaran_data), "rows\n\n")
  
  migration_results <- list()
  
  # Migrate Kategori Data
  if (nrow(kategori_data) > 0) {
    cat("Migrating kategori data...\n")
    tryCatch({
      kategori_conn <- get_mongo_connection("kategori")
      
      # Prepare data for MongoDB
      mongo_kategori <- kategori_data
      mongo_kategori$timestamp <- as.character(mongo_kategori$timestamp)
      
      # Insert data
      result <- kategori_conn$insert(mongo_kategori)
      kategori_conn$disconnect()
      
      migration_results$kategori <- list(success = TRUE, rows = nrow(kategori_data))
      cat("✓ Kategori data migrated:", nrow(kategori_data), "rows\n")
    }, error = function(e) {
      migration_results$kategori <- list(success = FALSE, error = e$message)
      cat("✗ Kategori migration failed:", as.character(e$message), "\n")
    })
  } else {
    cat("- No kategori data to migrate\n")
    migration_results$kategori <- list(success = TRUE, rows = 0)
  }
  
  # Migrate Periode Data  
  if (nrow(periode_data) > 0) {
    cat("Migrating periode data...\n")
    tryCatch({
      periode_conn <- get_mongo_connection("periode")
      
      # Clear existing default data first
      periode_conn$drop()
      
      # Prepare data for MongoDB
      mongo_periode <- periode_data
      mongo_periode$waktu_mulai <- as.character(mongo_periode$waktu_mulai)
      mongo_periode$waktu_selesai <- as.character(mongo_periode$waktu_selesai)
      mongo_periode$timestamp <- as.character(mongo_periode$timestamp)
      
      # Insert data
      result <- periode_conn$insert(mongo_periode)
      periode_conn$disconnect()
      
      migration_results$periode <- list(success = TRUE, rows = nrow(periode_data))
      cat("✓ Periode data migrated:", nrow(periode_data), "rows\n")
    }, error = function(e) {
      migration_results$periode <- list(success = FALSE, error = e$message)
      cat("✗ Periode migration failed:", as.character(e$message), "\n")
    })
  } else {
    cat("- No periode data to migrate\n")
    migration_results$periode <- list(success = TRUE, rows = 0)
  }
  
  # Migrate Lokasi Data
  if (nrow(lokasi_data) > 0) {
    cat("Migrating lokasi data...\n")
    tryCatch({
      lokasi_conn <- get_mongo_connection("lokasi")
      
      # Prepare data for MongoDB
      mongo_lokasi <- lokasi_data
      mongo_lokasi$timestamp <- as.character(mongo_lokasi$timestamp)
      
      # Handle optional columns
      if(!"alamat_lokasi" %in% names(mongo_lokasi)) {
        mongo_lokasi$alamat_lokasi <- ""
      }
      if(!"map_lokasi" %in% names(mongo_lokasi)) {
        mongo_lokasi$map_lokasi <- ""
      }
      if(!"foto_lokasi" %in% names(mongo_lokasi)) {
        mongo_lokasi$foto_lokasi <- ""
      }
      
      # Handle list columns
      if(!"program_studi" %in% names(mongo_lokasi)) {
        mongo_lokasi$program_studi <- replicate(nrow(mongo_lokasi), list(), simplify = FALSE)
      }
      if(!"foto_lokasi_list" %in% names(mongo_lokasi)) {
        mongo_lokasi$foto_lokasi_list <- replicate(nrow(mongo_lokasi), list(), simplify = FALSE)
      }
      
      # Insert data
      result <- lokasi_conn$insert(mongo_lokasi)
      lokasi_conn$disconnect()
      
      migration_results$lokasi <- list(success = TRUE, rows = nrow(lokasi_data))
      cat("✓ Lokasi data migrated:", nrow(lokasi_data), "rows\n")
    }, error = function(e) {
      migration_results$lokasi <- list(success = FALSE, error = e$message)
      cat("✗ Lokasi migration failed:", as.character(e$message), "\n")
    })
  } else {
    cat("- No lokasi data to migrate\n")
    migration_results$lokasi <- list(success = TRUE, rows = 0)
  }
  
  # Migrate Pendaftaran Data
  if (nrow(pendaftaran_data) > 0) {
    cat("Migrating pendaftaran data...\n")
    tryCatch({
      pendaftaran_conn <- get_mongo_connection("pendaftaran")
      
      # Prepare data for MongoDB
      mongo_pendaftaran <- pendaftaran_data
      mongo_pendaftaran$timestamp <- as.character(mongo_pendaftaran$timestamp)
      
      # Handle optional columns with default values
      optional_cols <- c("letter_of_interest_path", "cv_mahasiswa_path", 
                        "form_rekomendasi_prodi_path", "form_komitmen_mahasiswa_path", 
                        "transkrip_nilai_path", "alasan_penolakan")
      for(col in optional_cols) {
        if(!col %in% names(mongo_pendaftaran)) {
          mongo_pendaftaran[[col]] <- ""
        } else {
          # Replace NA values with empty strings
          mongo_pendaftaran[[col]][is.na(mongo_pendaftaran[[col]])] <- ""
        }
      }
      
      # Ensure status has default value
      if(!"status_pendaftaran" %in% names(mongo_pendaftaran)) {
        mongo_pendaftaran$status_pendaftaran <- "Pending"
      } else {
        mongo_pendaftaran$status_pendaftaran[is.na(mongo_pendaftaran$status_pendaftaran)] <- "Pending"
      }
      
      # Insert data
      result <- pendaftaran_conn$insert(mongo_pendaftaran)
      pendaftaran_conn$disconnect()
      
      migration_results$pendaftaran <- list(success = TRUE, rows = nrow(pendaftaran_data))
      cat("✓ Pendaftaran data migrated:", nrow(pendaftaran_data), "rows\n")
    }, error = function(e) {
      migration_results$pendaftaran <- list(success = FALSE, error = e$message)
      cat("✗ Pendaftaran migration failed:", as.character(e$message), "\n")
    })
  } else {
    cat("- No pendaftaran data to migrate\n")
    migration_results$pendaftaran <- list(success = TRUE, rows = 0)
  }
  
  # Migration Summary
  cat("\n=== Migration Summary ===\n")
  total_success <- sum(sapply(migration_results, function(x) x$success))
  total_collections <- length(migration_results)
  total_rows <- sum(sapply(migration_results, function(x) x$rows))
  
  cat("Collections migrated:", total_success, "/", total_collections, "\n")
  cat("Total rows migrated:", total_rows, "\n")
  
  if (total_success == total_collections) {
    cat("✓ Migration completed successfully!\n")
    return(TRUE)
  } else {
    cat("✗ Some migrations failed. Check errors above.\n")
    return(FALSE)
  }
}

# Run migration if called directly
if (interactive() || (length(commandArgs(trailingOnly = TRUE)) > 0 && commandArgs(trailingOnly = TRUE)[1] == "migrate")) {
  result <- migrate_rds_to_mongodb()
  if (result) {
    cat("\nMigration completed. You can now use MongoDB as your primary database.\n")
  } else {
    cat("\nMigration had errors. Please check the output above.\n")
  }
}