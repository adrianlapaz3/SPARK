#' Coefficients c
#' 
#' @param bands The bands
#' @param coefs The coefficients c are 1, 0, and -1 in a vector. Each of these coefficients is used to multiply each band in iteration i (see figure in the document).
#'
#' @return Matrix with the coefficients c
#' 
#' @importFrom stats cor
#' 
#' @importFrom utils combn
#' @export
#'
#' @examples
#' B2 = c(0.2, 0.7, 0.5)
#' B3 = c(0.4, 0.2, 0.6)
#' spectral_bands = cbind(B2, B3)
#' band_name = c("B2", "B3")
#' coefficients = c(1,0,-1)
#' coefficients_c(band_name,coefficients)

coefficients_c <- function(bands, coefs) {
  # Create a data frame with all possible combinations of the specified coefficients for each spectral band. 
  # 'expand.grid' creates a data frame with all possible combinations of the specified vectors or factors
  all_combinations <- expand.grid(rep(list(coefs), length(bands)))
  
  # Remove combinations where all coefficients are zero
  # This is done with 'subset' to filter out rows where the sum of the zeros in each row is less than or 
  # equal to the length of the bands minus one
  valid_combinations <- subset(all_combinations, rowSums(all_combinations == 0) <= length(bands) - 1)
  
  # Create names for each combination by assigning coefficients to the bands
  # A combination with -1 for band B2 is called "-1_B2", for example
  combo_names <- apply(valid_combinations, 1, function(row) paste0(row, bands, collapse="_"))
  
  # Transpose the matrix of valid combinations to arrange the combinations correctly
  t_valid_combinations <- t(as.matrix(valid_combinations))
  
  # Assign column names to the transposed matrix by using the generated names
  colnames(t_valid_combinations) <- combo_names
  
  return(t_valid_combinations)
}
