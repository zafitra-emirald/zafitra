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

# Application version
APP_VERSION <- "1.0.0"
APP_BUILD_DATE <- Sys.Date()

# Version check function for production verification
get_app_version_info <- function() {
  list(
    version = APP_VERSION,
    build_date = format(APP_BUILD_DATE, "%Y-%m-%d"),
    full_info = paste("Labsos v", APP_VERSION, " (", format(APP_BUILD_DATE, "%Y-%m-%d"), ")", sep = "")
  )
}

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
source("fn/restore_from_backup.R")

# ================================
# 6. INITIALIZE DATA
# ================================

# Load or create initial data when global.R is sourced
load_or_create_data()