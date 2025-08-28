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
  username = "adminlabsos",
  password = "labsosunu4869",
  stringsAsFactors = FALSE
)

# ================================
# 3. LOAD FUNCTION FILES
# ================================

# Source all function files from fn/ directory
source("fn/load_or_create_data.R")
source("fn/save_kategori_data.R")
source("fn/save_periode_data.R")
source("fn/save_lokasi_data.R") 
source("fn/save_pendaftaran_data.R")
source("fn/validate_admin.R")
source("fn/is_registration_open.R")
source("fn/check_category_usage.R")
source("fn/get_next_registration_id.R")
source("fn/check_registration_eligibility.R")
source("fn/get_current_quota_status.R")
source("fn/validate_documents.R")
source("fn/search_registrations.R")
source("fn/cleanup_old_backups.R")

# ================================
# 6. INITIALIZE DATA
# ================================

# Load or create initial data when global.R is sourced
load_or_create_data()