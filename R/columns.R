# #' Create column definitions from data
# #' @param data (data.frame) data
# #' @param editor (bool): Whether to make columns editable.
# #' @param filter (bool): Whether to add a header filter to the columns.
# #' @returns list
# TODO: We do not need to export this func anymore
create_columns <- function(data, editor = FALSE, filter = FALSE) {
  data <- fix_colnames(data)
  dtype_is_numeric <- sapply(data, is.numeric)
  columns <- purrr::map(
    colnames(data),
    ~ list(
      title = .x,
      field = .x,
      hozAlign = as.vector(ifelse(dtype_is_numeric[.x], "right", "left"))
    )
  )
  if (isTRUE(editor)) {
    columns <- add_editor_to_columns(columns, data)
  }

  if (isTRUE(filter)) {
    columns <- add_filter_to_columns(columns)
  }

  return(columns)
}

fix_colnames <- function(data) {
  colnames(data) <- sub("\\.", "_", colnames(data))
  return(data)
}

set_auto_id <- function(data) {
  if ("id" %in% colnames(data)) {
    return(data)
  }

  if (nrow(data) == 0) {
    data$id <- numeric()
    return(data)
  }

  data$id <- seq(1:nrow(data))
  return(data)
}

# TODO: Add possibility to add editor to specific columns only
# TODO: Check if func is obsolete
add_editor_to_columns <- function(columns, data) {
  dtype_is_numeric <- sapply(data, is.numeric)
  for (index in 1:length(columns)) {
    columns[[index]]$editor <- as.vector(ifelse(dtype_is_numeric[index], "number", "input"))
  }

  return(columns)
}

# TODO: Check if func is obsolete
add_filter_to_columns <- function(columns) {
  for (index in 1:length(columns)) {
    columns[[index]]$headerFilter <- TRUE # detects column type automatically if editor type is set
  }

  return(columns)
}

#' Apply a column setter function to multiple columns
#' @inherit set_formatter_html params return
#' @param columns (character vector): The columns the column setter function (\code{.f}) is applied to.
#'  If set to \code{NULL},  it is applied to all columns.
#' @param .f (function): The column setter function that updates the column settings.
#' @param ... Arguments that are passed to \code{.f}.
#' @example examples/for_each_col.R
#' @export
for_each_col <- function(widget, columns = NULL, .f, ...) {
  if (is.null(columns)) columns <- colnames(widget$x$data)

  args <- list(...)

  for (column in columns) {
    widget <- do.call(.f, c(list(widget = widget, column = column), args))
  }

  return(widget)
}

# Formatters ####
# TODO: Move formatters to separate file

#' Set HTML formatter
#' @param widget A [tabulator()] HTML widget.
#' @param column The name of the column the formatter is applied to.
#' @param hoz_align (character): The horizontal alignment of the column.
#' @returns The updated [tabulator()] HTML widget
#' @example examples/formatters/formatter_html.R
#' @export
set_formatter_html <- function(widget, column, hoz_align = c("left", "center", "right")) {
  col_update <- list(formatter = "html", hozAlign = match.arg(hoz_align))
  modify_col_def(widget, column, col_update)
}

#' Set plain text formatter
#' @inherit set_formatter_html params return
#' @examples
#' tabulator(iris) |>
#'   set_formatter_plaintext("Species", hoz_align = "right")
#' @export
set_formatter_plaintext <- function(widget, column, hoz_align = "left") {
  col_update <- list(formatter = "plaintext", hozAlign = hoz_align)
  modify_col_def(widget, column, col_update)
}

#' Set text area formatter
#' @inherit set_formatter_html params return
#' @example examples/formatters/formatter_textarea.R
#' @export
set_formatter_textarea <- function(widget, column, hoz_align = "left") {
  col_update <- list(formatter = "textarea", hozAlign = hoz_align)
  modify_col_def(widget, column, col_update)
}

#' Set money formatter
#' @inherit set_formatter_html params return
#' @param decimal (character): Symbol to represent the decimal point.
#' @param thousand (character, bool): Symbol to represent the thousands separator.
#'  Set to \code{FALSE} to disable the separator.
#' @param symbol (character): The currency symbol.
#' @param symbol_after (bool): Whether to put the symbol after the number.
#' @param negative_sign (character, bool): The sign to show in front of the number.
#'  Set to \code{TRUE} causes negative numbers to be enclosed in brackets (123.45),
#'  which is the standard style for negative numbers in accounting.
#' @param precision (integer, bool): The number of decimals to display.
#'  Set to \code{FALSE} to display all decimals that are provided.
#' @example examples/formatters/formatter_money.R
#' @export
set_formatter_money <- function(
    widget,
    column,
    decimal = c(",", "."),
    thousand = c(".", ","),
    symbol = "$", # "\U20AC"
    symbol_after = "p",
    negative_sign = "-",
    precision = FALSE,
    hoz_align = "left") {
  # Body
  col_update <- list(
    formatter = "money",
    formatterParams = list(
      decimal = match.arg(decimal),
      thousand = match.arg(thousand),
      symbol = symbol,
      symbolAfter = symbol_after,
      negativeSign = negative_sign,
      precision = precision
    ),
    hozAlign = hoz_align
  )
  modify_col_def(widget, column, col_update)
}

