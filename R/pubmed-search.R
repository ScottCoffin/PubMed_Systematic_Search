query_pubmed <- function(query, fetch = TRUE, parse = TRUE, format = "xml", verbose = TRUE) {
  query <- normalize_pubmed_query(query)
  if (identical(query, "")) {
    pubmed_abort("PubMed query is empty.")
  }

  if (verbose) {
    pubmed_report_info(
      "Submitting PubMed query: {query}",
      query = pubmed_format_value(abbreviate_query(query)),
      verbose = verbose
    )
  }

  result <- with_pubmed_error_context(
    run_pubmed_step(easyPubMed::epm_query(query), verbose = verbose),
    phase = "submit query",
    query = query
  )
  expected_count <- pubmed_result_count(result)

  if (!is.na(expected_count) && expected_count == 0L) {
    if (verbose) {
      pubmed_report_warning("No records found; skipping fetch/parse.", verbose = verbose)
    }
    return(result)
  }

  if (verbose && !is.na(expected_count)) {
    pubmed_report_success(
      "PubMed reports {count} matching {record_label}.",
      count = expected_count,
      record_label = pluralize_n("record", expected_count),
      verbose = verbose
    )
  }

  if (fetch) {
    if (verbose) {
      pubmed_report_info(
        "Fetching records as {format}.",
        format = pubmed_format_value(format),
        verbose = verbose
      )
    }
    result <- with_pubmed_error_context(
      run_pubmed_step(easyPubMed::epm_fetch(result, format = format), verbose = verbose),
      phase = "fetch records",
      query = query
    )
  }

  if (parse) {
    if (verbose) {
      pubmed_report_info("Parsing PubMed records.", verbose = verbose)
    }
    result <- with_pubmed_error_context(
      run_pubmed_step(easyPubMed::epm_parse(result), verbose = verbose),
      phase = "parse records",
      query = query
    )
  }

  result
}

run_pubmed_search <- function(include_query,
                              exclude_query = NULL,
                              chunk = TRUE,
                              limit = Inf,
                              sleep = 0,
                              verbose = TRUE) {
  include_query <- normalize_pubmed_query(include_query)
  exclude_query <- if (is.null(exclude_query)) NULL else normalize_pubmed_query(exclude_query)

  include_chunks <- if (isTRUE(chunk)) split_pubmed_or_query(include_query) else include_query
  if (length(include_chunks) == 0L) {
    pubmed_abort("No include query terms were found.")
  }

  if (is.finite(limit)) {
    include_chunks <- utils::head(include_chunks, limit)
  }

  queries <- vapply(include_chunks, build_pubmed_query, character(1), exclude_query = exclude_query)

  if (verbose) {
    pubmed_report_header("PubMed systematic search", verbose = verbose)
    pubmed_report_info(
      "Prepared {count} query {chunk_label}.",
      count = length(queries),
      chunk_label = pluralize_n("chunk", length(queries)),
      verbose = verbose
    )
    pubmed_report_info(
      "Chunking: {chunking}.",
      chunking = pubmed_format_value(if (isTRUE(chunk)) "enabled" else "disabled"),
      verbose = verbose
    )
  }

  results <- vector("list", length(queries))

  for (i in seq_along(queries)) {
    query_label <- sprintf("chunk %d of %d", i, length(queries))
    if (verbose) {
      pubmed_report_step(paste("Querying", query_label), verbose = verbose)
      pubmed_report_info(
        "Query preview: {query}",
        query = pubmed_format_value(abbreviate_query(queries[[i]], width = 80L)),
        verbose = verbose
      )
    }
    results[[i]] <- tryCatch(
      query_pubmed(queries[[i]], verbose = verbose),
      error = function(err) {
        pubmed_abort(
          c(
            "PubMed search failed.",
            "x" = paste0("Failed at ", query_label, "."),
            "i" = paste0("Query preview: ", abbreviate_query(queries[[i]])),
            "i" = paste0("Underlying error: ", conditionMessage(err))
          ),
          parent = err
        )
      }
    )
    if (verbose) {
      pubmed_report_success("Completed {query_label}.", query_label = query_label, verbose = verbose)
    }
    if (sleep > 0 && i < length(queries)) {
      if (verbose) {
        pubmed_report_info(
          "Sleeping for {seconds} before the next chunk.",
          seconds = paste(sleep, pluralize_n("second", sleep)),
          verbose = verbose
        )
      }
      Sys.sleep(sleep)
    }
  }

  names(results) <- paste0("chunk_", seq_along(results))
  attr(results, "queries") <- queries
  if (verbose) {
    pubmed_report_success(
      "Finished {count} query {chunk_label}.",
      count = length(results),
      chunk_label = pluralize_n("chunk", length(results)),
      verbose = verbose
    )
  }
  results
}

