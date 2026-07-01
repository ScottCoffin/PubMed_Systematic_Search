# PubMed Systematic Search Workflow

[![R-CMD-check](https://github.com/ScottCoffin/PubMed_Systematic_Search/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ScottCoffin/PubMed_Systematic_Search/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/ScottCoffin/PubMed_Systematic_Search/graph/badge.svg)](https://app.codecov.io/gh/ScottCoffin/PubMed_Systematic_Search)

<img src="pubmedsearch_logo.png" align="right" width="160" alt="PubMed Search Workflow logo" />

Reusable R helpers for systematic PubMed searches. The repository is organized
as a lightweight R package so collaborators can install the search utilities,
keep study-specific search strings in plain-text files, and run repeatable
exports without editing notebooks.

## Repository Layout

- `R/`: reusable package functions for reading, normalizing, chunking, running,
  combining, and exporting PubMed searches.
- `exec/run_pubmed_search.R`: command-line runner for collaborators who do
  not need to write R code.
- `inst/examples/qac/`: QAC example study with search-specific terms and
  example commands.
- `tests/`: unit tests for query parsing and construction.
- `outputs/`: recommended local output directory; ignored by Git.

## Author and License

Author and maintainer: Dr. Scott Coffin
<scott.l.coffin@gmail.com>.

This project is licensed under the GNU General Public License v3.0. See
`LICENSE.md` for the full license text.

## Install

From the repository root:

```r
install.packages("remotes")
remotes::install_deps(dependencies = TRUE, upgrade = "never")
system2(file.path(R.home("bin"), "R"), c("CMD", "INSTALL", "."))
```

`DESCRIPTION` includes the GitHub remote for `easyPubMed`, so
`remotes::install_deps()` can install that dependency.

On Windows, restart R first if installation reports that packages such as
`cli`, `fs`, or `rlang` cannot be removed or are already loaded. Those packages
are often locked by the active RStudio session.

If using `renv`, run `renv::install(".")` from the repository root instead.

## Run a Search From Text Files

Use one plain-text file for include terms and, optionally, a second file for
exclusions. The runner splits only top-level `OR` operators, preserving nested
parentheses and quoted strings.

```powershell
Rscript exec/run_pubmed_search.R `
  --include "inst/examples/qac/search_terms/qac_chemical_string_841.txt" `
  --exclude "inst/examples/qac/search_terms/qac_exclusion_string.txt" `
  --output "outputs/qac_search_1.csv"
```

Smoke test only the first two chunks:

```powershell
Rscript exec/run_pubmed_search.R `
  --include "inst/examples/qac/search_terms/qac_chemical_string_841.txt" `
  --exclude "inst/examples/qac/search_terms/qac_exclusion_string.txt" `
  --output "outputs/qac_search_1_smoke.csv" `
  --limit 2
```

Submit a query without chunking:

```powershell
Rscript exec/run_pubmed_search.R `
  --include "path/to/full_query.txt" `
  --output "outputs/pubmed_results.csv" `
  --no-chunk
```

Run a minimal live smoke test against one known PMID:

```powershell
Rscript exec/run_pubmed_search.R `
  --include "inst/examples/smoke/pubmed_pmid_query.txt" `
  --output "outputs/smoke_pubmed_pmid.csv" `
  --no-chunk
```

Progress messages use colored formatting when the terminal supports it. Override
color detection when needed:

```r
options(pubmedsearchworkflow.use_color = TRUE)  # force color
options(pubmedsearchworkflow.use_color = FALSE) # disable color for logs
```

## Use From R

```r
library(pubmedsearchworkflow)

include_query <- read_pubmed_query("inst/examples/qac/search_terms/qac_chemical_string_841.txt")
exclude_query <- read_pubmed_query("inst/examples/qac/search_terms/qac_exclusion_string.txt")

results <- run_pubmed_search(
  include_query = include_query,
  exclude_query = exclude_query,
  chunk = TRUE,
  limit = 2
)

records <- combine_pubmed_data(results)
write_pubmed_csv(results, "outputs/qac_search_1_smoke.csv")
```

After installation, use `system.file()` to locate bundled example files:

```r
system.file("examples/qac/search_terms/qac_chemical_string_841.txt",
            package = "pubmedsearchworkflow")
```

Remove `limit = 2` for a full run.

## Adapting for a New Study

1. Copy `inst/examples/qac/` to a new folder under `inst/examples/` or to your
   own project.
2. Replace the include and exclusion text files with your study-specific PubMed
   query strings.
3. Run `exec/run_pubmed_search.R` with the new file paths.
4. Commit search-term files and workflow notes, but keep generated CSV outputs in
   `outputs/` unless they are final curated artifacts.
5. If a query is too broad or PubMed requests time out, use chunking plus
   `--sleep 1` or run smaller include files separately.

## Validation

Build and view the workflow vignette:

```r
devtools::build_vignettes()
browseVignettes("pubmedsearchworkflow")
```

Run unit tests:

```r
devtools::test()
```

Run a lightweight package check:

```r
devtools::check()
```

Network-dependent PubMed searches are not run during tests. Validate a live
search separately with `--limit 1` or `--limit 2` before launching a full query.

## Continuous Integration

GitHub Actions are configured for standard package checks, test coverage, and
pkgdown site builds:

- `.github/workflows/R-CMD-check.yaml`
- `.github/workflows/test-coverage.yaml`
- `.github/workflows/pkgdown.yaml`