#' Set image formatter
#' @inherit set_formatter_html params return
#' @param height (character): A CSS value for the height of the image.
#' @param width (character): A CSS value for the width of the image.
#' @param url_prefix (character): String to add to the start of the cell value
#'  when generating the image src url.
#' @param url_suffix (character): String to add to the end of the cell value
#'  when generating the image src url.
#' @example examples/formatters/formatter_image.R
#' @export
set_formatter_image <- function(
    widget,
    column,
    height = "50px",
    width = "50px",
    url_prefix = NULL,
    url_suffix = NULL,
    hoz_align = "center") {
  # Body
  col_update <- list(
    formatter = "image",
    formatterParams = compact(list(
      height = height,
      width = width,
      urlPrefix = url_prefix,
      urlSuffix = url_suffix
    )),
    hozAlign = hoz_align
  )
  modify_col_def(widget, column, col_update)
}

#' Set link formatter
#' @inherit set_formatter_html params return
#' @param label_field (character): Column to be used as label for the link.
#' @param url_prefix (character): Prefix to add to the URL value.
#' @param url (JavaScript function): A JavaScript function that return the URL value.
#'  The cell is passed to the function as its first argument.
#'  Use \link[htmlwidgets]{JS} to pass JS code.
#' @param target (character): Target attribute of the anchor tag.
#' @example examples/formatters/formatter_link.R
#' @export
set_formatter_link <- function(
    widget,
    column,
    label_field = NULL,
    url_prefix = NULL,
    url = NULL,
    target = "_blank",
    hoz_align = "left") {
  # Body
  col_update <- list(
    formatter = "link",
    formatterParams = compact(list(
      labelField = label_field,
      urlPrefix = url_prefix,
      url = url,
      target = target
    )),
    hozAlign = hoz_align
  )
  modify_col_def(widget, column, col_update)
}

#' Set star rating formatter
#' @inherit set_formatter_html params return
#' @param number_of_stars The maximum number of stars to be displayed.
#'  If set to \code{NA}, the maximum value of the column is used.
#' @example examples/formatters/formatter_star.R
#' @export
set_formatter_star <- function(widget, column, number_of_stars = NA, hoz_align = "center") {
  if (is.na(number_of_stars)) {
    number_of_stars <- max(widget$x$data[column])
  }

  col_update <- list(
    formatter = "star",
    formatterParams = list(stars = number_of_stars),
    hozAlign = hoz_align
  )
  modify_col_def(widget, column, col_update)
}

#' Set progress formatter
#' @inherit set_formatter_html params return
#' @param min (numeric): The minimum value for progress bar.
#'  If set to \code{NA}, the minimum value of the column is used.
#' @param max (numeric): The maximum value for progress bar.
#'  If set to \code{NA}, the maximum value of the column is used.
#' @param color (character): Either a single color or a vector of colors
#' @param legend (character, \code{TRUE}, JavaScript function): If set to \code{TRUE},
#'  the value of the cell is displayed. Set to \code{NA} to display no value at all.
#'  Use \link[htmlwidgets]{JS} to pass a JavaScript function as legend.
#'  In this case, the cell value is passed to the function as its first argument.
#' @param legend_color (character): The text color of the legend.
#' @param legend_align (character): The text alignment of the legend.
#' @example examples/formatters/formatter_progress.R
#' @export
set_formatter_progress <- function(
    widget,
    column,
    min = NA,
    max = NA,
    color = c("yellow", "orange", "red"),
    legend = NA,
    legend_color = "#000000",
    legend_align = c("center", "left", "right", "justify"),
    hoz_align = "left") {
  # Body
  if (is.na(min)) {
    min <- min(widget$x$data[column])
  }

  if (is.na(max)) {
    max <- max(widget$x$data[column])
  }

  col_update <- list(
    formatter = "progress",
    formatterParams = list(
      min = min,
      max = max,
      color = color,
      legend = legend,
      legendColor = legend_color,
      legendAlign = match.arg(legend_align)
    ),
    hozAlign = hoz_align
  )
  modify_col_def(widget, column, col_update)
}

