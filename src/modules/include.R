#' Simple include function, similar to C/C++
#'
#' @param file_path relative path and file name for the R source file to be included
#'
#' @export
#' @importFrom dplyr filter
#' @importFrom dplyr pull
#' @importFrom magrittr %>%
#' @importFrom rstudioapi getSourceEditorContext
#' @importFrom stringr str_replace
#' @importFrom tibble enframe
#' @importFrom tidyr separate
#'
include <- function (file_path = getwd()) {
  
  if (file.exists(file_path)) {
    
    file_name <- basename(file_path)
    module_directory <- dirname(file_path)
    # message(paste0("file_name: ", file_name))
    # message(paste0("module_directory: ", module_directory))
    
    message(paste0("include ", file_name, " from ", module_directory))
    
    # message(getwd())
    
    if (grepl("^\\.", module_directory, perl = TRUE)) {
      # message("File is in same dir")
      source(file_name)
      
    } else {
      # Need to change dir context before loading modules
      original_wd <- setwd(module_directory)
      
      source(file_name)
      
      # Then change back
      setwd(original_wd)
    }
    
    # message(getwd())
    
  } else {
    
    # Derived from https://stackoverflow.com/questions/47044068/get-the-path-of-current-script#answer-55322344
    current_script <- commandArgs() %>% 
      tibble::enframe(name = NULL) %>%
      tidyr::separate(col=value, into=c("key", "value"), sep="=", fill='right') %>%
      dplyr::filter(key == "-f" | key == "--file") %>%
      dplyr::pull(value)
    
    if (length(current_script)==0) {
      current_script <- rstudioapi::getSourceEditorContext()$path
    }
    
    call_path <- dirname(current_script)
    
    message(paste0("call_path: ", call_path))
    
    if (file.exists(paste0(call_path, "/", file_path))) {
    
      file_name <- basename(file_path)
      module_directory <- dirname(paste0(call_path, "/", file_path))
      # message(paste0("file_name: ", file_name))
      # message(paste0("module_directory: ", module_directory))
      
      message(paste0("include ", file_name, " from ", module_directory))
      
      # message(getwd())
      
      # Need to change dir context before loading modules
      original_wd <- setwd(module_directory)
      
      source(file_name)
      
      # Then change back
      setwd(original_wd)
      
      # message(getwd())
      
    } else {
      stop(paste0("Could not locate ", file_path, " relative to ", getwd()))
    }
  }
}
