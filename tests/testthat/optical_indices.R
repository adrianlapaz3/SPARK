
#' Optical_indices
#'
#' @param data Data with observed variable and optical bands 
#' @param y Observed variable
#' @param n_bands Number of optical bands to be combined for vegetation indices calculated from combinations of spectral bands
#' @param set_bands Names of spectral bands
#' @param scan Scan increases the number of selected vegetation indices, as each time the best correlation is saved, it is multiplied by scan (around 0.95-1)
#'
#' @return Selected vegetation indices according to correlation with the observed variable
#' @export
#'
#' @examples
#' maize_data = SPARK::maize
#' V10 = maize_data[maize_data$Stage == "V10", ]
#' bands_names <- c("B2", "B3", "B4", "B5", "B6", "B7", "B8", "B8A", "B11", "B12")
#' NNI_V10_VIs = optical_indices(
#' data = V10, 
#' y = V10["NNI"], 
#' n_bands= 4, 
#' set_bands = bands_names, 
#' scan = 0.995
#' )
#' 
#' 
optical_indices <- function(data, y, n_bands, set_bands, scan = FALSE) {
  if (scan == FALSE){scan = 1}
  VIs <- NULL
  names_list <- NULL
  maximum  <- 0
  
  dividend = y
  divisor = y
  
  max_cor <- -Inf
  coefs = c(1,0,-1)
  
  combinations <- combn(set_bands, n_bands, simplify = FALSE)    
  
  for (bands in combinations) {
    if (all(bands %in% names(data))) {
      data_subset <- data[, bands, drop = FALSE]
      coef_combinations <- coefficients_c(bands, coefs)
      setbands <- band_summations(data_subset, coef_combinations)
      n = ncol(setbands)
      for (i in 1:(n-1)) {
        VI <- setbands[, i] / setbands[, i:n]
        cor_vals <- suppressWarnings(abs(cor(y, VI[, -1], use="complete.obs",method = 'pearson')))
        cor_vals[is.nan(cor_vals)] <- 0
        significant_band <- which.max(cor_vals) + i  
        max_cor_val = cor_vals[significant_band-i]
        
        if (max_cor_val > max_cor){
          VIs <- cbind(VIs, setbands[, i]/setbands[, significant_band])
          name = paste(colnames(setbands[i]), "_div_", colnames(setbands[significant_band]), sep = "")
          names_list <- c(names_list, name)
          max_cor = max_cor_val*scan
          if (max_cor_val > maximum) {maximum = max_cor_val }
        }
        
      }
    }
  }
  
  maximum = round(maximum, 2)
  print(paste("A total of", ncol(VIs), "Vegetation indices were identified, which achieved a maximum Pearson correlation coefficient of", maximum))
  VIs = data.frame(VIs)
  colnames(VIs) <- names_list
  return(VIs)
}
