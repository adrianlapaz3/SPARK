% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/coefficients_c.R
\name{coefficients_c}
\alias{coefficients_c}
\title{Coefficients c}
\usage{
coefficients_c(name_band, coeffs)
}
\arguments{
\item{name_band}{The name band}

\item{coeffs}{The coefficients c are 1, 0, and -1 in a vector. Each of these coefficients is used to multiply each band in iteration i (see figure in the document).}
}
\value{
Matrix with the coefficients c
}
\description{
Coefficients c
}
\examples{
band_name = c("B2", "B3")
coefficients = c(1,0,-1)
coefficients_c(band_name,coefficients)

}
