# validate_documents.R
# Function to validate document uploads

validate_documents <- function(doc_list) {
  required_docs <- c("reg_cv_mahasiswa", "reg_form_rekomendasi", "reg_form_komitmen", "reg_transkrip_nilai")
  missing_docs <- character(0)
  
  for(doc in required_docs) {
    if(is.null(doc_list[[doc]]) || is.null(doc_list[[doc]]$name)) {
      missing_docs <- c(missing_docs, doc)
    }
  }
  
  if(length(missing_docs) > 0) {
    return(list(valid = FALSE, missing = missing_docs))
  }
  
  return(list(valid = TRUE, missing = character(0)))
}