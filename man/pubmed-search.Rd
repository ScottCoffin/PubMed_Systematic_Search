\name{pubmed-search}
\alias{query_pubmed}
\alias{run_pubmed_search}
\alias{combine_pubmed_data}
\alias{write_pubmed_csv}
\title{Run PubMed searches and export records}
\usage{
query_pubmed(query, fetch = TRUE, parse = TRUE, format = "xml", verbose = TRUE)

run_pubmed_search(include_query, exclude_query = NULL, chunk = TRUE,
  limit = Inf, sleep = 0, verbose = TRUE)

combine_pubmed_data(results, dedupe_by = "pmid")

write_pubmed_csv(results, path, dedupe_by = "pmid", verbose = TRUE)
}
\arguments{
\item{query}{A PubMed query string.}
\item{fetch}{Whether to fetch matching PubMed records after querying.}
\item{parse}{Whether to parse fetched PubMed records.}
\item{format}{Fetch format passed to \code{easyPubMed::epm_fetch()}.}
\item{verbose}{Whether to print progress messages.}
\item{include_query}{Terms to include in the PubMed search.}
\item{exclude_query}{Optional terms to exclude from each include query chunk.}
\item{chunk}{Whether to split top-level include terms joined by \code{OR}.}
\item{limit}{Maximum number of chunks to run. Use \code{Inf} for all chunks.}
\item{sleep}{Seconds to wait between chunk queries.}
\item{results}{A list of \code{easyPubMed} results or data frames.}
\item{dedupe_by}{Column used to deduplicate combined records.}
\item{path}{Output CSV path. Parent directories are created when needed.}
}
\description{
Run PubMed searches through \pkg{easyPubMed}, combine parsed records across
query chunks, deduplicate by PMID, and write CSV outputs. Progress and errors
are reported with formatted \pkg{cli} messages that include the active chunk,
query preview, and underlying PubMed or \pkg{easyPubMed} error.
}
\value{
\code{query_pubmed()} returns an \pkg{easyPubMed} result object.
\code{run_pubmed_search()} returns a named list of result objects.
\code{combine_pubmed_data()} and \code{write_pubmed_csv()} return a data frame.
}
