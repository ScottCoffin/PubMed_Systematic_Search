\name{query-utils}
\alias{read_pubmed_query}
\alias{normalize_pubmed_query}
\alias{build_pubmed_query}
\alias{split_pubmed_or_query}
\title{Read and prepare PubMed query strings}
\usage{
read_pubmed_query(path)

normalize_pubmed_query(query)

build_pubmed_query(include_query, exclude_query = NULL)

split_pubmed_or_query(query)
}
\arguments{
\item{path}{Path to a plain-text PubMed query file.}
\item{query}{A PubMed query string or character vector.}
\item{include_query}{Terms to include in the PubMed search.}
\item{exclude_query}{Optional terms to exclude from the PubMed search.}
}
\description{
Utilities for keeping study-specific PubMed search strings in plain-text files
while using a reusable R workflow. \code{split_pubmed_or_query()} splits only
top-level \code{OR} operators so nested parentheses and quoted strings are
preserved.
}
\value{
A character vector. \code{split_pubmed_or_query()} returns one query chunk per
top-level include term.
}
