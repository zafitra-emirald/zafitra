# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Labsos (Laboratorium Sosial) Information System** built with R Shiny. It's a web application for managing social laboratory programs where students register for community service locations and administrators manage the entire program lifecycle.

## Key Technologies & Dependencies

- **R Shiny + Shinydashboard**: Web framework with dashboard layout
- **DT**: DataTables for interactive data display
- **dplyr**: Data manipulation and processing
- **shinyjs**: JavaScript functionality enhancement
- **Database**: MongoDB Atlas for data persistence with RDS fallback
- **mongolite**: MongoDB R driver for database connectivity

## Development Commands

```r
# Install dependencies
install.packages(c("shiny", "shinydashboard", "DT", "dplyr", "shinyjs", "mongolite"))

# Run the application from project root
shiny::runApp()

# Run with auto-reload during development
options(shiny.autoreload = TRUE)
shiny::runApp()
```

## Core Architecture

### Three-File Structure
1. **global.R**: Configuration, constants, data functions, business logic
2. **ui.R**: Complete UI definition with custom CSS and responsive design  
3. **server.R**: Reactive server logic, event handlers, data operations

### Data Model (MongoDB Collections)
- **kategori_data**: Location categories (Pendidikan, Kesehatan, Teknologi)
- **periode_data**: Time-bounded registration periods with status
- **lokasi_data**: Community locations with quotas and program restrictions
- **pendaftaran_data**: Student applications with documents and approval status

### MongoDB Configuration
- **Database**: `labsos` on MongoDB Atlas
- **Connection**: `mongodb+srv://labsos:T5CmgVtU2mV4K01t@cluster0.ejeivru.mongodb.net/labsos`
- **Collections**: 4 main collections mapping to data entities
- **Fallback**: Automatic RDS file fallback if MongoDB unavailable
- **Data Layer**: Abstracted through wrapper functions for seamless switching

### File Organization
```
fn/                # Function files including MongoDB integration
  mongodb_config.R          # MongoDB connection configuration
  load_or_create_data_mongo.R  # MongoDB data loading functions
  save_*_data_mongo.R       # MongoDB data saving functions  
  data_layer_wrapper.R      # MongoDB/RDS abstraction layer
data/              # RDS backup files (fallback storage)
www/documents/     # Student document uploads (PDF)
www/images/        # Location photos
Requirement/       # Business requirements documentation
```

## Application Flow & Business Logic

### User Workflows
1. **Student Journey**: Browse locations → Register → Upload documents → Check status
2. **Admin Journey**: Login → Manage master data → Review applications → Approve/reject

### Key Business Rules
- Only one active registration period allowed
- Students identified by NIM (Nomor Induk Mahasiswa) as unique ID
- Students limited to one registration per period (unless rejected)
- Location quotas enforced automatically
- Required documents: Letter of Interest (PDF, max 5MB), CV, recommendation form, commitment form, transcript (all PDF, max 10MB each)
- Document templates provided with download links in registration form
- Form Komitmen requires handwritten signature (not typed)
- Category deletion blocked if used by locations

### Document Templates
- **Letter of Interest**: https://docs.google.com/document/d/1pT7n8SdpjMKp3ZxXUhGdEvMYEdb3DGEG/edit
- **CV Mahasiswa**: https://docs.google.com/document/d/16592N2h5Zn4rbgZtea9wM1jfiLSwKObS/edit  
- **Form Rekomendasi**: https://docs.google.com/document/d/1jF9iV9WG87_KrBk6gSv8yC1EdAAHibvJ/edit
- **Form Komitmen**: https://drive.google.com/file/d/1ueuzgsDjykQcVemVT922c8eswAbaHV4m/view

