#' Band summations
#'
#' @param bands Band summations as a result of multiplying the bands by the coefficients
#' @param coefficients_c The coefficients c
#'
#' @return
#' @export
#'
#' @examples
#' B2 = c(0.2, 0.7, 0.5)
#' B3 = c(0.4, 0.2, 0.6)
#' spectral_bands = cbind(B2, B3)
#' coefficients = cbind(
#'  "1B2_1B3" = c(1, 1),
#'  "0B2_1B3" = c(0, 1),
#'  "-1B2_1B3" = c(-1, 1),
#'  "1B2_0B3" = c(1, 0)
#' )
#' band_summations(spectral_bands, coefficients)
#' 
band_summations <- function(bands, coefficients_c) {
  # matrix with the bands
  band_matrix <- as.matrix(bands) 
  
  # multiplying the bands by the coefficients c
  summations <- band_matrix %*% coefficients_c 
  summations_df <- as.data.frame(summations)
  colnames(summations_df) <- colnames(coefficients_c)
  return(summations_df)
}
