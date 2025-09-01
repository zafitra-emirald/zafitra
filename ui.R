# ui.R - Labsos Information System User Interface (Fixed Version)

# Define elegant modern CSS
custom_css <- "
/* Modern Color Palette & Variables */
:root {
  --primary-gradient: linear-gradient(135deg, #6366f1 0%, #8b5cf6 100%);
  --secondary-gradient: linear-gradient(135deg, #10b981 0%, #059669 100%);
  --accent-gradient: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
  --danger-gradient: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
  --surface: #ffffff;
  --background: #f8fafc;
  --text-primary: #1e293b;
  --text-secondary: #64748b;
  --border: #e2e8f0;
  --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
  --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  --shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  --border-radius: 8px;
  --border-radius-lg: 12px;
}

/* Base Layout */
.content-wrapper, .right-side {
  background: var(--background);
  min-height: 100vh;
}

.main-header {
  background: var(--primary-gradient) !important;
  border: none !important;
  box-shadow: var(--shadow-md);
}

.main-header .navbar {
  background: transparent !important;
}

.main-header .navbar-brand {
  color: white !important;
  font-weight: 600;
  font-size: 1.2rem;
}

/* Sidebar Styling */
.main-sidebar {
  background: var(--surface) !important;
  box-shadow: var(--shadow-lg);
}

.sidebar-menu > li > a {
  color: var(--text-primary) !important;
  font-weight: 500;
  border-radius: var(--border-radius);
  margin: 4px 8px;
  transition: all 0.2s ease;
}

.sidebar-menu > li.active > a, .sidebar-menu > li > a:hover {
  background: var(--primary-gradient) !important;
  color: white !important;
  transform: translateX(4px);
}

/* Card Components */
.card-modern {
  background: var(--surface);
  border-radius: var(--border-radius-lg);
  border: none;
  box-shadow: var(--shadow-md);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  overflow: hidden;
}

.card-modern:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-xl);
}

/* Welcome Hero Section */
.hero-section {
  background: var(--primary-gradient);
  color: white;
  padding: 2rem;
  border-radius: var(--border-radius-lg);
  margin-bottom: 2rem;
  position: relative;
  overflow: hidden;
}

.hero-section::before {
  content: '';
  position: absolute;
  top: -50%;
  right: -50%;
  width: 200%;
  height: 200%;
  background: url('data:image/svg+xml,<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\"><circle cx=\"50\" cy=\"50\" r=\"2\" fill=\"rgba(255,255,255,0.1)\"/></svg>') repeat;
  animation: float 20s infinite linear;
  z-index: 1;
}

@keyframes float {
  0% { transform: translate(-50%, -50%) rotate(0deg); }
  100% { transform: translate(-50%, -50%) rotate(360deg); }
}

.hero-content {
  position: relative;
  z-index: 2;
}

.hero-title {
  font-size: 3.5rem;
  font-weight: 700;
  margin-bottom: 0.75rem;
  background: linear-gradient(45deg, #ffffff, #e2e8f0);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  line-height: 1.2;
}

.hero-subtitle {
  font-size: 1.5rem;
  opacity: 0.9;
  margin-bottom: 1.5rem;
  font-weight: 400;
}

/* Program Info Box */
.program-info-compact {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border-radius: var(--border-radius);
  padding: 1.5rem;
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1rem;
  margin-bottom: 1rem;
}

.info-item {
  background: rgba(255, 255, 255, 0.1);
  padding: 1rem;
  border-radius: var(--border-radius);
  backdrop-filter: blur(5px);
  font-size: 1.1rem;
  line-height: 1.4;
}

.info-highlight {
  background: var(--accent-gradient);
  color: white;
  padding: 1rem;
  border-radius: var(--border-radius);
  text-align: center;
  font-weight: 600;
  margin-top: 1rem;
}

/* Location Cards - Horizontal Flow Layout */
.content-wrapper .location-grid,
.tab-content .location-grid,
div.location-grid {
  display: flex !important;
  flex-wrap: wrap !important;
  flex-direction: row !important;
  gap: 0.75rem !important;
  margin-top: 1.5rem;
  justify-content: flex-start !important;
  align-items: flex-start !important;
}

/* Ensure children are properly spaced */
.location-grid > *,
.location-grid > div {
  flex-shrink: 0 !important;
  margin-bottom: 0 !important;
}

.location-card {
  background: var(--surface);
  border-radius: var(--border-radius-lg);
  border: none;
  box-shadow: var(--shadow-md);
  transition: all 0.3s ease;
  overflow: hidden;
  position: relative;
  display: flex;
  flex-direction: column;
  height: fit-content;
  width: 260px;
  flex-shrink: 0;
}

.location-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-xl);
}

