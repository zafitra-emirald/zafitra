# Safe test of rejection functionality - creates single test record and cleans up
# Will NOT modify existing data in MongoDB

source("global.R")

cat("🧪 Safe Rejection Test (No existing data modified)\n")
cat("=====================================================\n")

initialize_data_layer()

# Create a unique test registration that we'll clean up afterwards
test_nim <- paste0("TEST_REJECT_", format(Sys.time(), "%Y%m%d_%H%M%S"))
test_name <- "Safe Test Rejection Student"

cat("📝 Creating test registration with NIM:", test_nim, "\n")

# Get available location
current_lokasi <- refresh_lokasi_data()
available_location <- current_lokasi$nama_lokasi[1]

# Create test registration
test_registration <- data.frame(
  nim_mahasiswa = test_nim,
  nama_mahasiswa = test_name,
  program_studi = "Informatika",
  kontak = "08999888777",
  pilihan_lokasi = available_location,
  letter_of_interest_path = "documents/test_letter_safe.pdf",
  cv_mahasiswa_path = "documents/test_cv_safe.pdf",
  form_rekomendasi_prodi_path = "documents/test_rekomendasi_safe.pdf",
  form_komitmen_mahasiswa_path = "documents/test_komitmen_safe.pdf",
  transkrip_nilai_path = "documents/test_transkrip_safe.pdf",
  status_pendaftaran = "Diajukan",
  alasan_penolakan = "",
  stringsAsFactors = FALSE
)

# Create the test registration
test_id <- tryCatch({
  new_id <- save_single_pendaftaran_mongo(test_registration)
  cat("✅ Test registration created with ID:", new_id, "\n")
  new_id
}, error = function(e) {
  cat("❌ Failed to create test registration:", e$message, "\n")
  quit(status = 1)
})

cat("\n📝 Testing rejection functionality...\n")

# Test the rejection function
rejection_result <- tryCatch({
  update_pendaftaran_status_mongo(test_id, "Ditolak", "Test rejection - safe test only")
  cat("✅ Rejection function executed successfully\n")
  TRUE
}, error = function(e) {
  cat("❌ Rejection function failed:", e$message, "\n")
  FALSE
})

if (rejection_result) {
  # Verify the rejection worked
  updated_data <- refresh_pendaftaran_data()
  test_record <- updated_data[updated_data$id_pendaftaran == test_id, ]
  
  if (nrow(test_record) > 0) {
    cat("📊 Test record status:", test_record$status_pendaftaran[1], "\n")
    cat("📊 Test record reason:", test_record$alasan_penolakan[1], "\n")
    
    if (test_record$status_pendaftaran[1] == "Ditolak") {
      cat("✅ Rejection functionality working correctly!\n")
      
      # Test eligibility for re-registration
      eligibility <- check_registration_eligibility(test_nim, available_location, updated_data, refresh_periode_data())
      cat("📊 Re-registration eligibility:", eligibility$eligible, "\n")
      
      if (eligibility$eligible) {
        cat("✅ Rejected student can re-register as expected!\n")
      } else {
        cat("❌ Issue: Rejected student cannot re-register. Reason:", eligibility$reason, "\n")
      }
    } else {
      cat("❌ Issue: Status not updated to 'Ditolak'\n")
    }
  } else {
    cat("❌ Issue: Test record not found after update\n")
  }
}

cat("\n🧹 Cleaning up test data...\n")

# Clean up: Remove the test record
pendaftaran_conn <- get_mongo_connection("pendaftaran")
cleanup_result <- pendaftaran_conn$remove(paste0('{"id_pendaftaran": ', as.integer(test_id), '}'))
pendaftaran_conn$disconnect()

cat("🗑️ Test record cleaned up (removed", cleanup_result, "records)\n")

# Verify no test data remains
final_data <- refresh_pendaftaran_data()
remaining_test_data <- final_data[grepl("TEST_REJECT_", final_data$nim_mahasiswa), ]

if (nrow(remaining_test_data) == 0) {
  cat("✅ All test data cleaned up successfully\n")
} else {
  cat("⚠️ Warning:", nrow(remaining_test_data), "test records still remain\n")
}

cat("\n🏁 Safe rejection test completed!\n")
cat("No existing data was modified during this test.\n")