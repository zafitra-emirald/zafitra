# load_or_create_data.R
# Function to load data from RDS files or create initial data

load_or_create_data <- function() {
  
  # Load or create Kategori data
  if (file.exists("data/kategori_data.rds")) {
    kategori_data <<- readRDS("data/kategori_data.rds")
  } else {
    kategori_data <<- data.frame(
      id_kategori = integer(0),
      nama_kategori = character(0),
      deskripsi_kategori = character(0),
      isu_strategis = character(0),
      timestamp = as.POSIXct(character(0)),
      stringsAsFactors = FALSE
    )
    # Create data directory if it doesn't exist
    if (!dir.exists("data")) dir.create("data")
    saveRDS(kategori_data, "data/kategori_data.rds")
  }
  
  # Load or create Periode data
  if (file.exists("data/periode_data.rds")) {
    periode_data <<- readRDS("data/periode_data.rds")
  } else {
    periode_data <<- data.frame(
      id_periode = 1:2,
      nama_periode = c("Semester Genap 2024/2025", "Semester Ganjil 2025/2026"),
      waktu_mulai = as.Date(c("2025-01-01", "2025-07-01")),
      waktu_selesai = as.Date(c("2025-06-30", "2025-12-31")),
      status = c("Aktif", "Tidak Aktif"),
      timestamp = Sys.time(),
      stringsAsFactors = FALSE
    )
    saveRDS(periode_data, "data/periode_data.rds")
  }
  
  # Load or create Lokasi data
  if (file.exists("data/lokasi_data.rds")) {
    lokasi_data <<- readRDS("data/lokasi_data.rds")
    
    # MIGRATION: Add new columns if missing
    new_cols <- c("alamat_lokasi", "map_lokasi", "foto_lokasi_list")
    for(col in new_cols) {
      if(!col %in% names(lokasi_data)) {
        if(col == "foto_lokasi_list") {
          # Initialize with existing foto_lokasi if available, otherwise empty list
          if("foto_lokasi" %in% names(lokasi_data)) {
            lokasi_data[[col]] <- lapply(lokasi_data$foto_lokasi, function(x) if(x != "") list(x) else list())
          } else {
            lokasi_data[[col]] <- replicate(nrow(lokasi_data), list(), simplify = FALSE)
          }
        } else {
          lokasi_data[[col]] <- character(nrow(lokasi_data))
        }
      }
    }
    
    # MIGRATION: Ensure program_studi column exists - PRODUCTION SAFE
    # Only add column if completely missing, never modify existing data
    if(!"program_studi" %in% names(lokasi_data) && nrow(lokasi_data) > 0) {
      # Create program_studi as list column with empty lists for existing records
      # Admin will need to manually populate these via the UI
      lokasi_data$program_studi <- replicate(nrow(lokasi_data), list(), simplify = FALSE)
    } else if(!"program_studi" %in% names(lokasi_data)) {
      # Empty data frame case - just add the column structure
      lokasi_data$program_studi <- list()
    }
    
    # Ensure list column structure for foto_lokasi_list
    if("foto_lokasi_list" %in% names(lokasi_data) && length(lokasi_data$foto_lokasi_list) > 0 && !is.list(lokasi_data$foto_lokasi_list[[1]])) {
      lokasi_data$foto_lokasi_list <- replicate(nrow(lokasi_data), list(), simplify = FALSE)
    }
    
    lokasi_data <<- lokasi_data
    
    # PRODUCTION SAFETY: Extremely careful migration that preserves ALL existing data
    migration_needed <- FALSE
    original_data <- lokasi_data  # Keep original for comparison
    
    # Create backup before any migration attempts
    if(file.exists("data/lokasi_data.rds")) {
      backup_filename <- paste0("data/lokasi_data_backup_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".rds")
      file.copy("data/lokasi_data.rds", backup_filename)
    }
    
    # Check if program_studi column exists and has correct structure
    if(nrow(lokasi_data) > 0) {
      if(!"program_studi" %in% names(lokasi_data)) {
        # SAFE: Add missing column with empty lists (preserves all existing data)
        lokasi_data$program_studi <- replicate(nrow(lokasi_data), list(), simplify = FALSE)
        migration_needed <- TRUE
      } else if(!is.list(lokasi_data$program_studi)) {
        # CRITICAL SAFETY: Convert existing program_studi data to list format
        # This preserves existing data instead of wiping it out
        old_program_studi <- lokasi_data$program_studi
        lokasi_data$program_studi <- vector("list", nrow(lokasi_data))
        
        for(i in seq_len(nrow(lokasi_data))) {
          if(i <= length(old_program_studi)) {
            # Preserve existing data by converting to character vector in list
            if(is.character(old_program_studi[i]) && !is.na(old_program_studi[i]) && old_program_studi[i] != "") {
              # If it's a single string, split by comma if it contains multiple values
              if(grepl(",", old_program_studi[i])) {
                lokasi_data$program_studi[[i]] <- trimws(strsplit(old_program_studi[i], ",")[[1]])
              } else {
                lokasi_data$program_studi[[i]] <- as.character(old_program_studi[i])
              }
            } else {
              lokasi_data$program_studi[[i]] <- character(0)
            }
          } else {
            lokasi_data$program_studi[[i]] <- character(0)
          }
        }
        migration_needed <- TRUE
      } else {
        # Check each entry in program_studi list - only fix broken entries, preserve good ones
        for(i in seq_len(min(nrow(lokasi_data), length(lokasi_data$program_studi)))) {
          if(!is.character(lokasi_data$program_studi[[i]])) {
            # Only reset to empty if it's completely broken, preserve any valid data
            if(!is.null(lokasi_data$program_studi[[i]]) && length(lokasi_data$program_studi[[i]]) > 0) {
              # Try to convert to character vector
              tryCatch({
                lokasi_data$program_studi[[i]] <- as.character(lokasi_data$program_studi[[i]])
              }, error = function(e) {
                lokasi_data$program_studi[[i]] <- character(0)
              })
            } else {
              lokasi_data$program_studi[[i]] <- character(0)
            }
            migration_needed <- TRUE
          }
        }
      }
    }
    
    # Update the global assignment after migration
    lokasi_data <<- lokasi_data
    
    # Save migration changes only if structural fixes were needed AND data was preserved
    if(migration_needed) {
      # Final safety check: ensure we haven't lost any location records
      if(nrow(lokasi_data) == nrow(original_data) && 
         all(lokasi_data$id_lokasi == original_data$id_lokasi) &&
         all(lokasi_data$nama_lokasi == original_data$nama_lokasi)) {
        
        # Save with additional verification
        tryCatch({
          saveRDS(lokasi_data, "data/lokasi_data.rds")
          
          # Verify save was successful
          test_read <- readRDS("data/lokasi_data.rds")
          if(nrow(test_read) != nrow(lokasi_data)) {
            stop("Data verification failed: row count mismatch after save")
          }
          
        }, error = function(e) {
          # If save fails, restore from original data
          lokasi_data <<- original_data
          warning(paste("Migration save failed, reverted to original data:", e$message))
        })
      } else {
        # Data integrity check failed - revert to original
        lokasi_data <<- original_data
        warning("Migration aborted: data integrity check failed, reverted to original data")
      }
    }
  } else {
    lokasi_data <<- data.frame(
      id_lokasi = integer(0),
      nama_lokasi = character(0),
      deskripsi_lokasi = character(0),
      kategori_lokasi = character(0),
      isu_strategis = character(0),
      kuota_mahasiswa = integer(0),
      alamat_lokasi = character(0),
      map_lokasi = character(0),
      foto_lokasi = character(0),
      timestamp = as.POSIXct(character(0)),
      stringsAsFactors = FALSE
    )
    
    # Add program_studi as list column
    lokasi_data$program_studi <<- list()
    
    # Add foto_lokasi_list as list column
    lokasi_data$foto_lokasi_list <<- list()
    
    saveRDS(lokasi_data, "data/lokasi_data.rds")
  }
  
  # Load or create Pendaftaran data - FIXED: proper structure
  if (file.exists("data/pendaftaran_data.rds")) {
    # PRODUCTION SAFETY: Backup pendaftaran data before migration
    pendaftaran_backup_filename <- paste0("data/pendaftaran_data_migration_backup_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".rds")
    file.copy("data/pendaftaran_data.rds", pendaftaran_backup_filename)
    
    pendaftaran_data <<- readRDS("data/pendaftaran_data.rds")
    original_pendaftaran_data <- pendaftaran_data  # Keep original for safety checks
    
    # Validate structure - ensure all required columns exist
    required_cols <- c("id_pendaftaran", "timestamp", "nim_mahasiswa", "nama_mahasiswa", "program_studi", 
                       "kontak", "pilihan_lokasi", "letter_of_interest_path",
                       "cv_mahasiswa_path", "form_rekomendasi_prodi_path", 
                       "form_komitmen_mahasiswa_path", "transkrip_nilai_path", 
                       "status_pendaftaran", "alasan_penolakan")
    
    migration_needed_pendaftaran <- FALSE
    
    # MIGRATION: Remove old columns that no longer exist (SAFE - only removes deprecated columns)
    old_cols_to_remove <- c("alasan_pemilihan", "usulan_dosen_pembimbing")
    for(old_col in old_cols_to_remove) {
      if(old_col %in% names(pendaftaran_data)) {
        pendaftaran_data[[old_col]] <- NULL
        migration_needed_pendaftaran <- TRUE
      }
    }
    
    # Add new required columns if missing (SAFE - only adds, never removes existing data)
    for(col in required_cols) {
      if(!col %in% names(pendaftaran_data)) {
        if(col == "timestamp") {
          pendaftaran_data[[col]] <- as.POSIXct(character(nrow(pendaftaran_data)))
        } else if(col == "id_pendaftaran") {
          pendaftaran_data[[col]] <- integer(nrow(pendaftaran_data))
        } else {
          pendaftaran_data[[col]] <- character(nrow(pendaftaran_data))
        }
        migration_needed_pendaftaran <- TRUE
      }
    }
    
    # Ensure columns are in the correct order
    pendaftaran_data <- pendaftaran_data[, required_cols, drop = FALSE]
    
    # PRODUCTION SAFETY: Save migration only if needed and data integrity is preserved
    if(migration_needed_pendaftaran) {
      # Final safety check: ensure we haven't lost any registration records
      if(nrow(pendaftaran_data) == nrow(original_pendaftaran_data) &&
         (nrow(pendaftaran_data) == 0 || all(pendaftaran_data$nim_mahasiswa == original_pendaftaran_data$nim_mahasiswa))) {
        
        tryCatch({
          saveRDS(pendaftaran_data, "data/pendaftaran_data.rds")
          
          # Verify save was successful
          test_read <- readRDS("data/pendaftaran_data.rds")
          if(nrow(test_read) != nrow(pendaftaran_data)) {
            stop("Pendaftaran data verification failed: row count mismatch after save")
          }
          
        }, error = function(e) {
          # If save fails, restore from original data
          pendaftaran_data <<- original_pendaftaran_data
          warning(paste("Pendaftaran migration save failed, reverted to original data:", e$message))
        })
      } else {
        # Data integrity check failed - revert to original
        pendaftaran_data <<- original_pendaftaran_data
        warning("Pendaftaran migration aborted: data integrity check failed, reverted to original data")
      }
    }
    
    pendaftaran_data <<- pendaftaran_data
  } else {
    pendaftaran_data <<- data.frame(
      id_pendaftaran = integer(0),
      timestamp = as.POSIXct(character(0)),
      nim_mahasiswa = character(0),
      nama_mahasiswa = character(0),
      program_studi = character(0),
      kontak = character(0),
      pilihan_lokasi = character(0),
      letter_of_interest_path = character(0),
      cv_mahasiswa_path = character(0),
      form_rekomendasi_prodi_path = character(0),
      form_komitmen_mahasiswa_path = character(0),
      transkrip_nilai_path = character(0),
      status_pendaftaran = character(0),
      alasan_penolakan = character(0),
      stringsAsFactors = FALSE
    )
    saveRDS(pendaftaran_data, "data/pendaftaran_data.rds")
  }
}