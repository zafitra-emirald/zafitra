# ui.R - Labsos Information System User Interface (Simplified Master Data)

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
        menuItem("🏠 Beranda & Lokasi", tabName = "locations", icon = icon("home"))
      )
    ),
    
    conditionalPanel(
      condition = "output.is_admin_logged_in",
      sidebarMenu(
        id = "admin_menu",
        menuItem("Dashboard", tabName = "admin_dashboard", icon = icon("tachometer-alt")),
        menuItem("Master Data", icon = icon("database"),
                 menuSubItem("Kategori", tabName = "master_kategori"),
                 menuSubItem("Periode", tabName = "master_periode"), 
                 menuSubItem("Lokasi", tabName = "master_lokasi")
        )
      )
    )
  ),
  
  # Body
  dashboardBody(
    # Student Interface
    conditionalPanel(
      condition = "!output.is_admin_logged_in",
      tabItems(
        # Locations Tab
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
        )
      )
    ),
    
    # Admin Interface
    conditionalPanel(
      condition = "output.is_admin_logged_in",
      tabItems(
        # Admin Dashboard
        tabItem(
          tabName = "admin_dashboard", 
          fluidRow(
            valueBoxOutput("total_locations"),
            valueBoxOutput("total_categories"),
            valueBoxOutput("active_periods")
          ),
          fluidRow(
            box(
              title = "Selamat Datang, Admin!", status = "primary", solidHeader = TRUE, width = 12,
              div(style = "padding: 20px; text-align: center;",
                  h4("Sistem Informasi Labsos - Panel Administrasi"),
                  p("Gunakan menu di sidebar untuk mengelola master data sistem."),
                  br(),
                  div(style = "background: #f8f9fa; padding: 15px; border-radius: 8px;",
                      h5("Fitur yang Tersedia:"),
                      tags$ul(
                        tags$li("📋 Kelola Master Data Kategori"),
                        tags$li("📅 Kelola Master Data Periode"),
                        tags$li("📍 Kelola Master Data Lokasi"),
                        tags$li("💾 Data otomatis tersimpan dalam file RDS")
                      )
                  )
              )
            )
          )
        ),
        
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
                         textInput("lokasi_foto", "URL Foto Lokasi:", 
                                   placeholder = "https://example.com/photo.jpg (opsional)"),
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
        )
      )
    ),
    
    # Admin Login Modal
    conditionalPanel(
      condition = "input.admin_login_btn > 0 && !output.is_admin_logged_in",
      div(
        style = "position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 9999;",
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