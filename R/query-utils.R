read_pubmed_query <- function(path) {
  if (!file.exists(path)) {
    stop("Query file does not exist: ", path, call. = FALSE)
  }

  normalize_pubmed_query(readLines(path, warn = FALSE, encoding = "UTF-8"))
}

normalize_pubmed_query <- function(query) {
  query <- paste(query, collapse = " ")
  query <- gsub("[\r\n\t]+", " ", query)
  query <- gsub("[[:space:]]+", " ", query)
  trimws(query)
}

build_pubmed_query <- function(include_query, exclude_query = NULL) {
  include_query <- normalize_pubmed_query(include_query)

  if (is.null(exclude_query) || identical(trimws(exclude_query), "")) {
    return(include_query)
  }

  exclude_query <- normalize_pubmed_query(exclude_query)
  paste0("(", include_query, ") NOT (", exclude_query, ")")
}

split_pubmed_or_query <- function(query) {
  query <- normalize_pubmed_query(query)
  if (identical(query, "")) {
    return(character())
  }

  chars <- strsplit(query, "", fixed = TRUE)[[1]]
  parts <- character()
  start <- 1L
  depth <- 0L
  in_quote <- FALSE
  i <- 1L

  while (i <= length(chars)) {
    char <- chars[[i]]

    if (identical(char, "\"") && (i == 1L || !identical(chars[[i - 1L]], "\\"))) {
      in_quote <- !in_quote
    }

    if (!in_quote) {
      if (identical(char, "(")) {
        depth <- depth + 1L
      } else if (identical(char, ")")) {
        depth <- max(0L, depth - 1L)
      }

      if (
        depth == 0L &&
          i + 3L <= length(chars) &&
          identical(paste(chars[i:(i + 3L)], collapse = ""), " OR ")
      ) {
        parts <- c(parts, trimws(paste(chars[start:(i - 1L)], collapse = "")))
        start <- i + 4L
        i <- i + 4L
        next
      }
    }

    i <- i + 1L
  }

  parts <- c(parts, trimws(paste(chars[start:length(chars)], collapse = "")))
  parts[nzchar(parts)]
}
