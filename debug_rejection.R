# Debug the rejection function

source("global.R")

cat("🔍 Debugging Rejection Function\n")
cat("===============================\n")

initialize_data_layer()

# Create a test record first
test_nim <- paste0("DEBUG_REJECT_", format(Sys.time(), "%Y%m%d_%H%M%S"))

# Get available location
current_lokasi <- refresh_lokasi_data()
available_location <- current_lokasi$nama_lokasi[1]

test_registration <- data.frame(
  nim_mahasiswa = test_nim,
  nama_mahasiswa = "Debug Test Student",
  program_studi = "Informatika",
  kontak = "08999888777",
  pilihan_lokasi = available_location,
  letter_of_interest_path = "documents/debug_letter.pdf",
  cv_mahasiswa_path = "documents/debug_cv.pdf",
  form_rekomendasi_prodi_path = "documents/debug_rekomendasi.pdf",
  form_komitmen_mahasiswa_path = "documents/debug_komitmen.pdf",
  transkrip_nilai_path = "documents/debug_transkrip.pdf",
  status_pendaftaran = "Diajukan",
  alasan_penolakan = "",
  stringsAsFactors = FALSE
)

test_id <- save_single_pendaftaran_mongo(test_registration)
cat("📝 Created test record with ID:", test_id, "\n")

# Check the record before update
before_data <- refresh_pendaftaran_data()
before_record <- before_data[before_data$id_pendaftaran == test_id, ]
cat("📊 Status before rejection:", before_record$status_pendaftaran[1], "\n")

# Test the update function directly with verbose output
cat("\n🔍 Testing update function...\n")

result <- tryCatch({
  # Let's test the function manually with detailed debugging
  pendaftaran_conn <- get_mongo_connection("pendaftaran")
  
  # Check if record exists
  existing_reg <- pendaftaran_conn$find(paste0('{"id_pendaftaran": ', as.integer(test_id), '}'))
  cat("📊 Found", nrow(existing_reg), "records with ID", test_id, "\n")
  
  if (nrow(existing_reg) > 0) {
    cat("📊 Current status in MongoDB:", existing_reg$status_pendaftaran[1], "\n")
    
    # Prepare update
    update_data <- list(
      status_pendaftaran = "Ditolak",
      alasan_penolakan = "Debug test rejection"
    )
    
    cat("📝 Updating with data:", jsonlite::toJSON(update_data, auto_unbox = TRUE), "\n")
    
    # Perform update
    update_result <- pendaftaran_conn$update(
      query = paste0('{"id_pendaftaran": ', as.integer(test_id), '}'),
      update = paste0('{"$set": ', jsonlite::toJSON(update_data, auto_unbox = TRUE), '}')
    )
    
    cat("📊 Update result - Modified:", update_result$modifiedCount, "Matched:", update_result$matchedCount, "\n")
    
    # Verify update
    updated_reg <- pendaftaran_conn$find(paste0('{"id_pendaftaran": ', as.integer(test_id), '}'))
    cat("📊 Status after update:", updated_reg$status_pendaftaran[1], "\n")
    cat("📊 Reason after update:", updated_reg$alasan_penolakan[1], "\n")
  }
  
  pendaftaran_conn$disconnect()
  TRUE
}, error = function(e) {
  cat("❌ Error during manual test:", e$message, "\n")
  FALSE
})

# Clean up test record
cat("\n🧹 Cleaning up debug record...\n")
pendaftaran_conn <- get_mongo_connection("pendaftaran")
cleanup_result <- pendaftaran_conn$remove(paste0('{"id_pendaftaran": ', as.integer(test_id), '}'))
pendaftaran_conn$disconnect()
cat("🗑️ Removed", cleanup_result, "test records\n")

cat("\n✅ Debug test completed!\n")