combine_pubmed_data <- function(results, dedupe_by = "pmid") {
  if (!is.list(results) || is.data.frame(results)) {
    results <- list(results)
  }

  data_frames <- Filter(
    function(x) is.data.frame(x) && nrow(x) > 0L,
    lapply(results, pubmed_data_frame)
  )

  if (length(data_frames) == 0L) {
    return(data.frame())
  }

  all_names <- unique(unlist(lapply(data_frames, names), use.names = FALSE))
  data_frames <- lapply(data_frames, align_columns, all_names = all_names)
  combined <- do.call(rbind, data_frames)
  rownames(combined) <- NULL

  if (!is.null(dedupe_by) && dedupe_by %in% names(combined)) {
    before_dedupe <- nrow(combined)
    combined <- combined[!duplicated(combined[[dedupe_by]]), , drop = FALSE]
    rownames(combined) <- NULL
    attr(combined, "duplicates_removed") <- before_dedupe - nrow(combined)
  }

  combined
}

write_pubmed_csv <- function(results, path, dedupe_by = "pmid", verbose = TRUE) {
  data <- combine_pubmed_data(results, dedupe_by = dedupe_by)
  output_dir <- dirname(path)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  utils::write.csv(data, path, row.names = FALSE)
  if (isTRUE(verbose)) {
    pubmed_report_success(
      "Wrote {count} unique {record_label} to {path}.",
      count = nrow(data),
      record_label = pluralize_n("record", nrow(data)),
      path = pubmed_format_value(path, "path"),
      verbose = verbose
    )
  }
  invisible(data)
}

pubmed_result_count <- function(result) {
  if (!isS4(result) || !"meta" %in% methods::slotNames(result)) {
    return(NA_integer_)
  }

  meta <- result@meta
  if (is.list(meta) && "exp_count" %in% names(meta)) {
    return(as.integer(meta$exp_count))
  }

  NA_integer_
}

pubmed_data_frame <- function(result) {
  if (is.data.frame(result)) {
    return(result)
  }

  if (!isS4(result) || !"data" %in% methods::slotNames(result)) {
    return(data.frame())
  }

  data <- result@data
  if (is.null(data) || length(data) == 0L) {
    return(data.frame())
  }

  as.data.frame(data)
}

abbreviate_query <- function(query, width = 120L) {
  query <- normalize_pubmed_query(query)
  if (nchar(query) <= width) {
    return(query)
  }

  paste0(substr(query, 1L, width - 3L), "...")
}

align_columns <- function(data, all_names) {
  missing_names <- setdiff(all_names, names(data))
  for (name in missing_names) {
    data[[name]] <- NA
  }

  data[, all_names, drop = FALSE]
}

with_pubmed_error_context <- function(expr, phase, query) {
  tryCatch(
    expr,
    error = function(err) {
      pubmed_abort(
        c(
          paste0("Failed to ", phase, "."),
          "i" = paste0("Query preview: ", abbreviate_query(query)),
          "i" = paste0("Underlying error: ", conditionMessage(err))
        ),
        parent = err
      )
    }
  )
}

pubmed_abort <- function(message, parent = NULL) {
  message <- pubmed_format_error(message)
  cli::cli_abort(message, class = "pubmedsearchworkflow_error", parent = parent)
}

pubmed_format_error <- function(message) {
  if (is.character(message)) {
    return(stats::setNames(
      pubmed_style(unname(message), "error"),
      names(message)
    ))
  }

  message
}

pluralize_n <- function(word, n) {
  if (identical(as.numeric(n), 1)) {
    return(word)
  }

  paste0(word, "s")
}

run_pubmed_step <- function(expr, verbose = TRUE) {
  if (isTRUE(verbose)) {
    return(force(expr))
  }

  stdout_file <- tempfile("pubmed_stdout_")
  message_file <- tempfile("pubmed_message_")
  stdout_con <- file(stdout_file, open = "wt")
  message_con <- file(message_file, open = "wt")

  sink(stdout_con)
  sink(message_con, type = "message")
  on.exit({
    if (sink.number(type = "message") > 0L) {
      sink(type = "message")
    }
    if (sink.number() > 0L) {
      sink()
    }
    close(stdout_con)
    close(message_con)
    unlink(c(stdout_file, message_file))
  }, add = TRUE)

  force(expr)
}
