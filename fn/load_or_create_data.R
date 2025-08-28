# load_or_create_data.R
# Function to load data from RDS files or create initial data (fallback only)

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
  
  # Load or create Pendaftaran data
  if (file.exists("data/pendaftaran_data.rds")) {
    pendaftaran_data <<- readRDS("data/pendaftaran_data.rds")
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