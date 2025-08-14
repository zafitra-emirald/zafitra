# ui.R - Labsos Information System User Interface (Fixed Version)

# Define custom CSS
custom_css <- "
.content-wrapper, .right-side {
  background-color: #f8f9fa;
}

/* Enhanced location cards */
.location-card {
  background: white;
  border-radius: 12px;
  padding: 0;
  margin: 15px 0;
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  overflow: hidden;
}

.location-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0,0,0,0.15);
}

.location-image {
  width: 100%;
  height: 200px;
  object-fit: cover;
  border-radius: 12px 12px 0 0;
}

.location-content {
  padding: 20px;
}

.location-title {
  font-size: 1.4em;
  font-weight: bold;
  color: #2c3e50;
  margin-bottom: 10px;
}

.location-category {
  background: #e3f2fd;
  color: #1976d2;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.85em;
  display: inline-block;
  margin-bottom: 15px;
}

.location-description {
  color: #555;
  line-height: 1.6;
  margin-bottom: 15px;
}

.location-details {
  border-top: 1px solid #eee;
  padding-top: 15px;
}

.location-prodi, .location-quota {
  background: #f8f9fa;
  padding: 8px 12px;
  border-radius: 6px;
  margin: 8px 0;
  font-size: 0.9em;
}

.quota-section {
  margin-top: 15px;
  padding: 15px;
  background: #f8f9fa;
  border-radius: 8px;
}

