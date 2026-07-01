#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

usage <- function() {
  cat(
    "Usage:\n",
    "  Rscript exec/run_pubmed_search.R --include INCLUDE.txt [--exclude EXCLUDE.txt] --output results.csv [options]\n\n",
    "Options:\n",
    "  --no-chunk       Submit the include query as one query instead of splitting top-level OR terms.\n",
    "  --limit N        Run only the first N chunks. Useful for smoke tests.\n",
    "  --sleep SECONDS  Pause between chunk queries.\n",
    "  --quiet          Suppress progress messages.\n",
    sep = ""
  )
}

parse_args <- function(args) {
  parsed <- list(chunk = TRUE, limit = Inf, sleep = 0, verbose = TRUE)
  i <- 1L

  while (i <= length(args)) {
    arg <- args[[i]]

    if (identical(arg, "--no-chunk")) {
      parsed$chunk <- FALSE
      i <- i + 1L
    } else if (identical(arg, "--quiet")) {
      parsed$verbose <- FALSE
      i <- i + 1L
    } else if (arg %in% c("--include", "--exclude", "--output", "--limit", "--sleep")) {
      if (i == length(args)) {
        stop("Missing value for ", arg, call. = FALSE)
      }
      value <- args[[i + 1L]]
      name <- substring(arg, 3L)
      parsed[[name]] <- value
      i <- i + 2L
    } else if (arg %in% c("--help", "-h")) {
      usage()
      quit(status = 0)
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }

  parsed
}

file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (length(file_arg) > 0L) {
  sub("^--file=", "", file_arg[[1]])
} else {
  "exec/run_pubmed_search.R"
}
repo_root <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)

source_dir <- file.path(repo_root, "R")
if (dir.exists(source_dir)) {
  for (file in list.files(source_dir, pattern = "\\.R$", full.names = TRUE)) {
    source(file)
  }
} else {
  suppressPackageStartupMessages(library(pubmedsearchworkflow))
}

parsed <- parse_args(args)
if (is.null(parsed$include) || is.null(parsed$output)) {
  usage()
  stop("--include and --output are required.", call. = FALSE)
}

parsed$limit <- as.numeric(parsed$limit)
parsed$sleep <- as.numeric(parsed$sleep)

include_query <- read_pubmed_query(parsed$include)
exclude_query <- if (is.null(parsed$exclude)) NULL else read_pubmed_query(parsed$exclude)

results <- run_pubmed_search(
  include_query = include_query,
  exclude_query = exclude_query,
  chunk = parsed$chunk,
  limit = parsed$limit,
  sleep = parsed$sleep,
  verbose = parsed$verbose
)

data <- write_pubmed_csv(results, parsed$output, verbose = parsed$verbose)

if (isTRUE(parsed$verbose)) {
  pubmed_report_info(
    "Output columns: {count}.",
    count = length(names(data)),
    verbose = parsed$verbose
  )
}
