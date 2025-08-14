# validate_admin.R
# Function to validate admin login credentials

validate_admin <- function(username, password) {
  if (is.null(username) || is.null(password) || username == "" || password == "") {
    return(FALSE)
  }
  return(username == admin_credentials$username && password == admin_credentials$password)
}