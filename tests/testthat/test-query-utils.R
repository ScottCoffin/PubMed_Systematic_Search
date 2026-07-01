test_that("normalize_pubmed_query collapses whitespace", {
  expect_equal(normalize_pubmed_query(c("alpha\r\n", "  OR\tbeta ")), "alpha OR beta")
})

test_that("read_pubmed_query reads and normalizes files", {
  path <- tempfile(fileext = ".txt")
  writeLines(c("alpha", " OR beta"), path)

  expect_equal(read_pubmed_query(path), "alpha OR beta")
  expect_error(read_pubmed_query("missing-query-file.txt"), "does not exist")
})

test_that("build_pubmed_query combines include and exclude terms", {
  expect_equal(
    build_pubmed_query('"alpha"[Title]', '"beta"[Title]'),
    '("alpha"[Title]) NOT ("beta"[Title])'
  )
})

test_that("split_pubmed_or_query splits only top-level OR operators", {
  query <- '("a"[Title] AND ("b"[Title] OR "c"[Title])) OR "d OR e"[Title] OR "f"[Title]'
  expect_equal(
    split_pubmed_or_query(query),
    c('("a"[Title] AND ("b"[Title] OR "c"[Title]))', '"d OR e"[Title]', '"f"[Title]')
  )
  expect_equal(split_pubmed_or_query(""), character())
})

test_that("empty queries fail with package error class", {
  expect_error(query_pubmed(""), class = "pubmedsearchworkflow_error")
})

test_that("combine_pubmed_data aligns columns and deduplicates PMIDs", {
  results <- list(
    data.frame(pmid = c("1", "2"), title = c("a", "b")),
    data.frame(pmid = c("2", "3"), doi = c("doi-b", "doi-c"))
  )

  combined <- combine_pubmed_data(results)

  expect_equal(combined$pmid, c("1", "2", "3"))
  expect_true(all(c("title", "doi") %in% names(combined)))
  expect_equal(attr(combined, "duplicates_removed"), 1L)
})

test_that("write_pubmed_csv creates parent directories and writes records", {
  output <- file.path(tempdir(), "pubmedsearchworkflow-test", "records.csv")
  if (file.exists(output)) {
    unlink(output)
  }

  data <- write_pubmed_csv(
    list(data.frame(pmid = "1", title = "Example")),
    output,
    verbose = FALSE
  )

  expect_true(file.exists(output))
  expect_equal(nrow(data), 1L)
  expect_equal(read.csv(output)$pmid, 1L)
})

test_that("internal formatting helpers return stable values", {
  long_query <- paste(rep("alpha", 40), collapse = " ")
  expect_true(nchar(pubmedsearchworkflow:::abbreviate_query(long_query, width = 25L)) <= 25L)
  expect_equal(pubmedsearchworkflow:::pubmed_data_frame(data.frame(x = 1)), data.frame(x = 1))
  expect_equal(pubmedsearchworkflow:::pubmed_data_frame(list()), data.frame())
})

test_that("reporting helpers support colors and quiet mode", {
  old <- options(pubmedsearchworkflow.use_color = TRUE)
  on.exit(options(old), add = TRUE)

  expect_true(pubmedsearchworkflow:::pubmed_should_color())
  colored <- pubmedsearchworkflow:::pubmed_format_value("query", "field")
  expect_type(colored, "character")

  options(pubmedsearchworkflow.use_color = FALSE)
  expect_identical(pubmedsearchworkflow:::pubmed_format_value("query", "field"), "query")
  expect_identical(pubmedsearchworkflow:::pubmed_style("warn", "warning"), "warn")

  options(pubmedsearchworkflow.use_color = TRUE)
  expect_true(pubmedsearchworkflow:::pubmed_should_color())

  quiet_output <- capture.output(
    pubmedsearchworkflow:::pubmed_report_info("Hidden", verbose = FALSE)
  )
  expect_equal(quiet_output, character())
})
