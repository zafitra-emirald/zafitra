# Debug MongoDB data structure and refresh function

source("fn/mongodb_config.R")
source("fn/data_layer_wrapper.R")

cat("🔍 MongoDB Data Structure Debug\n")
cat("===============================\n")

# Test direct MongoDB vs wrapper function
pendaftaran_conn <- get_mongo_connection("pendaftaran")

# Get a small sample of records
sample_records <- pendaftaran_conn$find('{}', limit = 2)
cat("📊 Sample records from direct MongoDB:\n")
cat("  Class:", class(sample_records), "\n")
cat("  Columns:", paste(names(sample_records), collapse = ", "), "\n")
cat("  First status type:", class(sample_records$status_pendaftaran), "\n")
if (nrow(sample_records) > 0) {
  cat("  First status value:", as.character(sample_records$status_pendaftaran[1]), "\n")
}

pendaftaran_conn$disconnect()

cat("\n📊 Sample records from refresh function:\n")
wrapper_data <- refresh_pendaftaran_data()
cat("  Class:", class(wrapper_data), "\n")
cat("  Columns:", paste(names(wrapper_data), collapse = ", "), "\n")
cat("  First status type:", class(wrapper_data$status_pendaftaran), "\n")
if (nrow(wrapper_data) > 0) {
  cat("  First status value:", as.character(wrapper_data$status_pendaftaran[1]), "\n")
}

# Check if there are differences in data structure
cat("\n🔍 Comparing data structures...\n")
if (nrow(sample_records) > 0 && nrow(wrapper_data) > 0) {
  direct_status <- as.character(sample_records$status_pendaftaran[1])
  wrapper_status <- as.character(wrapper_data$status_pendaftaran[1])
  
  cat("Direct MongoDB status:", direct_status, "\n")
  cat("Wrapper function status:", wrapper_status, "\n")
  cat("Match:", direct_status == wrapper_status, "\n")
}

cat("\n✅ Data structure debug completed!\n")