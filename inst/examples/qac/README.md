# QAC PubMed Search Example

This directory contains the original quaternary ammonium compound (QAC) search
as an example study. Treat these files as replaceable project inputs, not as
the reusable workflow implementation.

## Files

- `search_terms/qac_chemical_string_841.txt`: large chemical-name include query.
- `search_terms/qac_general_chemical_terms.txt`: broader QAC include query.
- `search_terms/qac_exclusion_string.txt`: exclusions applied to include chunks.
- `search_terms/qac_full_query.txt`: earlier all-in-one query string.
- `search_terms/qac_full_query_with_exclusions.txt`: earlier all-in-one query with exclusions.
- `easypubmed_qac_workflow.Rmd`: legacy exploratory notebook-style workflow retained for provenance.
- `pubmed_qac_search.ipynb`: legacy notebook retained for provenance.
- `pubmed_qac_matches.csv`: prior placeholder or output artifact.

## Run the Example

From the repository root:

```powershell
Rscript exec/run_pubmed_search.R `
  --include "inst/examples/qac/search_terms/qac_chemical_string_841.txt" `
  --exclude "inst/examples/qac/search_terms/qac_exclusion_string.txt" `
  --output "outputs/qac_search_1.csv"
```

For a fast smoke test that submits only the first two top-level include chunks:

```powershell
Rscript exec/run_pubmed_search.R `
  --include "inst/examples/qac/search_terms/qac_chemical_string_841.txt" `
  --exclude "inst/examples/qac/search_terms/qac_exclusion_string.txt" `
  --output "outputs/qac_search_1_smoke.csv" `
  --limit 2
```

Repeat with `qac_general_chemical_terms.txt` for the broader query.
