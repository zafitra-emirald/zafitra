# server.R - Labsos Information System Server Logic (Simplified Master Data)

server <- function(input, output, session) {
  
  # ================================
  # 1. REACTIVE VALUES INITIALIZATION
  # ================================
  
  values <- reactiveValues(
    admin_logged_in = FALSE,
    login_error = FALSE,
    kategori_data = kategori_data,
    periode_data = periode_data,
    lokasi_data = lokasi_data
  )
  
  # ================================
  # 2. ADMIN AUTHENTICATION MODULE
  # ================================
  
  # Admin login status output
  output$is_admin_logged_in <- reactive({
    values$admin_logged_in
  })
  outputOptions(output, "is_admin_logged_in", suspendWhenHidden = FALSE)
  
  # Admin login process
  observeEvent(input$do_admin_login, {
    if (validate_admin(input$admin_username, input$admin_password)) {
      values$admin_logged_in <- TRUE
      values$login_error <- FALSE
      updateTabItems(session, "admin_menu", "admin_dashboard")
      showNotification("Login berhasil! Selamat datang, Admin.", type = "message")
    } else {
      values$login_error <- TRUE
    }
  })
  
  # Cancel/Close login modal
  observeEvent(input$cancel_admin_login, {
    values$login_error <- FALSE
    shinyjs::runjs("$('.modal').modal('hide'); $('.modal-backdrop').remove(); $('body').removeClass('modal-open');")
  })
  
  observeEvent(input$close_admin_login, {
    values$login_error <- FALSE
    shinyjs::runjs("$('.modal').modal('hide'); $('.modal-backdrop').remove(); $('body').removeClass('modal-open');")
  })
  
  # Admin logout
  observeEvent(input$admin_logout_btn, {
    values$admin_logged_in <- FALSE
    values$login_error <- FALSE
    # Reset any selected items
    session$userData$selected_kategori_id <- NULL
    session$userData$selected_periode_id <- NULL
    session$userData$selected_lokasi_id <- NULL
    # Redirect to homepage
    shinyjs::runjs("$('.modal').modal('hide'); $('.modal-backdrop').remove(); $('body').removeClass('modal-open');")
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
  # 3. ADMIN DASHBOARD MODULE
  # ================================
  
  # Dashboard value boxes
  output$total_locations <- renderValueBox({
    valueBox(
      value = nrow(values$lokasi_data),
      subtitle = "Total Lokasi",
      icon = icon("map-marker-alt"),
      color = "blue"
    )
  })
  
  output$total_categories <- renderValueBox({
    valueBox(
      value = nrow(values$kategori_data),
      subtitle = "Total Kategori",
      icon = icon("tags"),
      color = "green"
    )
  })
  
  output$active_periods <- renderValueBox({
    active <- sum(values$periode_data$status == "Aktif")
    valueBox(
      value = active,
      subtitle = "Periode Aktif",
      icon = icon("calendar"),
      color = "yellow"
    )
  })
  
  # ================================
  # 4. MASTER DATA - KATEGORI MODULE
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
        new_id <- max(values$kategori_data$id_kategori) + 1
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
        save_kategori_data(values$kategori_data)
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
          save_kategori_data(values$kategori_data)
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
      save_kategori_data(values$kategori_data)
      
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
  # 5. MASTER DATA - PERIODE MODULE
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
            !(if(!is.null(session$userData$selected_periode_id)) 
              values$periode_data$id_periode == session$userData$selected_periode_id else FALSE), ]
        
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
        save_periode_data(values$periode_data)
        showNotification("Periode baru berhasil ditambahkan!", type = "message")
      } else {
        # EDIT EXISTING PERIODE
        row_idx <- which(values$periode_data$id_periode == session$userData$selected_periode_id)
        if(length(row_idx) > 0) {
          values$periode_data[row_idx, "nama_periode"] <- input$periode_nama
          values$periode_data[row_idx, "waktu_mulai"] <- input$periode_mulai
          values$periode_data[row_idx, "waktu_selesai"] <- input$periode_selesai
          values$periode_data[row_idx, "status"] <- input$periode_status
          save_periode_data(values$periode_data)
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
      save_periode_data(values$periode_data)
      
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
  # 6. MASTER DATA - LOKASI MODULE
  # ================================
  
  # Update kategori choices when kategori data changes
  observe({
    updateSelectInput(session, "lokasi_kategori", choices = values$kategori_data$nama_kategori)
  })
  
  # Lokasi table display
  output$lokasi_table <- DT::renderDataTable({
    display_lokasi <- values$lokasi_data[, c("id_lokasi", "nama_lokasi", "kategori_lokasi", "kuota_mahasiswa")]
    
    DT::datatable(display_lokasi,
                  options = list(
                    pageLength = 10, 
                    dom = 'tip',
                    language = list(
                      emptyTable = "Tidak ada data lokasi",
                      info = "Menampilkan _START_ sampai _END_ dari _TOTAL_ lokasi"
                    )
                  ),
                  colnames = c("ID", "Nama Lokasi", "Kategori", "Kuota"),
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
      updateSelectInput(session, "lokasi_kategori", selected = lokasi$kategori_lokasi)
      updateTextAreaInput(session, "lokasi_isu", value = lokasi$isu_strategis)
      updateTextInput(session, "lokasi_foto", value = lokasi$foto_lokasi)
      updateSelectInput(session, "lokasi_prodi", selected = lokasi$program_studi[[1]])
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
      if (is.null(session$userData$selected_lokasi_id)) {
        # ADD NEW LOKASI
        new_id <- max(values$lokasi_data$id_lokasi) + 1
        new_lokasi <- data.frame(
          id_lokasi = new_id,
          nama_lokasi = input$lokasi_nama,
          deskripsi_lokasi = ifelse(is.null(input$lokasi_deskripsi) || input$lokasi_deskripsi == "", 
                                    "Tidak ada deskripsi", input$lokasi_deskripsi),
          kategori_lokasi = input$lokasi_kategori,
          isu_strategis = ifelse(is.null(input$lokasi_isu) || input$lokasi_isu == "", 
                                 "Tidak ada isu strategis", input$lokasi_isu),
          kuota_mahasiswa = ifelse(is.null(input$lokasi_kuota) || input$lokasi_kuota == 0, 5, input$lokasi_kuota),
          foto_lokasi = ifelse(is.null(input$lokasi_foto) || input$lokasi_foto == "", 
                               "https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400&h=250&fit=crop", 
                               input$lokasi_foto),
          timestamp = Sys.time(),
          stringsAsFactors = FALSE
        )
        
        # Add program studi
        selected_prodi <- input$lokasi_prodi
        if (is.null(selected_prodi) || length(selected_prodi) == 0) {
          selected_prodi <- c("Informatika") # Default
        }
        new_lokasi$program_studi <- list(selected_prodi)
        
        values$lokasi_data <- rbind(values$lokasi_data, new_lokasi)
        save_lokasi_data(values$lokasi_data)
        showNotification("Lokasi baru berhasil ditambahkan!", type = "message")
        
      } else {
        # EDIT EXISTING LOKASI
        row_idx <- which(values$lokasi_data$id_lokasi == session$userData$selected_lokasi_id)
        if(length(row_idx) > 0) {
          values$lokasi_data[row_idx, "nama_lokasi"] <- input$lokasi_nama
          values$lokasi_data[row_idx, "deskripsi_lokasi"] <- ifelse(is.null(input$lokasi_deskripsi) || input$lokasi_deskripsi == "", 
                                                                    "Tidak ada deskripsi", input$lokasi_deskripsi)
          values$lokasi_data[row_idx, "kategori_lokasi"] <- input$lokasi_kategori
          values$lokasi_data[row_idx, "isu_strategis"] <- ifelse(is.null(input$lokasi_isu) || input$lokasi_isu == "", 
                                                                 "Tidak ada isu strategis", input$lokasi_isu)
          values$lokasi_data[row_idx, "foto_lokasi"] <- ifelse(is.null(input$lokasi_foto) || input$lokasi_foto == "", 
                                                               values$lokasi_data[row_idx, "foto_lokasi"], 
                                                               input$lokasi_foto)
          values$lokasi_data[row_idx, "kuota_mahasiswa"] <- ifelse(is.null(input$lokasi_kuota) || input$lokasi_kuota == 0, 5, input$lokasi_kuota)
          
          # Update program studi
          selected_prodi <- input$lokasi_prodi
          if (is.null(selected_prodi) || length(selected_prodi) == 0) {
            selected_prodi <- values$lokasi_data[row_idx, "program_studi"][[1]]
          }
          values$lokasi_data[row_idx, "program_studi"] <- list(selected_prodi)
          
          save_lokasi_data(values$lokasi_data)
          showNotification("Lokasi berhasil diperbarui!", type = "message")
        }
      }
      
      # Reset form
      session$userData$selected_lokasi_id <- NULL
      updateTextInput(session, "lokasi_nama", value = "")
      updateTextAreaInput(session, "lokasi_deskripsi", value = "")
      updateSelectInput(session, "lokasi_kategori", selected = character(0))
      updateTextAreaInput(session, "lokasi_isu", value = "")
      updateTextInput(session, "lokasi_foto", value = "")
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
      save_lokasi_data(values$lokasi_data)
      
      showNotification(paste("Lokasi '", lokasi_name, "' berhasil dihapus!"), type = "message")
      removeModal()
    }
  })
  
  # Reset lokasi form
  observeEvent(input$reset_lokasi, {
    session$userData$selected_lokasi_id <- NULL
    updateTextInput(session, "lokasi_nama", value = "")
    updateTextAreaInput(session, "lokasi_deskripsi", value = "")
    updateSelectInput(session, "lokasi_kategori", selected = character(0))
    updateTextAreaInput(session, "lokasi_isu", value = "")
    updateTextInput(session, "lokasi_foto", value = "")
    updateSelectInput(session, "lokasi_prodi", selected = character(0))
    updateNumericInput(session, "lokasi_kuota", value = 5)
    showNotification("Form lokasi direset", type = "message")
  })
  
  # ================================
  # 7. STUDENT INTERFACE MODULE
  # ================================
  
  # Quick stats for students
  output$total_locations_student <- renderText({
    nrow(values$lokasi_data)
  })
  
  output$active_period_student <- renderText({
    if(is_registration_open(values$periode_data)) "AKTIF" else "TUTUP"
  })
  
  # Check if there are locations to display
  output$has_locations <- reactive({
    nrow(values$lokasi_data) > 0
  })
  outputOptions(output, "has_locations", suspendWhenHidden = FALSE)
  
  # Enhanced locations display for students
  output$locations_grid <- renderUI({
    locations <- values$lokasi_data
    
    if (nrow(locations) == 0) {
      return(div(class = "alert alert-info text-center",
                 style = "margin-top: 50px; padding: 40px;",
                 icon("info-circle", style = "font-size: 3em; margin-bottom: 15px;"),
                 h4("Belum ada lokasi tersedia"),
                 p("Admin belum menambahkan lokasi. Silakan cek kembali nanti.")))
    }
    
    registration_open <- is_registration_open(values$periode_data)
    
    location_cards <- lapply(1:nrow(locations), function(i) {
      loc <- locations[i, ]
      
      # Create enhanced card
      div(class = "location-card", style = "margin-bottom: 20px;",
          img(src = loc$foto_lokasi, class = "location-image", alt = loc$nama_lokasi),
          
          div(class = "location-content",
              div(class = "location-title", loc$nama_lokasi),
              span(class = "location-category", loc$kategori_lokasi),
              
              div(class = "location-description", loc$deskripsi_lokasi),
              
              div(class = "location-details",
                  div(style = "margin-bottom: 10px;",
                      strong("🎯 Isu Strategis: "), loc$isu_strategis
                  ),
                  div(class = "location-prodi",
                      strong("📚 Program Studi: "), 
                      paste(loc$program_studi[[1]], collapse = ", ")
                  ),
                  div(class = "location-quota",
                      strong("👥 Kuota: "), paste(loc$kuota_mahasiswa, "mahasiswa")
                  ),
                  
                  # Action section
                  div(class = "quota-section", style = "margin-top: 15px;",
                      if (registration_open) {
                        actionButton(paste0("register_", i), "📝 Daftar Sekarang", 
                                     class = "register-btn",
                                     style = "width: 100%;")
                      } else {
                        span("⏰ Periode pendaftaran tidak aktif", 
                             class = "text-muted", 
                             style = "font-style: italic; display: block; text-align: center; padding: 10px;")
                      }
                  )
              )
          )
      )
    })
    
    return(do.call(tagList, location_cards))
  })
  
  # ================================
  # 8. HELPER OBSERVERS & OUTPUTS
  # ================================
  
  # Update filter choices dynamically
  observe({
    # Update kategori filter choices for student interface
    current_kategoris <- unique(values$kategori_data$nama_kategori)
    if(exists("input") && !is.null(input$filter_kategori)) {
      updateSelectInput(session, "filter_kategori", 
                        choices = c("Semua Kategori" = "", current_kategoris))
    }
  })
  
  # Session cleanup
  session$onSessionEnded(function() {
    message("Session ended, cleaning up resources...")
    
    # Clear any temporary session data
    session$userData$selected_kategori_id <- NULL
    session$userData$selected_periode_id <- NULL
    session$userData$selected_lokasi_id <- NULL
  })
  
} # End of server function