.location-image {
  width: 100%;
  height: 120px;
  object-fit: cover;
  border-radius: var(--border-radius-lg) var(--border-radius-lg) 0 0;
}

.location-content {
  padding: 0.75rem;
  display: flex;
  flex-direction: column;
  flex: 1;
}

.location-header {
  margin-bottom: 0.5rem;
}

.location-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--text-primary);
  margin-bottom: 0.5rem;
  line-height: 1.2;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.location-category {
  background: var(--primary-gradient);
  color: white;
  padding: 0.3rem 0.8rem;
  border-radius: 12px;
  font-size: 0.95rem;
  font-weight: 600;
  display: inline-block;
}

.location-body {
  flex: 1;
  margin-bottom: 0.5rem;
}

.location-description {
  color: var(--text-secondary);
  line-height: 1.4;
  margin-bottom: 0.75rem;
  font-size: 1rem;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.location-meta {
  display: flex;
  gap: 0.3rem;
  flex-wrap: wrap;
  margin-bottom: 0.5rem;
}

.meta-tag {
  background: var(--background);
  color: var(--text-secondary);
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  border: 1px solid var(--border);
  white-space: nowrap;
  font-weight: 500;
}

.location-footer {
  margin-top: auto;
}

.quota-indicator {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.5rem 0.75rem;
  background: var(--background);
  border-radius: var(--border-radius);
  font-size: 0.85rem;
  margin-bottom: 0.75rem;
}

.location-action {
  width: 100%;
}

.quota-available { color: #059669; }
.quota-limited { color: #d97706; }
.quota-full { color: #dc2626; }

/* Buttons */
.btn-modern {
  border: none;
  border-radius: var(--border-radius);
  font-weight: 500;
  transition: all 0.2s ease;
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
}

.btn-primary-modern {
  background: var(--primary-gradient);
  color: white;
}

.btn-primary-modern:hover {
  transform: translateY(-1px);
  box-shadow: var(--shadow-md);
  filter: brightness(1.1);
}

.btn-success-modern {
  background: var(--secondary-gradient);
  color: white;
}

.btn-success-modern:hover {
  transform: translateY(-1px);
  box-shadow: var(--shadow-md);
  filter: brightness(1.1);
}

.btn-outline-modern {
  background: transparent;
  color: var(--text-primary);
  border: 1px solid var(--border);
}

.btn-outline-modern:hover {
  background: var(--surface);
  transform: translateY(-1px);
}

/* Stats Section */
.stats-compact {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.stat-card {
  background: var(--surface);
  padding: 1.5rem;
  border-radius: var(--border-radius-lg);
  text-align: center;
  box-shadow: var(--shadow-md);
  transition: transform 0.2s ease;
}

.stat-card:hover {
  transform: translateY(-2px);
}

.stat-number {
  font-size: 2rem;
  font-weight: 700;
  background: var(--primary-gradient);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.stat-label {
  color: var(--text-secondary);
  font-size: 0.9rem;
  margin-top: 0.5rem;
}

/* Admin Interface */
.admin-header {
  background: var(--surface);
  padding: 1rem;
  border-radius: var(--border-radius-lg);
  margin-bottom: 1.5rem;
  box-shadow: var(--shadow-sm);
  border-left: 4px solid;
  border-image: var(--accent-gradient) 1;
}

/* Responsive Design for Horizontal Flow Layout */
@media (min-width: 1400px) {
  .location-card {
    width: 240px;
  }
}

@media (min-width: 1200px) {
  .location-card {
    width: 250px;
  }
}

@media (max-width: 768px) {
  .hero-title {
    font-size: 2.8rem;
  }
  
  .hero-subtitle {
    font-size: 1.3rem;
  }
  
  .location-grid {
    gap: 1rem;
    justify-content: center;
  }
  
  .location-card {
    width: 280px;
  }
  
  .location-image {
    height: 140px;
  }
  
  .location-content {
    padding: 1rem;
  }
  
  .info-grid {
    grid-template-columns: 1fr;
  }
  
  .stats-compact {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 600px) {
  .location-grid {
    gap: 0.5rem;
    justify-content: center;
  }
  
  .location-card {
    width: 240px;
  }
  
  .location-content {
    padding: 0.6rem;
  }
  
  .location-title {
    font-size: 1.3rem;
  }
  
  .location-description {
    font-size: 0.95rem;
    -webkit-line-clamp: 2;
  }
  
  .location-category {
    font-size: 0.85rem;
  }
  
  .meta-tag {
    font-size: 0.7rem;
    padding: 0.2rem 0.4rem;
  }
}

@media (max-width: 480px) {
  .location-grid {
    gap: 0.75rem;
    justify-content: center;
  }
  
  .location-card {
    width: calc(100vw - 2rem);
    max-width: 320px;
  }
  
  .location-image {
    height: 120px;
  }
  
  .location-content {
    padding: 0.75rem;
  }
  
  .location-title {
    font-size: 1rem;
    -webkit-line-clamp: 1;
  }
  
  .location-description {
    font-size: 0.8rem;
    -webkit-line-clamp: 2;
  }
}

/* Animation Classes */
.fade-in {
  opacity: 0;
  transform: translateY(20px);
  animation: fadeIn 0.6s ease forwards;
}

@keyframes fadeIn {
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.slide-in-left {
  opacity: 0;
  transform: translateX(-20px);
  animation: slideInLeft 0.5s ease forwards;
}

@keyframes slideInLeft {
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

/* Modal Improvements */
.modal-modern .modal-content {
  border: none;
  border-radius: var(--border-radius-lg);
  box-shadow: var(--shadow-xl);
}

.modal-modern .modal-header {
  background: var(--primary-gradient);
  color: white;
  border-bottom: none;
  border-radius: var(--border-radius-lg) var(--border-radius-lg) 0 0;
}

/* Form Improvements */
#admin_login_modal .form-control {
  border: 1px solid var(--border);
  border-radius: var(--border-radius);
  transition: all 0.2s ease;
  padding: 0.9rem;
  font-size: 1.4rem;
}

#admin_login_modal .form-control:focus {
  border-color: #6366f1;
  box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
  outline: none;
}

/* General form improvements */
.form-control {
  border: 1px solid var(--border);
  border-radius: var(--border-radius);
  transition: all 0.2s ease;
}

.form-control:focus {
  border-color: #6366f1;
  box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
  outline: none;
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

/* Photo modal improvements */
.photo-gallery-modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 10001;
}

/* Photo scaling animation */
.photo-scaled {
  transform: scale(1.8) !important;
  transition: transform 0.2s ease !important;
  z-index: 1000;
  position: relative;
}
"

ui <- dashboardPage(
  # Header
  dashboardHeader(
    title = paste("Sistem Informasi Labsos", "v", APP_VERSION),
    tags$li(
      class = "dropdown",
      style = "margin: 8px;",
      conditionalPanel(
        condition = "!output.is_admin_logged_in",
        actionButton("admin_login_btn", "🔐 Admin Login", 
                     class = "btn btn-modern btn-primary-modern btn-sm")
      )
    ),
    tags$li(
      class = "dropdown", 
      style = "margin: 8px;",
      conditionalPanel(
        condition = "output.is_admin_logged_in",
        span("Admin Panel", class = "navbar-text text-white"),
        actionButton("admin_logout_btn", "🚪 Logout", 
                     class = "btn btn-modern btn-outline-modern btn-sm", style = "margin-left: 10px; color: white; border-color: rgba(255,255,255,0.3);")
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
        menuItem("Kelola Pendaftaran", tabName = "manage_registration", icon = icon("users")),
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
        # Locations Tab (Homepage)
        tabItem(
          tabName = "locations",
          # Hero Section
          fluidRow(
            column(12,
                   div(class = "hero-section fade-in",
                       div(class = "hero-content",
                           div(class = "hero-title", "Selamat Datang di Sistem Labsos"),
                           div(class = "hero-subtitle", "Jelajahi dan Pilih Lokasi Laboratorium Sosial"),
                           
                           div(class = "program-info-compact",
                               div(style = "margin-bottom: 1.5rem; font-size: 1.3rem; line-height: 1.6; font-weight: 400;",
                                   "Hai Sobat UNU Yogyakarta! 👋", br(),
                                   "Tahun ini, ", strong("Laboratorium Sosial Angkatan VII"), " kembali hadir untuk mengajak kamu belajar langsung dari lapangan.", br(),
                                   "Bukan sekadar teori, tapi ", strong("pengalaman nyata"), " yang akan membentuk kompetensimu!"
                               ),
                               
                               div(style = "margin-bottom: 1.5rem;",
                                   h4("📌 4 Cluster Pilihan:", style = "margin-bottom: 1rem; font-size: 1.4rem; font-weight: 600;"),
                                   div(class = "info-grid",
                                       div(class = "info-item", "🎓 ", strong("Pendidikan"), br(), "Menginspirasi generasi muda"),
                                       div(class = "info-item", "🌱 ", strong("Green Ekonomi"), br(), "Ekonomi ramah lingkungan"),
                                       div(class = "info-item", "🤝 ", strong("Pemberdayaan"), br(), "Menguatkan komunitas"),
                                       div(class = "info-item", "🕌 ", strong("Filantropi Islam"), br(), "Membangun jejaring kebaikan")
                                   )
                               ),
                               
                               div(style = "margin-bottom: 1.5rem; padding: 1rem; background: rgba(16, 185, 129, 0.15); border-radius: var(--border-radius); border-left: 3px solid #10b981;",
                                   "💡 Di Labsos, kamu akan membuat ", strong("proyek penelitian/pengabdian"), " yang menjadi bekal karier dan masa depanmu."
                               ),
                               
                               div(class = "info-grid", style = "margin-bottom: 1.5rem;",
                                   div(class = "info-item",
                                       "🗓 ", strong("Periode:"), br(),
                                       "Sep 2025 – Jan 2026", br(),
                                       span("(5 bulan / 20 SKS)", style = "font-size: 0.9rem; opacity: 0.8;")
                                   ),
                                   div(class = "info-item",
                                       "📍 ", strong("Metode:"), br(), 
                                       "Hybrid", br(),
                                       span("Flexibel sesuai kebutuhan", style = "font-size: 0.9rem; opacity: 0.8;")
                                   )
                               ),
                               
                               div(class = "info-highlight",
                                   "📢 ", strong("Pendaftaran: 15 Agustus – 1 September 2025"), br(),
                                   "🔥 Kuota terbatas! Ambil peluang ini sekarang!"
                               )
                           )
                       )
                   )
            )
          ),
          
          # Stats Section
          fluidRow(
            column(12,
                   div(class = "stats-compact slide-in-left",
                       div(class = "stat-card",
                           div(class = "stat-number", textOutput("total_locations_student", inline = TRUE)),
                           div(class = "stat-label", "📍 Total Lokasi")
                       ),
                       div(class = "stat-card",
                           div(class = "stat-number", textOutput("active_period_student", inline = TRUE)),
                           div(class = "stat-label", "⏰ Status Periode")
                       )
                   )
            )
          ),
          
          # Locations Display
          fluidRow(
            column(12,
                   conditionalPanel(
                     condition = "output.has_locations",
                     div(style = "text-align: center; margin-bottom: 2rem;",
                         h3("📍 Pilih Lokasi Laboratorium Sosial", 
                            style = "color: var(--text-primary); font-weight: 600; margin-bottom: 0.5rem;"),
                         p("Temukan lokasi yang sesuai dengan minat dan passion kamu", 
                           style = "color: var(--text-secondary); font-size: 1rem;")
                     ),
                     uiOutput("locations_registration", 
                              class = "location-grid",
                              style = "display: flex !important; flex-wrap: wrap !important; gap: 0.75rem !important; justify-content: flex-start !important;")
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
                                    textInput("search_nim", "NIM:", 
                                              placeholder = "Masukkan NIM Anda"),
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
                                        "💡 Tips: Gunakan NIM atau nama lengkap untuk pencarian yang akurat. Bisa digunakan sebagian NIM/nama."
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
                         tags$div(
                           tags$label("Nama Kategori:", `for` = "kategori_nama"),
                           tags$input(id = "kategori_nama", type = "text", class = "form-control", placeholder = "Masukkan nama kategori", autocomplete = "off")
                         ),
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
                         tags$div(
                           tags$label("Nama Periode:", `for` = "periode_nama"),
                           tags$input(id = "periode_nama", type = "text", class = "form-control", placeholder = "Contoh: Semester Genap 2024/2025", autocomplete = "off")
                         ),
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
                         tags$div(
                           tags$label("Nama Lokasi:", `for` = "lokasi_nama"),
                           tags$input(id = "lokasi_nama", type = "text", class = "form-control", placeholder = "Contoh: Desa Tanjungsari", autocomplete = "off")
                         ),
                         textAreaInput("lokasi_deskripsi", "Deskripsi:", rows = 2, placeholder = "Deskripsi singkat lokasi"),
                         textAreaInput("lokasi_alamat", "Alamat Lokasi:", rows = 2, placeholder = "Alamat lengkap lokasi"),
                         tags$div(
                           tags$label("Link Google Maps:", `for` = "lokasi_map"),
                           tags$input(id = "lokasi_map", type = "text", class = "form-control", placeholder = "https://maps.google.com/?q=...", autocomplete = "off")
                         ),
                         selectInput("lokasi_kategori", "Kategori:", choices = NULL),
                         textAreaInput("lokasi_isu", "Isu Strategis:", rows = 2, placeholder = "Isu strategis yang akan ditangani"),
                         fileInput("lokasi_foto", "Upload Foto Lokasi (Multiple):", 
                                   accept = c(".png", ".jpg", ".jpeg"),
                                   placeholder = "Pilih file gambar (PNG/JPG)",
                                   multiple = TRUE),
                         div(style = "background: #f8f9fa; padding: 8px; border-radius: 4px; margin-bottom: 10px; font-size: 0.8em;",
                             "💡 Anda dapat memilih beberapa foto sekaligus untuk menampilkan galeri lokasi"
                         ),
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
                             "💡 Tips: Pilih minimal satu program studi. Link maps bisa didapat dari Google Maps > Share > Copy Link. Upload beberapa foto untuk galeri lokasi yang menarik."
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
                       # Document Statistics Summary
                       div(id = "document_stats_section", style = "margin-bottom: 20px;",
                           uiOutput("document_completion_stats")
                       ),
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
                    column(4,
                           textInput("reg_nim", "NIM (Nomor Induk Mahasiswa):", 
                                     placeholder = "Masukkan NIM Anda")
                    ),
                    column(4,
                           textInput("reg_nama", "Nama Mahasiswa:", 
                                     placeholder = "Masukkan nama lengkap Anda")
                    ),
                    column(4,
                           selectInput("reg_program_studi", "Program Studi:", choices = NULL)
                    )
                  ),
                  fluidRow(
                    column(12,
                           textInput("reg_kontak", "Kontak (WhatsApp):", 
                                     placeholder = "08xxxxxxxxxx")
                    )
                  )
              ),
              
              # Letter of Interest Upload Section
              div(style = "border: 1px solid #ddd; padding: 20px; border-radius: 8px; margin-bottom: 20px;",
                  h5("📄 Letter of Interest", style = "color: #007bff; margin-bottom: 15px;"),
                  p("Upload surat minat dalam format PDF yang menjelaskan alasan pemilihan lokasi, isu strategis yang menarik, dan rencana kontribusi Anda:", 
                    style = "color: #666; font-size: 0.9em; margin-bottom: 10px;"),
                  div(style = "background: #e8f4fd; padding: 12px; border-radius: 6px; margin-bottom: 15px; border-left: 4px solid #007bff;",
                      div(style = "font-weight: bold; color: #007bff; margin-bottom: 8px;", "📥 Template Download:"),
                      tags$a(href = "https://docs.google.com/document/d/1pT7n8SdpjMKp3ZxXUhGdEvMYEdb3DGEG/edit?usp=sharing&ouid=115431379466807729001&rtpof=true&sd=true", 
                             target = "_blank",
                             style = "color: #007bff; text-decoration: none; font-weight: bold;",
                             "🔗 Download Template Letter of Interest",
                             title = "Klik untuk download template surat minat"
                      ),
                      div(style = "font-size: 0.8em; color: #666; margin-top: 5px;",
                          "Silakan download template, edit sesuai kebutuhan, dan upload dalam format PDF"
                      )
                  ),
                  div(style = "background: #fff3cd; padding: 10px; border-radius: 6px; margin-bottom: 15px; font-size: 0.85em;",
                      "💡 Format: PDF | Ukuran maksimal: 5MB | Pastikan surat minat mencakup motivasi dan ide project yang akan dijalankan."
                  ),
                  fileInput("reg_letter_of_interest", 
                           label = NULL,
                           accept = ".pdf",
                           placeholder = "Pilih file PDF...",
                           buttonLabel = "Browse",
                           multiple = FALSE)
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
                               div(style = "background: #f8f9fa; padding: 8px; border-radius: 4px; margin-bottom: 10px; font-size: 0.8em;",
                                   tags$a(href = "https://docs.google.com/document/d/16592N2h5Zn4rbgZtea9wM1jfiLSwKObS/edit?usp=sharing&ouid=115431379466807729001&rtpof=true&sd=true",
                                          target = "_blank",
                                          style = "color: #007bff; text-decoration: none; font-weight: bold;",
                                          "🔗 Template CV Mahasiswa"
                                   )
                               ),
                               fileInput("reg_cv_mahasiswa", "", 
                                         accept = ".pdf", width = "100%")
                           ),
                           div(style = "border: 1px solid #ddd; padding: 15px; border-radius: 8px; margin-bottom: 15px;",
                               h6("📋 Form Komitmen Mahasiswa", style = "color: #007bff; margin-bottom: 10px;"),
                               div(style = "background: #f8f9fa; padding: 8px; border-radius: 4px; margin-bottom: 8px; font-size: 0.8em;",
                                   tags$a(href = "https://drive.google.com/file/d/1ueuzgsDjykQcVemVT922c8eswAbaHV4m/view?usp=sharing",
                                          target = "_blank", 
                                          style = "color: #007bff; text-decoration: none; font-weight: bold;",
                                          "🔗 Template Form Komitmen"
                                   )
                               ),
                               div(style = "background: #fff3cd; padding: 8px; border-radius: 4px; margin-bottom: 10px; font-size: 0.75em; border-left: 3px solid #ffc107;",
                                   strong("⚠️ PENTING:"), " Surat ditulis dan ditandatangani secara basah kemudian diunggah, bukan diketik"
                               ),
                               fileInput("reg_form_komitmen", "", 
                                         accept = ".pdf", width = "100%")
                           )
                    ),
                    column(6,
                           div(style = "border: 1px solid #ddd; padding: 15px; border-radius: 8px; margin-bottom: 15px;",
                               h6("🎓 Form Rekomendasi Program Studi", style = "color: #007bff; margin-bottom: 10px;"),
                               div(style = "background: #f8f9fa; padding: 8px; border-radius: 4px; margin-bottom: 10px; font-size: 0.8em;",
                                   tags$a(href = "https://docs.google.com/document/d/1jF9iV9WG87_KrBk6gSv8yC1EdAAHibvJ/edit?usp=drive_link&ouid=115431379466807729001&rtpof=true&sd=true",
                                          target = "_blank",
                                          style = "color: #007bff; text-decoration: none; font-weight: bold;",
                                          "🔗 Template Form Rekomendasi"
                                   )
                               ),
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
                  div(style = "background: #e8f5e8; padding: 15px; border-radius: 8px; margin-top: 15px; border-left: 4px solid #28a745;",
                      h6("📋 Persyaratan Dokumen:", style = "margin-bottom: 10px; color: #155724;"),
                      tags$ul(style = "margin-bottom: 10px;",
                        tags$li(strong("Letter of Interest:"), " Gunakan template yang disediakan (maksimal 5MB)"),
                        tags$li(strong("CV Mahasiswa:"), " Gunakan template yang disediakan (maksimal 10MB)"),
                        tags$li(strong("Form Rekomendasi Program Studi:"), " Gunakan template, ditandatangani pihak program studi (maksimal 10MB)"),
                        tags$li(strong("Form Komitmen Mahasiswa:"), " Gunakan template, ", 
                               span(style = "color: #dc3545; font-weight: bold;", "ditulis tangan dan ditandatangani basah"), " (maksimal 10MB)"),
                        tags$li(strong("Transkrip Nilai:"), " Transkrip resmi terkini dari program studi (maksimal 10MB)")
                      ),
                      div(style = "background: #d1ecf1; padding: 10px; border-radius: 4px; font-size: 0.85em; color: #0c5460;",
                          "💡 ", strong("Tips:"), " Download semua template terlebih dahulu, lengkapi sesuai petunjuk, lalu upload dalam format PDF."
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
      condition = "output.show_admin_modal && !output.is_admin_logged_in",
      div(
        id = "admin_login_modal",
        style = "position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); z-index: 10000;",
        onclick = "if(event.target === this) { Shiny.setInputValue('cancel_admin_login', Math.random()); }",
        div(
          style = "position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); background: white; padding: 0; border-radius: 15px; min-width: 400px; box-shadow: 0 10px 30px rgba(0,0,0,0.3);",
          
          # Modal Header - Modern Design
          div(style = "background: var(--primary-gradient); color: white; padding: 1.5rem; border-radius: var(--border-radius-lg) var(--border-radius-lg) 0 0; position: relative;",
              h3("🔐 Admin Login", style = "margin: 0; text-align: center; font-weight: 600;"),
              div(style = "text-align: center; margin-top: 0.5rem; opacity: 0.9; font-size: 0.95rem;", "Masuk ke panel administrasi"),
              # Close button
              actionButton("close_admin_login", "×", 
                           class = "btn btn-modern", 
                           style = "position: absolute; top: 0.75rem; right: 1rem; background: rgba(255,255,255,0.2); border: none; color: white; font-size: 1.5rem; padding: 0.25rem 0.5rem; border-radius: 50%;")
          ),
          
          # Modal Body - Modern Form
          div(style = "padding: 2rem;",
              div(style = "margin-bottom: 1.5rem;",
                  tags$label("👤 Username", style = "display: block; margin-bottom: 0.5rem; font-weight: 500; color: var(--text-primary); font-size: 1.1rem;"),
                  tags$div(
                    tags$input(id = "admin_username", type = "text", class = "form-control", 
                               placeholder = "Masukkan username admin", autocomplete = "username")
                  )
              ),
              div(style = "margin-bottom: 1.5rem;",
                  tags$label("🔒 Password", style = "display: block; margin-bottom: 0.5rem; font-weight: 500; color: var(--text-primary); font-size: 1.1rem;"),
                  tags$div(
                    tags$input(id = "admin_password", type = "password", class = "form-control", 
                               placeholder = "Masukkan password", autocomplete = "current-password")
                  )
              ),
              conditionalPanel(
                condition = "output.login_error",
                div(style = "background: rgba(239, 68, 68, 0.1); color: #dc2626; padding: 1rem; border-radius: var(--border-radius); border-left: 3px solid #dc2626;", 
                    "❌ ", textOutput("login_error_message", inline = TRUE))
              )
          ),
          
          # Modal Footer - Modern Buttons
          div(style = "padding: 1.5rem; border-top: 1px solid var(--border); text-align: center; background: var(--background); border-radius: 0 0 var(--border-radius-lg) var(--border-radius-lg); display: flex; gap: 1rem; justify-content: center;",
              actionButton("do_admin_login", "🔓 Login", class = "btn btn-modern btn-primary-modern", style = "padding: 0.75rem 2rem;"),
              actionButton("cancel_admin_login", "❌ Batal", class = "btn btn-modern btn-outline-modern", style = "padding: 0.75rem 2rem;")
          )
        )
      )
    ),
    
    # Photo Gallery Modal with improved event handling
    conditionalPanel(
      condition = "output.show_photo_modal",
      div(
        id = "photo_gallery_modal",
        style = "position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.8); z-index: 99999; overflow: auto; cursor: pointer;",
        onclick = "
          console.log('Modal background clicked, target:', event.target.id, 'current:', this.id);
          if(event.target === this && event.target.id === 'photo_gallery_modal') { 
            console.log('Confirmed background click - closing modal'); 
            Shiny.setInputValue('close_photo_modal_custom', Math.random(), {priority: 'event'});
          }
        ",
        div(
          style = "position: relative; margin: 20px auto; background: white; padding: 0; border-radius: 15px; max-width: 1200px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); cursor: default; overflow: visible;",
          onclick = "event.stopPropagation();",
          
          # Modal Header
          div(style = "background: linear-gradient(135deg, #28a745, #20c997); color: white; padding: 20px 25px; border-radius: 15px 15px 0 0; position: relative;",
              h3("📸 Galeri Foto Lokasi", style = "margin: 0; text-align: center;"),
              div(style = "text-align: center; margin-top: 5px; opacity: 0.9; font-size: 1.1em;",
                  textOutput("photo_location_name", inline = TRUE)),
              tags$button("×",
                          id = "close_photo_modal_btn",
                          type = "button",
                          class = "btn",
                          style = "position: absolute; top: 15px; right: 20px; background: transparent; border: none; color: white; font-size: 24px; padding: 8px 12px; cursor: pointer; border-radius: 50%; transition: background 0.2s ease; z-index: 10010;",
                          onclick = "
                            console.log('X button clicked - attempting multiple close methods');
                            event.stopPropagation();
                            // Try multiple methods to ensure modal closes
                            Shiny.setInputValue('close_photo_modal', Math.random(), {priority: 'event'});
                            Shiny.setInputValue('close_photo_modal_custom', Math.random(), {priority: 'event'});
                            // Direct method as fallback
                            setTimeout(function() {
                              var modal = document.getElementById('photo_gallery_modal');
                              if(modal) modal.style.display = 'none';
                            }, 100);
                          ",
                          onmouseover = "this.style.background = 'rgba(255,255,255,0.2)';",
                          onmouseout = "this.style.background = 'transparent';")
          ),
          
          # Modal Body
          div(style = "padding: 20px; max-height: 75vh; overflow-y: auto; text-align: center; position: relative;",
              uiOutput("photo_gallery_content")),
              
          # Add instruction text
          div(style = "text-align: center; padding: 10px 20px; color: #666; font-size: 0.9em; border-top: 1px solid #eee;",
              "💡 Klik foto untuk memperbesar/mengecilkan | Klik di luar area atau tombol × untuk menutup")
        )
      )
    ),
    
    # Version Footer
    div(
      style = "position: fixed; bottom: 10px; right: 15px; background: rgba(255,255,255,0.9); padding: 5px 10px; border-radius: 5px; font-size: 0.8em; color: #666; border: 1px solid #eee; z-index: 1000;",
      paste("v", APP_VERSION, "•", format(APP_BUILD_DATE, "%Y-%m-%d"))
    )
  )
)