#' Set tick cross formatter
#' @inherit set_formatter_html params return
#' @example examples/formatters/formatter_tick_cross.R
#' @export
set_formatter_tick_cross <- function(widget, column, hoz_align = "center") {
  col_update <- list(formatter = "tickCross", hozAlign = hoz_align)
  modify_col_def(widget, column, col_update)
}

#' Set toggle switch formatter
#' @inherit set_formatter_html params return
#' @param size (numeric): The size of the switch in pixels.
#' @param on_value (character): The value of the cell for the switch to be on.
#' @param off_value (character) The value of the cell for the switch to be off.
#' @param on_truthy (bool): Whether to show the switch as on if the value of the cell is truthy.
#' @param on_color (character): The color of the switch if it is on.
#' @param off_color (character): The color of the switch if it is off.
#' @param clickable (bool): Enable switch functionality to toggle the cell value on click.
#' @example examples/formatters/formatter_toggle_switch.R
#' @export
set_formatter_toggle_switch <- function(
    widget,
    column,
    size = 20,
    on_value = "on",
    off_value = "off",
    on_truthy = FALSE,
    on_color = "green",
    off_color = "red",
    clickable = TRUE) {
  # Body
  col_update <- list(
    formatter = "toggle",
    formatterParams = list(
      size = size,
      onValue = on_value,
      offValue = off_value,
      onTruthy = on_truthy,
      onColor = on_color,
      offColor = off_color,
      clickable = clickable
    )
  )
  modify_col_def(widget, column, col_update)
}

#' Set datetime formatter
#'
#' @details
#' To use this formatter, you need to include
#' the [luxon](https://moment.github.io/luxon/) HTML dependency with `tabulator(..., luxon = TRUE)`.
#' @inherit set_formatter_html params return
#' @param input_format (character): The datetime input format.
#' @param output_format (character): The datetime output format.
#' @param invalid_placeholder (character): The value to be displayed
#'  if an invalid datetime is provided.
#' @param timezone (character): The timezone of the datetime.
#' @example examples/formatters/formatter_datetime.R
#' @export
set_formatter_datetime <- function(
    widget,
    column,
    input_format = "yyyy-MM-dd hh:ss:mm",
    output_format = "yy/MM/dd",
    invalid_placeholder = "(invalid datetime)",
    timezone = NA,
    hoz_align = "left") {
  # Body
  col_update <- list(
    formatter = "datetime",
    formatterParams = list(
      inputFormat = input_format,
      outputFormat = output_format,
      invalidPlaceholder = invalid_placeholder,
      timezone = timezone
    ),
    hozAlign = hoz_align
  )
  modify_col_def(widget, column, col_update)
}

#' Set color formatter
#' @inherit set_formatter_html params return
#' @example examples/formatters/formatter_color.R
#' @export
set_formatter_color <- function(widget, column) {
  col_update <- list(formatter = "color")
  modify_col_def(widget, column, col_update)
}

#' Set traffic light formatter
#' @inherit set_formatter_progress params return
#' @example examples/formatters/formatter_traffic_light.R
#' @export
set_formatter_traffic_light <- function(
    widget,
    column,
    min = NA,
    max = NA,
    color = c("green", "orange", "red"),
    hoz_align = "center") {
  # Body
  if (is.na(min)) min <- min(widget$x$data[column])

  if (is.na(max)) max <- max(widget$x$data[column])

  col_update <- list(
    formatter = "traffic",
    formatterParams = list(
      min = min,
      max = max,
      color = color
    ),
    hozAlign = hoz_align
  )
  modify_col_def(widget, column, col_update)
}

# Other

# TODO: Deprecated
# #' Make columns editable
# #' @inheritParams set_formatter_html
# #' @param columns (character vector): Columns the editor is applied to.
# #' @param type (character): Either \code{input} or \code{number}.
# #' @example examples/formatters/column_editor.R
set_column_editor <- function(widget, columns, type = c("input", "number")) {
  col_update <- list(editor = match.arg(type))
  for (column in columns) {
    widget <- modify_col_def(widget, column, col_update)
  }

  return(widget)
}

