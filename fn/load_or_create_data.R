# load_or_create_data.R
# Function to load data from RDS files or create initial data

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