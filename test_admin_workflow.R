# Test complete admin rejection workflow with proper data refresh

source("global.R")

cat("🧪 Testing Complete Admin Rejection Workflow\n")
cat("===========================================\n")

initialize_data_layer()

# Create a test registration
test_nim <- paste0("ADMIN_TEST_", format(Sys.time(), "%Y%m%d_%H%M%S"))
test_name <- "Admin Workflow Test Student"

# Get available location
current_lokasi <- refresh_lokasi_data()
available_location <- current_lokasi$nama_lokasi[1]

cat("📝 Step 1: Creating test registration...\n")

test_registration <- data.frame(
  nim_mahasiswa = test_nim,
  nama_mahasiswa = test_name,
  program_studi = "Informatika", 
  kontak = "08999888777",
  pilihan_lokasi = available_location,
  letter_of_interest_path = "documents/admin_test_letter.pdf",
  cv_mahasiswa_path = "documents/admin_test_cv.pdf",
  form_rekomendasi_prodi_path = "documents/admin_test_rekomendasi.pdf",
  form_komitmen_mahasiswa_path = "documents/admin_test_komitmen.pdf",
  transkrip_nilai_path = "documents/admin_test_transkrip.pdf",
  status_pendaftaran = "Diajukan",
  alasan_penolakan = "",
  stringsAsFactors = FALSE
)

test_id <- save_single_pendaftaran_mongo(test_registration)
cat("✅ Test registration created with ID:", test_id, "\n")

cat("\n📝 Step 2: Simulating admin rejection workflow...\n")

# Simulate the exact workflow that happens in server.R
tryCatch({
  # First, get the current data (like values$pendaftaran_data)
  current_pendaftaran_data <- refresh_pendaftaran_data()
  
  # Find the record (like the server does)
  row_idx <- which(current_pendaftaran_data$id_pendaftaran == test_id)
  
  if(length(row_idx) == 0) {
    stop("Test record not found in current data")
  }
  
  student_name <- current_pendaftaran_data[row_idx, "nama_mahasiswa"]
  cat("📊 Found student:", student_name, "\n")
  
  # Perform the atomic update (exactly like server.R does)
  cat("📝 Performing atomic update...\n")
  update_pendaftaran_status_mongo(test_id, "Ditolak", "Admin workflow test rejection")
  
  # Refresh data (like server.R does)
  cat("📝 Refreshing data...\n")
  refreshed_data <- refresh_pendaftaran_data()
  
  # Check the updated record
  updated_record <- refreshed_data[refreshed_data$id_pendaftaran == test_id, ]
  
  if (nrow(updated_record) > 0) {
    cat("📊 Status after refresh:", updated_record$status_pendaftaran[1], "\n")
    cat("📊 Reason after refresh:", updated_record$alasan_penolakan[1], "\n")
    
    if (updated_record$status_pendaftaran[1] == "Ditolak") {
      cat("✅ Admin rejection workflow working correctly!\n")
      
      # Test re-registration eligibility
      eligibility <- check_registration_eligibility(test_nim, available_location, refreshed_data, refresh_periode_data())
      cat("📊 Re-registration eligibility:", eligibility$eligible, "\n")
      
      if (eligibility$eligible) {
        cat("✅ Rejected student can re-register!\n")
      } else {
        cat("❌ Re-registration blocked. Reason:", eligibility$reason, "\n")
      }
    } else {
      cat("❌ Status not updated correctly\n")
    }
  } else {
    cat("❌ Updated record not found\n")
  }
  
}, error = function(e) {
  cat("❌ Admin workflow failed:", e$message, "\n")
})

# Clean up test record
cat("\n🧹 Cleaning up test data...\n")
pendaftaran_conn <- get_mongo_connection("pendaftaran")
cleanup_result <- pendaftaran_conn$remove(paste0('{"id_pendaftaran": ', as.integer(test_id), '}'))
pendaftaran_conn$disconnect()
cat("🗑️ Test record cleaned up\n")

cat("\n🏁 Admin workflow test completed!\n")