#' Set editor
#' @inherit set_formatter_html params return
#' @param editor (character): The editor type.
#' @param validator (character vector): One or more validators to validate user input.
#' @param ... Optional editor parameters depending on the selected editor.
#' @seealso
#'  * \url{https://tabulator.info/docs/6.2/edit} for available editors
#'  * \url{https://tabulator.info/docs/6.2/validate} for available validators
#' @md
#' @example examples/editors.R
#' @export
set_editor <- function(
    widget,
    column,
    editor = c(
      "input", "textarea", "number", "range",
      "tickCross", "star", "progress", "date", "time", "datetime", "list"
    ),
    validator = NULL,
    ...) {
  # Body
  col_update <- list(editor = match.arg(editor), validator = validator)
  editor_params <- list(...)
  if (length(editor_params) > 0) {
    col_update$editorParams <- keys_to_camel_case(compact(editor_params))
  }

  modify_col_def(widget, column, col_update)
}

#' Set header filter
#' @inherit set_formatter_html params return
#' @param type (character): The type of the filter.
#' @param values_lookup (bool): Whether to use unique column values for the list filter.
#' @param func (character): The filter function.
#' @param clearable (bool): Whether to display a cross to clear the filter.
#' @param placeholder (character): Text that is displayed when no filter is set.
#' @example examples/misc/header_filter.R
#' @export
# TODO: Rename to params that they match params used by Tabulator JS
set_header_filter <- function(
    widget,
    column,
    # TODO: Rename to 'filter_type' or just 'filter' or 'header_filter'?
    type = c("input", "number", "list", "tickCross"),
    # TODO: Rename to 'filter_func'?
    func = c("like", "=", ">", ">=", "<", "<="),
    values_lookup = TRUE,
    clearable = TRUE,
    placeholder = NULL) {
  # Body
  if (is.null(type)) {
    type <- ifelse(is.numeric(widget$x$data[, column]), "number", "input")
  } else {
    type <- match.arg(type)
  }

  header_filter_params <- compact(list(
    clearable = clearable,
    valuesLookup = values_lookup
  ))
  col_update <- list(
    headerFilter = type,
    headerFilterPlaceholder = placeholder,
    headerFilterFunc = func,
    headerFilterParams = header_filter_params
  )
  modify_col_def(widget, column, col_update)
}

#' Set tooltip
#' @inherit set_formatter_html params return
#' @example examples/misc/tooltip.R
#' @export
set_tooltip <- function(widget, column) {
  modify_col_def(widget, column, list(tooltip = TRUE))
}


#' Set column defaults
#' @inherit set_formatter_html params return
#' @param editor (character, bool): One of \code{"input"} or \code{"number"}.
#'  If set to \code{FALSE} cells are not editable.
#' @param header_filter (character, bool): One of \code{"input"} or \code{"number"}.
#'  Set to \code{FALSE} to disable header filters.
#' @param header_sort (bool): Whether to enable header sorting.
#' @param tooltip (bool): Whether to show tooltips displaying the cell value.
#' @param width (integer): Fixed width of columns.
#' @param ... Additional settings.
#' @seealso \url{https://tabulator.info/docs/6.2/columns#defaults}
#' @example examples/column_defaults.R
#' @export
set_column_defaults <- function(
    widget,
    editor = FALSE,
    header_filter = FALSE,
    header_sort = TRUE,
    tooltip = TRUE,
    width = NULL,
    ...) {
  # Body
  widget$x$options$columnDefaults <- compact(list(
    editor = editor,
    headerFilter = header_filter,
    headerSort = header_sort,
    tooltip = tooltip,
    width = width,
    ...
  ))
  return(widget)
}

#' Set calculation
#' @inherit set_formatter_html params return
#' @param column (character): The column the \code{func} is applied to.
#' @param func (character): The calculation function to be applied
#'  to the values of the \code{column}.
#' @param precision (integer)  The number of decimals to display.
#'  Set to \code{FALSE} to display all decimals.
#' @param pos (character): Position at which calculated values are displayed.
#' @examples
#' tabulator(iris) |>
#'   set_calculation("Sepal_Length", "avg")
#' @export
set_calculation <- function(
    widget,
    column,
    func = c("avg", "max", "min", "sum", "count", "unique"), # Rename to 'calc'?
    precision = 2,
    pos = c("top", "bottom")) {
  # Body
  pos <- match.arg(pos)
  col_update <- list(match.arg(func), list(precision = precision))
  names(col_update) <- c(paste0(pos, "Calc"), paste0(pos, "CalcParams"))
  modify_col_def(widget, column, col_update)
}

# Generics

modify_col_def <- function(widget, column, col_update) {
  for (index in 1:length(widget$x$options$columns)) {
    if (widget$x$options$columns[[index]]$field == column) {
      widget$x$options$columns[[index]] <- utils::modifyList(
        widget$x$options$columns[[index]], col_update
      )
    }
  }

  return(widget)
}
