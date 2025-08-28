# data_layer_wrapper.R
# Wrapper functions that handle MongoDB/RDS fallback

# Global flag to track which data layer is active
USE_MONGODB <- TRUE

# Check if MongoDB is available and working
check_mongodb_availability <- function() {
  tryCatch({
    test_result <- test_mongo_connection()
    return(test_result$success)
  }, error = function(e) {
    return(FALSE)
  })
}

# Initialize data layer (called from global.R)
initialize_data_layer <- function() {
  if (check_mongodb_availability()) {
    tryCatch({
      load_or_create_data_mongo()
      USE_MONGODB <<- TRUE
      cat("Successfully initialized MongoDB data layer\n")
      return("mongodb")
    }, error = function(e) {
      cat("MongoDB initialization failed:", e$message, "\n")
      cat("Falling back to RDS file system\n")
      USE_MONGODB <<- FALSE
      load_or_create_data()
      return("rds")
    })
  } else {
    cat("MongoDB not available, using RDS file system\n")
    USE_MONGODB <<- FALSE
    load_or_create_data()
    return("rds")
  }
}

# Wrapper save functions
save_kategori_data_wrapper <- function(data) {
  if (USE_MONGODB) {
    tryCatch({
      save_kategori_data_mongo(data)
    }, error = function(e) {
      cat("MongoDB save failed, falling back to RDS:", e$message, "\n")
      save_kategori_data(data)
    })
  } else {
    save_kategori_data(data)
  }
}

save_periode_data_wrapper <- function(data) {
  if (USE_MONGODB) {
    tryCatch({
      save_periode_data_mongo(data)
    }, error = function(e) {
      cat("MongoDB save failed, falling back to RDS:", e$message, "\n")
      save_periode_data(data)
    })
  } else {
    save_periode_data(data)
  }
}

save_lokasi_data_wrapper <- function(data) {
  if (USE_MONGODB) {
    tryCatch({
      save_lokasi_data_mongo(data)
    }, error = function(e) {
      cat("MongoDB save failed, falling back to RDS:", e$message, "\n")
      save_lokasi_data(data)
    })
  } else {
    save_lokasi_data(data)
  }
}

save_pendaftaran_data_wrapper <- function(data) {
  if (USE_MONGODB) {
    tryCatch({
      save_pendaftaran_data_mongo(data)
    }, error = function(e) {
      cat("MongoDB save failed, falling back to RDS:", e$message, "\n")
      save_pendaftaran_data(data)
    })
  } else {
    save_pendaftaran_data(data)
  }
}

# Function to refresh data from current data layer
refresh_kategori_data <- function() {
  if (USE_MONGODB) {
    tryCatch({
      kategori_conn <- get_mongo_connection("kategori")
      kategori_data_mongo <- kategori_conn$find()
      kategori_conn$disconnect()
      
      if (nrow(kategori_data_mongo) == 0) {
        return(data.frame(
          id_kategori = integer(0),
          nama_kategori = character(0),
          deskripsi_kategori = character(0),
          isu_strategis = character(0),
          timestamp = as.POSIXct(character(0)),
          stringsAsFactors = FALSE
        ))
      } else {
        return(data.frame(
          id_kategori = as.integer(kategori_data_mongo$id_kategori),
          nama_kategori = as.character(kategori_data_mongo$nama_kategori),
          deskripsi_kategori = as.character(kategori_data_mongo$deskripsi_kategori),
          isu_strategis = as.character(kategori_data_mongo$isu_strategis),
          timestamp = as.POSIXct(kategori_data_mongo$timestamp),
          stringsAsFactors = FALSE
        ))
      }
    }, error = function(e) {
      cat("MongoDB refresh failed, falling back to RDS:", e$message, "\n")
      return(if(file.exists("data/kategori_data.rds")) readRDS("data/kategori_data.rds") else kategori_data)
    })
  } else {
    return(if(file.exists("data/kategori_data.rds")) readRDS("data/kategori_data.rds") else kategori_data)
  }
}

refresh_periode_data <- function() {
  if (USE_MONGODB) {
    tryCatch({
      periode_conn <- get_mongo_connection("periode")
      periode_data_mongo <- periode_conn$find()
      periode_conn$disconnect()
      
      if (nrow(periode_data_mongo) == 0) {
        return(data.frame(
          id_periode = integer(0),
          nama_periode = character(0),
          waktu_mulai = as.Date(character(0)),
          waktu_selesai = as.Date(character(0)),
          status = character(0),
          timestamp = as.POSIXct(character(0)),
          stringsAsFactors = FALSE
        ))
      } else {
        return(data.frame(
          id_periode = as.integer(periode_data_mongo$id_periode),
          nama_periode = as.character(periode_data_mongo$nama_periode),
          waktu_mulai = as.Date(periode_data_mongo$waktu_mulai),
          waktu_selesai = as.Date(periode_data_mongo$waktu_selesai),
          status = as.character(periode_data_mongo$status),
          timestamp = as.POSIXct(periode_data_mongo$timestamp),
          stringsAsFactors = FALSE
        ))
      }
    }, error = function(e) {
      cat("MongoDB refresh failed, falling back to RDS:", e$message, "\n")
      return(if(file.exists("data/periode_data.rds")) readRDS("data/periode_data.rds") else periode_data)
    })
  } else {
    return(if(file.exists("data/periode_data.rds")) readRDS("data/periode_data.rds") else periode_data)
  }
}

