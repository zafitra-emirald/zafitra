# global.R - Labsos Information System (Fixed Version)

# ================================
# 1. LOAD REQUIRED LIBRARIES
# ================================
library(shiny)
library(shinydashboard)
library(DT)
library(dplyr)
library(shinyjs)

# ================================
# 2. GLOBAL CONSTANTS
# ================================

# Define program studi options
PROGRAM_STUDI_OPTIONS <- c(
  "Studi Islam Interdisipliner",
  "Manajemen", 
  "Akuntansi",
  "Farmasi",
  "Agribisnis",
  "Teknologi Hasil Pertanian",
  "Informatika",
  "Teknik Elektro",
  "Teknik Komputer",
  "Pendidikan Guru Sekolah Dasar",
  "Pendidikan Bahasa Inggris"
)

# Admin credentials
admin_credentials <- data.frame(
  username = "admin",
  password = "admin123",
  stringsAsFactors = FALSE
)

# ================================
# 3. DATA LOADING/SAVING FUNCTIONS
# ================================

# Load data from RDS files or create initial data
load_or_create_data <- function() {
  
  # Load or create Kategori data
  if (file.exists("data/kategori_data.rds")) {
    kategori_data <<- readRDS("data/kategori_data.rds")
  } else {
    kategori_data <<- data.frame(
      id_kategori = 1:3,
      nama_kategori = c("Pendidikan", "Kesehatan", "Teknologi"),
      deskripsi_kategori = c(
        "Fokus pada pengembangan sistem pendidikan masyarakat",
        "Peningkatan kesehatan dan kesejahteraan masyarakat",  
        "Implementasi teknologi untuk pemberdayaan masyarakat"
      ),
      isu_strategis = c(
        "Peningkatan literasi dan kualitas pendidikan",
        "Akses layanan kesehatan yang merata",
        "Digital divide dan adopsi teknologi"
      ),
      timestamp = Sys.time(),
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
  } else {
    lokasi_data <<- data.frame(
      id_lokasi = 1:3,
      nama_lokasi = c("Desa Tanjungsari", "Kelurahan Ngampilan", "Desa Wonokromo"),
      deskripsi_lokasi = c(
        "Desa agraris dengan potensi pertanian organik yang besar",
        "Kawasan wisata budaya dengan banyak UMKM kreatif",
        "Desa dengan potensi perikanan dan pengolahan ikan"
      ),
      kategori_lokasi = c("Pendidikan", "Teknologi", "Kesehatan"),
      isu_strategis = c(
        "Modernisasi pertanian dan pemasaran produk",
        "Digitalisasi UMKM dan promosi wisata",
        "Teknologi pengolahan ikan dan cold storage"
      ),
      kuota_mahasiswa = c(10, 15, 8),
      foto_lokasi = c(
        "https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=400&h=250&fit=crop",
        "https://images.unsplash.com/photo-1548013146-72479768bada?w=400&h=250&fit=crop",
        "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400&h=250&fit=crop"
      ),
      timestamp = Sys.time(),
      stringsAsFactors = FALSE
    )
    
    # Add program_studi as list column
    lokasi_data$program_studi <<- list(
      c("Agribisnis", "Teknologi Hasil Pertanian"),
      c("Manajemen", "Informatika"),
      c("Farmasi", "Teknologi Hasil Pertanian")
    )
    
    saveRDS(lokasi_data, "data/lokasi_data.rds")
  }
  
  # Load or create Pendaftaran data - FIXED: proper structure
  if (file.exists("data/pendaftaran_data.rds")) {
    pendaftaran_data <<- readRDS("data/pendaftaran_data.rds")
    # Validate structure - ensure all required columns exist
    required_cols <- c("id_pendaftaran", "timestamp", "nama_mahasiswa", "program_studi", 
                       "kontak", "pilihan_lokasi", "alasan_pemilihan", "usulan_dosen_pembimbing",
                       "cv_mahasiswa_path", "form_rekomendasi_prodi_path", 
                       "form_komitmen_mahasiswa_path", "transkrip_nilai_path", 
                       "status_pendaftaran", "alasan_penolakan")
    
    for(col in required_cols) {
      if(!col %in% names(pendaftaran_data)) {
        if(col == "timestamp") {
          pendaftaran_data[[col]] <- as.POSIXct(character(nrow(pendaftaran_data)))
        } else if(col == "id_pendaftaran") {
          pendaftaran_data[[col]] <- integer(nrow(pendaftaran_data))
        } else {
          pendaftaran_data[[col]] <- character(nrow(pendaftaran_data))
        }
      }
    }
    pendaftaran_data <<- pendaftaran_data
  } else {
    pendaftaran_data <<- data.frame(
      id_pendaftaran = integer(0),
      timestamp = as.POSIXct(character(0)),
      nama_mahasiswa = character(0),
      program_studi = character(0),
      kontak = character(0),
      pilihan_lokasi = character(0),
      alasan_pemilihan = character(0),
      usulan_dosen_pembimbing = character(0),
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

# Save functions for each data type
save_kategori_data <- function(data) {
  if (!dir.exists("data")) dir.create("data")
  saveRDS(data, "data/kategori_data.rds")
}

save_periode_data <- function(data) {
  if (!dir.exists("data")) dir.create("data")
  saveRDS(data, "data/periode_data.rds")
}

save_lokasi_data <- function(data) {
  if (!dir.exists("data")) dir.create("data")
  saveRDS(data, "data/lokasi_data.rds")
}

save_pendaftaran_data <- function(data) {
  if (!dir.exists("data")) dir.create("data")
  saveRDS(data, "data/pendaftaran_data.rds")
}

# ================================
# 4. AUTHENTICATION FUNCTIONS
# ================================

# Function to validate admin login
validate_admin <- function(username, password) {
  if (is.null(username) || is.null(password) || username == "" || password == "") {
    return(FALSE)
  }
  return(username == admin_credentials$username && password == admin_credentials$password)
}

# ================================
# 5. BUSINESS LOGIC FUNCTIONS
# ================================

# Check if registration is currently open
is_registration_open <- function(periode_data = NULL) {
  if(is.null(periode_data)) {
    if(exists("periode_data")) {
      periode_data <- get("periode_data", envir = .GlobalEnv)
    } else {
      return(FALSE)
    }
  }
  
  # Find active period
  active_periods <- periode_data[periode_data$status == "Aktif", ]
  if(nrow(active_periods) == 0) return(FALSE)
  
  # Check if current date is within active period
  current_date <- Sys.Date()
  active_period <- active_periods[1, ]
  
  return(current_date >= active_period$waktu_mulai & current_date <= active_period$waktu_selesai)
}

# Check if kategori can be deleted (used in lokasi)
check_category_usage <- function(kategori_id, lokasi_data = NULL) {
  if(is.null(lokasi_data)) {
    if(exists("lokasi_data")) {
      lokasi_data <- get("lokasi_data", envir = .GlobalEnv)
    } else {
      return(list(can_delete = TRUE, reason = ""))
    }
  }
  
  if(exists("kategori_data")) {
    kategori_name <- kategori_data[kategori_data$id_kategori == kategori_id, "nama_kategori"]
    if(length(kategori_name) == 0) return(list(can_delete = FALSE, reason = "Kategori tidak ditemukan"))
    
    usage_count <- sum(lokasi_data$kategori_lokasi == kategori_name)
    
    if(usage_count > 0) {
      return(list(can_delete = FALSE, reason = paste("Kategori digunakan oleh", usage_count, "lokasi")))
    }
  }
  
  return(list(can_delete = TRUE, reason = ""))
}

# NEW: Generate next registration ID
get_next_registration_id <- function(pendaftaran_data = NULL) {
  if(is.null(pendaftaran_data)) {
    if(exists("pendaftaran_data")) {
      pendaftaran_data <- get("pendaftaran_data", envir = .GlobalEnv)
    } else {
      return(1)
    }
  }
  
  if(nrow(pendaftaran_data) == 0) {
    return(1)
  } else {
    return(max(pendaftaran_data$id_pendaftaran, na.rm = TRUE) + 1)
  }
}

# NEW: Check registration eligibility
check_registration_eligibility <- function(student_name, location_name, pendaftaran_data = NULL, periode_data = NULL) {
  # Check if registration period is open
  if(!is_registration_open(periode_data)) {
    return(list(eligible = FALSE, reason = "Periode pendaftaran tidak aktif"))
  }
  
  if(is.null(pendaftaran_data)) {
    if(exists("pendaftaran_data")) {
      pendaftaran_data <- get("pendaftaran_data", envir = .GlobalEnv)
    } else {
      return(list(eligible = TRUE, reason = ""))
    }
  }
  
  # Check if student already has active registration
  existing <- pendaftaran_data[
    pendaftaran_data$nama_mahasiswa == student_name & 
      pendaftaran_data$status_pendaftaran %in% c("Diajukan", "Disetujui"), 
  ]
  
  if(nrow(existing) > 0) {
    return(list(eligible = FALSE, reason = "Sudah terdaftar di lokasi lain atau masih dalam proses review"))
  }
  
  return(list(eligible = TRUE, reason = ""))
}

# NEW: Get current quota status for a location
get_current_quota_status <- function(location_name, pendaftaran_data = NULL, lokasi_data = NULL) {
  if(is.null(pendaftaran_data)) {
    if(exists("pendaftaran_data")) {
      pendaftaran_data <- get("pendaftaran_data", envir = .GlobalEnv)
    }
  }
  
  if(is.null(lokasi_data)) {
    if(exists("lokasi_data")) {
      lokasi_data <- get("lokasi_data", envir = .GlobalEnv)
    }
  }
  
  # Get location info
  lokasi <- lokasi_data[lokasi_data$nama_lokasi == location_name, ]
  if(nrow(lokasi) == 0) {
    return(list(
      total_quota = 0,
      used_quota = 0,
      available_quota = 0,
      pending = 0,
      approved = 0,
      rejected = 0
    ))
  }
  
  # Count registrations for this location
  registrations <- pendaftaran_data[pendaftaran_data$pilihan_lokasi == location_name, ]
  
  pending <- sum(registrations$status_pendaftaran == "Diajukan", na.rm = TRUE)
  approved <- sum(registrations$status_pendaftaran == "Disetujui", na.rm = TRUE)
  rejected <- sum(registrations$status_pendaftaran == "Ditolak", na.rm = TRUE)
  
  # Used quota includes both pending and approved
  used_quota <- pending + approved
  available_quota <- max(0, lokasi$kuota_mahasiswa - used_quota)
  
  return(list(
    total_quota = lokasi$kuota_mahasiswa,
    used_quota = used_quota,
    available_quota = available_quota,
    pending = pending,
    approved = approved,
    rejected = rejected
  ))
}

# NEW: Validate document uploads
validate_documents <- function(doc_list) {
  required_docs <- c("reg_cv_mahasiswa", "reg_form_rekomendasi", "reg_form_komitmen", "reg_transkrip_nilai")
  missing_docs <- character(0)
  
  for(doc in required_docs) {
    if(is.null(doc_list[[doc]]) || is.null(doc_list[[doc]]$name)) {
      missing_docs <- c(missing_docs, doc)
    }
  }
  
  if(length(missing_docs) > 0) {
    return(list(valid = FALSE, missing = missing_docs))
  }
  
  return(list(valid = TRUE, missing = character(0)))
}

# NEW: Search registrations with multiple criteria
search_registrations <- function(nama = NULL, tanggal = NULL, lokasi = NULL, status = NULL, pendaftaran_data = NULL) {
  if(is.null(pendaftaran_data)) {
    if(exists("pendaftaran_data")) {
      pendaftaran_data <- get("pendaftaran_data", envir = .GlobalEnv)
    } else {
      return(data.frame())
    }
  }
  
  result <- pendaftaran_data
  
  # Filter by name (partial match, case insensitive)
  if(!is.null(nama) && nama != "") {
    result <- result[grepl(nama, result$nama_mahasiswa, ignore.case = TRUE), ]
  }
  
  # Filter by date (exact match)
  if(!is.null(tanggal) && !is.na(tanggal)) {
    result <- result[as.Date(result$timestamp) == tanggal, ]
  }
  
  # Filter by location
  if(!is.null(lokasi) && lokasi != "") {
    result <- result[result$pilihan_lokasi == lokasi, ]
  }
  
  # Filter by status
  if(!is.null(status) && status != "") {
    result <- result[result$status_pendaftaran == status, ]
  }
  
  return(result)
}

# ================================
# 6. INITIALIZE DATA
# ================================

# Load or create initial data when global.R is sourced
load_or_create_data()