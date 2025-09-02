# Check MongoDB timestamp format

source("fn/mongodb_config.R")

cat("🔍 Checking MongoDB Timestamp Format\n")
cat("====================================\n")

pendaftaran_conn <- get_mongo_connection("pendaftaran")

# Get one record to check timestamp format
sample_record <- pendaftaran_conn$find('{}', limit = 1)

if (nrow(sample_record) > 0) {
  cat("📊 Timestamp column class:", class(sample_record$timestamp), "\n")
  cat("📊 Timestamp value:", sample_record$timestamp[1], "\n")
  cat("📊 Timestamp structure:\n")
  str(sample_record$timestamp[1])
  
  # Test different conversion methods
  cat("\n🧪 Testing conversion methods:\n")
  
  # Method 1: Direct conversion
  tryCatch({
    converted1 <- as.POSIXct(sample_record$timestamp[1])
    cat("✅ Direct as.POSIXct works:", converted1, "\n")
  }, error = function(e) {
    cat("❌ Direct as.POSIXct failed:", e$message, "\n")
  })
  
  # Method 2: Character conversion first
  tryCatch({
    converted2 <- as.POSIXct(as.character(sample_record$timestamp[1]))
    cat("✅ Character then POSIXct works:", converted2, "\n")
  }, error = function(e) {
    cat("❌ Character then POSIXct failed:", e$message, "\n")
  })
  
  # Method 3: Keep as character
  tryCatch({
    converted3 <- as.character(sample_record$timestamp[1])
    cat("✅ Keep as character works:", converted3, "\n")
  }, error = function(e) {
    cat("❌ Keep as character failed:", e$message, "\n")
  })
  
} else {
  cat("❌ No records found in database\n")
}

pendaftaran_conn$disconnect()

cat("\n✅ Timestamp format check completed!\n")