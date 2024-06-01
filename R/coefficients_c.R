#' Coefficients c
#' 
#' @param name_band The name band
#' @param coeffs The coefficients c are 1, 0, and -1 in a vector. Each of these coefficients is used to multiply each band in iteration i (see figure in the document).
#'
#' @return Matrix with the coefficients c
#' 
#' @importFrom stats cor
#' 
#' @importFrom utils combn
#' @export
#'
#' @examples
#' band_name = c("B2", "B3")
#' coefficients = c(1,0,-1)
#' coefficients_c(band_name,coefficients)

coefficients_c <- function(name_band, coeffs) {
  # Create a data frame with all possible combinations of the coefficients c for each spectral band. 
  # 'expand.grid' creates a data frame with all possible combinations of the coefficients c and name band
  all_combinations <- expand.grid(rep(list(coeffs), length(name_band)))
  
  # Select the first half of the rows (rounded down)
  num_rows <- nrow(all_combinations)
  half_rows <- floor(num_rows / 2)
  coeff_combinations <- all_combinations[1:half_rows, ]
  
  # Create names for each combination by assigning coefficients to the name band
  # For example, merge the coefficient -1 with name band B2 is "-1_B2"
  coeff_names <- apply(coeff_combinations, 1, function(row) paste0(row, name_band, collapse="_"))
  
  # Transpose the matrix of coeff_names to arrange the combinations correctly
  t_coeff_combinations <- t(as.matrix(coeff_combinations))
  
  # Assign the column names of the coefficient values c to the transposed matrix
  colnames(t_coeff_combinations) <- coeff_names
  
  return(t_coeff_combinations)
}