### Data Persistence Pattern
- **MongoDB Primary**: Auto-initialization via `initialize_data_layer()` in global.R:91
- **RDS Fallback**: Automatic fallback to RDS files if MongoDB unavailable  
- **Immediate persistence**: All changes saved to active data layer (MongoDB or RDS)
- **Wrapper Functions**: `save_*_data_wrapper()` functions handle layer switching
- **Data Refresh**: `refresh_*_data()` functions reload from active data layer
- **Connection Pooling**: Automatic connection management with proper cleanup

## Critical Architecture Details

### Reactive Programming Structure
- `reactiveValues()` for application state management
- `observeEvent()` handlers for user actions
- `renderDataTable()` and `renderUI()` for dynamic content
- `conditionalPanel()` for role-based UI switching

### Authentication & Security
- Hardcoded admin credentials: username "adminlabsos", password "labsosunu4869"
- Session-based authentication (no persistent sessions)
- File uploads stored in publicly accessible `www/` directory
- Basic validation only - no advanced security measures

### Configuration Constants
- **Program Studi**: 11 predefined academic programs (global.R:17-29)
- **Admin Credentials**: Stored in global.R:32-36
- **File Size Limits**: 10MB for documents, no explicit limit for images

## Development Patterns & Conventions

### Adding New Features
1. **Business Logic**: Add functions to global.R with error handling
2. **UI Components**: Follow existing modal and card patterns in ui.R
3. **Server Handlers**: Use `observeEvent()` with consistent error notification patterns
4. **Data Changes**: Update `load_or_create_data()` for schema changes

### Code Style Conventions
- Function names: snake_case (e.g., `save_kategori_data()`)
- Reactive values: camelCase (e.g., `values$adminLoggedIn`)
- UI elements: kebab-case IDs (e.g., `admin_login_btn`)
- File naming: descriptive with underscores

### Common Modification Points
- **global.R:17-29**: Program Studi options
- **ui.R:4-176**: Custom CSS styling  
- **server.R:9-20**: Reactive values initialization
- **Data schema**: Modify `load_or_create_data()` function

## Important File Locations & Functions

### Key Functions (global.R)
- `load_or_create_data()`: Data initialization and schema setup with migration safety
- `validate_admin()`: Authentication logic  
- `is_registration_open()`: Period validation
- `check_category_usage()`: Referential integrity checking
- `get_current_quota_status()`: Real-time quota calculations
- `cleanup_old_backups()`: Backup file management utility

### Production Safety & Backup System
- **Automatic Backups**: All save operations create timestamped backups
- **Migration Safety**: Schema changes preserve existing data with rollback protection
- **Data Integrity**: Comprehensive validation before/after all operations
- **Backup Types**:
  - `*_backup_YYYYMMDD_HHMMSS.rds`: Regular save operation backups
  - `*_migration_backup_YYYYMMDD_HHMMSS.rds`: Pre-migration backups
  - `*_save_backup_YYYYMMDD_HHMMSS.rds`: Additional save verification backups
- **Cleanup**: Use `cleanup_old_backups(keep_days = 30, dry_run = FALSE)` to manage disk space

### Server Event Handlers (server.R)
- Registration submission: Lines 400+ (complex multi-step validation)
- Admin CRUD operations: Lines 200-800 (category, period, location management)
- File upload processing: Integrated throughout registration handlers
- Modal management: Custom JavaScript integration for UX

### UI Components (ui.R)  
- Location cards: Dynamic generation with quota display
- Registration modal: Multi-step form with document uploads
- Admin tables: DataTables with inline editing
- Custom CSS: Lines 4-176 for professional styling

## Debugging & Development Notes

- **Data Issues**: Check `data/` directory creation and RDS file permissions
- **Upload Problems**: Verify `www/documents/` and `www/images/` directories exist
- **Modal Issues**: JavaScript conflicts may require browser refresh
- **Performance**: Large datasets may slow DataTable rendering
- **Session Management**: Admin logout clears all reactive values

## Requirements Documentation

Detailed business requirements available in `Requirement/` directory:
- Functional requirements with use cases
- Data catalogs for each entity  
- Complete user story specifications