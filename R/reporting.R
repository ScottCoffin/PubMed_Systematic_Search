pubmed_report_header <- function(text, verbose = TRUE) {
  if (!isTRUE(verbose)) {
    return(invisible(NULL))
  }

  cli::cat_line()
  cli::cat_line(pubmed_style(paste0("== ", text, " =="), "header"))
  cli::cat_line()
  invisible(NULL)
}

pubmed_report_step <- function(text, verbose = TRUE) {
  if (!isTRUE(verbose)) {
    return(invisible(NULL))
  }

  cli::cat_line()
  cli::cat_line(pubmed_style(paste0("-- ", text, " --"), "step"))
  invisible(NULL)
}

pubmed_report_info <- function(text, ..., verbose = TRUE) {
  pubmed_report_line("info", text, ..., verbose = verbose)
}

pubmed_report_success <- function(text, ..., verbose = TRUE) {
  pubmed_report_line("success", text, ..., verbose = verbose)
}

pubmed_report_warning <- function(text, ..., verbose = TRUE) {
  pubmed_report_line("warning", text, ..., verbose = verbose)
}

pubmed_report_line <- function(level, text, ..., verbose = TRUE) {
  if (!isTRUE(verbose)) {
    return(invisible(NULL))
  }

  values <- list(...)
  text <- interpolate_report_text(text, values)
  prefix <- switch(
    level,
    info = pubmed_style("i", "info"),
    success = pubmed_style("v", "success"),
    warning = pubmed_style("!", "warning"),
    pubmed_style("-", "muted")
  )
  text <- switch(
    level,
    success = pubmed_style(text, "success"),
    warning = pubmed_style(text, "warning"),
    error = pubmed_style(text, "error"),
    text
  )

  cli::cat_line(paste(prefix, text))
  invisible(NULL)
}

pubmed_format_value <- function(value, style = "field") {
  pubmed_style(as.character(value), style)
}

pubmed_style <- function(text, style = "plain") {
  text <- as.character(text)
  if (!pubmed_should_color()) {
    return(text)
  }

  old <- options(crayon.enabled = TRUE)
  on.exit(options(old), add = TRUE)

  switch(
    style,
    header = crayon::bold(pubmed_crayon("blue")(text)),
    step = crayon::bold(pubmed_crayon("cyan")(text)),
    info = pubmed_crayon("blue")(text),
    success = pubmed_crayon("green")(text),
    warning = pubmed_crayon("#FFA500")(text),
    error = pubmed_crayon("red")(text),
    field = pubmed_crayon("cyan")(text),
    path = pubmed_crayon("magenta")(text),
    muted = pubmed_crayon("gray")(text),
    text
  )
}

pubmed_crayon <- function(color) {
  crayon::make_style(color, colors = 256)
}

pubmed_should_color <- function() {
  opt <- getOption("pubmedsearchworkflow.use_color")
  if (!is.null(opt)) {
    return(isTRUE(opt))
  }

  crayon::has_color()
}

interpolate_report_text <- function(text, values) {
  if (length(values) == 0L) {
    return(text)
  }

  for (name in names(values)) {
    text <- gsub(
      paste0("{", name, "}"),
      as.character(values[[name]]),
      text,
      fixed = TRUE
    )
  }

  text
}