refresh_lokasi_data <- function() {
  if (USE_MONGODB) {
    tryCatch({
      lokasi_conn <- get_mongo_connection("lokasi")
      lokasi_data_mongo <- lokasi_conn$find()
      lokasi_conn$disconnect()
      
      if (nrow(lokasi_data_mongo) == 0) {
        empty_data <- data.frame(
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
        empty_data$program_studi <- list()
        empty_data$foto_lokasi_list <- list()
        return(empty_data)
      } else {
        refreshed_data <- data.frame(
          id_lokasi = as.integer(lokasi_data_mongo$id_lokasi),
          nama_lokasi = as.character(lokasi_data_mongo$nama_lokasi),
          deskripsi_lokasi = as.character(lokasi_data_mongo$deskripsi_lokasi),
          kategori_lokasi = as.character(lokasi_data_mongo$kategori_lokasi),
          isu_strategis = as.character(lokasi_data_mongo$isu_strategis),
          kuota_mahasiswa = as.integer(lokasi_data_mongo$kuota_mahasiswa),
          alamat_lokasi = as.character(lokasi_data_mongo$alamat_lokasi %||% ""),
          map_lokasi = as.character(lokasi_data_mongo$map_lokasi %||% ""),
          foto_lokasi = as.character(lokasi_data_mongo$foto_lokasi %||% ""),
          timestamp = as.POSIXct(lokasi_data_mongo$timestamp),
          stringsAsFactors = FALSE
        )
        
        if ("program_studi" %in% names(lokasi_data_mongo)) {
          refreshed_data$program_studi <- lokasi_data_mongo$program_studi
        } else {
          refreshed_data$program_studi <- replicate(nrow(refreshed_data), list(), simplify = FALSE)
        }
        
        if ("foto_lokasi_list" %in% names(lokasi_data_mongo)) {
          refreshed_data$foto_lokasi_list <- lokasi_data_mongo$foto_lokasi_list
        } else {
          refreshed_data$foto_lokasi_list <- replicate(nrow(refreshed_data), list(), simplify = FALSE)
        }
        
        return(refreshed_data)
      }
    }, error = function(e) {
      cat("MongoDB refresh failed, falling back to RDS:", e$message, "\n")
      return(if(file.exists("data/lokasi_data.rds")) readRDS("data/lokasi_data.rds") else lokasi_data)
    })
  } else {
    return(if(file.exists("data/lokasi_data.rds")) readRDS("data/lokasi_data.rds") else lokasi_data)
  }
}

refresh_pendaftaran_data <- function() {
  if (USE_MONGODB) {
    tryCatch({
      pendaftaran_conn <- get_mongo_connection("pendaftaran")
      pendaftaran_data_mongo <- pendaftaran_conn$find()
      pendaftaran_conn$disconnect()
      
      if (nrow(pendaftaran_data_mongo) == 0) {
        return(data.frame(
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
        ))
      } else {
        return(data.frame(
          id_pendaftaran = as.integer(pendaftaran_data_mongo$id_pendaftaran),
          timestamp = as.POSIXct(pendaftaran_data_mongo$timestamp),
          nim_mahasiswa = as.character(pendaftaran_data_mongo$nim_mahasiswa),
          nama_mahasiswa = as.character(pendaftaran_data_mongo$nama_mahasiswa),
          program_studi = as.character(pendaftaran_data_mongo$program_studi),
          kontak = as.character(pendaftaran_data_mongo$kontak),
          pilihan_lokasi = as.character(pendaftaran_data_mongo$pilihan_lokasi),
          letter_of_interest_path = as.character(pendaftaran_data_mongo$letter_of_interest_path %||% ""),
          cv_mahasiswa_path = as.character(pendaftaran_data_mongo$cv_mahasiswa_path %||% ""),
          form_rekomendasi_prodi_path = as.character(pendaftaran_data_mongo$form_rekomendasi_prodi_path %||% ""),
          form_komitmen_mahasiswa_path = as.character(pendaftaran_data_mongo$form_komitmen_mahasiswa_path %||% ""),
          transkrip_nilai_path = as.character(pendaftaran_data_mongo$transkrip_nilai_path %||% ""),
          status_pendaftaran = as.character(pendaftaran_data_mongo$status_pendaftaran %||% "Pending"),
          alasan_penolakan = as.character(pendaftaran_data_mongo$alasan_penolakan %||% ""),
          stringsAsFactors = FALSE
        ))
      }
    }, error = function(e) {
      cat("MongoDB refresh failed, falling back to RDS:", e$message, "\n")
      return(if(file.exists("data/pendaftaran_data.rds")) readRDS("data/pendaftaran_data.rds") else pendaftaran_data)
    })
  } else {
    return(if(file.exists("data/pendaftaran_data.rds")) readRDS("data/pendaftaran_data.rds") else pendaftaran_data)
  }
}

# Function to get current data layer info
get_data_layer_info <- function() {
  return(list(
    layer = if(USE_MONGODB) "MongoDB" else "RDS Files",
    mongodb_available = check_mongodb_availability(),
    currently_using_mongodb = USE_MONGODB
  ))
}