#' optical_Ns_indices
#'
#' @param data Data with observed variable, optical bands, and soil nitrogen (Ns, if another variable is used, as Lidar, the name should be Ns)
#' @param y Observed variable
#' @param n_bands Number of optical bands to be combined for vegetation indices calculated from combinations of spectral bands and SAR backscatter
#' @param set_bands Names of spectral bands and SAR backscatter
#' @param scan Scan increases the number of selected vegetation indices, as each time the best correlation is saved, it is multiplied by scan (around 0.95-1)
#'
#' @return Selected vegetation indices according to correlation with the observed variable
#' @export
#'
#' @examples
#' maize_data = SPARK::maize
#' V10 = maize_data[maize_data$Stage == "V10", ]
#' bands_names <- c("B2", "B3", "B4", "B5", "B6", "B7", "B8", "B8A", "B11", "B12", "Ns")
#' NNI_V10_VIs = optical_Ns_indices(
#'   data = V10, 
#'   y = V10["NNI"], 
#'   n_bands= 4, 
#'   set_bands = bands_names, 
#'   scan = 0.995
#' )
#' 
optical_Ns_indices <- function(data, y, n_bands, set_bands, scan = FALSE) {
  if (scan == FALSE) { scan = 1 }
  VIs <- NULL
  names_list <- NULL
  maximum <- 0
  
  max_cor <- -Inf
  coefs = c(1, 0, -1)
  
  combinations <- combn(set_bands, n_bands, simplify = FALSE)
  combinations <- Filter(function(bands) any(grepl("Ns", bands)), combinations)
  
  for (bands in combinations) {
    
    data_subset <- data[, bands, drop = FALSE]
    
    if (all(bands %in% names(data))) {
      coef_combinations <- coefficients_c(bands, coefs)
      setbands <- band_summations(data_subset, coef_combinations)
      n = ncol(setbands)
      
      for (i in 1:(n-1)) {
        for (j in (i+1):n) {
          if (grepl("1Ns", colnames(setbands)[i]) || grepl("1Ns", colnames(setbands)[j])) {
            VI <- setbands[, i] / setbands[, j]
            cor_val <- suppressWarnings(abs(cor(y, VI, use = "complete.obs")))
            
            if (!is.na(cor_val) && cor_val > max_cor) {
              VIs <- cbind(VIs, VI)
              name <- paste(colnames(setbands)[i], "_div_", colnames(setbands)[j], sep = "")
              names_list <- c(names_list, name)
              max_cor <- cor_val * scan
              if (cor_val > maximum) { maximum <- cor_val }
            }
          }
        }
      }
    }
    
  }
  
  maximum <- round(maximum, 2)
  print(paste("A total of", ncol(VIs), "vegetation indices were identified, which achieved a maximum Pearson correlation coefficient of", maximum))
  VIs <- data.frame(VIs)
  colnames(VIs) <- names_list
  return(VIs)
}