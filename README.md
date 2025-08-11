# Sistem Informasi Laboratorium Sosial (Labsos)

[![R Shiny](https://img.shields.io/badge/R-Shiny-blue.svg)](https://shiny.rstudio.com/)
[![Version](https://img.shields.io/badge/version-4.0-green.svg)](https://github.com/yourusername/labsos)

## Overview

**Sistem Informasi Labsos** is a comprehensive web application built with R Shiny for managing Social Laboratory (Laboratorium Sosial) programs at universities. The system facilitates student registration for community service locations and provides administrative tools for managing the entire program lifecycle.

### What is Laboratorium Sosial?

Laboratorium Sosial (Social Laboratory) is a community engagement program where university students work on real-world social issues in partnership with local communities. Students select locations based on strategic issues they want to address, submit comprehensive proposals, and contribute to community development through structured projects.

## Key Features

### 🎓 **For Students**
- **Browse Available Locations**: View detailed location cards with photos, descriptions, and strategic issues
- **Smart Registration System**: Register for preferred locations with comprehensive form validation
- **Document Upload**: Submit required documents (CV, recommendation letters, transcripts) in PDF format
- **Registration Status Tracking**: Check application status and receive feedback
- **Reapplication Support**: Ability to reapply if initially rejected

### 👨‍💼 **For Administrators**
- **Master Data Management**: Manage categories, periods, and locations
- **Registration Period Control**: Set active registration periods with date ranges
- **Application Review**: Evaluate student applications with document viewing capabilities
- **Approval/Rejection System**: Process applications with detailed feedback
- **Quota Management**: Automatic quota tracking and registration closure when full
- **Dashboard Analytics**: Monitor registration statistics and location utilization

### 🔧 **System Features**
- **Responsive Design**: Mobile-friendly interface with modern UI
- **File Management**: Secure document upload and storage
- **Real-time Validation**: Period-based and quota-based registration control
- **Authentication System**: Simple admin login with session management
- **Data Persistence**: File-based storage using RDS format

## Technology Stack

- **Framework**: R Shiny + Shinydashboard
- **Frontend**: Custom CSS with responsive design
- **Backend**: R with reactive programming
- **Database**: File-based storage (RDS files)
- **File Handling**: Built-in R file operations
- **UI Components**: DataTables (DT), ShinyJS for interactivity

## Quick Start

### Prerequisites

```r
# Required R packages
install.packages(c(
  "shiny",
  "shinydashboard", 
  "DT",
  "dplyr",
  "shinyjs"
))
```

### Installation

1. **Clone the repository**
   ```bash
   git clone [repository-url]
   cd labsos
   ```

2. **Run the application**
   ```r
   # Run the application
   shiny::runApp()
   ```

3. **Access the application**
   - Open your browser to `http://localhost:3838` (or displayed URL)
   - For admin access, click "Admin Login" and use credentials: `admin` / `admin123`

## Project Structure

```
labsos/
├── README.md                 # This file
├── CLAUDE.md                 # Development guidance
├── Requirement/              # Business requirements and specifications
│   ├── Product Requirement - Sistem Informasi Labsos - Requirement List.csv
│   ├── Product Requirement - Sistem Informasi Labsos - List of Function.csv
│   └── Product Requirement - Sistem Informasi Labsos - Katalog Data_*.csv
├── global.R                  # Global configuration and functions
├── ui.R                      # User interface definition
├── server.R                  # Server-side logic
├── labsos.Rproj              # R Studio project file
└── data/                     # Persistent data storage (auto-created)
    ├── kategori_data.rds
    ├── periode_data.rds
    ├── lokasi_data.rds
    └── pendaftaran_data.rds
```

## Data Models

### Core Entities

1. **Kategori (Categories)**
   - Educational, Health, Technology categories for locations
   - Contains strategic issues and descriptions

2. **Periode (Registration Periods)**
   - Time-bound registration windows
   - Controls when students can apply

3. **Lokasi (Locations)**
   - Community locations with quotas and program restrictions
   - Linked to categories and strategic issues

4. **Pendaftaran (Registrations)**
   - Student applications with documents and status tracking
   - Approval workflow with feedback

### Sample Programs Supported

- Studi Islam Interdisipliner
- Manajemen & Akuntansi
- Farmasi & Health Sciences
- Agribisnis & Teknologi Hasil Pertanian
- Informatika & Engineering
- Education Programs

## User Stories & Requirements

The system implements comprehensive user stories covering:

### Student Journey
1. **Location Discovery**: Browse and filter available locations
2. **Registration Process**: Multi-step form with document upload
3. **Status Tracking**: Search and monitor application status
4. **Reapplication**: Second chance for rejected applications

### Admin Workflow
1. **Master Data Setup**: Configure categories, periods, and locations
2. **Application Management**: Review documents and make decisions
3. **System Administration**: Monitor quotas and generate insights

*Full requirements available in `/Requirement/` folder*

## Configuration

### Admin Credentials
- **Username**: `admin`
- **Password**: `admin123`
- **Access**: Full system administration

### File Limits
- **Documents**: PDF format, max 10MB per file
- **Images**: JPG/PNG format, max 50MB for location photos

### Data Storage
- **Location**: `data/` directory (auto-created)
- **Format**: R RDS files for cross-session persistence
- **Backup**: Manual file backup recommended

## Development

### Development Philosophy: Function-First Approach

This project follows a **function-first development methodology** where business logic functions are the heart of the application. This approach ensures:

- **Separation of Concerns**: Business logic is independent from UI/Server code
- **Testability**: Pure functions can be easily tested in isolation  
- **Maintainability**: Changes to business rules don't affect presentation layer
- **Reusability**: Functions can be reused across different parts of the app

### Development Workflow

#### Phase 1: Business Logic Functions (`global.R`)
```r
# 1. Data Management Functions
create_initial_data()
load_data_safely()
save_data_with_validation()

# 2. Core Business Logic
validate_registration_eligibility()
calculate_available_quota()
process_student_application()
evaluate_admin_decision()

# 3. Validation & Rules
validate_period_constraints()
validate_document_requirements()
check_duplicate_registration()
enforce_quota_limits()

# 4. Status Management
update_registration_status()
manage_period_lifecycle()
handle_quota_updates()
```

#### Phase 2: User Interface (`ui.R`)
- Build reactive UI components that call business functions
- Design forms and displays based on function outputs
- Implement responsive design with accessibility

#### Phase 3: Server Logic (`server.R`) 
- Connect UI events to business functions
- Handle reactive programming with `observeEvent()` and `reactive()`
- Manage session state and user interactions

### Development Plan Guide

#### 📋 **Phase 1: Core Business Functions (Week 1-2)**

**Step 1: Data Foundation**
```r
# Priority Functions to Build First:
- load_or_create_data()           # Initialize data structures
- validate_data_integrity()       # Ensure data consistency
- backup_data()                   # Data safety mechanisms
- restore_from_backup()          # Recovery functions
```

**Step 2: Registration Business Logic**
```r
# Registration Core Functions:
- check_registration_eligibility() # Period + quota + duplicate checks
- validate_student_documents()     # Document format/size validation
- process_new_registration()       # Handle complete registration flow
- calculate_quota_status()         # Real-time quota management
```

**Step 3: Admin Business Logic**
```r
# Admin Management Functions:
- validate_admin_credentials()     # Authentication logic
- manage_master_data()            # CRUD operations for categories/locations
- process_application_decision()   # Approval/rejection workflow
- generate_admin_reports()        # Statistics and insights
```

**Step 4: Validation & Rules Engine**
```r
# Business Rules Functions:
- enforce_period_rules()          # Period-based access control
- validate_quota_constraints()    # Quota management rules
- check_referential_integrity()   # Data consistency checks
- apply_business_constraints()    # All business rule validation
```

#### 🎨 **Phase 2: User Interface Design (Week 3)**

**Student Interface Priority:**
1. Location browsing cards with filtering
2. Registration form with progressive disclosure
3. Document upload interface with validation feedback
4. Status checking with search functionality

**Admin Interface Priority:**
1. Dashboard with key metrics
2. Master data management tables
3. Application review interface
4. Batch operations for efficiency

#### ⚙️ **Phase 3: Server Integration (Week 4)**

**Reactive Programming Structure:**
```r
# Server Organization:
- observeEvent() for user actions → business functions
- reactive() for computed values → UI updates  
- validate() for input validation → error handling
- isolate() for controlling reactivity scope
```

### Getting Started with Function-First Development

#### 1. **Set Up Development Environment**
```r
# Load development environment
source("global.R")

# Enable hot reloading
options(shiny.autoreload = TRUE)

# Test business functions independently
source("tests/test_business_logic.R")
```

#### 2. **Build & Test Functions First**
```r
# Example: Test registration logic without UI
test_registration <- function() {
  # Mock data setup
  mock_student <- list(nama = "John Doe", program_studi = "Informatika")
  mock_location <- list(nama_lokasi = "Desa Test", kuota = 10)
  
  # Test business function
  result <- check_registration_eligibility(mock_student, mock_location)
  stopifnot(result$eligible == TRUE)
}
```

#### 3. **Integrate with UI/Server**
```r
# Server: Use business functions
observeEvent(input$submit_registration, {
  result <- process_new_registration(
    student_data = collect_student_input(),
    location_id = input$selected_location,
    documents = collect_documents()
  )
  
  if(result$success) {
    showNotification("Registration successful!")
  } else {
    showNotification(result$error_message, type = "error")
  }
})
```

### Key Development Areas

#### **Business Logic Architecture**
- **Pure Functions**: No side effects, predictable outputs
- **Error Handling**: Comprehensive validation with meaningful messages
- **Data Validation**: Multi-level validation (format, business rules, constraints)
- **State Management**: Clear data flow and state transitions

#### **UI/Server Integration**
- **Reactive Programming**: Efficient use of `reactive()` and `observeEvent()`
- **Modular Design**: Clear separation between presentation and logic
- **Error Handling**: User-friendly error messages and recovery flows
- **Session Management**: Proper cleanup and state management

#### **Testing Strategy**
- **Function Testing**: Unit tests for all business logic functions
- **Integration Testing**: Test UI-Server-Function integration
- **User Flow Testing**: End-to-end testing of complete workflows
- **Data Testing**: Validate data integrity and business rules

### Code Quality Guidelines

#### **Function Design Principles**
```r
# Good: Pure function with clear inputs/outputs
validate_registration <- function(student_data, location_data, period_data) {
  # Clear validation logic
  # Return structured result with success/error info
  return(list(valid = TRUE/FALSE, message = "...", data = ...))
}

# Bad: Function with side effects and unclear outputs  
process_stuff <- function(input) {
  # Updates global state
  # Returns unclear values
  # Mixed concerns
}
```

#### **Error Handling Patterns**
```r
# Consistent error handling across all functions
safe_function <- function(input) {
  tryCatch({
    # Validate inputs
    validate_inputs(input)
    
    # Process business logic
    result <- core_business_logic(input)
    
    # Return success
    return(list(success = TRUE, data = result, message = "Success"))
    
  }, error = function(e) {
    return(list(success = FALSE, data = NULL, message = e$message))
  })
}
```

This function-first approach ensures robust, maintainable, and testable code that forms the solid foundation of the Labsos application.

## AI-Assisted Development Prompts

### 🤖 **Phase 1: Business Logic Functions (global.R)**

#### **Data Foundation Functions**
```
CONTEXT: I'm developing a Shiny app for Laboratorium Sosial (social laboratory) student registration system. This system manages categories, periods, locations, and student registrations using RDS file storage.

TASK: Create data foundation functions for the global.R file.

REQUIREMENTS:
- Functions should handle RDS file loading/saving with error handling
- Include data integrity validation
- Support backup and recovery mechanisms
- Follow R best practices with clear return values

DATA STRUCTURES:
- kategori_data: id_kategori, nama_kategori, deskripsi_kategori, isu_strategis, timestamp
- periode_data: id_periode, nama_periode, waktu_mulai, waktu_selesai, status, timestamp  
- lokasi_data: id_lokasi, nama_lokasi, deskripsi_lokasi, kategori_lokasi, isu_strategis, kuota_mahasiswa, foto_lokasi, program_studi (list), timestamp
- pendaftaran_data: id_pendaftaran, timestamp, nama_mahasiswa, program_studi, kontak, pilihan_lokasi, alasan_pemilihan, usulan_dosen_pembimbing, cv_path, form_rekomendasi_path, form_komitmen_path, transkrip_path, status_pendaftaran, alasan_penolakan

FUNCTIONS NEEDED:
1. load_data_safely() - Load RDS files with error handling
2. validate_data_integrity() - Check data consistency and relationships
3. backup_data() - Create timestamped backups
4. restore_from_backup() - Restore from backup files
5. initialize_empty_data() - Create empty data structures

Please generate clean, well-documented R functions with consistent error handling patterns.
```

#### **Registration Business Logic**
```
CONTEXT: Building core registration business logic for a university social laboratory program where students apply to community locations with quota limits and period restrictions.

TASK: Create registration validation and processing functions.

BUSINESS RULES:
- Students can only register during active periods
- Only one registration per student (unless previous was rejected)
- Locations have quota limits that must be enforced
- Required documents: CV, recommendation form, commitment form, transcript
- All documents must be PDF format, max 10MB

FUNCTIONS NEEDED:
1. check_registration_eligibility(student_data, location_id, periode_data)
2. validate_student_documents(document_list)
3. process_new_registration(student_data, location_id, documents)
4. calculate_quota_status(location_id, registration_data)
5. check_duplicate_registration(student_name, registration_data)

Each function should return a consistent structure: list(success = TRUE/FALSE, message = "...", data = result)

Please include comprehensive validation logic and clear error messages in Indonesian.
```

#### **Admin Management Functions**
```
CONTEXT: Admin panel for managing master data (categories, periods, locations) with referential integrity checking.

TASK: Create admin management functions for CRUD operations.

REQUIREMENTS:
- Category deletion should check if used by locations
- Period management should ensure only one active period
- Location management should validate category relationships
- All operations should maintain data consistency

FUNCTIONS NEEDED:
1. validate_admin_credentials(username, password)
2. manage_master_data(operation, data_type, data)
3. process_application_decision(registration_id, decision, reason)
4. generate_admin_reports(report_type)
5. check_referential_integrity(data_type, id)

Include proper validation for business constraints and return structured results for UI consumption.
```

### 🎨 **Phase 2: User Interface (ui.R)**

#### **Student Interface Components**
```
CONTEXT: Creating a modern, responsive student interface for browsing locations and registering for social laboratory programs.

TASK: Generate UI components for the student interface.

DESIGN REQUIREMENTS:
- Modern card-based design for location display
- Responsive layout that works on mobile
- Progressive disclosure for registration forms
- Clear visual feedback for form validation
- Indonesian language throughout

COMPONENTS NEEDED:
1. Location browsing cards with photos and details
2. Advanced filtering options (category, program studi)
3. Registration modal with multi-step form
4. Document upload interface with validation feedback
5. Registration status checking interface

EXISTING CSS CLASSES: location-card, location-image, location-content, location-title, register-btn

Please generate Shiny UI code using shinydashboard with custom CSS for professional appearance.
```

#### **Admin Interface Components**
```
CONTEXT: Admin dashboard for managing master data and reviewing student applications.

TASK: Create admin interface components with full CRUD capabilities.

REQUIREMENTS:
- DataTables for all master data with inline editing
- Application review interface with document viewing
- Batch operations for efficiency
- Statistical dashboard with key metrics
- Modal dialogs for confirmations and detailed views

COMPONENTS NEEDED:
1. Master data management tables (categories, periods, locations)
2. Application review interface with status management
3. Dashboard with statistics and charts
4. Bulk approval/rejection interface
5. System settings and configuration

Use DT package for advanced tables and include proper form validation throughout.
```

### ⚙️ **Phase 3: Server Integration (server.R)**

#### **Reactive Event Handlers**
```
CONTEXT: Connecting UI events to business logic functions in a Shiny server with proper reactive programming.

TASK: Create server-side event handlers that use the business logic functions.

REQUIREMENTS:
- Use observeEvent() for user actions
- Implement reactive() for computed values
- Handle file uploads securely
- Provide clear user feedback with notifications
- Maintain session state properly

HANDLERS NEEDED:
1. Registration form submission with validation
2. Admin login and session management
3. Master data CRUD operations
4. File upload processing
5. Real-time quota updates

PATTERN:
observeEvent(input$action, {
  result <- business_function(input_data)
  if(result$success) {
    # Update UI and show success
  } else {
    # Show error message
  }
})

Integrate with the business logic functions from global.R and provide comprehensive error handling.
```

#### **Reactive Data Management**
```
CONTEXT: Managing reactive data flows for real-time updates across the Shiny application.

TASK: Implement reactive data management with proper state handling.

REQUIREMENTS:
- reactiveValues for application state
- Automatic UI updates when data changes
- Efficient reactive dependencies
- Session cleanup and memory management

REACTIVE COMPONENTS:
1. Real-time quota tracking and display
2. Dynamic form field updates based on selections
3. Live validation feedback
4. Auto-refresh for admin dashboard statistics
5. Session state management across page navigation

Use Shiny's reactive programming effectively while maintaining performance and avoiding unnecessary re-computations.
```

### 🧪 **Phase 4: Testing and Validation**

#### **Function Testing**
```
CONTEXT: Creating comprehensive tests for business logic functions to ensure reliability.

TASK: Generate test cases for all business logic functions.

REQUIREMENTS:
- Unit tests for individual functions
- Integration tests for function combinations
- Edge case testing (empty data, invalid inputs)
- Mock data for testing scenarios

TEST FRAMEWORK: Use testthat package

Create test files that cover:
1. Data validation functions
2. Registration business logic
3. Admin management functions  
4. Error handling scenarios
5. Business rule enforcement

Include both positive and negative test cases with clear assertions.
```

#### **User Flow Testing**
```
CONTEXT: End-to-end testing of complete user workflows in the Shiny application.

TASK: Create user flow test scenarios.

WORKFLOWS TO TEST:
1. Student registration flow (browse → select → register → confirm)
2. Admin approval workflow (login → review → approve/reject)
3. Master data management (add → edit → delete with validation)
4. Period management and quota enforcement
5. Document upload and validation

Create test scripts that simulate user interactions and validate expected outcomes at each step.
```

### 📝 **Development Prompt Usage Guidelines**

1. **Sequential Development**: Use prompts in order (Functions → UI → Server → Testing)
2. **Context Preservation**: Each prompt includes full context to maintain coherence
3. **Iterative Refinement**: Use follow-up prompts to refine generated code
4. **Integration Testing**: Test each component integration before moving to next phase
5. **Documentation**: Document any deviations from generated code for future reference

### 🔄 **Prompt Customization Template**

When generating code, always include:
```
CONTEXT: [Brief description of the component and its role]
TASK: [Specific development task]
REQUIREMENTS: [Technical and business requirements]
EXISTING CODE: [Reference to related components]
OUTPUT FORMAT: [Expected code structure and style]
```

This systematic approach ensures consistent, high-quality code generation while maintaining the function-first architecture.

## API Reference

### Core Functions
- `load_or_create_data()`: Initialize data structures
- `is_registration_open()`: Check period availability
- `validate_admin()`: Authentication validation
- `check_category_usage()`: Referential integrity checks

### Business Logic
- Registration eligibility validation
- Quota management automation
- Document upload processing
- Status workflow management

*Full function documentation in `/Requirement/Product Requirement - Sistem Informasi Labsos - List of Function.csv`*

## Contributing

1. **Code Style**: Follow R style conventions
2. **Testing**: Test all user flows before commits
3. **Documentation**: Update CLAUDE.md for architecture changes
4. **Requirements**: Reference requirement documents for feature changes

## Support & Documentation

- **Requirements**: See `/Requirement/` folder for detailed specifications
- **Development Guide**: Check `CLAUDE.md` for technical guidance
- **Templates**: Document templates linked in requirement specifications

## License

[Add your license information here]

## Changelog

### Current Version
- Enhanced UI with modern card-based design
- Comprehensive document upload system
- Advanced admin dashboard with master data management
- Real-time quota and period management
- Responsive mobile design
- Complete business workflow implementation

---

**Developed for University Social Laboratory Programs**

*For technical support or feature requests, please refer to the project documentation or contact the development team.*