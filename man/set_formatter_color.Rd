% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/columns.R
\name{set_formatter_color}
\alias{set_formatter_color}
\title{Set color formatter}
\usage{
set_formatter_color(widget, column)
}
\arguments{
\item{widget}{A \code{\link[=tabulator]{tabulator()}} HTML widget.}

\item{column}{The name of the column the formatter is applied to.}
}
\value{
The updated \code{\link[=tabulator]{tabulator()}} HTML widget
}
\description{
Set color formatter
}
\examples{
data <- data.frame(
  Label = c("R", "G", "B"),
  Color = c("red", "green", "blue")
)

tabulator(data, width = 200) |>
  set_formatter_color("Color")
}
