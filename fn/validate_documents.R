# validate_documents.R
# Function to validate document uploads

validate_documents <- function(doc_list) {
  required_docs <- c("reg_letter_of_interest", "reg_cv_mahasiswa", "reg_form_rekomendasi", "reg_form_komitmen", "reg_transkrip_nilai")
  missing_docs <- character(0)
  
  for(doc in required_docs) {
    if(is.null(doc_list[[doc]]) || is.null(doc_list[[doc]]$name)) {
      missing_docs <- c(missing_docs, doc)
    }
  }
  
  # Additional validation for Letter of Interest file size (max 5MB)
  if(!is.null(doc_list[["reg_letter_of_interest"]]) && !is.null(doc_list[["reg_letter_of_interest"]]$size)) {
    if(doc_list[["reg_letter_of_interest"]]$size > 5 * 1024 * 1024) {
      return(list(valid = FALSE, missing = character(0), error = "Letter of Interest file size exceeds 5MB limit"))
    }
  }
  
  if(length(missing_docs) > 0) {
    return(list(valid = FALSE, missing = missing_docs, error = NULL))
  }
  
  return(list(valid = TRUE, missing = character(0), error = NULL))
}