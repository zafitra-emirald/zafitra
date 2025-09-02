# server.R - Labsos Information System Server Logic (Enhanced Data Persistence Version)

server <- function(input, output, session) {
  
  # ================================
  # 1. REACTIVE VALUES INITIALIZATION
  # ================================
  
  # Load fresh data from RDS files to ensure session refresh doesn't lose data
  fresh_kategori_data <- refresh_kategori_data()
  fresh_periode_data <- refresh_periode_data()
  fresh_lokasi_data <- refresh_lokasi_data()
  fresh_pendaftaran_data <- refresh_pendaftaran_data()
  
  values <- reactiveValues(
    admin_logged_in = FALSE,
    login_error = FALSE,
    kategori_data = fresh_kategori_data,
    periode_data = fresh_periode_data,
    lokasi_data = fresh_lokasi_data,
    pendaftaran_data = fresh_pendaftaran_data,
    selected_location = NULL,
    show_registration_modal = FALSE,
    show_photo_modal = FALSE,
    show_admin_modal = FALSE,
    selected_photo_location = NULL,
    last_registration_id = if(nrow(fresh_pendaftaran_data) > 0) max(fresh_pendaftaran_data$id_pendaftaran, na.rm = TRUE) else 0,
    last_update_timestamp = Sys.time(),  # ENHANCED: Add timestamp for real-time updates
    registration_in_progress = FALSE,  # Lock to prevent concurrent registrations
    registration_queue = list()  # Queue for processing registrations
  )
  
  # Helper function to generate unique queue ID
  generate_queue_id <- function() {
    paste0("reg_", as.numeric(Sys.time()), "_", sample(1000:9999, 1))
  }
  
  # Process single registration from queue
  process_single_registration <- function(queue_item) {
    # Refresh data to get latest state
    tryCatch({
      values$pendaftaran_data <- refresh_pendaftaran_data()
    }, error = function(e) {
      showNotification("❌ Gagal memuat data. Silakan refresh halaman.", type = "error", duration = 8)
      return()
    })
    
    # Re-validate with fresh data
    eligibility <- check_registration_eligibility(queue_item$reg_nim, queue_item$location_name, 
                                                values$pendaftaran_data, values$periode_data)
    
    if (!eligibility$eligible) {
      showNotification(paste("❌", queue_item$reg_nama, "tidak dapat mendaftar:", eligibility$reason), 
                      type = "error", duration = 5)
      return()
    }
    
    quota_status <- get_current_quota_status(queue_item$location_name, 
                                           values$pendaftaran_data, values$lokasi_data)
    
    if (quota_status$available_quota <= 0) {
      showNotification(paste("❌", queue_item$reg_nama, "- kuota sudah penuh"), 
                      type = "error", duration = 5)
      return()
    }
    
    # Create registration entry (without ID - will be generated atomically)
    new_registration <- data.frame(
      nim_mahasiswa = as.character(queue_item$reg_nim),
      nama_mahasiswa = as.character(queue_item$reg_nama),
      program_studi = as.character(queue_item$reg_program_studi),
      kontak = as.character(queue_item$reg_kontak),
      pilihan_lokasi = as.character(queue_item$location_name),
      letter_of_interest_path = as.character(ifelse(is.null(queue_item$doc_paths$reg_letter_of_interest), "", queue_item$doc_paths$reg_letter_of_interest)),
      cv_mahasiswa_path = as.character(ifelse(is.null(queue_item$doc_paths$reg_cv_mahasiswa), "", queue_item$doc_paths$reg_cv_mahasiswa)),
      form_rekomendasi_prodi_path = as.character(ifelse(is.null(queue_item$doc_paths$reg_form_rekomendasi), "", queue_item$doc_paths$reg_form_rekomendasi)),
      form_komitmen_mahasiswa_path = as.character(ifelse(is.null(queue_item$doc_paths$reg_form_komitmen), "", queue_item$doc_paths$reg_form_komitmen)),
      transkrip_nilai_path = as.character(ifelse(is.null(queue_item$doc_paths$reg_transkrip_nilai), "", queue_item$doc_paths$reg_transkrip_nilai)),
      status_pendaftaran = as.character("Diajukan"),
      alasan_penolakan = as.character(""),
      stringsAsFactors = FALSE
    )
    
    # Use atomic save operation for MongoDB only
    tryCatch({
      source("fn/save_single_pendaftaran_mongo.R")
      new_id <- save_single_pendaftaran_mongo(new_registration)
      
      # Refresh data after save
      tryCatch({
        values$pendaftaran_data <- refresh_pendaftaran_data()
      }, error = function(e) {
        showNotification("❌ Gagal memuat data terbaru. Silakan refresh halaman.", type = "warning", duration = 5)
      })
      values$last_registration_id <- new_id
      
      # Show success notification
      showNotification(paste("✅", queue_item$reg_nama, "berhasil didaftarkan! ID:", new_id), 
                      type = "success", duration = 5)
      
    }, error = function(e) {
      showNotification(paste("❌", queue_item$reg_nama, "gagal disimpan. Silakan coba lagi:", e$message), 
                      type = "error", duration = 8)
    })
  }
  
  # Process registration queue sequentially
  process_registration_queue <- function() {
    if (values$registration_in_progress || length(values$registration_queue) == 0) {
      return()
    }
    
    values$registration_in_progress <- TRUE
    queue_item <- values$registration_queue[[1]]
    values$registration_queue <- values$registration_queue[-1]
    
    tryCatch({
      process_single_registration(queue_item)
    }, error = function(e) {
      # Show error for this specific registration
      showNotification(paste("❌ Pendaftaran", queue_item$reg_nama, "gagal:", e$message), 
                      type = "error", duration = 5)
    }, finally = {
      values$registration_in_progress <- FALSE
      # Process next item in queue
      if (length(values$registration_queue) > 0) {
        shinyjs::delay(100, process_registration_queue())
      }
    })
  }
  
  # Helper function to release registration lock and restore button state
  release_registration_lock <- function() {
    values$registration_in_progress <- FALSE
    shinyjs::enable("submit_registration")
    removeNotification("registration_processing")
    
    # Restore button to original state
    shinyjs::runjs("
      $('#submit_registration').html('✅ Submit Pendaftaran');
      $('#submit_registration').removeClass('btn-warning').addClass('btn-success');
    ")
  }
  
  # ================================
  # 2. VERSION INFO OUTPUT
  # ================================
  
  # Version info output for production verification
  output$version_info <- renderText({
    paste("Version:", APP_VERSION, "| Build:", format(APP_BUILD_DATE, "%Y-%m-%d"))
  })
  
  # ================================
  # 3. ADMIN AUTHENTICATION MODULE
  # ================================
  
  # Admin login status output
  output$is_admin_logged_in <- reactive({
    values$admin_logged_in
  })
  outputOptions(output, "is_admin_logged_in", suspendWhenHidden = FALSE)
  
  # Admin modal state output
  output$show_admin_modal <- reactive({
    values$show_admin_modal
  })
  outputOptions(output, "show_admin_modal", suspendWhenHidden = FALSE)
  
  # Admin login button handler
  observeEvent(input$admin_login_btn, {
    values$show_admin_modal <- TRUE
  })
  
  # Admin login process
  observeEvent(input$do_admin_login, {
    tryCatch({
      if (validate_admin(input$admin_username, input$admin_password)) {
        values$admin_logged_in <- TRUE
        values$login_error <- FALSE
        values$current_tab <- "manage_registration"  # Set default menu to Kelola Data Pendaftaran
        
        # Set the active tab to Kelola Pendaftaran
        updateTabItems(session, "admin_menu", "manage_registration")
        
        # Close login modal properly
        values$show_admin_modal <- FALSE
        updateTextInput(session, "admin_username", value = "")
        updateTextInput(session, "admin_password", value = "")
        
        showNotification("Login berhasil! Selamat datang, Admin.", type = "message")
      } else {
        values$login_error <- TRUE
      }
    }, error = function(e) {
      values$login_error <- TRUE
      showNotification("Terjadi kesalahan saat login", type = "error")
    })
  })
  
  # Cancel/Close login modal - FIXED: Proper custom modal closing
  observeEvent(input$cancel_admin_login, {
    values$login_error <- FALSE
    values$show_admin_modal <- FALSE
    # Clear login inputs
    updateTextInput(session, "admin_username", value = "")
    updateTextInput(session, "admin_password", value = "")
  })
  
  observeEvent(input$close_admin_login, {
    values$login_error <- FALSE
    values$show_admin_modal <- FALSE
    # Clear login inputs
    updateTextInput(session, "admin_username", value = "")
    updateTextInput(session, "admin_password", value = "")
  })
  
  # Admin logout
  observeEvent(input$admin_logout_btn, {
    values$admin_logged_in <- FALSE
    values$login_error <- FALSE
    
    # Reset any selected items
    session$userData$selected_kategori_id <- NULL
    session$userData$selected_periode_id <- NULL
    session$userData$selected_lokasi_id <- NULL
    
    # Reset registration modal state
    values$selected_location <- NULL
    values$show_registration_modal <- FALSE
    
    # FIXED: Clean logout without affecting other modals
    shinyjs::runjs("
      // Only hide admin login modal if it's open
      if($('#admin_login_modal').hasClass('show')) {
        $('#admin_login_modal').modal('hide');
      }
      // Only remove body classes if no other modals are open
      setTimeout(function() {
        if($('.modal.show').length === 0) {
          $('.modal-backdrop').remove();
          $('body').removeClass('modal-open');
          $('body').css('padding-right', '');
          $('body').css('overflow', '');
        }
      }, 100);
    ")
    
    # Redirect to homepage
    updateTabItems(session, "student_menu", "locations")
    showNotification("Logout berhasil! Diarahkan ke halaman utama.", type = "message")
  })
  
  # Login error handling
  output$login_error <- reactive({
    values$login_error
  })
  outputOptions(output, "login_error", suspendWhenHidden = FALSE)
  
  output$login_error_message <- renderText({
    "Username atau password salah!"
  })
  
  # ================================
  # 3. MASTER DATA - KATEGORI MODULE
  # ================================
  
  # Kategori table display
  output$kategori_table <- DT::renderDataTable({
    display_data <- values$kategori_data[, c("id_kategori", "nama_kategori", "deskripsi_kategori", "isu_strategis")]
    
    DT::datatable(display_data,
                  options = list(
                    pageLength = 10, 
                    dom = 'tip',
                    language = list(
                      emptyTable = "Tidak ada data kategori",
                      info = "Menampilkan _START_ sampai _END_ dari _TOTAL_ kategori"
                    )
                  ),
                  colnames = c("ID", "Nama Kategori", "Deskripsi", "Isu Strategis"),
                  selection = "single",
                  rownames = FALSE)
  })
  
  # Handle kategori table row selection for editing
  observeEvent(input$kategori_table_rows_selected, {
    if (length(input$kategori_table_rows_selected) > 0) {
      selected_row <- input$kategori_table_rows_selected
      kategori <- values$kategori_data[selected_row, ]
      
      # Populate form fields
      updateTextInput(session, "kategori_nama", value = kategori$nama_kategori)
      updateTextAreaInput(session, "kategori_deskripsi", value = kategori$deskripsi_kategori)
      updateTextAreaInput(session, "kategori_isu", value = kategori$isu_strategis)
      
      # Store the selected ID for editing
      session$userData$selected_kategori_id <- kategori$id_kategori
      showNotification("Data kategori dipilih untuk edit", type = "message")
    }
  })
  
  # Save kategori (Add/Edit)
  observeEvent(input$save_kategori, {
    req(input$kategori_nama)
    
    tryCatch({
      if (is.null(session$userData$selected_kategori_id)) {
        # ADD NEW KATEGORI
        # Handle case where existing IDs might be invalid (e.g., -Inf)
        valid_ids <- values$kategori_data$id_kategori[is.finite(values$kategori_data$id_kategori)]
        new_id <- if(length(valid_ids) > 0) max(valid_ids) + 1 else 1
        new_kategori <- data.frame(
          id_kategori = new_id,
          nama_kategori = input$kategori_nama,
          deskripsi_kategori = ifelse(is.null(input$kategori_deskripsi) || input$kategori_deskripsi == "", 
                                      "Tidak ada deskripsi", input$kategori_deskripsi),
          isu_strategis = ifelse(is.null(input$kategori_isu) || input$kategori_isu == "", 
                                 "Tidak ada isu strategis", input$kategori_isu),
          timestamp = Sys.time(),
          stringsAsFactors = FALSE
        )
        values$kategori_data <- rbind(values$kategori_data, new_kategori)
        save_kategori_data_wrapper(values$kategori_data)
        values$kategori_data <- refresh_kategori_data()
        showNotification("Kategori baru berhasil ditambahkan!", type = "message")
      } else {
        # EDIT EXISTING KATEGORI
        row_idx <- which(values$kategori_data$id_kategori == session$userData$selected_kategori_id)
        if(length(row_idx) > 0) {
          values$kategori_data[row_idx, "nama_kategori"] <- input$kategori_nama
          values$kategori_data[row_idx, "deskripsi_kategori"] <- ifelse(is.null(input$kategori_deskripsi) || input$kategori_deskripsi == "", 
                                                                        "Tidak ada deskripsi", input$kategori_deskripsi)
          values$kategori_data[row_idx, "isu_strategis"] <- ifelse(is.null(input$kategori_isu) || input$kategori_isu == "", 
                                                                   "Tidak ada isu strategis", input$kategori_isu)
          save_kategori_data_wrapper(values$kategori_data)
          values$kategori_data <- refresh_kategori_data()
          showNotification("Kategori berhasil diperbarui!", type = "message")
        }
      }
      
      # Update lokasi kategori choices
      updateSelectInput(session, "lokasi_kategori", choices = values$kategori_data$nama_kategori)
      
      # Reset form
      session$userData$selected_kategori_id <- NULL
      updateTextInput(session, "kategori_nama", value = "")
      updateTextAreaInput(session, "kategori_deskripsi", value = "")
      updateTextAreaInput(session, "kategori_isu", value = "")
      
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Delete kategori with validation
  observeEvent(input$delete_kategori, {
    if (length(input$kategori_table_rows_selected) > 0) {
      selected_row <- input$kategori_table_rows_selected
      kategori_id <- values$kategori_data[selected_row, "id_kategori"]
      kategori_name <- values$kategori_data[selected_row, "nama_kategori"]
      
      # Check if kategori is used in lokasi
      usage_check <- check_category_usage(kategori_id, values$lokasi_data)
      
      if (!usage_check$can_delete) {
        showModal(modalDialog(
          title = "❌ Tidak Dapat Menghapus",
          div(class = "alert alert-danger", usage_check$reason),
          footer = modalButton("OK")
        ))
        return()
      }
      
      # Confirm deletion
      showModal(modalDialog(
        title = "⚠️ Konfirmasi Hapus",
        paste("Apakah Anda yakin ingin menghapus kategori '", kategori_name, "'?"),
        footer = tagList(
          actionButton("confirm_delete_kategori", "Hapus", class = "btn btn-danger"),
          modalButton("Batal")
        )
      ))
    } else {
      showNotification("Pilih kategori yang akan dihapus terlebih dahulu!", type = "warning")
    }
  })
  
  # Confirm kategori deletion
  observeEvent(input$confirm_delete_kategori, {
    if (length(input$kategori_table_rows_selected) > 0) {
      selected_row <- input$kategori_table_rows_selected
      kategori_name <- values$kategori_data[selected_row, "nama_kategori"]
      values$kategori_data <- values$kategori_data[-selected_row, ]
      save_kategori_data_wrapper(values$kategori_data)
      values$kategori_data <- refresh_kategori_data()
      
      # Update choices in other components
      updateSelectInput(session, "lokasi_kategori", choices = values$kategori_data$nama_kategori)
      
      showNotification(paste("Kategori '", kategori_name, "' berhasil dihapus!"), type = "message")
      removeModal()
    }
  })
  
  # Reset kategori form
  observeEvent(input$reset_kategori, {
    session$userData$selected_kategori_id <- NULL
    updateTextInput(session, "kategori_nama", value = "")
    updateTextAreaInput(session, "kategori_deskripsi", value = "")
    updateTextAreaInput(session, "kategori_isu", value = "")
    showNotification("Form kategori direset", type = "message")
  })
  
  # ================================
  # 4. MASTER DATA - PERIODE MODULE
  # ================================
  
  # Periode table display
  output$periode_table <- DT::renderDataTable({
    display_data <- values$periode_data[, c("id_periode", "nama_periode", "waktu_mulai", "waktu_selesai", "status")]
    display_data$waktu_mulai <- format(display_data$waktu_mulai, "%d-%m-%Y")
    display_data$waktu_selesai <- format(display_data$waktu_selesai, "%d-%m-%Y")
    
    DT::datatable(display_data,
                  options = list(
                    pageLength = 10,
                    dom = 'tip',
                    language = list(
                      emptyTable = "Tidak ada data periode",
                      info = "Menampilkan _START_ sampai _END_ dari _TOTAL_ periode"
                    )
                  ),
                  colnames = c("ID", "Nama Periode", "Mulai", "Selesai", "Status"),
                  selection = "single",
                  rownames = FALSE) %>%
      DT::formatStyle("status",
                      backgroundColor = DT::styleEqual(
                        c("Aktif", "Tidak Aktif"),
                        c("#d4edda", "#f8d7da")
                      ),
                      fontWeight = "bold"
      )
  })
  
  # Handle periode table row selection for editing
  observeEvent(input$periode_table_rows_selected, {
    if (length(input$periode_table_rows_selected) > 0) {
      selected_row <- input$periode_table_rows_selected
      periode <- values$periode_data[selected_row, ]
      
      # Populate form fields
      updateTextInput(session, "periode_nama", value = periode$nama_periode)
      updateDateInput(session, "periode_mulai", value = periode$waktu_mulai)
      updateDateInput(session, "periode_selesai", value = periode$waktu_selesai)
      updateSelectInput(session, "periode_status", selected = periode$status)
      
      # Store the selected ID for editing
      session$userData$selected_periode_id <- periode$id_periode
      showNotification("Data periode dipilih untuk edit", type = "message")
    }
  })
  
  # Save periode (Add/Edit)
  observeEvent(input$save_periode, {
    req(input$periode_nama, input$periode_mulai, input$periode_selesai)
    
    tryCatch({
      # Validate dates
      if (input$periode_mulai >= input$periode_selesai) {
        showNotification("Tanggal mulai harus lebih awal dari tanggal selesai!", type = "error")
        return()
      }
      
      # Check for overlapping active periods
      if (input$periode_status == "Aktif") {
        overlapping <- values$periode_data[
          values$periode_data$status == "Aktif" & 
            !(if(!is.null(session$userData$selected_periode_id)) {
              values$periode_data$id_periode == session$userData$selected_periode_id
            } else {
              FALSE
            }), ]
        
        if (nrow(overlapping) > 0) {
          showNotification("Tidak boleh ada lebih dari satu periode aktif pada satu waktu!", type = "error")
          return()
        }
      }
      
      if (is.null(session$userData$selected_periode_id)) {
        # ADD NEW PERIODE
        new_id <- max(values$periode_data$id_periode) + 1
        new_periode <- data.frame(
          id_periode = new_id,
          nama_periode = input$periode_nama,
          waktu_mulai = input$periode_mulai,
          waktu_selesai = input$periode_selesai,
          status = input$periode_status,
          timestamp = Sys.time(),
          stringsAsFactors = FALSE
        )
        values$periode_data <- rbind(values$periode_data, new_periode)
        save_periode_data_wrapper(values$periode_data)
        values$periode_data <- refresh_periode_data()
        showNotification("Periode baru berhasil ditambahkan!", type = "message")
      } else {
        # EDIT EXISTING PERIODE
        row_idx <- which(values$periode_data$id_periode == session$userData$selected_periode_id)
        if(length(row_idx) > 0) {
          values$periode_data[row_idx, "nama_periode"] <- input$periode_nama
          values$periode_data[row_idx, "waktu_mulai"] <- input$periode_mulai
          values$periode_data[row_idx, "waktu_selesai"] <- input$periode_selesai
          values$periode_data[row_idx, "status"] <- input$periode_status
          save_periode_data_wrapper(values$periode_data)
          values$periode_data <- refresh_periode_data()
          showNotification("Periode berhasil diperbarui!", type = "message")
        }
      }
      
      # Reset form
      session$userData$selected_periode_id <- NULL
      updateTextInput(session, "periode_nama", value = "")
      updateDateInput(session, "periode_mulai", value = Sys.Date())
      updateDateInput(session, "periode_selesai", value = Sys.Date() + 30)
      updateSelectInput(session, "periode_status", selected = "Tidak Aktif")
      
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Delete periode
  observeEvent(input$delete_periode, {
    if (length(input$periode_table_rows_selected) > 0) {
      selected_row <- input$periode_table_rows_selected
      periode_name <- values$periode_data[selected_row, "nama_periode"]
      
      # Confirm deletion
      showModal(modalDialog(
        title = "⚠️ Konfirmasi Hapus",
        paste("Apakah Anda yakin ingin menghapus periode '", periode_name, "'?"),
        footer = tagList(
          actionButton("confirm_delete_periode", "Hapus", class = "btn btn-danger"),
          modalButton("Batal")
        )
      ))
    } else {
      showNotification("Pilih periode yang akan dihapus terlebih dahulu!", type = "warning")
    }
  })
  
  # Confirm periode deletion
  observeEvent(input$confirm_delete_periode, {
    if (length(input$periode_table_rows_selected) > 0) {
      selected_row <- input$periode_table_rows_selected
      periode_name <- values$periode_data[selected_row, "nama_periode"]
      values$periode_data <- values$periode_data[-selected_row, ]
      save_periode_data_wrapper(values$periode_data)
      values$periode_data <- refresh_periode_data()
      
      showNotification(paste("Periode '", periode_name, "' berhasil dihapus!"), type = "message")
      removeModal()
    }
  })
  
  # Reset periode form
  observeEvent(input$reset_periode, {
    session$userData$selected_periode_id <- NULL
    updateTextInput(session, "periode_nama", value = "")
    updateDateInput(session, "periode_mulai", value = Sys.Date())
    updateDateInput(session, "periode_selesai", value = Sys.Date() + 30)
    updateSelectInput(session, "periode_status", selected = "Tidak Aktif")
    showNotification("Form periode direset", type = "message")
  })
  
  # ================================
  # 5. MASTER DATA - LOKASI MODULE
  # ================================
  
  # Update kategori choices when kategori data changes
  observe({
    updateSelectInput(session, "lokasi_kategori", choices = values$kategori_data$nama_kategori)
  })
  
  # Enhanced lokasi table with quota status
  output$lokasi_table <- DT::renderDataTable({
    display_lokasi <- values$lokasi_data[, c("id_lokasi", "nama_lokasi", "kategori_lokasi", "kuota_mahasiswa")]
    
    # Add quota status information
    display_lokasi$quota_status <- sapply(display_lokasi$nama_lokasi, function(nama) {
      status <- get_current_quota_status(nama, values$pendaftaran_data, values$lokasi_data)
      paste0(status$used_quota, "/", status$total_quota, 
             " (Tersedia: ", status$available_quota, ")")
    })
    
    display_lokasi$quota_detail <- sapply(display_lokasi$nama_lokasi, function(nama) {
      status <- get_current_quota_status(nama, values$pendaftaran_data, values$lokasi_data)
      paste0("Pending: ", status$pending, ", Approved: ", status$approved, ", Rejected: ", status$rejected)
    })
    
    DT::datatable(display_lokasi,
                  options = list(
                    pageLength = 10, 
                    dom = 'tip',
                    language = list(
                      emptyTable = "Tidak ada data lokasi",
                      info = "Menampilkan _START_ sampai _END_ dari _TOTAL_ lokasi"
                    )
                  ),
                  colnames = c("ID", "Nama Lokasi", "Kategori", "Kuota Total", "Status Kuota", "Detail Pendaftar"),
                  selection = "single",
                  rownames = FALSE)
  })
  
  # Handle lokasi table row selection for editing
  observeEvent(input$lokasi_table_rows_selected, {
    if (length(input$lokasi_table_rows_selected) > 0) {
      selected_row <- input$lokasi_table_rows_selected
      lokasi <- values$lokasi_data[selected_row, ]
      
      # Populate form fields
      updateTextInput(session, "lokasi_nama", value = lokasi$nama_lokasi)
      updateTextAreaInput(session, "lokasi_deskripsi", value = lokasi$deskripsi_lokasi)
      updateTextAreaInput(session, "lokasi_alamat", value = ifelse("alamat_lokasi" %in% names(lokasi), lokasi$alamat_lokasi, ""))
      updateTextInput(session, "lokasi_map", value = ifelse("map_lokasi" %in% names(lokasi), lokasi$map_lokasi, ""))
      updateSelectInput(session, "lokasi_kategori", selected = lokasi$kategori_lokasi)
      updateTextAreaInput(session, "lokasi_isu", value = lokasi$isu_strategis)
      # Safely extract program_studi - it's stored as a list of character vectors
      current_prodi <- tryCatch({
        if (!is.null(lokasi$program_studi) && length(lokasi$program_studi) > 0 && 
            !is.null(lokasi$program_studi[[1]]) && length(lokasi$program_studi[[1]]) > 0) {
          as.character(lokasi$program_studi[[1]])
        } else {
          character(0)
        }
      }, error = function(e) {
        cat("Error extracting program_studi for edit:", e$message, "\n")
        character(0)
      })
      updateSelectInput(session, "lokasi_prodi", selected = current_prodi)
      updateNumericInput(session, "lokasi_kuota", value = lokasi$kuota_mahasiswa)
      
      # Store the selected ID for editing
      session$userData$selected_lokasi_id <- lokasi$id_lokasi
      showNotification("Data lokasi dipilih untuk edit", type = "message")
    }
  })
  
  # Save lokasi (Add/Edit)
  observeEvent(input$save_lokasi, {
    req(input$lokasi_nama, input$lokasi_kategori)
    
    tryCatch({
      # Handle multiple file uploads for foto_lokasi
      foto_url <- "https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400&h=250&fit=crop"
      foto_url_list <- list()
      
      if (!is.null(input$lokasi_foto)) {
        # Create images directory if it doesn't exist
        if (!dir.exists("www/images")) dir.create("www/images", recursive = TRUE)
        
        # Process multiple files
        for(i in 1:nrow(input$lokasi_foto)) {
          file_ext <- tools::file_ext(input$lokasi_foto$name[i])
          new_filename <- paste0("lokasi_", Sys.time() %>% as.numeric(), "_", i, ".", file_ext)
          foto_path <- file.path("www/images", new_filename)
          
          # Copy uploaded file
          file.copy(input$lokasi_foto$datapath[i], foto_path)
          foto_url_list <- append(foto_url_list, paste0("images/", new_filename))
        }
        
        # Set first image as main foto_lokasi for backward compatibility
        if(length(foto_url_list) > 0) {
          foto_url <- foto_url_list[[1]]
        }
      }
      
      if (is.null(session$userData$selected_lokasi_id)) {
        # ADD NEW LOKASI
        # Generate safe new ID
        valid_ids <- values$lokasi_data$id_lokasi[is.finite(values$lokasi_data$id_lokasi)]
        new_id <- if(length(valid_ids) > 0) max(valid_ids) + 1 else 1
        # Add program studi - handle multiple selection properly
        selected_prodi <- input$lokasi_prodi
        if (is.null(selected_prodi)) {
          selected_prodi <- character(0)  # Allow empty selection
        }
        
        new_lokasi <- data.frame(
          id_lokasi = new_id,
          nama_lokasi = input$lokasi_nama,
          deskripsi_lokasi = ifelse(is.null(input$lokasi_deskripsi) || input$lokasi_deskripsi == "", 
                                    "Tidak ada deskripsi", input$lokasi_deskripsi),
          kategori_lokasi = input$lokasi_kategori,
          isu_strategis = ifelse(is.null(input$lokasi_isu) || input$lokasi_isu == "", 
                                 "Tidak ada isu strategis", input$lokasi_isu),
          kuota_mahasiswa = ifelse(is.null(input$lokasi_kuota) || input$lokasi_kuota == 0, 5, input$lokasi_kuota),
          alamat_lokasi = ifelse(is.null(input$lokasi_alamat) || input$lokasi_alamat == "", 
                                "Alamat belum diisi", input$lokasi_alamat),
          map_lokasi = ifelse(is.null(input$lokasi_map) || input$lokasi_map == "", 
                             "", input$lokasi_map),
          foto_lokasi = foto_url,
          timestamp = Sys.time(),
          stringsAsFactors = FALSE
        )
        
        # Add list columns with proper structure
        new_lokasi$program_studi <- list(selected_prodi)
        new_lokasi$foto_lokasi_list <- list(if(length(foto_url_list) > 0) foto_url_list else list())
        
        # Ensure column order matches existing data structure
        # First ensure values$lokasi_data has all required columns
        if(!"alamat_lokasi" %in% names(values$lokasi_data)) {
          values$lokasi_data$alamat_lokasi <- rep("", nrow(values$lokasi_data))
        }
        if(!"map_lokasi" %in% names(values$lokasi_data)) {
          values$lokasi_data$map_lokasi <- rep("", nrow(values$lokasi_data))
        }
        
        existing_cols <- names(values$lokasi_data)
        cat("DEBUG: Existing columns:", paste(existing_cols, collapse=", "), "\n")
        cat("DEBUG: New lokasi columns:", paste(names(new_lokasi), collapse=", "), "\n")
        new_lokasi <- new_lokasi[, existing_cols]
        
        # Robust rbind with error handling
        tryCatch({
          values$lokasi_data <- rbind(values$lokasi_data, new_lokasi)
        }, error = function(e) {
          # If rbind fails, debug and fix structure
          cat("Column mismatch error. Existing columns:", paste(names(values$lokasi_data), collapse=", "), "\n")
          cat("New location columns:", paste(names(new_lokasi), collapse=", "), "\n")
          
          # Force refresh data structure and try again
          load_or_create_data()
          new_lokasi <- new_lokasi[, names(values$lokasi_data)]
          values$lokasi_data <- rbind(values$lokasi_data, new_lokasi)
        })
        
        # Save data with detailed error handling
        tryCatch({
          save_lokasi_data_wrapper(values$lokasi_data)
        }, error = function(e) {
          showNotification(paste("Error saving location data:", e$message), type = "error")
          return()
        })
        
        # PRODUCTION FIX: Reload data from file to ensure consistency
        tryCatch({
          values$lokasi_data <- refresh_lokasi_data()
        }, error = function(e) {
          showNotification(paste("Error refreshing location data:", e$message), type = "error")
          return()
        })
        
        showNotification("Lokasi baru berhasil ditambahkan!", type = "message")
        
      } else {
        # EDIT EXISTING LOKASI
        row_idx <- which(values$lokasi_data$id_lokasi == session$userData$selected_lokasi_id)
        if(length(row_idx) > 0) {
          # Ensure alamat_lokasi and map_lokasi columns exist
          if(!"alamat_lokasi" %in% names(values$lokasi_data)) {
            values$lokasi_data$alamat_lokasi <- rep("", nrow(values$lokasi_data))
          }
          if(!"map_lokasi" %in% names(values$lokasi_data)) {
            values$lokasi_data$map_lokasi <- rep("", nrow(values$lokasi_data))
          }
          
          values$lokasi_data[row_idx, "nama_lokasi"] <- input$lokasi_nama
          values$lokasi_data[row_idx, "deskripsi_lokasi"] <- ifelse(is.null(input$lokasi_deskripsi) || input$lokasi_deskripsi == "", 
                                                                    "Tidak ada deskripsi", input$lokasi_deskripsi)
          # Debug: Print what we're trying to save
          alamat_value <- ifelse(is.null(input$lokasi_alamat) || input$lokasi_alamat == "", 
                                "Alamat belum diisi", input$lokasi_alamat)
          map_value <- ifelse(is.null(input$lokasi_map) || input$lokasi_map == "", 
                             "", input$lokasi_map)
          
          cat("DEBUG: Updating alamat_lokasi to:", alamat_value, "\n")
          cat("DEBUG: Updating map_lokasi to:", map_value, "\n")
          
          values$lokasi_data[row_idx, "alamat_lokasi"] <- alamat_value
          values$lokasi_data[row_idx, "map_lokasi"] <- map_value
          values$lokasi_data[row_idx, "kategori_lokasi"] <- input$lokasi_kategori
          values$lokasi_data[row_idx, "isu_strategis"] <- ifelse(is.null(input$lokasi_isu) || input$lokasi_isu == "", 
                                                                 "Tidak ada isu strategis", input$lokasi_isu)
          # Update foto only if new file uploaded
          if (!is.null(input$lokasi_foto)) {
            values$lokasi_data[row_idx, "foto_lokasi"] <- foto_url
            values$lokasi_data$foto_lokasi_list[[row_idx]] <- if(length(foto_url_list) > 0) foto_url_list else list()
          }
          values$lokasi_data[row_idx, "kuota_mahasiswa"] <- ifelse(is.null(input$lokasi_kuota) || input$lokasi_kuota == 0, 5, input$lokasi_kuota)
          
          # Update program studi - handle multiple selection properly
          selected_prodi <- input$lokasi_prodi
          if (is.null(selected_prodi)) {
            selected_prodi <- character(0)  # Allow empty selection
          }
          
          # Ensure program_studi column exists and is properly structured
          if(!"program_studi" %in% names(values$lokasi_data)) {
            values$lokasi_data$program_studi <- replicate(nrow(values$lokasi_data), list(), simplify = FALSE)
          }
          
          # Properly assign the list structure - ensure it's a list column
          if(!is.list(values$lokasi_data$program_studi)) {
            values$lokasi_data$program_studi <- replicate(nrow(values$lokasi_data), list(), simplify = FALSE)
          }
          
          # Update the specific row with the selected programs (ensure consistency with add logic)
          values$lokasi_data$program_studi[[row_idx]] <- as.character(selected_prodi)
          
          # Update timestamp to reflect the edit
          values$lokasi_data[row_idx, "timestamp"] <- Sys.time()
          
          # Save data with detailed error handling
          cat("DEBUG: About to save. Row", row_idx, "alamat_lokasi:", values$lokasi_data[row_idx, "alamat_lokasi"], "\n")
          cat("DEBUG: About to save. Row", row_idx, "map_lokasi:", values$lokasi_data[row_idx, "map_lokasi"], "\n")
          
          tryCatch({
            save_lokasi_data_wrapper(values$lokasi_data)
            cat("DEBUG: Save completed successfully\n")
          }, error = function(e) {
            showNotification(paste("Error saving location data:", e$message), type = "error")
            cat("DEBUG: Save failed with error:", e$message, "\n")
            return()
          })
          
          # PRODUCTION FIX: Reload data from file to ensure consistency
          tryCatch({
            old_alamat <- values$lokasi_data[row_idx, "alamat_lokasi"]
            old_map <- values$lokasi_data[row_idx, "map_lokasi"]
            
            values$lokasi_data <- refresh_lokasi_data()
            
            # Check if values were preserved after refresh
            new_alamat <- values$lokasi_data[row_idx, "alamat_lokasi"]
            new_map <- values$lokasi_data[row_idx, "map_lokasi"]
            
            cat("DEBUG: After refresh - alamat_lokasi:", new_alamat, "(was:", old_alamat, ")\n")
            cat("DEBUG: After refresh - map_lokasi:", new_map, "(was:", old_map, ")\n")
            
          }, error = function(e) {
            showNotification(paste("Error refreshing location data:", e$message), type = "error")
            return()
          })
          
          # Debug notification showing what was saved
          prodi_text <- if(length(selected_prodi) > 0) paste(selected_prodi, collapse=", ") else "Kosong"
          showNotification(paste0("Lokasi berhasil diperbarui! Program Studi: ", prodi_text), type = "message")
        }
      }
      
      # Reset form
      session$userData$selected_lokasi_id <- NULL
      updateTextInput(session, "lokasi_nama", value = "")
      updateTextAreaInput(session, "lokasi_deskripsi", value = "")
      updateTextAreaInput(session, "lokasi_alamat", value = "")
      updateTextInput(session, "lokasi_map", value = "")
      updateSelectInput(session, "lokasi_kategori", selected = character(0))
      updateTextAreaInput(session, "lokasi_isu", value = "")
      updateSelectInput(session, "lokasi_prodi", selected = character(0))
      updateNumericInput(session, "lokasi_kuota", value = 5)
      
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Delete lokasi
  observeEvent(input$delete_lokasi, {
    if (length(input$lokasi_table_rows_selected) > 0) {
      selected_row <- input$lokasi_table_rows_selected
      lokasi_name <- values$lokasi_data[selected_row, "nama_lokasi"]
      
      # Confirm deletion
      showModal(modalDialog(
        title = "⚠️ Konfirmasi Hapus",
        paste("Apakah Anda yakin ingin menghapus lokasi '", lokasi_name, "'?"),
        footer = tagList(
          actionButton("confirm_delete_lokasi", "Hapus", class = "btn btn-danger"),
          modalButton("Batal")
        )
      ))
    } else {
      showNotification("Pilih lokasi yang akan dihapus terlebih dahulu!", type = "warning")
    }
  })
  
  # Confirm lokasi deletion
  observeEvent(input$confirm_delete_lokasi, {
    if (length(input$lokasi_table_rows_selected) > 0) {
      selected_row <- input$lokasi_table_rows_selected
      lokasi_name <- values$lokasi_data[selected_row, "nama_lokasi"]
      values$lokasi_data <- values$lokasi_data[-selected_row, ]
      
      # Save data with detailed error handling
      tryCatch({
        save_lokasi_data_wrapper(values$lokasi_data)
      }, error = function(e) {
        showNotification(paste("Error deleting location:", e$message), type = "error")
        return()
      })
      
      # PRODUCTION FIX: Reload data from file to ensure consistency
      tryCatch({
        values$lokasi_data <- refresh_lokasi_data()
      }, error = function(e) {
        showNotification(paste("Error refreshing location data:", e$message), type = "error")
        return()
      })
      
      showNotification(paste("Lokasi '", lokasi_name, "' berhasil dihapus!"), type = "message")
      removeModal()
    }
  })
  
  # Reset lokasi form
  observeEvent(input$reset_lokasi, {
    session$userData$selected_lokasi_id <- NULL
    updateTextInput(session, "lokasi_nama", value = "")
    updateTextAreaInput(session, "lokasi_deskripsi", value = "")
    updateTextAreaInput(session, "lokasi_alamat", value = "")
    updateTextInput(session, "lokasi_map", value = "")
    updateSelectInput(session, "lokasi_kategori", selected = character(0))
    updateTextAreaInput(session, "lokasi_isu", value = "")
    updateSelectInput(session, "lokasi_prodi", selected = character(0))
    updateNumericInput(session, "lokasi_kuota", value = 5)
    showNotification("Form lokasi direset", type = "message")
  })
  
  # Add new lokasi - clear form for new entry
  observeEvent(input$add_new_lokasi, {
    session$userData$selected_lokasi_id <- NULL
    updateTextInput(session, "lokasi_nama", value = "")
    updateTextAreaInput(session, "lokasi_deskripsi", value = "")
    updateTextAreaInput(session, "lokasi_alamat", value = "")
    updateTextInput(session, "lokasi_map", value = "")
    updateSelectInput(session, "lokasi_kategori", selected = character(0))
    updateTextAreaInput(session, "lokasi_isu", value = "")
    updateSelectInput(session, "lokasi_prodi", selected = character(0))
    updateNumericInput(session, "lokasi_kuota", value = 5)
    showNotification("Form siap untuk lokasi baru", type = "message")
  })
  
  # ================================
  # 6. STUDENT INTERFACE MODULE
  # ================================
  
  # Quick stats defined in student interface section below
  
  # Check if there are locations to display
  output$has_locations <- reactive({
    nrow(values$lokasi_data) > 0
  })
  outputOptions(output, "has_locations", suspendWhenHidden = FALSE)
  
  # Enhanced locations display with real-time quota
  output$locations_grid <- renderUI({
    locations <- values$lokasi_data
    
    if (nrow(locations) == 0) {
      return(div(class = "alert alert-info text-center",
                 style = "margin-top: 50px; padding: 40px;",
                 icon("info-circle", style = "font-size: 3em; margin-bottom: 15px;"),
                 h4("Belum ada lokasi tersedia"),
                 p("Admin belum menambahkan lokasi. Silakan cek kembali nanti.")))
    }
    
    # Performance optimization: handle large datasets
    if (nrow(locations) > 50) {
      return(div(class = "alert alert-warning text-center",
                 style = "margin-top: 50px; padding: 40px;",
                 icon("exclamation-triangle", style = "font-size: 3em; margin-bottom: 15px;"),
                 h4("Terlalu banyak lokasi untuk ditampilkan"),
                 p(paste("Saat ini ada", nrow(locations), "lokasi. Silakan gunakan pencarian untuk menemukan lokasi yang diinginkan."))))
    }
    
    registration_open <- is_registration_open(values$periode_data)
    
    # Use tryCatch to handle rendering errors gracefully
    tryCatch({
      location_cards <- lapply(1:nrow(locations), function(i) {
      loc <- locations[i, ]
      quota_status <- get_current_quota_status(loc$nama_lokasi, values$pendaftaran_data, values$lokasi_data)
      
      # Determine quota status and styling
      quota_class <- if (quota_status$available_quota > 5) "quota-available" 
      else if (quota_status$available_quota > 0) "quota-limited" 
      else "quota-full"
      
      quota_text <- if (quota_status$available_quota > 0) 
        paste("Tersedia:", quota_status$available_quota, "dari", quota_status$total_quota) else 
          "KUOTA PENUH"
      
      quota_icon <- if (quota_status$available_quota > 5) "✅" 
      else if (quota_status$available_quota > 0) "⚠️" 
      else "❌"
      
      # Create compact vertical card
      div(class = "location-card card-modern",
          # Image with fallback - use first photo from foto_lokasi_list if available
          {
            # Get first photo from foto_lokasi_list as primary source
            thumbnail_src <- NULL
            if("foto_lokasi_list" %in% names(loc) && !is.null(loc$foto_lokasi_list) && length(unlist(loc$foto_lokasi_list)) > 0) {
              thumbnail_src <- unlist(loc$foto_lokasi_list)[1]
            } else if(!is.null(loc$foto_lokasi) && loc$foto_lokasi != "" && loc$foto_lokasi != "foto1.jpg" && loc$foto_lokasi != "foto2.jpg") {
              thumbnail_src <- loc$foto_lokasi
            }
            
            if(!is.null(thumbnail_src) && thumbnail_src != "") {
              img(src = thumbnail_src, class = "location-image", alt = loc$nama_lokasi, 
                  onerror = "this.src='data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjE1MCIgdmlld0JveD0iMCAwIDIwMCAxNTAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIyMDAiIGhlaWdodD0iMTUwIiBmaWxsPSIjRjNGNEY2Ii8+CjxwYXRoIGQ9Ik03NSA2MEw5MCA3NUw5MCA5MEw3NSA5MEw2MCA3NUw2MCA2MEg3NVoiIGZpbGw9IiM5Q0EzQUYiLz4KPHRleHQgeD0iMTAwIiB5PSIxMDAiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIxNCIgZmlsbD0iIzlDQTNBRiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+Rm90byBUaWRhayBUZXJzZWRpYTwvdGV4dD4KPC9zdmc+';")
            } else {
              div(class = "location-image no-image", 
                  div(style = "padding: 40px; text-align: center; color: #9CA3AF; background: #F3F4F6;",
                      icon("image", style = "font-size: 24px; margin-bottom: 10px;"),
                      br(),
                      "Foto Tidak Tersedia"))
            }
          },
          
          div(class = "location-content",
              # Header section
              div(class = "location-header",
                  div(class = "location-title", loc$nama_lokasi),
                  span(class = "location-category", loc$kategori_lokasi)
              ),
              
              # Body section
              div(class = "location-body",
                  div(class = "location-description", loc$deskripsi_lokasi),
                  
                  # Compact meta information
                  div(class = "location-meta",
                      span(class = "meta-tag", "🎯 ", 
                           # Truncate strategic issues for compact display
                           if(nchar(loc$isu_strategis) > 12) paste0(substr(loc$isu_strategis, 1, 12), "...") else loc$isu_strategis),
                      span(class = "meta-tag", 
                           tryCatch({
                             if(!is.null(loc$program_studi) && is.list(loc$program_studi) && 
                                length(loc$program_studi) > 0 && !is.null(loc$program_studi[[1]]) && 
                                length(loc$program_studi[[1]]) > 0) {
                               prodi_list <- as.character(loc$program_studi[[1]])
                               if(length(prodi_list) == 1) {
                                 paste0("📚 ", prodi_list[1])
                               } else if(length(prodi_list) <= 3) {
                                 paste0("📚 ", paste(prodi_list, collapse=", "))
                               } else {
                                 paste0("📚 ", paste(prodi_list[1:2], collapse=", "), " + ", length(prodi_list)-2, " lainnya")
                               }
                             } else {
                               "📚 Belum diset"
                             }
                           }, error = function(e) "📚 Belum diset")),
                      span(class = "meta-tag", "👥 ", quota_status$total_quota)
                  )
              ),
              
              # Footer section 
              div(class = "location-footer",
                  # Quota indicator
                  div(class = "quota-indicator",
                      div(style = "display: flex; align-items: center; gap: 0.4rem;",
                          span(quota_icon, class = quota_class, style = "font-weight: 600; font-size: 1rem;"),
                          span(quota_text, class = quota_class, style = "font-weight: 600; font-size: 0.85rem;")
                      ),
                      span(paste0(quota_status$pending, "/", quota_status$approved), 
                           style = "font-size: 0.75rem; color: var(--text-secondary); font-weight: 500;", 
                           title = paste("Pending:", quota_status$pending, "| Disetujui:", quota_status$approved))
                  ),
                  
                  # Action button
                  div(class = "location-action",
                      if (quota_status$available_quota > 0 && registration_open) {
                        actionButton(paste0("register_", i), "📝 Daftar Sekarang", 
                                     class = "btn btn-modern btn-success-modern",
                                     style = "width: 100%; padding: 0.6rem; font-size: 0.9rem; font-weight: 600;",
                                     onclick = paste0("
                                         Shiny.setInputValue('selected_location_id', '", loc$id_lokasi, "', {priority: 'event'}); 
                                         Shiny.setInputValue('show_registration_modal', Math.random(), {priority: 'event'});
                                       "))
                      } else {
                        if (!registration_open) {
                          div(class = "btn btn-modern btn-outline-modern disabled", 
                              style = "width: 100%; padding: 0.6rem; text-align: center; cursor: not-allowed; font-size: 0.85rem; font-weight: 500;",
                              "⏰ Periode Tidak Aktif")
                        } else {
                          div(class = "btn btn-modern btn-outline-modern disabled", 
                              style = "width: 100%; padding: 0.6rem; text-align: center; cursor: not-allowed; border-color: #dc2626; color: #dc2626; font-size: 0.85rem; font-weight: 500;",
                              "❌ Kuota Penuh")
                        }
                      }
                  )
              )
          )
      )
    })
    
    # Return cards as tagList to work with CSS .location-grid class
    return(do.call(tagList, location_cards))
    
    }, error = function(e) {
      # Handle UI rendering errors gracefully
      return(div(class = "alert alert-danger text-center",
                 style = "margin-top: 50px; padding: 40px;",
                 icon("exclamation-triangle", style = "font-size: 3em; margin-bottom: 15px;"),
                 h4("Error menampilkan lokasi"),
                 p(paste("Terjadi kesalahan:", e$message)),
                 p("Silakan refresh halaman atau hubungi administrator.")))
    })
  })
  
  # ================================
  # 7. ENHANCED REGISTRATION FUNCTIONALITY
  # ================================
  
  # FIXED: Handle location selection and show registration modal with form reset
  observeEvent(input$selected_location_id, {
    req(input$selected_location_id)
    
    tryCatch({
      # FIXED: Always reset form when opening modal (whether new location or reopening)
      reset_registration_form()
      
      lokasi <- values$lokasi_data[values$lokasi_data$id_lokasi == input$selected_location_id, ]
      if (nrow(lokasi) > 0) {
        values$selected_location <- lokasi[1, ]
        values$show_registration_modal <- TRUE
        # Safely extract program_studi choices - it's stored as list of character vectors
        prodi_choices <- if(!is.null(lokasi$program_studi[[1]])) {
          as.character(lokasi$program_studi[[1]])
        } else character(0)
        updateSelectInput(session, "reg_program_studi", choices = prodi_choices)
        
        # FIXED: Additional delay to ensure file inputs are properly cleared
        shinyjs::delay(200, {
          shinyjs::runjs("
            // Extra insurance that file inputs are cleared when modal opens
            $('input[type=file]').each(function() {
              this.value = '';
              $(this).val('');
            });
          ")
        })
        
        showNotification("Lokasi dipilih. Form telah dibersihkan dan siap diisi.", type = "message")
      } else {
        showNotification("Error: Lokasi tidak ditemukan", type = "error")
      }
    }, error = function(e) {
      showNotification(paste("Error memilih lokasi:", e$message), type = "error")
    })
  }, ignoreInit = TRUE)
  
  # Show/hide registration modal reactive output
  output$show_registration_modal <- reactive({
    values$show_registration_modal
  })
  outputOptions(output, "show_registration_modal", suspendWhenHidden = FALSE)
  
  # Photo modal reactive output
  output$show_photo_modal <- reactive({
    values$show_photo_modal
  })
  outputOptions(output, "show_photo_modal", suspendWhenHidden = FALSE)
  
  # Photo modal rendering using reactive output
  output$photo_gallery_content <- renderUI({
    req(values$show_photo_modal, values$selected_photo_location)
    
    location <- values$selected_photo_location
    photos <- NULL
    
    # Extract photos with robust handling for different data structures
    if("foto_lokasi_list" %in% names(location) && !is.null(location$foto_lokasi_list)) {
      tryCatch({
        # Try nested list first (consistent structure)
        if(is.list(location$foto_lokasi_list[[1]]) && length(location$foto_lokasi_list[[1]]) > 0) {
          photos <- unlist(location$foto_lokasi_list[[1]])
        } else if(length(location$foto_lokasi_list) > 0) {
          # Fallback for direct list structure
          photos <- unlist(location$foto_lokasi_list)
        }
      }, error = function(e) {
        # Last resort: try to extract any photo data
        photos <- unlist(location$foto_lokasi_list)
      })
    }
    
    if(!is.null(photos) && length(photos) > 0) {
      if(length(photos) == 1) {
        # Single photo: Show enlarged by default, click to zoom further
        photo <- photos[1]
        return(div(style = "text-align: center; padding: 15px; max-width: 100%; max-height: 100%; overflow: hidden;",
                   div(style = "position: relative; display: inline-block; border-radius: 12px; overflow: visible;",
                       tags$img(src = photo, 
                                id = "single_photo_display",
                                style = "width: auto; height: auto; max-width: 70vw; max-height: 55vh; min-width: 400px; border-radius: 12px; cursor: pointer; transition: all 0.3s ease; display: block; box-shadow: 0 8px 25px rgba(0,0,0,0.3);",
                                onclick = "
                                  console.log('Single photo clicked');
                                  event.preventDefault();
                                  event.stopPropagation();
                                  event.stopImmediatePropagation();
                                  
                                  var img = document.getElementById('single_photo_display');
                                  if(!img) {
                                    console.log('Single photo image not found');
                                    return false;
                                  }
                                  
                                  if(img.style.transform && img.style.transform.includes('scale')) {
                                    console.log('Resetting single photo zoom');
                                    // Reset to enlarged default
                                    img.style.transform = '';
                                    img.style.zIndex = '';
                                    img.style.position = '';
                                    img.style.maxWidth = '70vw';
                                    img.style.maxHeight = '55vh';
                                  } else {
                                    console.log('Zooming single photo further');
                                    // Zoom further but stay within modal bounds
                                    img.style.transform = 'scale(1.3)';
                                    img.style.zIndex = '10001';
                                    img.style.position = 'relative';
                                    img.style.maxWidth = '85vw';
                                    img.style.maxHeight = '65vh';
                                  }
                                  return false;
                                ",
                                onmouseover = "this.style.filter = 'brightness(1.05)';",
                                onmouseout = "this.style.filter = 'brightness(1)';")
                   ),
                   div(style = "margin-top: 15px; font-size: 0.9em; color: #666; font-weight: 500;", "Klik untuk zoom lebih jauh")
        ))
      } else {
        # Multiple photos: Show grid layout with click to zoom
        photo_elements <- lapply(seq_along(photos), function(i) {
          photo <- photos[i]
          div(style = "display: inline-block; margin: 10px; vertical-align: top; text-align: center;",
              div(style = "position: relative; border-radius: 8px; overflow: hidden;",
                  tags$img(src = photo, 
                           id = paste0("photo_", i),
                           style = "width: 220px; height: 160px; object-fit: cover; border-radius: 8px; cursor: pointer; transition: all 0.2s ease; display: block; box-shadow: 0 4px 8px rgba(0,0,0,0.2);",
                           onclick = paste0("
                             event.stopPropagation();
                             var img = document.getElementById('photo_", i, "');
                             var isZoomed = img.classList.contains('zoomed');
                             
                             if(isZoomed) {
                               // Reset zoom
                               img.classList.remove('zoomed');
                               img.style.transform = '';
                               img.style.zIndex = '';
                               img.style.position = '';
                               img.style.width = '220px';
                               img.style.height = '160px';
                               img.style.objectFit = 'cover';
                             } else {
                               // Reset all other photos
                               var allPhotos = document.querySelectorAll('[id^=\\\"photo_\\\"]');
                               allPhotos.forEach(function(p) {
                                 p.classList.remove('zoomed');
                                 p.style.transform = '';
                                 p.style.zIndex = '';
                                 p.style.position = '';
                                 p.style.width = '220px';
                                 p.style.height = '160px';
                                 p.style.objectFit = 'cover';
                               });
                               // Zoom this photo
                               img.classList.add('zoomed');
                               img.style.transform = 'scale(2.5)';
                               img.style.zIndex = '1000';
                               img.style.position = 'relative';
                               img.style.width = 'auto';
                               img.style.height = 'auto';
                               img.style.objectFit = 'contain';
                             }
                           "),
                           onmouseover = "if(!this.classList.contains('zoomed')) this.style.filter = 'brightness(1.1)';",
                           onmouseout = "if(!this.classList.contains('zoomed')) this.style.filter = 'brightness(1)';")),
              div(style = "margin-top: 8px; font-size: 0.8em; color: #666;", "Klik untuk perbesar"),
              div(style = "font-size: 0.7em; color: #999; margin-top: 2px;", paste0("Foto ", i, " dari ", length(photos)))
          )
        })
        
        return(div(style = "text-align: center; padding: 10px;", photo_elements))
      }
    } else {
      return(div(style = "text-align: center; padding: 40px;",
                 p("Tidak ada foto tersedia untuk lokasi ini")))
    }
  })
  
  # Photo button click handler using reactive approach
  observe({
    req(values$lokasi_data)
    
    # Monitor all photo button inputs
    all_inputs <- names(input)
    photo_button_inputs <- all_inputs[grepl("^view_photos_", all_inputs)]
    
    for(button_name in photo_button_inputs) {
      button_value <- input[[button_name]]
      if(!is.null(button_value) && button_value > 0) {
        # Extract location ID from button name
        location_id <- as.numeric(gsub("view_photos_", "", button_name))
        
        # Find the location
        location_row <- values$lokasi_data[values$lokasi_data$id_lokasi == location_id, ]
        if(nrow(location_row) > 0) {
          cat("=== PHOTO BUTTON CLICKED ===", "\n")
          cat("Button:", as.character(button_name), "Value:", as.character(button_value), "Location ID:", as.character(location_id), "\n")
          
          # Reset and open modal with proper state management
          isolate({
            # Force immediate state reset
            if(values$show_photo_modal) {
              values$show_photo_modal <- FALSE
              values$selected_photo_location <- NULL
            }
            
            # Set new state
            values$selected_photo_location <- location_row[1, ]
            values$show_photo_modal <- TRUE
          })
          
          cat("Photo modal opened for location:", as.character(location_row$nama_lokasi[1]), "\n")
          break
        }
      }
    }
  })
  
  # Update photo modal location name
  output$photo_location_name <- renderText({
    if(!is.null(values$selected_photo_location)) {
      values$selected_photo_location$nama_lokasi
    } else {
      ""
    }
  })
  
  # Close photo modal with complete state cleanup
  observeEvent(input$close_photo_modal, {
    cat("=== CLOSE PHOTO MODAL TRIGGERED (input method) ===", "\n")
    
    # Complete modal cleanup
    values$show_photo_modal <- FALSE
    values$selected_photo_location <- NULL
    
    # Reset any scaled images and remove ESC listener
    runjs("
      console.log('Complete photo modal cleanup');
      var photos = document.querySelectorAll('[id^=\\\"photo_\\\"]');
      photos.forEach(function(photo) {
        photo.style.transform = '';
        photo.style.zIndex = '';
        photo.style.position = '';
        photo.style.width = '';
        photo.style.height = '';
        photo.style.objectFit = '';
        photo.style.maxWidth = '';
        photo.style.maxHeight = '';
      });
      // Remove ESC key listener
      if(window.photoModalEscHandler) {
        document.removeEventListener('keydown', window.photoModalEscHandler);
        window.photoModalEscHandler = null;
      }
      console.log('Photo modal completely reset');
    ")
  }, ignoreNULL = TRUE, ignoreInit = TRUE)
  
  # Close button handler (× button)
  observeEvent(input$close_photo_modal_btn, {
    cat("=== CLOSE PHOTO MODAL TRIGGERED (× button) ===", "\n")
    
    values$show_photo_modal <- FALSE
    values$selected_photo_location <- NULL
    
    # Complete cleanup
    runjs("
      console.log('× button close triggered');
      var photos = document.querySelectorAll('[id^=\\\"photo_\\\"]');
      photos.forEach(function(photo) {
        photo.style.transform = '';
        photo.style.zIndex = '';
        photo.style.position = '';
        photo.style.width = '';
        photo.style.height = '';
        photo.style.objectFit = '';
        photo.style.maxWidth = '';
        photo.style.maxHeight = '';
      });
    ")
  }, ignoreNULL = TRUE, ignoreInit = TRUE)
  
  # Alternative close handler using custom input
  observeEvent(input$close_photo_modal_custom, {
    cat("=== CLOSE PHOTO MODAL TRIGGERED (custom method) ===", "\n")
    
    values$show_photo_modal <- FALSE
    values$selected_photo_location <- NULL
    
    # Reset any scaled images
    runjs("
      console.log('Custom close triggered');
      var photos = document.querySelectorAll('[id^=\\\"photo_\\\"]');
      photos.forEach(function(photo) {
        photo.style.transform = '';
        photo.style.zIndex = '';
        photo.style.position = '';
        photo.style.width = '';
        photo.style.height = '';
        photo.style.objectFit = '';
        photo.style.maxWidth = '';
        photo.style.maxHeight = '';
      });
      // Remove ESC key listener
      if(window.photoModalEscHandler) {
        document.removeEventListener('keydown', window.photoModalEscHandler);
        window.photoModalEscHandler = null;
      }
    ")
  }, ignoreNULL = TRUE, ignoreInit = TRUE)
  
  # Add ESC key support when photo modal opens
  observeEvent(values$show_photo_modal, {
    if(values$show_photo_modal) {
      runjs("
        // Add ESC key listener for photo modal
        window.photoModalEscHandler = function(event) {
          if(event.key === 'Escape') {
            Shiny.setInputValue('close_photo_modal', Math.random());
            console.log('ESC key pressed - closing photo modal');
          }
        };
        document.addEventListener('keydown', window.photoModalEscHandler);
        console.log('ESC key listener added for photo modal');
      ")
    }
  }, ignoreInit = TRUE)
  
  # Registration modal trigger
  observeEvent(input$show_registration_modal, {
    req(input$show_registration_modal)
    values$show_registration_modal <- TRUE
  }, ignoreInit = TRUE)
  
  # Registration form information outputs
  output$selected_location_info <- renderText({
    tryCatch({
      if (!is.null(values$selected_location)) {
        prodi_list <- if(!is.null(values$selected_location$program_studi[[1]])) {
          values$selected_location$program_studi[[1]]
        } else character(0)
        
        prodi_text <- if(length(prodi_list) > 0) {
          paste(prodi_list, collapse = ", ")
        } else {
          "Semua program studi"
        }
        
        paste0(
          "📍 Lokasi: ", values$selected_location$nama_lokasi, "\n",
          "🏷️ Kategori: ", values$selected_location$kategori_lokasi, "\n", 
          "👥 Kuota: ", values$selected_location$kuota_mahasiswa, " mahasiswa\n",
          "📚 Program Studi yang dapat mendaftar: ", prodi_text
        )
      } else {
        "Tidak ada lokasi yang dipilih"
      }
    }, error = function(e) {
      "Error memuat informasi lokasi"
    })
  })
  
  output$location_description <- renderText({
    tryCatch({
      if (!is.null(values$selected_location)) {
        as.character(values$selected_location$deskripsi_lokasi)
      } else {
        "Tidak ada deskripsi"
      }
    }, error = function(e) {
      "Error memuat deskripsi"
    })
  })
  
  output$location_strategic_issues <- renderText({
    tryCatch({
      if (!is.null(values$selected_location)) {
        as.character(values$selected_location$isu_strategis)
      } else {
        "Tidak ada isu strategis"
      }
    }, error = function(e) {
      "Error memuat isu strategis"
    })
  })
  
  # FIXED: Enhanced reset registration form function with comprehensive file input clearing
  reset_registration_form <- function() {
    tryCatch({
      # Reset text inputs
      updateTextInput(session, "reg_nim", value = "")
      updateTextInput(session, "reg_nama", value = "")
      updateSelectInput(session, "reg_program_studi", selected = character(0))
      updateTextInput(session, "reg_kontak", value = "")
      
      # FIXED: Comprehensive file inputs clearing that persists across modal reopens
      shinyjs::runjs("
          // FIXED: Method 1 - Direct DOM manipulation for file inputs
          var fileInputIds = ['reg_letter_of_interest', 'reg_cv_mahasiswa', 'reg_form_rekomendasi', 'reg_form_komitmen', 'reg_transkrip_nilai'];
          
          fileInputIds.forEach(function(inputId) {
            var input = document.getElementById(inputId);
            if (input) {
              // Reset value
              input.value = '';
              input.files = null;
              
              // Clone and replace to ensure complete reset (most reliable method)
              var newInput = input.cloneNode(false);
              input.parentNode.replaceChild(newInput, input);
            }
          });
          
          // FIXED: Method 2 - jQuery backup clearing
          $('input[type=file]').each(function() {
            this.value = '';
            $(this).val('');
            
            // Clear visual indicators
            $(this).removeClass('is-valid is-invalid has-file file-selected');
            $(this).siblings('label, .custom-file-label').text('Choose file');
            $(this).next('.file-feedback, .file-name').text('');
          });
          
          // FIXED: Method 3 - Clear Shiny file input bindings
          if (window.Shiny && window.Shiny.inputBindings) {
            fileInputIds.forEach(function(inputId) {
              try {
                window.Shiny.inputBindings.getInputBinding('#' + inputId)?.setValue(document.getElementById(inputId), null);
              } catch(e) {}
            });
          }
          
          console.log('File inputs completely reset and cleared');
        ")
      
    }, error = function(e) {
      console.log("Error resetting form:", e)
    })
  }
  
  # Close registration modal handler
  observeEvent(input$close_registration_modal, {
    tryCatch({
      # Reset all form data
      values$selected_location <- NULL
      values$show_registration_modal <- FALSE
      reset_registration_form()
      
      # Clean up modal state without affecting other modals
      shinyjs::runjs("
        setTimeout(function() {
          if($('.modal.show').length === 0) {
            $('.modal-backdrop').remove();
            $('body').removeClass('modal-open');
            $('body').css('padding-right', '');
            $('body').css('overflow', '');
          }
        }, 100);
      ")
      
      showNotification("Form pendaftaran ditutup", type = "message")
    }, error = function(e) {
      # Force cleanup even if there's an error
      values$selected_location <- NULL
      values$show_registration_modal <- FALSE
    })
  })
  
  # REMOVED: Duplicate function - using modular version from fn/check_registration_eligibility.R
  
  # FIXED: Handle success modal closure with proper registration modal cleanup
  observeEvent(input$close_success_modal, {
    tryCatch({
      # Step 1: Remove the success modal first
      removeModal()
      
      # Step 2: FIXED - Reset registration modal state BEFORE cleanup
      values$selected_location <- NULL
      values$show_registration_modal <- FALSE
      
      # Step 3: FIXED - Enhanced form reset with comprehensive cleanup
      reset_registration_form()
      
      # Step 4: FIXED - Complete modal cleanup with registration modal removal
      shinyjs::runjs("
          // Remove all modals and backdrops
          // FIXED: Removed global modal hide to preserve admin login modal
          // FIXED: Removed global modal remove to preserve admin login modal
          $('.modal-backdrop').remove();
          
          // Reset body state
          $('body').removeClass('modal-open');
          $('body').css('padding-right', '');
          $('body').css('overflow', '');
          $('body').css('overflow-x', '');
          $('body').css('overflow-y', '');
          
          // FIXED: Safe cleanup - preserve admin login modal
          // Only remove modal backdrops, not modal elements themselves
          
          // Clear any lingering modal states
          setTimeout(function() {
            // FIXED: Removed global modal remove to preserve admin login modal
            $('.modal-backdrop').remove();
            $('body').removeClass('modal-open');
            $('body').css('padding-right', '');
            $('body').css('overflow', '');
          }, 100);
        ")
      
      # Step 5: FIXED - Add delay to ensure DOM cleanup before final state reset
      shinyjs::delay(200, {
        # Final state verification and cleanup
        values$show_registration_modal <- FALSE
        values$selected_location <- NULL
        
        # Force reactive update
        values$last_update_timestamp <- Sys.time()
        
        showNotification("Pendaftaran selesai! Form telah ditutup.", type = "message")
      })
      
    }, error = function(e) {
      # FIXED: Force cleanup even if there's an error
      values$selected_location <- NULL
      values$show_registration_modal <- FALSE
      
      # Emergency modal cleanup
      shinyjs::runjs("
          // FIXED: Removed global modal hide to preserve admin login modal
          // FIXED: Removed global modal remove to preserve admin login modal
          $('.modal-backdrop').remove();
          $('body').removeClass('modal-open');
          $('body').css('padding-right', '');
          $('body').css('overflow', '');
          
          // Force cleanup
          setTimeout(function() {
            // FIXED: Removed global modal remove to preserve admin login modal
            $('.modal-backdrop').remove();
            $('body').removeClass('modal-open');
          }, 100);
        ")
      
      showNotification("Form pendaftaran telah ditutup", type = "message")
    })
  })
  
  # FIXED: Enhanced reset registration form function with comprehensive file input clearing
  reset_registration_form <- function() {
    tryCatch({
      # Reset text inputs
      updateTextInput(session, "reg_nim", value = "")
      updateTextInput(session, "reg_nama", value = "")
      updateSelectInput(session, "reg_program_studi", selected = character(0))
      updateTextInput(session, "reg_kontak", value = "")
      
      # FIXED: Comprehensive file inputs clearing that works across sessions
      shinyjs::runjs("
          // FIXED: Clear all file inputs with multiple approaches for reliability
          var fileInputs = ['#reg_cv_mahasiswa', '#reg_form_rekomendasi', '#reg_form_komitmen', '#reg_transkrip_nilai'];
          
          fileInputs.forEach(function(inputId) {
            var input = $(inputId);
            if (input.length) {
              // Method 1: Clear value and trigger change
              input.val('').trigger('change');
              
              // Method 2: Reset the DOM element directly
              input[0].value = '';
              
              // Method 3: Clone and replace (most reliable for persistent file inputs)
              var newInput = input.clone(true);
              input.replaceWith(newInput);
              
              // Method 4: Clear any associated labels or display elements
              var label = input.next('label, .file-label, .custom-file-label');
              if (label.length) {
                label.text('Choose file');
                label.removeClass('selected file-selected');
              }
              
              // Method 5: Clear any file name displays
              var fileName = input.siblings('.file-name, .selected-file');
              if (fileName.length) {
                fileName.text('').hide();
              }
            }
          });
          
          // FIXED: Clear all file input types comprehensively
          $('input[type=file]').each(function() {
            // Clear the value
            $(this).val('');
            this.value = '';
            
            // Clone and replace to ensure complete reset
            var newElement = $(this).clone(true);
            $(this).replaceWith(newElement);
            
            // Reset any associated elements
            var wrapper = newElement.closest('.form-group, .input-group, .file-input-wrapper');
            if (wrapper.length) {
              wrapper.find('.file-upload-info, .file-preview, .upload-status').remove();
              wrapper.find('label').text('Choose file');
            }
          });
          
          // FIXED: Clear any file-related UI elements
          $('.form-control-file').each(function() {
            $(this).val('');
            this.value = '';
            $(this).trigger('change');
            
            // Reset custom file input styling
            var customLabel = $(this).next('.custom-file-label');
            if (customLabel.length) {
              customLabel.text('Choose file').removeClass('selected');
            }
          });
          
          // FIXED: Remove any file preview or status elements
          $('.file-preview, .upload-success, .file-selected-indicator').remove();
          $('.file-upload-status').html('');
          
          // FIXED: Reset form validation states for file inputs
          $('input[type=file]').removeClass('is-valid is-invalid');
          $('.file-input-feedback').hide();
          
          // FIXED: Clear any cached file data in JavaScript
          if (window.selectedFiles) {
            window.selectedFiles = {};
          }
          
          // FIXED: Force form reset to ensure all inputs are clean
          var form = $('input[type=file]').closest('form');
          if (form.length && form[0].reset) {
            // Store non-file values
            var nonFileValues = {};
            form.find('input:not([type=file]), select, textarea').each(function() {
              nonFileValues[this.id || this.name] = $(this).val();
            });
            
            // Reset form
            form[0].reset();
            
            // Restore non-file values
            Object.keys(nonFileValues).forEach(function(key) {
              var element = form.find('#' + key + ', [name=\"' + key + '\"]');
              if (element.length) {
                element.val(nonFileValues[key]);
              }
            });
          }
          
          console.log('File inputs cleared completely');
        ")
      
      showNotification("Form pendaftaran telah direset lengkap", type = "message")
    }, error = function(e) {
      # FIXED: Fallback file clearing if main method fails
      shinyjs::runjs("
          // Emergency file input clearing
          $('input[type=file]').each(function() {
            this.value = '';
            $(this).val('');
          });
          console.log('Emergency file input clearing executed');
        ")
      showNotification("Form direset (beberapa field mungkin perlu dibersihkan manual)", type = "warning")
    })
  }
  
  # FIXED: Handle location selection with mandatory form reset
  observeEvent(input$selected_location_id, {
    req(input$selected_location_id)
    
    tryCatch({
      # FIXED: Always reset form when selecting a new location
      if (!is.null(values$selected_location) || values$show_registration_modal == TRUE) {
        # User is switching locations or reopening modal - clear everything
        reset_registration_form()
        showNotification("Form dibersihkan untuk lokasi baru", type = "message")
      }
      
      lokasi <- values$lokasi_data[values$lokasi_data$id_lokasi == input$selected_location_id, ]
      if (nrow(lokasi) > 0) {
        values$selected_location <- lokasi[1, ]
        values$show_registration_modal <- TRUE
        # Safely extract program_studi choices - it's stored as list of character vectors
        prodi_choices <- if(!is.null(lokasi$program_studi[[1]])) {
          as.character(lokasi$program_studi[[1]])
        } else character(0)
        updateSelectInput(session, "reg_program_studi", choices = prodi_choices)
        
        # FIXED: Force file input clearing after location selection
        shinyjs::delay(100, {
          shinyjs::runjs("
              // Ensure file inputs are clean for new registration
              $('input[type=file]').each(function() {
                this.value = '';
                $(this).val('').trigger('change');
                
                // Reset labels
                var label = $(this).next('label, .custom-file-label');
                if (label.length) {
                  label.text('Choose file');
                }
              });
            ")
        })
        
        showNotification("Lokasi dipilih. Form siap untuk pendaftaran baru.", type = "message")
      } else {
        showNotification("Error: Lokasi tidak ditemukan", type = "error")
      }
    }, error = function(e) {
      showNotification(paste("Error memilih lokasi:", e$message), type = "error")
    })
  }, ignoreInit = TRUE)
  
  # FIXED: Close registration modal handler with comprehensive file clearing
  observeEvent(input$close_registration_modal, {
    tryCatch({
      # FIXED: Reset form with comprehensive file clearing before closing
      reset_registration_form()
      
      # Reset modal state
      values$show_registration_modal <- FALSE
      values$selected_location <- NULL
      
      # FIXED: Additional file clearing on modal close
      shinyjs::runjs("
          // Final file input clearing on modal close
          setTimeout(function() {
            $('input[type=file]').each(function() {
              this.value = '';
              $(this).val('');
              
              // Reset any visual indicators
              $(this).siblings('label').text('Choose file');
              $(this).removeClass('is-valid is-invalid');
            });
            
            // Clear any remaining file artifacts
            $('.file-preview, .upload-success').remove();
            console.log('Modal close: File inputs cleared');
          }, 50);
        ")
      
      # Clean up modal state
      shinyjs::runjs("
          $('.modal-backdrop').remove();
          $('body').removeClass('modal-open');
          $('body').css('padding-right', '');
        ")
      
      showNotification("Form pendaftaran ditutup dan dibersihkan", type = "message")
    }, error = function(e) {
      # Force cleanup even if there's an error
      values$selected_location <- NULL
      values$show_registration_modal <- FALSE
      
      # Emergency file clearing
      shinyjs::runjs("
          $('input[type=file]').each(function() {
            this.value = '';
            $(this).val('');
          });
        ")
    })
  })
  
  # FIXED: Registration modal trigger with pre-clearing
  observeEvent(input$show_registration_modal, {
    req(input$show_registration_modal)
    
    # FIXED: Clear form before showing modal
    if (values$show_registration_modal == TRUE) {
      shinyjs::delay(50, {
        reset_registration_form()
      })
    }
    
    values$show_registration_modal <- TRUE
  }, ignoreInit = TRUE)
  
  # FIXED: Add a general file input observer to track and clear file selections
  observe({
    # FIXED: Monitor file input changes and clear them when modal is closed
    if (!isTRUE(values$show_registration_modal)) {
      shinyjs::runjs("
          // Clear any lingering file selections when modal is not active
          if (!$('.modal').is(':visible')) {
            $('input[type=file]').each(function() {
              if ($(this).val() !== '') {
                this.value = '';
                $(this).val('').trigger('change');
                
                // Reset labels
                $(this).next('label, .custom-file-label').text('Choose file');
              }
            });
          }
        ")
    }
  })
  
  # FIXED: Additional file clearing on session events
  observeEvent(values$show_registration_modal, {
    if (values$show_registration_modal == TRUE) {
      # FIXED: Clear files when modal opens
      shinyjs::delay(100, {
        shinyjs::runjs("
            // Clear file inputs when modal opens for clean start
            $('input[type=file]').each(function() {
              if (this.value !== '') {
                this.value = '';
                $(this).val('').trigger('change');
                $(this).next('label, .custom-file-label').text('Choose file');
              }
            });
            console.log('Modal opened: File inputs cleared');
          ")
      })
    } else if (values$show_registration_modal == FALSE) {
      # FIXED: Clear files when modal closes
      shinyjs::delay(50, {
        shinyjs::runjs("
            // Clear file inputs when modal closes
            $('input[type=file]').each(function() {
              this.value = '';
              $(this).val('');
              $(this).next('label, .custom-file-label').text('Choose file');
            });
            console.log('Modal closed: File inputs cleared');
          ")
      })
    }
  })
  
  # FIXED: Enhanced show/hide registration modal reactive output with proper state tracking
  output$show_registration_modal <- reactive({
    # Ensure the reactive properly responds to state changes
    result <- values$show_registration_modal
    
    # FIXED: Additional check to ensure modal state consistency
    if (is.null(values$selected_location) || is.null(result)) {
      values$show_registration_modal <- FALSE
      return(FALSE)
    }
    
    return(result)
  })
  outputOptions(output, "show_registration_modal", suspendWhenHidden = FALSE)
# ================================
# 2. ADMIN AUTHENTICATION MODULE
# ================================

# Admin login status output
output$is_admin_logged_in <- reactive({
  values$admin_logged_in
})
outputOptions(output, "is_admin_logged_in", suspendWhenHidden = FALSE)

# REMOVED: Duplicate admin login handler - using the earlier definition with safe cleanup

# REMOVED: Duplicate login modal handlers - using earlier definitions with safe cleanup

# Admin logout
observeEvent(input$admin_logout_btn, {
  values$admin_logged_in <- FALSE
  values$login_error <- FALSE
  
  # Reset any selected items
  session$userData$selected_kategori_id <- NULL
  session$userData$selected_periode_id <- NULL
  session$userData$selected_lokasi_id <- NULL
  
  # Reset registration modal state
  values$selected_location <- NULL
  values$show_registration_modal <- FALSE
  
  # Complete modal cleanup
  shinyjs::runjs("
      // FIXED: Removed global modal hide to preserve admin login modal
      $('.modal-backdrop').remove();
      $('body').removeClass('modal-open');
      $('body').css('padding-right', '');
      $('body').css('overflow', '');
      $('#admin_login_modal').hide();
    ")
  
  # Redirect to homepage
  updateTabItems(session, "student_menu", "locations")
  showNotification("Logout berhasil! Diarahkan ke halaman utama.", type = "message")
})

# Login error handling
output$login_error <- reactive({
  values$login_error
})
outputOptions(output, "login_error", suspendWhenHidden = FALSE)

# login_error_message defined above


# ================================
# 4. MASTER DATA - PERIODE MODULE
# ================================

# Periode table display
output$periode_table <- DT::renderDataTable({
  display_data <- values$periode_data[, c("id_periode", "nama_periode", "waktu_mulai", "waktu_selesai", "status")]
  display_data$waktu_mulai <- format(display_data$waktu_mulai, "%d-%m-%Y")
  display_data$waktu_selesai <- format(display_data$waktu_selesai, "%d-%m-%Y")
  
  DT::datatable(display_data,
                options = list(
                  pageLength = 10,
                  dom = 'tip',
                  language = list(
                    emptyTable = "Tidak ada data periode",
                    info = "Menampilkan _START_ sampai _END_ dari _TOTAL_ periode"
                  )
                ),
                colnames = c("ID", "Nama Periode", "Mulai", "Selesai", "Status"),
                selection = "single",
                rownames = FALSE) %>%
    DT::formatStyle("status",
                    backgroundColor = DT::styleEqual(
                      c("Aktif", "Tidak Aktif"),
                      c("#d4edda", "#f8d7da")
                    ),
                    fontWeight = "bold"
    )
})

# Handle periode table row selection for editing
observeEvent(input$periode_table_rows_selected, {
  if (length(input$periode_table_rows_selected) > 0) {
    selected_row <- input$periode_table_rows_selected
    periode <- values$periode_data[selected_row, ]
    
    # Populate form fields
    updateTextInput(session, "periode_nama", value = periode$nama_periode)
    updateDateInput(session, "periode_mulai", value = periode$waktu_mulai)
    updateDateInput(session, "periode_selesai", value = periode$waktu_selesai)
    updateSelectInput(session, "periode_status", selected = periode$status)
    
    # Store the selected ID for editing
    session$userData$selected_periode_id <- periode$id_periode
    showNotification("Data periode dipilih untuk edit", type = "message")
  }
})


# ================================
# 6. STUDENT INTERFACE MODULE
# ================================

# Quick stats for students
output$total_locations_student <- renderText({
  tryCatch({
    as.character(nrow(values$lokasi_data))
  }, error = function(e) {
    "0"
  })
})

output$active_period_student <- renderText({
  tryCatch({
    if(is_registration_open(values$periode_data)) "AKTIF" else "TUTUP"
  }, error = function(e) {
    "TUTUP"
  })
})

# Check if there are locations to display
output$has_locations <- reactive({
  nrow(values$lokasi_data) > 0
})
outputOptions(output, "has_locations", suspendWhenHidden = FALSE)

# Enhanced locations display for registration with real-time quota  
output$locations_registration <- renderUI({
  locations <- values$lokasi_data
  
  if (nrow(locations) == 0) {
    return(div(class = "alert alert-info text-center",
               style = "margin-top: 50px; padding: 40px;",
               icon("info-circle", style = "font-size: 3em; margin-bottom: 15px;"),
               h4("Belum ada lokasi tersedia"),
               p("Admin belum menambahkan lokasi. Silakan cek kembali nanti.")))
  }
  
  # Performance optimization: handle large datasets
  if (nrow(locations) > 50) {
    return(div(class = "alert alert-warning text-center",
               style = "margin-top: 50px; padding: 40px;",
               icon("exclamation-triangle", style = "font-size: 3em; margin-bottom: 15px;"),
               h4("Terlalu banyak lokasi untuk ditampilkan"),
               p(paste("Saat ini ada", nrow(locations), "lokasi. Silakan gunakan pencarian untuk menemukan lokasi yang diinginkan."))))
  }
  
  registration_open <- is_registration_open(values$periode_data)
  
  # Use tryCatch to handle rendering errors gracefully  
  tryCatch({
    location_cards <- lapply(1:nrow(locations), function(i) {
    loc <- locations[i, ]
    quota_status <- get_current_quota_status(loc$nama_lokasi, values$pendaftaran_data, values$lokasi_data)
    
    # Determine quota status and styling
    quota_class <- if (quota_status$available_quota > 5) "quota-available" 
    else if (quota_status$available_quota > 0) "quota-limited" 
    else "quota-full"
    
    quota_text <- if (quota_status$available_quota > 0) 
      paste("Tersedia:", quota_status$available_quota, "dari", quota_status$total_quota) else 
        "KUOTA PENUH"
    
    quota_icon <- if (quota_status$available_quota > 5) "✅" 
    else if (quota_status$available_quota > 0) "⚠️" 
    else "❌"
    
    # Create enhanced card
    div(class = "location-card", style = "margin-bottom: 20px;",
        # Image with fallback - use first photo from foto_lokasi_list if available
        {
          # Get first photo from foto_lokasi_list as primary source
          thumbnail_src <- NULL
          if("foto_lokasi_list" %in% names(loc) && !is.null(loc$foto_lokasi_list) && length(unlist(loc$foto_lokasi_list)) > 0) {
            thumbnail_src <- unlist(loc$foto_lokasi_list)[1]
          } else if(!is.null(loc$foto_lokasi) && loc$foto_lokasi != "" && loc$foto_lokasi != "foto1.jpg" && loc$foto_lokasi != "foto2.jpg") {
            thumbnail_src <- loc$foto_lokasi
          }
          
          if(!is.null(thumbnail_src) && thumbnail_src != "") {
            img(src = thumbnail_src, class = "location-image", alt = loc$nama_lokasi, 
                onerror = "this.src='data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjE1MCIgdmlld0JveD0iMCAwIDIwMCAxNTAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIyMDAiIGhlaWdodD0iMTUwIiBmaWxsPSIjRjNGNEY2Ii8+CjxwYXRoIGQ9Ik03NSA2MEw5MCA3NUw5MCA5MEw3NSA5MEw2MCA3NUw2MCA2MEg3NVoiIGZpbGw9IiM5Q0EzQUYiLz4KPHRleHQgeD0iMTAwIiB5PSIxMDAiIGZvbnQtZmFtaWx5PSJBcmlhbCIgZm9udC1zaXplPSIxNCIgZmlsbD0iIzlDQTNBRiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+Rm90byBUaWRhayBUZXJzZWRpYTwvdGV4dD4KPC9zdmc+';")
          } else {
            div(class = "location-image no-image", 
                div(style = "padding: 40px; text-align: center; color: #9CA3AF; background: #F3F4F6;",
                    icon("image", style = "font-size: 24px; margin-bottom: 10px;"),
                    br(),
                    "Foto Tidak Tersedia"))
          }
        },
        
        div(class = "location-content",
            div(class = "location-title", loc$nama_lokasi),
            span(class = "location-category", loc$kategori_lokasi),
            
            div(class = "location-description", loc$deskripsi_lokasi),
            
            div(class = "location-details",
                # Address section
                div(style = "margin-bottom: 10px;",
                    strong("📍 Alamat: "), 
                    ifelse("alamat_lokasi" %in% names(loc) && !is.na(loc$alamat_lokasi) && loc$alamat_lokasi != "", 
                           loc$alamat_lokasi, "Alamat belum tersedia")
                ),
                # Map and Photos buttons section
                div(style = "margin-bottom: 10px; display: flex; gap: 8px; flex-wrap: wrap;",
                    # Map button
                    if("map_lokasi" %in% names(loc) && !is.na(loc$map_lokasi) && loc$map_lokasi != "") {
                      tags$a(href = loc$map_lokasi, target = "_blank",
                             class = "btn btn-sm btn-outline-primary",
                             style = "text-decoration: none; font-size: 0.8em; padding: 4px 8px;",
                             "🗺️ Lihat di Maps")
                    } else NULL,
                    # Photos button
                    if("foto_lokasi_list" %in% names(loc) && !is.null(loc$foto_lokasi_list) && 
                       ((is.list(loc$foto_lokasi_list[[1]]) && length(loc$foto_lokasi_list[[1]]) > 0) || 
                        (!is.list(loc$foto_lokasi_list[[1]]) && length(loc$foto_lokasi_list) > 0))) {
                      actionButton(paste0("view_photos_", loc$id_lokasi), "📸 Lihat Foto",
                                   class = "btn btn-sm btn-outline-info",
                                   style = "font-size: 0.8em; padding: 4px 8px;")
                    } else NULL
                ),
                div(style = "margin-bottom: 10px;",
                    strong("🎯 Isu Strategis: "), loc$isu_strategis
                ),
                div(class = "location-prodi",
                    strong("📚 Program Studi: "), 
                    {
                      prodi_list <- if(!is.null(loc$program_studi[[1]])) {
                        loc$program_studi[[1]]
                      } else character(0)
                      paste(prodi_list, collapse = ", ")
                    }
                ),
                div(class = "location-quota",
                    strong("👥 Kuota: "), paste(quota_status$total_quota, "mahasiswa"),
                    br(),
                    span(style = "font-size: 0.9em; color: #666;",
                         "Pending: ", quota_status$pending, " | ",
                         "Disetujui: ", quota_status$approved, " | ",
                         "Ditolak: ", quota_status$rejected)
                ),
                
                # Action section with quota status
                div(class = "quota-section", style = "margin-top: 15px;",
                    div(
                      span(class = quota_class, paste(quota_icon, quota_text))
                    ),
                    div(style = "margin-top: 10px;",
                        if (quota_status$available_quota > 0 && registration_open) {
                          actionButton(paste0("register_", i), "📝 Daftar Sekarang", 
                                       class = "register-btn",
                                       style = "width: 100%;",
                                       onclick = paste0("
                                             Shiny.setInputValue('selected_location_id', '", loc$id_lokasi, "', {priority: 'event'}); 
                                             Shiny.setInputValue('show_registration_modal', Math.random(), {priority: 'event'});
                                           "))
                        } else {
                          if (!registration_open) {
                            span("⏰ Periode pendaftaran tidak aktif", 
                                 class = "text-muted", 
                                 style = "font-style: italic; display: block; text-align: center; padding: 10px;")
                          } else {
                            span("❌ Kuota Penuh", 
                                 class = "text-danger", 
                                 style = "font-weight: bold; display: block; text-align: center; padding: 10px;")
                          }
                        }
                    )
                )
            )
        )
    )
  })
  
  return(do.call(tagList, location_cards))
  
  }, error = function(e) {
    # Handle UI rendering errors gracefully
    return(div(class = "alert alert-danger text-center",
               style = "margin-top: 50px; padding: 40px;",
               icon("exclamation-triangle", style = "font-size: 3em; margin-bottom: 15px;"),
               h4("Error menampilkan lokasi"),
               p(paste("Terjadi kesalahan:", e$message)),
               p("Silakan refresh halaman atau hubungi administrator.")))
  })
})

# ================================
# 7. REGISTRATION FUNCTIONALITY
# ================================

# Handle location selection and show registration modal
observeEvent(input$selected_location_id, {
  req(input$selected_location_id)
  
  lokasi <- values$lokasi_data[values$lokasi_data$id_lokasi == input$selected_location_id, ]
  if (nrow(lokasi) > 0) {
    values$selected_location <- lokasi[1, ]
    values$show_registration_modal <- TRUE
    # Safely extract program_studi choices - it's stored as list of character vectors
    prodi_choices <- if(!is.null(lokasi$program_studi[[1]])) {
      as.character(lokasi$program_studi[[1]])
    } else character(0)
    updateSelectInput(session, "reg_program_studi", choices = prodi_choices)
  }
}, ignoreInit = TRUE)

# Show/hide registration modal
output$show_registration_modal <- reactive({
  values$show_registration_modal
})
outputOptions(output, "show_registration_modal", suspendWhenHidden = FALSE)

# Registration modal trigger
observeEvent(input$show_registration_modal, {
  req(input$show_registration_modal)
  values$show_registration_modal <- TRUE
}, ignoreInit = TRUE)

# Registration form outputs (selected_location_info defined above)

# location_description and location_strategic_issues defined above

# Reset registration form function
reset_registration_form <- function() {
  updateTextInput(session, "reg_nim", value = "")
  updateTextInput(session, "reg_nama", value = "")
  updateSelectInput(session, "reg_program_studi", selected = character(0))
  updateTextInput(session, "reg_kontak", value = "")
# REMOVED: updateTextInput(session, "reg_usulan_dosen", value = "") - field no longer exists
# REMOVED: updateTextAreaInput(session, "reg_alasan", value = "") - replaced with Letter of Interest upload
  
  # Clear file inputs
  shinyjs::runjs("
        $('#reg_letter_of_interest').val('');
        $('#reg_cv_mahasiswa').val('');
        $('#reg_form_rekomendasi').val('');
        $('#reg_form_komitmen').val('');
        $('#reg_transkrip_nilai').val('');
        $('.form-control-file').each(function() {
          $(this).val('');
        });
        $('input[type=file]').each(function() {
          var label = $(this).siblings('label');
          if (label.length) {
            label.text(label.data('original-text') || 'Choose file');
          }
        });
      ")
}

# Close registration modal
observeEvent(input$close_registration_modal, {
  values$selected_location <- NULL
  values$show_registration_modal <- FALSE
  reset_registration_form()
  
  # FIXED: Clean modal close without affecting other modals
  shinyjs::runjs("
    // Only clean up if no other modals are open
    setTimeout(function() {
      if($('.modal.show').length === 0) {
        $('.modal-backdrop').remove();
        $('body').removeClass('modal-open');
        $('body').css('padding-right', '');
        $('body').css('overflow', '');
      }
    }, 100);
  ")
})

# Registration submission with queue system
observeEvent(input$submit_registration, {
  req(input$reg_nim, input$reg_nama, input$reg_program_studi, input$reg_kontak)
  
  # Generate unique queue ID for this registration
  queue_id <- generate_queue_id()
  queue_position <- length(values$registration_queue) + 1
  
  tryCatch({
    # Initial validation (without blocking other users)
    eligibility <- check_registration_eligibility(input$reg_nim, values$selected_location$nama_lokasi, 
                                                  values$pendaftaran_data, values$periode_data)
    
    if (!eligibility$eligible) {
      showModal(modalDialog(
        title = "❌ Tidak Dapat Mendaftar",
        div(class = "alert alert-danger", eligibility$reason),
        footer = modalButton("OK")
      ))
      return()
    }
    
    # Validate documents
    doc_validation <- validate_documents(list(
      reg_letter_of_interest = input$reg_letter_of_interest,
      reg_cv_mahasiswa = input$reg_cv_mahasiswa,
      reg_form_rekomendasi = input$reg_form_rekomendasi,
      reg_form_komitmen = input$reg_form_komitmen,
      reg_transkrip_nilai = input$reg_transkrip_nilai
    ))
    
    if (!doc_validation$valid) {
      # Check for file size error first
      if(!is.null(doc_validation$error)) {
        showModal(modalDialog(
          title = "📎 File Size Error",
          div(class = "alert alert-danger", doc_validation$error),
          footer = modalButton("OK")
        ))
        return()
      }
      
      missing_doc_names <- c(
        reg_letter_of_interest = "Letter of Interest",
        reg_cv_mahasiswa = "CV Mahasiswa",
        reg_form_rekomendasi = "Form Rekomendasi Program Studi", 
        reg_form_komitmen = "Form Komitmen Mahasiswa",
        reg_transkrip_nilai = "Transkrip Nilai"
      )
      
      showModal(modalDialog(
        title = "📎 Dokumen Tidak Lengkap",
        div(class = "alert alert-warning", 
            "Harap upload semua dokumen yang diperlukan:",
            tags$ul(
              lapply(doc_validation$missing, function(doc) {
                tags$li(missing_doc_names[doc])
              })
            )
        ),
        footer = modalButton("OK")
      ))
      return()
    }
    
    # Handle file uploads
    doc_paths <- list()
    upload_dir <- "www/documents"
    if (!dir.exists(upload_dir)) dir.create(upload_dir, recursive = TRUE)
    
    required_docs <- c("reg_letter_of_interest", "reg_cv_mahasiswa", "reg_form_rekomendasi", "reg_form_komitmen", "reg_transkrip_nilai")
    
    for (doc in required_docs) {
      if (!is.null(input[[doc]])) {
        file_ext <- tools::file_ext(input[[doc]]$name)
        new_filename <- paste0(gsub("reg_", "", doc), "_", input$reg_nama, "_", Sys.time() %>% as.numeric(), ".", file_ext)
        doc_path <- file.path(upload_dir, new_filename)
        file.copy(input[[doc]]$datapath, doc_path)
        doc_paths[[doc]] <- paste0("documents/", new_filename)
      }
    }
    
    # Create queue item with all necessary data
    queue_item <- list(
      queue_id = queue_id,
      reg_nim = input$reg_nim,
      reg_nama = input$reg_nama,
      reg_program_studi = input$reg_program_studi,
      reg_kontak = input$reg_kontak,
      location_name = values$selected_location$nama_lokasi,
      doc_paths = doc_paths,
      timestamp = Sys.time()
    )
    
    # Add to queue
    values$registration_queue <- append(values$registration_queue, list(queue_item))
    
    # Show queue notification
    if (queue_position == 1) {
      showNotification("⏳ Memproses pendaftaran Anda...", type = "message", duration = 3)
    } else {
      showNotification(paste("⏳ Pendaftaran dalam antrian, posisi:", queue_position), type = "message", duration = 3)
    }
    
    # Close modal and reset form
    values$show_registration_modal <- FALSE
    reset_registration_form()
    values$selected_location <- NULL
    
    # Start processing queue
    process_registration_queue()
    
  }, error = function(e) {
    showModal(modalDialog(
      title = "❌ Error",
      div(class = "alert alert-danger", paste("Terjadi kesalahan:", e$message)),
      footer = modalButton("OK")
    ))
  })
})

# Handle success modal closure
observeEvent(input$close_success_modal, {
  removeModal()
  values$selected_location <- NULL
  values$show_registration_modal <- FALSE
  reset_registration_form()
  
  shinyjs::runjs("
        $('.modal-backdrop').remove();
        $('body').removeClass('modal-open');
        $('body').css('padding-right', '');
        $('body').css('overflow', '');
      ")
})

# ================================
# 8. STUDENT STATUS CHECK MODULE
# ================================

# Update filter choices for students
observe({
  if(nrow(values$pendaftaran_data) > 0) {
    current_lokasis <- unique(values$pendaftaran_data$pilihan_lokasi)
    current_lokasis <- current_lokasis[!is.na(current_lokasis) & current_lokasis != ""]
  } else {
    current_lokasis <- character(0)
  }
  
  updateSelectInput(session, "search_lokasi", 
                    choices = c("Semua Lokasi" = "", current_lokasis))
})

# Search registration reactive - PRODUCTION VERSION
search_results <- reactive({
  # Only execute search if button was clicked
  if(input$search_registration == 0) {
    return(data.frame())
  }
  
  isolate({
    # Check if any search criteria is provided
    has_criteria <- (!is.null(input$search_nama) && nchar(trimws(input$search_nama)) > 0) ||
      (!is.null(input$search_nim) && nchar(trimws(input$search_nim)) > 0) ||
      (!is.null(input$search_tanggal) && !is.na(input$search_tanggal)) ||
      (!is.null(input$search_lokasi) && input$search_lokasi != "") ||
      (!is.null(input$search_status) && input$search_status != "")
    
    if(!has_criteria) {
      showNotification("Masukkan minimal satu kriteria pencarian", type = "warning")
      return(data.frame())
    }
    
    # Perform search
    tryCatch({
      results <- search_registrations(
        nama = if(!is.null(input$search_nama) && nchar(trimws(input$search_nama)) > 0) input$search_nama else NULL,
        nim = if(!is.null(input$search_nim) && nchar(trimws(input$search_nim)) > 0) input$search_nim else NULL,
        tanggal = input$search_tanggal,
        lokasi = if(!is.null(input$search_lokasi) && input$search_lokasi != "") input$search_lokasi else NULL,
        status = if(!is.null(input$search_status) && input$search_status != "") input$search_status else NULL,
        pendaftaran_data = values$pendaftaran_data
      )
      
      return(results)
      
    }, error = function(e) {
      showNotification(paste("Error dalam pencarian:", e$message), type = "error")
      return(data.frame())
    })
  })
})

# Display search results for students - SIMPLIFIED APPROACH
output$registration_results <- DT::renderDataTable({
  # Simple approach: if search button not clicked, show help
  if(input$search_registration == 0) {
    return(data.frame(
      "🔍" = "Gunakan form pencarian di sebelah kiri untuk mencari status pendaftaran Anda",
      "💡" = "Masukkan minimal nama atau kriteria lain, lalu klik 'Cari Status'",
      check.names = FALSE
    ))
  }
  
  # Get search results
  results <- search_results()
  
  # If no results, show message
  if(is.null(results) || nrow(results) == 0) {
    return(data.frame(
      "📝" = "Tidak ada data ditemukan dengan kriteria pencarian yang diberikan",
      "💡" = "Coba ubah kriteria pencarian atau periksa ejaan nama",
      check.names = FALSE
    ))
  }
  
  # We have results - create simple table
  simple_data <- data.frame(
    ID = results$id_pendaftaran,
    NIM = ifelse(is.na(results$nim_mahasiswa) | results$nim_mahasiswa == "", "(kosong)", results$nim_mahasiswa),
    Nama = results$nama_mahasiswa,
    Prodi = results$program_studi,
    Lokasi = results$pilihan_lokasi,
    Status = results$status_pendaftaran,
    Tanggal = tryCatch(format(as.POSIXct(results$timestamp), "%d-%m-%Y %H:%M"), error = function(e) as.character(results$timestamp))
  )
  
  return(DT::datatable(simple_data, 
                       options = list(pageLength = 10, searching = FALSE),
                       rownames = FALSE))
  
  # OLD COMPLEX CODE REMOVED - using simple approach above
  
  # REMOVED: This code block was moved above in the simplified version
  # REMOVED: All complex code replaced with simple version above
})

# ================================
# 9. ADMIN REGISTRATION MANAGEMENT
# ================================

# Update filter choices for admin
observe({
  current_lokasis <- unique(values$lokasi_data$nama_lokasi)
  updateSelectInput(session, "admin_filter_lokasi", 
                    choices = c("Semua Lokasi" = "", current_lokasis))
})

# Filter function for admin registrations
admin_filtered_registrations <- reactive({
  data <- values$pendaftaran_data
  
  if (!is.null(input$admin_filter_lokasi) && input$admin_filter_lokasi != "") {
    data <- data[data$pilihan_lokasi == input$admin_filter_lokasi, ]
  }
  
  if (!is.null(input$admin_filter_status) && input$admin_filter_status != "") {
    data <- data[data$status_pendaftaran == input$admin_filter_status, ]
  }
  
  if (!is.null(input$admin_filter_prodi) && input$admin_filter_prodi != "") {
    data <- data[data$program_studi == input$admin_filter_prodi, ]
  }
  
  return(data)
})

# Document completion statistics for admin
output$document_completion_stats <- renderUI({
  registrations <- admin_filtered_registrations()
  
  if(nrow(registrations) == 0) {
    return(div())
  }
  
  docs <- c("letter_of_interest_path", "cv_mahasiswa_path", "form_rekomendasi_prodi_path", 
            "form_komitmen_mahasiswa_path", "transkrip_nilai_path")
  
  # Calculate stats
  complete_docs <- sapply(1:nrow(registrations), function(i) {
    sum(!is.na(registrations[i, docs]) & registrations[i, docs] != "", na.rm = TRUE)
  })
  
  total_registrations <- nrow(registrations)
  complete_registrations <- sum(complete_docs == 5)
  partial_registrations <- sum(complete_docs > 0 & complete_docs < 5)
  empty_registrations <- sum(complete_docs == 0)
  
  # Status-based stats
  pending_count <- sum(registrations$status_pendaftaran == "Diajukan", na.rm = TRUE)
  approved_count <- sum(registrations$status_pendaftaran == "Disetujui", na.rm = TRUE)
  rejected_count <- sum(registrations$status_pendaftaran == "Ditolak", na.rm = TRUE)
  
  div(class = "row", style = "margin-bottom: 15px;",
      # Document completion stats
      div(class = "col-md-8",
          div(class = "alert alert-info", style = "margin-bottom: 10px;",
              h5("📄 Statistik Kelengkapan Dokumen", style = "margin-top: 0; color: #0c5460;"),
              div(class = "row",
                  div(class = "col-md-4 text-center",
                      h4(complete_registrations, style = "color: #28a745; margin-bottom: 5px;"),
                      tags$small("✓ Lengkap", style = "color: #28a745; font-weight: bold;")
                  ),
                  div(class = "col-md-4 text-center",
                      h4(partial_registrations, style = "color: #ffc107; margin-bottom: 5px;"),
                      tags$small("⚠ Parsial", style = "color: #ffc107; font-weight: bold;")
                  ),
                  div(class = "col-md-4 text-center",
                      h4(empty_registrations, style = "color: #dc3545; margin-bottom: 5px;"),
                      tags$small("❌ Kosong", style = "color: #dc3545; font-weight: bold;")
                  )
              )
          )
      ),
      # Status stats
      div(class = "col-md-4",
          div(class = "alert alert-warning", style = "margin-bottom: 10px;",
              h5("📊 Status Pendaftaran", style = "margin-top: 0; color: #856404;"),
              p(strong(pending_count), " Menunggu | ", 
                strong(approved_count), " Disetujui | ", 
                strong(rejected_count), " Ditolak",
                style = "margin-bottom: 0; text-align: center;")
          )
      )
  )
})

# Display registration table for admin
output$admin_registrations_table <- DT::renderDataTable({
  registrations <- admin_filtered_registrations()
  
  if (nrow(registrations) == 0) {
    return(data.frame(
      Message = "Tidak ada data pendaftar yang sesuai dengan filter"
    ))
  }
  
  display_data <- registrations
  display_data$timestamp <- tryCatch(format(as.POSIXct(display_data$timestamp), "%d-%m-%Y %H:%M"), error = function(e) as.character(display_data$timestamp))
  
  # Add document status column
  display_data$dokumen_status <- sapply(1:nrow(display_data), function(i) {
    row <- display_data[i, ]
    docs <- c("letter_of_interest_path", "cv_mahasiswa_path", "form_rekomendasi_prodi_path", 
              "form_komitmen_mahasiswa_path", "transkrip_nilai_path")
    
    completed <- sum(!is.na(row[docs]) & row[docs] != "", na.rm = TRUE)
    total <- length(docs)
    
    if(completed == total) {
      return(paste0("<span style='color: #28a745; font-weight: bold;'>✓ Lengkap (5/5)</span>"))
    } else if(completed > 0) {
      return(paste0("<span style='color: #ffc107; font-weight: bold;'>⚠ Parsial (", completed, "/5)</span>"))
    } else {
      return(paste0("<span style='color: #dc3545; font-weight: bold;'>❌ Kosong (0/5)</span>"))
    }
  })
  
  table_data <- display_data[, c("id_pendaftaran", "timestamp", "nim_mahasiswa", "nama_mahasiswa", 
                                 "program_studi", "pilihan_lokasi", "dokumen_status", "status_pendaftaran")]
  
  table_data$aksi <- sapply(1:nrow(table_data), function(i) {
    reg_id <- display_data$id_pendaftaran[i]
    status <- display_data$status_pendaftaran[i]
    
    buttons <- paste0('<button class="btn btn-sm btn-info" onclick="Shiny.setInputValue(\'view_registration_detail\', ', reg_id, ')">📄 Detail</button>')
    
    if (status == "Diajukan") {
      buttons <- paste0(buttons, 
                        ' <button class="btn btn-sm btn-success" onclick="Shiny.setInputValue(\'approve_registration_id\', ', reg_id, ')">✅ Setujui</button>',
                        ' <button class="btn btn-sm btn-danger" onclick="Shiny.setInputValue(\'reject_registration_id\', ', reg_id, ')">❌ Tolak</button>')
    }
    
    return(buttons)
  })
  
  DT::datatable(table_data,
                escape = FALSE,  # Enable HTML rendering
                options = list(
                  pageLength = 10, 
                  searching = TRUE,
                  scrollX = TRUE,
                  columnDefs = list(
                    list(orderable = FALSE, targets = ncol(table_data) - 1),  # Actions column
                    list(orderable = FALSE, targets = ncol(table_data) - 2)   # Document status column
                  ),
                  language = list(
                    emptyTable = "Tidak ada data pendaftar",
                    info = "Menampilkan _START_ sampai _END_ dari _TOTAL_ pendaftar",
                    search = "Cari:",
                    lengthMenu = "Tampilkan _MENU_ data per halaman"
                  )
                ),
                colnames = c("ID", "📅 Tanggal", "🆔 NIM", "👤 Nama", "🎓 Prodi", "📍 Lokasi", "📄 Dokumen", "📊 Status", "🔧 Aksi"),
                selection = "none",
                rownames = FALSE) %>%
    DT::formatStyle("status_pendaftaran",
                    backgroundColor = DT::styleEqual(
                      c("Diajukan", "Disetujui", "Ditolak"),
                      c("#fff3cd", "#d4edda", "#f8d7da")
                    ),
                    fontWeight = "bold"
    )
})

# Admin refresh action
observeEvent(input$admin_refresh, {
  showNotification("Data berhasil direfresh!", type = "message")
})

# View registration detail
observeEvent(input$view_registration_detail, {
  req(input$view_registration_detail)
  
  tryCatch({
    shinyjs::runjs("
          // FIXED: Removed global modal hide to preserve admin login modal
          $('.modal-backdrop').remove();
          $('body').removeClass('modal-open');
          $('body').css('padding-right', '');
          $('body').css('overflow', '');
        ")
    
    reg_id <- input$view_registration_detail
    registration <- values$pendaftaran_data[values$pendaftaran_data$id_pendaftaran == reg_id, ]
    
    if (nrow(registration) > 0) {
      reg <- registration[1, ]
      
      safe_field <- function(field_name, default = "Tidak ada data") {
        if (field_name %in% names(reg) && !is.na(reg[[field_name]]) && reg[[field_name]] != "") {
          return(as.character(reg[[field_name]]))
        } else {
          return(default)
        }
      }
      
      # Helper function to create document action buttons
      create_doc_buttons <- function(path_field, doc_name) {
        if(safe_field(path_field) != "Tidak ada data") {
          tagList(
            div(style = "margin-bottom: 5px;",
                span("✓ File tersedia", style = "color: #28a745; font-size: 0.85em; font-weight: bold;")
            ),
            div(
              tags$a(href = safe_field(path_field), target = "_blank", 
                     class = "btn btn-sm btn-primary", 
                     style = "margin-right: 5px;",
                     "👁️ Lihat"),
              tags$a(href = safe_field(path_field), download = "",
                     class = "btn btn-sm btn-success", 
                     "💾 Download")
            )
          )
        } else {
          div(
            div(style = "margin-bottom: 5px;",
                span("❌ File tidak tersedia", style = "color: #dc3545; font-size: 0.85em; font-weight: bold;")
            ),
            span(paste0("Mahasiswa belum mengupload ", doc_name), style = "color: #6c757d; font-size: 0.8em;")
          )
        }
      }
      
      Sys.sleep(0.1)
      
      showModal(modalDialog(
        title = paste("📋 Detail Pendaftaran ID:", reg_id),
        size = "l",
        easyClose = TRUE,
        
        div(style = "max-height: 70vh; overflow-y: auto;",
            wellPanel(
              h4("👤 Informasi Pribadi", style = "color: #495057; margin-bottom: 15px;"),
              fluidRow(
                column(6,
                       p(strong("NIM: "), safe_field("nim_mahasiswa")),
                       p(strong("Nama: "), safe_field("nama_mahasiswa")),
                       p(strong("Program Studi: "), safe_field("program_studi")),
                       p(strong("Kontak: "), safe_field("kontak"))
                ),
                column(6,
                       p(strong("Tanggal Daftar: "), 
                         if("timestamp" %in% names(reg)) {
                           tryCatch(format(as.POSIXct(reg$timestamp), "%d-%m-%Y %H:%M"), error = function(e) as.character(reg$timestamp)) 
                         } else { 
                           "Tidak ada data" 
                         }),
                       p(strong("Pilihan Lokasi: "), safe_field("pilihan_lokasi")),
                       p(strong("Status: "), 
                         span(safe_field("status_pendaftaran"), 
                              style = paste0("padding: 4px 8px; border-radius: 4px; color: white; background-color: ", 
                                             switch(safe_field("status_pendaftaran", ""),
                                                    "Disetujui" = "#28a745",
                                                    "Ditolak" = "#dc3545", 
                                                    "#ffc107"))))
                )
              )
            ),
            
            wellPanel(
              h4("📍 Informasi Lokasi", style = "color: #1976d2; margin-bottom: 15px;"),
              div(style = "background: #e3f2fd; padding: 12px; border-radius: 8px;",
                  p(strong("Lokasi Pilihan: "), 
                    span(safe_field("pilihan_lokasi"), style = "font-size: 1.1em; color: #1976d2; font-weight: bold;"))
              )
            ),
            
            wellPanel(
              h4("📄 Dokumen Pendaftaran", style = "color: #6f42c1; margin-bottom: 15px;"),
              div(style = "background: #f8f9fa; padding: 15px; border-radius: 8px;",
                  # Document summary
                  div(style = "text-align: center; margin-bottom: 15px; padding: 10px; background: white; border-radius: 8px;",
                      h5("Status Kelengkapan Dokumen", style = "margin-bottom: 10px; color: #495057;"),
                      {
                        docs <- c("letter_of_interest_path", "cv_mahasiswa_path", "form_rekomendasi_prodi_path", 
                                  "form_komitmen_mahasiswa_path", "transkrip_nilai_path")
                        completed <- sum(!is.na(reg[docs]) & reg[docs] != "", na.rm = TRUE)
                        total <- length(docs)
                        percentage <- round((completed/total) * 100)
                        
                        if(completed == total) {
                          div(style = "color: #28a745; font-size: 1.2em;",
                              icon("check-circle"), " Semua dokumen lengkap (", completed, "/", total, " - ", percentage, "%)")
                        } else {
                          div(style = paste0("color: ", if(completed > 0) "#ffc107" else "#dc3545", "; font-size: 1.1em;"),
                              icon(if(completed > 0) "exclamation-triangle" else "times-circle"), 
                              " Dokumen ", if(completed > 0) "belum lengkap" else "kosong", 
                              " (", completed, "/", total, " - ", percentage, "%)")
                        }
                      }
                  ),
                  fluidRow(
                    column(12,
                           # Letter of Interest
                           div(style = "margin-bottom: 12px; padding: 10px; background: white; border-radius: 6px; border-left: 4px solid #007bff;",
                               div(style = "display: flex; justify-content: space-between; align-items: center;",
                                   div(
                                     strong("📝 Letter of Interest:"),
                                     br(),
                                     span(style = "font-size: 0.9em; color: #666;", "Surat minat mengikuti program")
                                   ),
                                   create_doc_buttons("letter_of_interest_path", "Letter of Interest")
                               )
                           ),
                           
                           # CV Mahasiswa
                           div(style = "margin-bottom: 12px; padding: 10px; background: white; border-radius: 6px; border-left: 4px solid #28a745;",
                               div(style = "display: flex; justify-content: space-between; align-items: center;",
                                   div(
                                     strong("👤 CV Mahasiswa:"),
                                     br(),
                                     span(style = "font-size: 0.9em; color: #666;", "Riwayat hidup mahasiswa")
                                   ),
                                   create_doc_buttons("cv_mahasiswa_path", "CV Mahasiswa")
                               )
                           ),
                           
                           # Form Rekomendasi
                           div(style = "margin-bottom: 12px; padding: 10px; background: white; border-radius: 6px; border-left: 4px solid #ffc107;",
                               div(style = "display: flex; justify-content: space-between; align-items: center;",
                                   div(
                                     strong("📋 Form Rekomendasi:"),
                                     br(),
                                     span(style = "font-size: 0.9em; color: #666;", "Rekomendasi mengikuti Labsos")
                                   ),
                                   create_doc_buttons("form_rekomendasi_prodi_path", "Form Rekomendasi")
                               )
                           ),
                           
                           # Form Komitmen
                           div(style = "margin-bottom: 12px; padding: 10px; background: white; border-radius: 6px; border-left: 4px solid #e83e8c;",
                               div(style = "display: flex; justify-content: space-between; align-items: center;",
                                   div(
                                     strong("📜 Surat Komitmen:"),
                                     br(),
                                     span(style = "font-size: 0.9em; color: #666;", "Komitmen mahasiswa mengikuti Labsos")
                                   ),
                                   create_doc_buttons("form_komitmen_mahasiswa_path", "Surat Komitmen")
                               )
                           ),
                           
                           # Transkrip Nilai
                           div(style = "margin-bottom: 0; padding: 10px; background: white; border-radius: 6px; border-left: 4px solid #17a2b8;",
                               div(style = "display: flex; justify-content: space-between; align-items: center;",
                                   div(
                                     strong("🎓 Transkrip Nilai:"),
                                     br(),
                                     span(style = "font-size: 0.9em; color: #666;", "Transkrip nilai akademik")
                                   ),
                                   create_doc_buttons("transkrip_nilai_path", "Transkrip Nilai")
                               )
                           )
                    )
                  )
              )
            ),
            
            if (safe_field("status_pendaftaran") == "Ditolak" && safe_field("alasan_penolakan") != "Tidak ada data") {
              wellPanel(style = "background-color: #f8d7da; border-color: #f5c6cb;",
                        h4("❌ Alasan Penolakan", style = "color: #721c24; margin-bottom: 15px;"),
                        p(safe_field("alasan_penolakan"), style = "color: #721c24; font-weight: bold; margin: 0;")
              )
            }
        ),
        
        footer = tagList(
          if (safe_field("status_pendaftaran") == "Diajukan") {
            tagList(
              actionButton("approve_from_detail", "✅ Setujui", 
                           class = "btn btn-success",
                           onclick = paste0("Shiny.setInputValue('approve_registration_id', ", reg_id, ");")),
              actionButton("reject_from_detail", "❌ Tolak", 
                           class = "btn btn-danger",
                           onclick = paste0("Shiny.setInputValue('reject_registration_id', ", reg_id, ");")),
              actionButton("close_detail_modal", "Tutup", class = "btn btn-secondary")
            )
          } else {
            actionButton("close_detail_modal", "Tutup", class = "btn btn-secondary")
          }
        )
      ))
    }
  }, error = function(e) {
    showNotification(paste("Error:", e$message), type = "error")
  })
})

# Handle detail modal closure
observeEvent(input$close_detail_modal, {
  removeModal()
  shinyjs::runjs("
        $('.modal-backdrop').remove();
        $('body').removeClass('modal-open');
        $('body').css('padding-right', '');
        $('body').css('overflow', '');
      ")
})

# Approve registration
observeEvent(input$approve_registration_id, {
  req(input$approve_registration_id)
  
  tryCatch({
    shinyjs::runjs("
          // FIXED: Removed global modal hide to preserve admin login modal
          $('.modal-backdrop').remove();
          $('body').removeClass('modal-open');
          $('body').css('padding-right', '');
          $('body').css('overflow', '');
        ")
    
    reg_id <- input$approve_registration_id
    
    # Get student name before update for display
    row_idx <- which(values$pendaftaran_data$id_pendaftaran == reg_id)
    if(length(row_idx) == 0) {
      showNotification("❌ Pendaftaran tidak ditemukan", type = "error")
      return()
    }
    
    student_name <- values$pendaftaran_data[row_idx, "nama_mahasiswa"]
    
    # Use atomic update function
    update_pendaftaran_status_mongo(reg_id, "Disetujui", "")
    
    # Refresh data to reflect changes
    tryCatch({
      values$pendaftaran_data <- refresh_pendaftaran_data()
    }, error = function(e) {
      showNotification("❌ Gagal memuat data terbaru. Silakan refresh halaman.", type = "warning", duration = 5)
    })
      
      Sys.sleep(0.1)
      
      showModal(modalDialog(
        title = "✅ Pendaftaran Disetujui",
        div(style = "text-align: center; padding: 20px;",
            h4(paste("Pendaftaran", student_name, "telah disetujui!"), style = "color: #28a745;"),
            p("Mahasiswa akan dihubungi untuk langkah selanjutnya.")
        ),
        footer = actionButton("close_approve_modal", "OK", class = "btn btn-success"),
        easyClose = TRUE
      ))
    
  }, error = function(e) {
    showNotification(paste("❌ Gagal menyetujui pendaftaran. Silakan coba lagi:", e$message), type = "error", duration = 8)
    removeModal()
  })
})

# Handle approve modal closure
observeEvent(input$close_approve_modal, {
  removeModal()
  shinyjs::runjs("
        $('.modal-backdrop').remove();
        $('body').removeClass('modal-open');
        $('body').css('padding-right', '');
        $('body').css('overflow', '');
      ")
})

# Reject registration
observeEvent(input$reject_registration_id, {
  req(input$reject_registration_id)
  
  shinyjs::runjs("
        // FIXED: Removed global modal hide to preserve admin login modal
        $('.modal-backdrop').remove();
        $('body').removeClass('modal-open');
        $('body').css('padding-right', '');
        $('body').css('overflow', '');
      ")
  
  reg_id <- input$reject_registration_id
  
  Sys.sleep(0.1)
  
  showModal(modalDialog(
    title = "❌ Tolak Pendaftaran",
    easyClose = TRUE,
    div(
      h4(paste("Tolak pendaftaran ID:", reg_id)),
      p("Silakan berikan alasan penolakan yang jelas:"),
      textAreaInput("rejection_reason", "Alasan Penolakan:", 
                    placeholder = "Masukkan alasan penolakan yang jelas dan konstruktif...", 
                    rows = 4, width = "100%"),
      div(class = "alert alert-info", style = "margin-top: 10px;",
          "💡 Tips: Berikan alasan yang spesifik dan konstruktif agar mahasiswa dapat memperbaiki untuk pendaftaran selanjutnya."
      )
    ),
    footer = tagList(
      actionButton("confirm_reject", "❌ Tolak", class = "btn btn-danger"),
      actionButton("cancel_reject", "Batal", class = "btn btn-secondary")
    )
  ))
})

# Handle reject modal cancellation
observeEvent(input$cancel_reject, {
  removeModal()
  shinyjs::runjs("
        $('.modal-backdrop').remove();
        $('body').removeClass('modal-open');
        $('body').css('padding-right', '');
        $('body').css('overflow', '');
      ")
})

# Confirm rejection
observeEvent(input$confirm_reject, {
  req(input$reject_registration_id, input$rejection_reason)
  
  if (input$rejection_reason == "") {
    showNotification("Alasan penolakan harus diisi!", type = "error")
    return()
  }
  
  tryCatch({
    reg_id <- input$reject_registration_id
    
    # Get student name before update for display
    row_idx <- which(values$pendaftaran_data$id_pendaftaran == reg_id)
    if(length(row_idx) == 0) {
      showNotification("❌ Pendaftaran tidak ditemukan", type = "error")
      return()
    }
    
    student_name <- values$pendaftaran_data[row_idx, "nama_mahasiswa"]
    
    # Use atomic update function
    update_pendaftaran_status_mongo(reg_id, "Ditolak", input$rejection_reason)
    
    # Refresh data to reflect changes
    tryCatch({
      values$pendaftaran_data <- refresh_pendaftaran_data()
    }, error = function(e) {
      showNotification("❌ Gagal memuat data terbaru. Silakan refresh halaman.", type = "warning", duration = 5)
    })
    
    removeModal()
    
    Sys.sleep(0.1)
    
    showModal(modalDialog(
      title = "❌ Pendaftaran Ditolak",
      div(style = "text-align: center; padding: 20px;",
          h4(paste("Pendaftaran", student_name, "telah ditolak."), style = "color: #dc3545;"),
          p("Mahasiswa dapat mendaftar kembali setelah memperbaiki dokumen/persyaratan.")
      ),
      footer = actionButton("close_reject_modal", "OK", class = "btn btn-secondary"),
      easyClose = TRUE
    ))
    
  }, error = function(e) {
    showNotification(paste("❌ Gagal menolak pendaftaran. Silakan coba lagi:", e$message), type = "error", duration = 8)
    removeModal()
  })
})

# Handle reject success modal closure
observeEvent(input$close_reject_modal, {
  removeModal()
  shinyjs::runjs("
        $('.modal-backdrop').remove();
        $('body').removeClass('modal-open');
        $('body').css('padding-right', '');
        $('body').css('overflow', '');
      ")
})



# ================================
# 10. SESSION CLEANUP
# ================================

session$onSessionEnded(function() {
  session$userData$selected_kategori_id <- NULL
  session$userData$selected_periode_id <- NULL
  session$userData$selected_lokasi_id <- NULL
})

}
