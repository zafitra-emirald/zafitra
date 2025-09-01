# load_or_create_data_mongo.R
# Function to load data from MongoDB or create initial data

source("fn/mongodb_config.R")

load_or_create_data_mongo <- function() {
  
  # Test connection first
  connection_test <- test_mongo_connection()
  if (!connection_test$success) {
    stop(paste("Cannot connect to MongoDB:", connection_test$message))
  }
  
  # Ensure indexes exist
  ensure_mongo_indexes()
  
  # Load or create Kategori data
  tryCatch({
    kategori_conn <- get_mongo_connection("kategori")
    kategori_data_mongo <- kategori_conn$find()
    kategori_conn$disconnect()
    
    if (nrow(kategori_data_mongo) == 0) {
      # Create initial empty structure
      kategori_data <<- data.frame(
        id_kategori = integer(0),
        nama_kategori = character(0),
        deskripsi_kategori = character(0),
        isu_strategis = character(0),
        timestamp = as.POSIXct(character(0)),
        stringsAsFactors = FALSE
      )
    } else {
      # Convert MongoDB data to R data.frame with proper types
      kategori_data <<- data.frame(
        id_kategori = as.integer(kategori_data_mongo$id_kategori),
        nama_kategori = as.character(kategori_data_mongo$nama_kategori),
        deskripsi_kategori = as.character(kategori_data_mongo$deskripsi_kategori),
        isu_strategis = as.character(kategori_data_mongo$isu_strategis),
        timestamp = as.POSIXct(kategori_data_mongo$timestamp),
        stringsAsFactors = FALSE
      )
    }
  }, error = function(e) {
    stop(paste("Failed to load kategori data from MongoDB:", e$message))
  })
  
  # Load or create Periode data
  tryCatch({
    periode_conn <- get_mongo_connection("periode")
    periode_data_mongo <- periode_conn$find()
    periode_conn$disconnect()
    
    if (nrow(periode_data_mongo) == 0) {
      # Create initial data with default periods
      periode_data <<- data.frame(
        id_periode = 1:2,
        nama_periode = c("Semester Genap 2024/2025", "Semester Ganjil 2025/2026"),
        waktu_mulai = as.Date(c("2025-01-01", "2025-07-01")),
        waktu_selesai = as.Date(c("2025-06-30", "2025-12-31")),
        status = c("Aktif", "Tidak Aktif"),
        timestamp = Sys.time(),
        stringsAsFactors = FALSE
      )
      
      # Save initial data to MongoDB
      periode_conn <- get_mongo_connection("periode")
      periode_conn$insert(periode_data)
      periode_conn$disconnect()
    } else {
      # Convert MongoDB data to R data.frame with proper types
      periode_data <<- data.frame(
        id_periode = as.integer(periode_data_mongo$id_periode),
        nama_periode = as.character(periode_data_mongo$nama_periode),
        waktu_mulai = as.Date(periode_data_mongo$waktu_mulai),
        waktu_selesai = as.Date(periode_data_mongo$waktu_selesai),
        status = as.character(periode_data_mongo$status),
        timestamp = as.POSIXct(periode_data_mongo$timestamp),
        stringsAsFactors = FALSE
      )
    }
  }, error = function(e) {
    stop(paste("Failed to load periode data from MongoDB:", e$message))
  })
  
  # Load or create Lokasi data
  tryCatch({
    lokasi_conn <- get_mongo_connection("lokasi")
    lokasi_data_mongo <- lokasi_conn$find()
    lokasi_conn$disconnect()
    
    if (nrow(lokasi_data_mongo) == 0) {
      # Create initial empty structure
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
    } else {
      # Convert MongoDB data to R data.frame with proper types
      lokasi_data <<- data.frame(
        id_lokasi = as.integer(lokasi_data_mongo$id_lokasi),
        nama_lokasi = as.character(lokasi_data_mongo$nama_lokasi),
        deskripsi_lokasi = as.character(lokasi_data_mongo$deskripsi_lokasi),
        kategori_lokasi = as.character(lokasi_data_mongo$kategori_lokasi),
        isu_strategis = as.character(lokasi_data_mongo$isu_strategis),
        kuota_mahasiswa = as.integer(lokasi_data_mongo$kuota_mahasiswa),
        alamat_lokasi = as.character(ifelse(is.null(lokasi_data_mongo$alamat_lokasi), "", lokasi_data_mongo$alamat_lokasi)),
        map_lokasi = as.character(ifelse(is.null(lokasi_data_mongo$map_lokasi), "", lokasi_data_mongo$map_lokasi)),
        foto_lokasi = as.character(ifelse(is.null(lokasi_data_mongo$foto_lokasi), "", lokasi_data_mongo$foto_lokasi)),
        timestamp = as.POSIXct(as.character(lokasi_data_mongo$timestamp)),
        stringsAsFactors = FALSE
      )
      
      # Handle list columns (program_studi and foto_lokasi_list)
      if ("program_studi" %in% names(lokasi_data_mongo)) {
        lokasi_data$program_studi <<- lokasi_data_mongo$program_studi
      } else {
        lokasi_data$program_studi <<- replicate(nrow(lokasi_data), list(), simplify = FALSE)
      }
      
      if ("foto_lokasi_list" %in% names(lokasi_data_mongo)) {
        lokasi_data$foto_lokasi_list <<- lokasi_data_mongo$foto_lokasi_list
      } else {
        lokasi_data$foto_lokasi_list <<- replicate(nrow(lokasi_data), list(), simplify = FALSE)
      }
    }
  }, error = function(e) {
    stop(paste("Failed to load lokasi data from MongoDB:", e$message))
  })
  
  # Load or create Pendaftaran data
  tryCatch({
    pendaftaran_conn <- get_mongo_connection("pendaftaran")
    pendaftaran_data_mongo <- pendaftaran_conn$find()
    pendaftaran_conn$disconnect()
    
    if (nrow(pendaftaran_data_mongo) == 0) {
      # Create initial empty structure
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
    } else {
      # Convert MongoDB data to R data.frame with proper types
      pendaftaran_data <<- data.frame(
        id_pendaftaran = as.integer(pendaftaran_data_mongo$id_pendaftaran),
        timestamp = as.POSIXct(pendaftaran_data_mongo$timestamp),
        nim_mahasiswa = as.character(pendaftaran_data_mongo$nim_mahasiswa),
        nama_mahasiswa = as.character(pendaftaran_data_mongo$nama_mahasiswa),
        program_studi = as.character(pendaftaran_data_mongo$program_studi),
        kontak = as.character(pendaftaran_data_mongo$kontak),
        pilihan_lokasi = as.character(pendaftaran_data_mongo$pilihan_lokasi),
        letter_of_interest_path = as.character(ifelse(is.null(pendaftaran_data_mongo$letter_of_interest_path), "", pendaftaran_data_mongo$letter_of_interest_path)),
        cv_mahasiswa_path = as.character(ifelse(is.null(pendaftaran_data_mongo$cv_mahasiswa_path), "", pendaftaran_data_mongo$cv_mahasiswa_path)),
        form_rekomendasi_prodi_path = as.character(ifelse(is.null(pendaftaran_data_mongo$form_rekomendasi_prodi_path), "", pendaftaran_data_mongo$form_rekomendasi_prodi_path)),
        form_komitmen_mahasiswa_path = as.character(ifelse(is.null(pendaftaran_data_mongo$form_komitmen_mahasiswa_path), "", pendaftaran_data_mongo$form_komitmen_mahasiswa_path)),
        transkrip_nilai_path = as.character(ifelse(is.null(pendaftaran_data_mongo$transkrip_nilai_path), "", pendaftaran_data_mongo$transkrip_nilai_path)),
        status_pendaftaran = as.character(ifelse(is.null(pendaftaran_data_mongo$status_pendaftaran), "Pending", pendaftaran_data_mongo$status_pendaftaran)),
        alasan_penolakan = as.character(ifelse(is.null(pendaftaran_data_mongo$alasan_penolakan), "", pendaftaran_data_mongo$alasan_penolakan)),
        stringsAsFactors = FALSE
      )
    }
  }, error = function(e) {
    stop(paste("Failed to load pendaftaran data from MongoDB:", e$message))
  })
  
  cat("Data successfully loaded from MongoDB\n")
}