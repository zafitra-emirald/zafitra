# global.R - Labsos Information System (Fixed Version)

# ================================
# 1. LOAD REQUIRED LIBRARIES
# ================================

# Function to install and load required packages
install_and_load <- function(package) {
  if (!require(package, character.only = TRUE)) {
    install.packages(package, dependencies = TRUE)
    library(package, character.only = TRUE)
  }
}

# List of required packages
required_packages <- c("shiny", "shinydashboard", "DT", "dplyr", "shinyjs", "mongolite")

# Install and load all required packages
for (pkg in required_packages) {
  install_and_load(pkg)
}

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
# MongoDB functions (new)
source("fn/mongodb_config.R")
source("fn/load_or_create_data_mongo.R")
source("fn/save_kategori_data_mongo.R")
source("fn/save_periode_data_mongo.R")
source("fn/save_lokasi_data_mongo.R") 
source("fn/save_single_lokasi_mongo.R")
source("fn/save_pendaftaran_data_mongo.R")
source("fn/save_single_pendaftaran_mongo.R")
source("fn/update_pendaftaran_status_mongo.R")

# Legacy RDS functions (for fallback if needed)
source("fn/load_or_create_data.R")
source("fn/save_kategori_data.R")
source("fn/save_periode_data.R")
source("fn/save_lokasi_data.R") 
source("fn/save_pendaftaran_data.R")

# Data layer wrapper (handles MongoDB/RDS fallback)
source("fn/data_layer_wrapper.R")
source("fn/validate_admin.R")
source("fn/is_registration_open.R")
source("fn/check_category_usage.R")
source("fn/get_next_registration_id.R")
source("fn/check_registration_eligibility.R")
source("fn/get_current_quota_status.R")
source("fn/validate_documents.R")
source("fn/search_registrations.R")
# Backup function stubs (disabled after MongoDB migration)
source("fn/backup_stubs.R")

# ================================
# 6. INITIALIZE DATA
# ================================

# Clear any conflicting MongoDB environment variables to ensure correct database usage
Sys.unsetenv("MONGODB_USERNAME")
Sys.unsetenv("MONGODB_PASSWORD") 
Sys.unsetenv("MONGODB_HOST")
Sys.unsetenv("MONGODB_DATABASE")

# ================================
# 13. MARKDOWN TO HTML CONVERTER
# ================================

# Convert simple markdown-style text to HTML for rich display
convert_markdown_to_html <- function(text) {
  if (is.null(text) || is.na(text) || text == "") {
    return("")
  }
  
  html <- as.character(text)
  
  # Convert **bold** to <strong>bold</strong>
  html <- gsub("\\*\\*([^*]+)\\*\\*", "<strong>\\1</strong>", html)
  
  # Convert *italic* to <em>italic</em>
  html <- gsub("\\*([^*]+)\\*", "<em>\\1</em>", html)
  
  # Convert bullet points (• or -) to HTML list
  lines <- strsplit(html, "\n")[[1]]
  in_list <- FALSE
  result_lines <- c()
  
  for (line in lines) {
    trimmed <- trimws(line)
    
    # Check if line starts with bullet point
    if (grepl("^[•-]\\s+", trimmed)) {
      if (!in_list) {
        result_lines <- c(result_lines, "<ul>")
        in_list <- TRUE
      }
      # Remove bullet and wrap in <li>
      content <- gsub("^[•-]\\s+", "", trimmed)
      result_lines <- c(result_lines, paste0("<li>", content, "</li>"))
    } else {
      # Close list if we were in one
      if (in_list) {
        result_lines <- c(result_lines, "</ul>")
        in_list <- FALSE
      }
      
      # Handle paragraphs (empty lines create paragraph breaks)
      if (trimmed == "") {
        result_lines <- c(result_lines, "<br><br>")
      } else {
        result_lines <- c(result_lines, line)
      }
    }
  }
  
  # Close list if still open
  if (in_list) {
    result_lines <- c(result_lines, "</ul>")
  }
  
  # Join lines with proper spacing
  html <- paste(result_lines, collapse = "\n")
  
  # Convert remaining single line breaks to <br>, but avoid within HTML tags
  html <- gsub("\n(?!<)", "<br>", html, perl = TRUE)
  
  # Clean up multiple <br> tags and spacing
  html <- gsub("<br><br><br>", "<br><br>", html)
  html <- gsub("(<ul>)<br>", "\\1", html)
  html <- gsub("<br>(</ul>)", "\\1", html)
  html <- gsub("(<li>[^<]*)</li><br>", "\\1</li>", html)
  
  return(html)
}

# ================================

# Load or create initial data when global.R is sourced
# Initialize data layer with MongoDB/RDS fallback
data_layer_result <- initialize_data_layer()