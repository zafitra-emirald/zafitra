# Debug direct MongoDB operations

source("fn/mongodb_config.R")

cat("🔍 Direct MongoDB Debug Test\n")
cat("============================\n")

# Test direct MongoDB operations
pendaftaran_conn <- get_mongo_connection("pendaftaran")

# Check current data count
current_count <- pendaftaran_conn$count()
cat("📊 Current pendaftaran count:", current_count, "\n")

# Create a simple test record directly in MongoDB
test_record <- list(
  id_pendaftaran = as.integer(9999),
  nim_mahasiswa = "MONGO_TEST_9999",
  nama_mahasiswa = "Direct MongoDB Test",
  program_studi = "Test",
  kontak = "test",
  pilihan_lokasi = "Test Location",
  letter_of_interest_path = "test.pdf",
  cv_mahasiswa_path = "test.pdf", 
  form_rekomendasi_prodi_path = "test.pdf",
  form_komitmen_mahasiswa_path = "test.pdf",
  transkrip_nilai_path = "test.pdf",
  status_pendaftaran = "Diajukan",
  alasan_penolakan = "",
  timestamp = as.character(Sys.time())
)

cat("📝 Inserting test record...\n")
insert_result <- pendaftaran_conn$insert(test_record)
cat("✅ Insert result:", !is.null(insert_result), "\n")

# Verify insertion
found_record <- pendaftaran_conn$find('{"id_pendaftaran": 9999}')
cat("📊 Found record after insert:", nrow(found_record), "\n")
if (nrow(found_record) > 0) {
  cat("📊 Initial status:", found_record$status_pendaftaran[1], "\n")
}

# Now test update directly
cat("\n📝 Testing direct update...\n")
update_data <- list(
  status_pendaftaran = "Ditolak",
  alasan_penolakan = "Direct MongoDB test rejection"
)

update_result <- pendaftaran_conn$update(
  query = '{"id_pendaftaran": 9999}',
  update = paste0('{"$set": ', jsonlite::toJSON(update_data, auto_unbox = TRUE), '}')
)

cat("📊 Update result - Modified:", update_result$modifiedCount, "Matched:", update_result$matchedCount, "\n")

# Verify update immediately
updated_record <- pendaftaran_conn$find('{"id_pendaftaran": 9999}')
cat("📊 Found record after update:", nrow(updated_record), "\n")
if (nrow(updated_record) > 0) {
  cat("📊 Updated status:", updated_record$status_pendaftaran[1], "\n")
  cat("📊 Updated reason:", updated_record$alasan_penolakan[1], "\n")
}

# Test the refresh function
cat("\n📝 Testing refresh function...\n")
pendaftaran_conn$disconnect()

# Use the wrapper refresh function
source("fn/data_layer_wrapper.R")
refreshed_data <- refresh_pendaftaran_data()
test_from_refresh <- refreshed_data[refreshed_data$id_pendaftaran == 9999, ]

if (nrow(test_from_refresh) > 0) {
  cat("📊 Status from refresh function:", test_from_refresh$status_pendaftaran[1], "\n")
  cat("📊 Reason from refresh function:", test_from_refresh$alasan_penolakan[1], "\n")
} else {
  cat("❌ Test record not found in refresh function result\n")
}

# Clean up
cat("\n🧹 Cleaning up...\n")
pendaftaran_conn <- get_mongo_connection("pendaftaran")
cleanup_result <- pendaftaran_conn$remove('{"id_pendaftaran": 9999}')
pendaftaran_conn$disconnect()
cat("🗑️ Cleaned up test record\n")

cat("\n✅ Direct MongoDB test completed!\n")