.register-btn {
  background: linear-gradient(135deg, #28a745, #20c997);
  border: none;
  padding: 12px 24px;
  border-radius: 25px;
  color: white;
  font-weight: bold;
  transition: all 0.2s ease;
}

.register-btn:hover {
  background: linear-gradient(135deg, #218838, #1ba085);
  transform: translateY(-1px);
}

.register-btn:disabled {
  background: #6c757d;
  cursor: not-allowed;
}

/* Quota status styling */
.quota-available { color: #28a745; font-weight: bold; }
.quota-limited { color: #ffc107; font-weight: bold; }
.quota-full { color: #dc3545; font-weight: bold; }

/* Welcome section */
.welcome-section {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 30px;
  border-radius: 12px;
  margin-bottom: 25px;
  text-align: center;
}

.welcome-title {
  font-size: 2em;
  font-weight: bold;
  margin-bottom: 10px;
}

.welcome-subtitle {
  font-size: 1.1em;
  opacity: 0.9;
}

/* Quick stats */
.quick-stats {
  display: flex;
  justify-content: space-around;
  background: white;
  padding: 20px;
  border-radius: 12px;
  margin-bottom: 20px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
}

.stat-item {
  text-align: center;
}

.stat-number {
  font-size: 2em;
  font-weight: bold;
  color: #007bff;
}

.stat-label {
  color: #6c757d;
  font-size: 0.9em;
}

/* Navigation improvements */
.main-header .navbar {
  background: linear-gradient(135deg, #007bff, #0056b3) !important;
}

.sidebar-menu > li.active > a {
  background-color: #007bff !important;
}

/* Responsive adjustments */
@media (max-width: 768px) {
  .location-card {
    margin: 10px 0;
  }
  
  .quota-section {
    flex-direction: column;
    gap: 10px;
  }
  
  .quick-stats {
    flex-direction: column;
    gap: 15px;
  }
}
"

ui <- dashboardPage(
  # Header
  dashboardHeader(
    title = "Sistem Informasi Labsos",
    tags$li(
      class = "dropdown",
      style = "margin: 8px;",
      conditionalPanel(
        condition = "!output.is_admin_logged_in",
        actionButton("admin_login_btn", "Admin Login", 
                     class = "btn btn-warning btn-sm")
      )
    ),
    tags$li(
      class = "dropdown", 
      style = "margin: 8px;",
      conditionalPanel(
        condition = "output.is_admin_logged_in",
        span("Admin Panel", class = "navbar-text text-white"),
        actionButton("admin_logout_btn", "Logout", 
                     class = "btn btn-danger btn-sm", style = "margin-left: 10px;")
      )
    )
  ),
  
  # Sidebar
  dashboardSidebar(
    useShinyjs(),
    tags$head(tags$style(HTML(custom_css))),
    
    conditionalPanel(
      condition = "!output.is_admin_logged_in",
      sidebarMenu(
        id = "student_menu",
        menuItem("🏠 Beranda & Lokasi", tabName = "locations", icon = icon("home")),
        menuItem("🔍 Cek Status", tabName = "status", icon = icon("search"))
      )
    ),
    
    conditionalPanel(
      condition = "output.is_admin_logged_in",
      sidebarMenu(
        id = "admin_menu",
        menuItem("Master Data", icon = icon("database"),
                 menuSubItem("Kategori", tabName = "master_kategori"),
                 menuSubItem("Periode", tabName = "master_periode"), 
                 menuSubItem("Lokasi", tabName = "master_lokasi")
        ),
        menuItem("Kelola Pendaftaran", tabName = "manage_registration", icon = icon("users"))
      )
    )
  ),
  
  # Body
  dashboardBody(
    # Student Interface
    conditionalPanel(
      condition = "!output.is_admin_logged_in",
      tabItems(
        # Locations Tab (Homepage)
        tabItem(
          tabName = "locations",
          # Welcome Section
          fluidRow(
            column(12,
                   div(class = "welcome-section",
                       div(class = "welcome-title", "Selamat Datang di Sistem Labsos"),
                       div(class = "welcome-subtitle", "Jelajahi dan Pilih Lokasi Laboratorium Sosial")
                   )
            )
          ),
          
          # Quick Stats
          fluidRow(
            column(12,
                   div(class = "quick-stats",
                       div(class = "stat-item",
                           div(class = "stat-number", textOutput("total_locations_student", inline = TRUE)),
                           div(class = "stat-label", "Total Lokasi")
                       ),
                       div(class = "stat-item",
                           div(class = "stat-number", textOutput("active_period_student", inline = TRUE)),
                           div(class = "stat-label", "Status Periode")
                       )
                   )
            )
          ),
          
          # Locations Display
          fluidRow(
            column(12,
                   conditionalPanel(
                     condition = "output.has_locations",
                     h3("📍 Lokasi Laboratorium Sosial Tersedia", style = "text-align: center; margin-bottom: 30px; color: #2c3e50;"),
                     uiOutput("locations_grid")
                   ),
                   conditionalPanel(
                     condition = "!output.has_locations",
                     div(class = "alert alert-info text-center",
                         style = "margin-top: 50px; padding: 40px;",
                         icon("info-circle", style = "font-size: 3em; margin-bottom: 15px;"),
                         h4("Belum ada lokasi tersedia"),
                         p("Admin belum menambahkan lokasi. Silakan cek kembali nanti.")
                     )
                   )
            )
          )
        ),
        
        # FIXED: Status Check Tab for Students
        tabItem(
          tabName = "status",
          fluidRow(
            column(12,
                   div(style = "background: white; padding: 30px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.08);",
                       h3("🔍 Cek Status Pendaftaran", style = "color: #007bff; text-align: center; margin-bottom: 25px;"),
                       
                       fluidRow(
                         column(4,
                                div(style = "border: 1px solid #ddd; padding: 20px; border-radius: 8px;",
                                    h5("🔎 Pencarian", style = "color: #007bff; margin-bottom: 15px;"),
                                    textInput("search_nama", "Nama Mahasiswa:", 
                                              placeholder = "Masukkan nama Anda"),
                                    dateInput("search_tanggal", "Tanggal Pendaftaran:", 
                                              value = NULL),
                                    selectInput("search_lokasi", "Lokasi:", 
                                                choices = c("Semua Lokasi" = "")),
                                    selectInput("search_status", "Status:", 
                                                choices = c("Semua Status" = "", "Diajukan", "Disetujui", "Ditolak")),
                                    div(style = "text-align: center; margin-top: 15px;",
                                        actionButton("search_registration", "🔍 Cari Status", 
                                                     class = "btn btn-primary", style = "width: 100%;")
                                    ),
                                    br(),
                                    div(class = "alert alert-info", style = "margin-top: 15px; font-size: 0.9em;",
                                        "💡 Tips: Gunakan nama lengkap atau sebagian nama untuk pencarian yang lebih akurat."
                                    )
                                )
                         ),
                         column(8,
                                div(style = "border: 1px solid #ddd; padding: 20px; border-radius: 8px;",
                                    h5("📊 Hasil Pencarian", style = "color: #007bff; margin-bottom: 15px;"),
                                    DT::dataTableOutput("registration_results")
                                )
                         )
                       )
                   )
            )
          )
        )
      )
    ),
    
    # Admin Interface
    conditionalPanel(
      condition = "output.is_admin_logged_in",
      tabItems(
        # Master Data - Kategori
        tabItem(
          tabName = "master_kategori",
          fluidRow(
            box(
              title = "Master Data Kategori", status = "primary", solidHeader = TRUE, width = 12,
              fluidRow(
                column(8, DT::dataTableOutput("kategori_table")),
                column(4,
                       wellPanel(
                         h4("Form Kategori"),
                         textInput("kategori_nama", "Nama Kategori:", placeholder = "Masukkan nama kategori"),
                         textAreaInput("kategori_deskripsi", "Deskripsi:", rows = 3, placeholder = "Deskripsi kategori"),
                         textAreaInput("kategori_isu", "Isu Strategis:", rows = 3, placeholder = "Isu strategis yang relevan"),
                         br(),
                         div(style = "text-align: center;",
                             actionButton("save_kategori", "💾 Simpan", class = "btn btn-success", style = "margin-right: 5px;"),
                             actionButton("delete_kategori", "🗑️ Hapus", class = "btn btn-danger", style = "margin-right: 5px;"),
                             actionButton("reset_kategori", "🔄 Reset", class = "btn btn-secondary")
                         ),
                         br(),
                         div(class = "alert alert-info", style = "margin-top: 10px; font-size: 0.9em;",
                             "💡 Tips: Klik pada baris tabel untuk mengedit. Pastikan kategori tidak digunakan sebelum menghapus."
                         )
                       )
                )
              )
            )
          )
        ),
        
        # Master Data - Periode
        tabItem(
          tabName = "master_periode",
          fluidRow(
            box(
              title = "Master Data Periode", status = "primary", solidHeader = TRUE, width = 12,
              fluidRow(
                column(8, DT::dataTableOutput("periode_table")),
                column(4,
                       wellPanel(
                         h4("Form Periode"),
                         textInput("periode_nama", "Nama Periode:", placeholder = "Contoh: Semester Genap 2024/2025"),
                         dateInput("periode_mulai", "Tanggal Mulai:", value = Sys.Date()),
                         dateInput("periode_selesai", "Tanggal Selesai:", value = Sys.Date() + 30),
                         selectInput("periode_status", "Status:", choices = c("Aktif", "Tidak Aktif"), selected = "Tidak Aktif"),
                         br(),
                         div(style = "text-align: center;",
                             actionButton("save_periode", "💾 Simpan", class = "btn btn-success", style = "margin-right: 5px;"),
                             actionButton("delete_periode", "🗑️ Hapus", class = "btn btn-danger", style = "margin-right: 5px;"),
                             actionButton("reset_periode", "🔄 Reset", class = "btn btn-secondary")
                         ),
                         br(),
                         div(class = "alert alert-warning", style = "margin-top: 10px; font-size: 0.9em;",
                             "⚠️ Hanya boleh ada satu periode aktif pada satu waktu. Tanggal mulai harus lebih awal dari tanggal selesai."
                         )
                       )
                )
              )
            )
          )
        ),
        
        # Master Data - Lokasi
        tabItem(
          tabName = "master_lokasi",
          fluidRow(
            box(
              title = "Master Data Lokasi", status = "primary", solidHeader = TRUE, width = 12,
              fluidRow(
                column(8, DT::dataTableOutput("lokasi_table")),
                column(4,
                       wellPanel(
                         h4("Form Lokasi"),
                         textInput("lokasi_nama", "Nama Lokasi:", placeholder = "Contoh: Desa Tanjungsari"),
                         textAreaInput("lokasi_deskripsi", "Deskripsi:", rows = 2, placeholder = "Deskripsi singkat lokasi"),
                         selectInput("lokasi_kategori", "Kategori:", choices = NULL),
                         textAreaInput("lokasi_isu", "Isu Strategis:", rows = 2, placeholder = "Isu strategis yang akan ditangani"),
                         fileInput("lokasi_foto", "Upload Foto Lokasi:", 
                                   accept = c(".png", ".jpg", ".jpeg"),
                                   placeholder = "Pilih file gambar (PNG/JPG)"),
                         selectInput("lokasi_prodi", "Program Studi:", choices = PROGRAM_STUDI_OPTIONS, multiple = TRUE),
                         numericInput("lokasi_kuota", "Kuota Mahasiswa:", value = 5, min = 1, max = 50),
                         br(),
                         div(style = "text-align: center;",
                             actionButton("save_lokasi", "💾 Simpan", class = "btn btn-success", style = "margin-right: 5px;"),
                             actionButton("delete_lokasi", "🗑️ Hapus", class = "btn btn-danger", style = "margin-right: 5px;"),
                             actionButton("reset_lokasi", "🔄 Reset", class = "btn btn-secondary")
                         ),
                         br(),
                         div(class = "alert alert-info", style = "margin-top: 10px; font-size: 0.9em;",
                             "💡 Tips: Pilih minimal satu program studi. Kuota menentukan jumlah maksimal mahasiswa yang dapat mendaftar."
                         )
                       )
                )
              )
            )
          )
        ),
        
        # FIXED: Manage Registrations Tab for Admin
        tabItem(
          tabName = "manage_registration",
          fluidRow(
            box(
              title = "Kelola Data Pendaftar", status = "warning", solidHeader = TRUE, width = 12,
              div(style = "margin-bottom: 20px;",
                  h4("📋 Daftar Data Pendaftar Laboratorium Sosial"),
                  p("Kelola semua data pendaftaran mahasiswa yang telah submit. Klik 'Detail' untuk melihat informasi lengkap dan dokumen. Klik 'Setujui' atau 'Tolak' untuk memproses pendaftaran.")
              ),
              
              # Filter Section
              fluidRow(
                column(3,
                       wellPanel(
                         h5("🔍 Filter Data", style = "color: #007bff; margin-bottom: 15px;"),
                         selectInput("admin_filter_lokasi", "Lokasi:", 
                                     choices = c("Semua Lokasi" = "")),
                         selectInput("admin_filter_status", "Status:",
                                     choices = c("Semua Status" = "", "Diajukan", "Disetujui", "Ditolak")),
                         selectInput("admin_filter_prodi", "Program Studi:",
                                     choices = c("Semua Program Studi" = "", PROGRAM_STUDI_OPTIONS)),
                         actionButton("admin_refresh", "🔄 Refresh Data", class = "btn btn-info", style = "width: 100%;"),
                         br(), br(),
                         div(class = "alert alert-info", style = "font-size: 0.9em;",
                             "💡 Tips: Gunakan filter untuk mempermudah pencarian data pendaftar."
                         )
                       )
                ),
                column(9,
                       DT::dataTableOutput("admin_registrations_table")
                )
              )
            )
          )
        )
      )
    ),
    
    # Registration Modal
    conditionalPanel(
      condition = "output.show_registration_modal",
      div(
        style = "position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 9999; overflow-y: auto;",
        onclick = "if(event.target === this) { Shiny.setInputValue('close_registration_modal', Math.random()); }",
        div(
          style = "position: relative; margin: 30px auto; background: white; padding: 0; border-radius: 15px; max-width: 1000px; box-shadow: 0 10px 30px rgba(0,0,0,0.3);",
          
          # Modal Header
          div(style = "background: linear-gradient(135deg, #007bff, #0056b3); color: white; padding: 25px; border-radius: 15px 15px 0 0;",
              h3("📝 Form Pendaftaran Labsos", style = "margin: 0; text-align: center;"),
              div(style = "text-align: center; margin-top: 10px; opacity: 0.9;", "Lengkapi semua informasi dan dokumen yang diperlukan"),
              actionButton("close_registration_modal", "×", 
                           style = "position: absolute; top: 15px; right: 20px; background: transparent; border: none; color: white; font-size: 24px; padding: 5px;")
          ),
          
          # Modal Body
          div(style = "padding: 30px; max-height: 70vh; overflow-y: auto;",
              
              # Location Information Section
              div(style = "background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 20px;",
                  h5("📍 Lokasi yang Dipilih:", style = "color: #007bff; margin-bottom: 15px;"),
                  verbatimTextOutput("selected_location_info"),
                  div(style = "margin-top: 15px;",
                      h6("📝 Deskripsi Lokasi:", style = "color: #495057; margin-bottom: 10px;"),
                      div(style = "background: white; padding: 15px; border-radius: 6px; border: 1px solid #dee2e6;",
                          textOutput("location_description")
                      )
                  ),
                  div(style = "margin-top: 15px;",
                      h6("🎯 Isu Strategis:", style = "color: #495057; margin-bottom: 10px;"),
                      div(style = "background: white; padding: 15px; border-radius: 6px; border: 1px solid #dee2e6;",
                          textOutput("location_strategic_issues")
                      )
                  )
              ),
              
              # Personal Information Section
              div(style = "border: 1px solid #ddd; padding: 20px; border-radius: 8px; margin-bottom: 20px;",
                  h5("👤 Informasi Pribadi", style = "color: #007bff; margin-bottom: 15px;"),
                  fluidRow(
                    column(6,
                           textInput("reg_nama", "Nama Mahasiswa:", 
                                     placeholder = "Masukkan nama lengkap Anda")
                    ),
                    column(6,
                           selectInput("reg_program_studi", "Program Studi:", choices = NULL)
                    )
                  ),
                  fluidRow(
                    column(6,
                           textInput("reg_kontak", "Kontak (WhatsApp):", 
                                     placeholder = "08xxxxxxxxxx")
                    ),
                    column(6,
                           textInput("reg_usulan_dosen", "Usulan Dosen Pembimbing:", 
                                     placeholder = "Nama lengkap dosen pembimbing")
                    )
                  )
              ),
              
              # Essay Section
              div(style = "border: 1px solid #ddd; padding: 20px; border-radius: 8px; margin-bottom: 20px;",
                  h5("💭 Alasan Pemilihan Lokasi", style = "color: #007bff; margin-bottom: 15px;"),
                  p("Essay tentang isu strategis yang menarik untuk Anda, respon dalam bentuk program/project, dan gambaran awal ide project:", 
                    style = "color: #666; font-size: 0.9em; margin-bottom: 10px;"),
                  div(style = "background: #fff3cd; padding: 10px; border-radius: 6px; margin-bottom: 10px; font-size: 0.85em;",
                      "💡 Tips: Jelaskan secara detail mengapa Anda tertarik dengan isu strategis di lokasi ini dan bagaimana rencana kontribusi Anda."
                  ),
                  textAreaInput("reg_alasan", "", 
                                placeholder = "Tulis essay Anda di sini...", 
                                rows = 6, width = "100%")
              ),
              
              # Document Upload Section
              div(style = "border: 1px solid #ddd; padding: 20px; border-radius: 8px; margin-bottom: 20px;",
                  h5("📎 Upload Dokumen Wajib", style = "color: #007bff; margin-bottom: 15px;"),
                  p("Semua dokumen harus dalam format PDF dengan maksimal ukuran 10MB per file:", 
                    style = "color: #666; font-size: 0.9em; margin-bottom: 20px;"),
                  
                  fluidRow(
                    column(6,
                           div(style = "border: 1px solid #ddd; padding: 15px; border-radius: 8px; margin-bottom: 15px;",
                               h6("📄 CV Mahasiswa", style = "color: #007bff; margin-bottom: 10px;"),
                               fileInput("reg_cv_mahasiswa", "", 
                                         accept = ".pdf", width = "100%")
                           ),
                           div(style = "border: 1px solid #ddd; padding: 15px; border-radius: 8px; margin-bottom: 15px;",
                               h6("📋 Form Komitmen Mahasiswa", style = "color: #007bff; margin-bottom: 10px;"),
                               fileInput("reg_form_komitmen", "", 
                                         accept = ".pdf", width = "100%")
                           )
                    ),
                    column(6,
                           div(style = "border: 1px solid #ddd; padding: 15px; border-radius: 8px; margin-bottom: 15px;",
                               h6("🎓 Form Rekomendasi Program Studi", style = "color: #007bff; margin-bottom: 10px;"),
                               fileInput("reg_form_rekomendasi", "", 
                                         accept = ".pdf", width = "100%")
                           ),
                           div(style = "border: 1px solid #ddd; padding: 15px; border-radius: 8px; margin-bottom: 15px;",
                               h6("📊 Transkrip Nilai Mahasiswa", style = "color: #007bff; margin-bottom: 10px;"),
                               fileInput("reg_transkrip_nilai", "", 
                                         accept = ".pdf", width = "100%")
                           )
                    )
                  ),
                  
                  # Document requirements info
                  div(style = "background: #fff3cd; padding: 15px; border-radius: 8px; margin-top: 15px;",
                      h6("📋 Persyaratan Dokumen:", style = "margin-bottom: 10px;"),
                      tags$ul(
                        tags$li("CV Mahasiswa dalam format PDF"),
                        tags$li("Form Rekomendasi Program Studi (ditandatangani)"),
                        tags$li("Form Komitmen Mahasiswa"),
                        tags$li("Transkrip Nilai terkini (maksimal 10MB)")
                      )
                  )
              )
          ),
          
          # Modal Footer
          div(style = "padding: 20px 30px; border-top: 1px solid #eee; text-align: center; background: #f8f9fa; border-radius: 0 0 15px 15px;",
              actionButton("submit_registration", "✅ Submit Pendaftaran", 
                           class = "btn btn-success", 
                           style = "font-size: 1.2em; margin-right: 15px; padding: 12px 30px;"),
              actionButton("close_registration_modal", "❌ Batal", 
                           class = "btn btn-outline-secondary",
                           style = "font-size: 1.1em; padding: 12px 30px;")
          )
        )
      )
    ),
    
    # Admin Login Modal
    conditionalPanel(
      condition = "input.admin_login_btn > 0 && !output.is_admin_logged_in",
      div(
        id = "admin_login_modal",
        style = "position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 10000;",
        onclick = "if(event.target === this) { Shiny.setInputValue('cancel_admin_login', Math.random()); }",
        div(
          style = "position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); background: white; padding: 0; border-radius: 15px; min-width: 400px; box-shadow: 0 10px 30px rgba(0,0,0,0.3);",
          
          # Modal Header
          div(style = "background: linear-gradient(135deg, #007bff, #0056b3); color: white; padding: 20px 25px; border-radius: 15px 15px 0 0; position: relative;",
              h3("🔐 Admin Login", style = "margin: 0; text-align: center;"),
              div(style = "text-align: center; margin-top: 5px; opacity: 0.9;", "Masuk ke panel administrasi"),
              # Close button
              actionButton("close_admin_login", "×", 
                           style = "position: absolute; top: 10px; right: 15px; background: transparent; border: none; color: white; font-size: 24px; padding: 5px 10px;",
                           onclick = "Shiny.setInputValue('cancel_admin_login', Math.random());")
          ),
          
          # Modal Body
          div(style = "padding: 30px;",
              textInput("admin_username", "👤 Username:", 
                        placeholder = "Masukkan username admin",
                        value = ""),
              passwordInput("admin_password", "🔒 Password:", 
                            placeholder = "Masukkan password",
                            value = ""),
              div(style = "background: #e3f2fd; padding: 10px; border-radius: 6px; margin-top: 15px; font-size: 0.9em;",
                  "💡 Demo Credentials: Username: ", strong("admin"), ", Password: ", strong("admin123")
              ),
              conditionalPanel(
                condition = "output.login_error",
                div(style = "background: #f8d7da; color: #721c24; padding: 10px; border-radius: 6px; margin-top: 15px;", 
                    "❌ ", textOutput("login_error_message", inline = TRUE))
              )
          ),
          
          # Modal Footer
          div(style = "padding: 20px 30px; border-top: 1px solid #eee; text-align: center; background: #f8f9fa; border-radius: 0 0 15px 15px;",
              actionButton("do_admin_login", "🔓 Login", class = "btn btn-primary", style = "margin-right: 10px;"),
              actionButton("cancel_admin_login", "❌ Batal", class = "btn btn-outline-secondary")
          )
        )
      )
    )
  )
)