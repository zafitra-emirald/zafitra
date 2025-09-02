# Final test of rejection functionality after fixes

source("global.R")

cat("🧪 Final Rejection Functionality Test\n")
cat("=====================================\n")

initialize_data_layer()

# Create test registration
test_nim <- paste0("FINAL_TEST_", format(Sys.time(), "%Y%m%d_%H%M%S"))
current_lokasi <- refresh_lokasi_data()
available_location <- current_lokasi$nama_lokasi[1]

test_registration <- data.frame(
  nim_mahasiswa = test_nim,
  nama_mahasiswa = "Final Test Student",
  program_studi = "Informatika",
  kontak = "08999888777",
  pilihan_lokasi = available_location,
  letter_of_interest_path = "documents/final_test_letter.pdf",
  cv_mahasiswa_path = "documents/final_test_cv.pdf",
  form_rekomendasi_prodi_path = "documents/final_test_rekomendasi.pdf",
  form_komitmen_mahasiswa_path = "documents/final_test_komitmen.pdf",
  transkrip_nilai_path = "documents/final_test_transkrip.pdf",
  status_pendaftaran = "Diajukan",
  alasan_penolakan = "",
  stringsAsFactors = FALSE
)

cat("📝 Creating test registration...\n")
test_id <- save_single_pendaftaran_mongo(test_registration)
cat("✅ Test registration created with ID:", test_id, "\n")

# Check initial status using refresh function
cat("\n📊 Checking initial status using refresh function...\n")
initial_data <- refresh_pendaftaran_data()
initial_record <- initial_data[initial_data$id_pendaftaran == test_id, ]

if (nrow(initial_record) > 0) {
  cat("📊 Initial status from refresh:", initial_record$status_pendaftaran[1], "\n")
} else {
  cat("❌ Test record not found in refresh data\n")
}

# Perform rejection
cat("\n📝 Testing rejection...\n")
tryCatch({
  update_pendaftaran_status_mongo(test_id, "Ditolak", "Final test rejection")
  cat("✅ Rejection executed\n")
}, error = function(e) {
  cat("❌ Rejection failed:", e$message, "\n")
})

# Check updated status using refresh function
cat("\n📊 Checking updated status using refresh function...\n")
updated_data <- refresh_pendaftaran_data()
updated_record <- updated_data[updated_data$id_pendaftaran == test_id, ]

if (nrow(updated_record) > 0) {
  cat("📊 Updated status from refresh:", updated_record$status_pendaftaran[1], "\n")
  cat("📊 Updated reason from refresh:", updated_record$alasan_penolakan[1], "\n")
  
  if (updated_record$status_pendaftaran[1] == "Ditolak") {
    cat("✅ REJECTION WORKING CORRECTLY!\n")
    
    # Test eligibility
    eligibility <- check_registration_eligibility(test_nim, available_location, updated_data, refresh_periode_data())
    cat("📊 Re-registration eligibility:", eligibility$eligible, "\n")
    
    if (eligibility$eligible) {
      cat("✅ REJECTED STUDENT CAN RE-REGISTER!\n")
    } else {
      cat("❌ Re-registration blocked:", eligibility$reason, "\n")
    }
  } else {
    cat("❌ REJECTION NOT WORKING - Status is still:", updated_record$status_pendaftaran[1], "\n")
  }
} else {
  cat("❌ Test record not found in updated refresh data\n")
}

# Clean up test record
cat("\n🧹 Cleaning up test record...\n")
pendaftaran_conn <- get_mongo_connection("pendaftaran")
cleanup_result <- pendaftaran_conn$remove(paste0('{"id_pendaftaran": ', as.integer(test_id), '}'))
pendaftaran_conn$disconnect()
cat("🗑️ Test record cleaned up\n")

cat("\n🏁 Final rejection test completed!\n")