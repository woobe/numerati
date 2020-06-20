# numerati

(Yet Another) Dashboard for Numerai Tournament

## Key Files

- `download_data.R`: download latest data from Numerai
- `./data/round_corr_latest.fst`: latest data in .fst format (not uploaded to github)
- `index.Rmd`: RMarkdown for generating final HTML output
- `index.html`: final HTML output


## Numerai ID and API Key (Optional)

Add `.Rprofile` to your project folder with the following two lines (so you don't need to set key every time):

- `invisible(Rnumerai::set_public_id("add_your_id_here"))`
- `invisible(Rnumerai::set_api_key("add_your_key_here"))`


## References

- https://rstudio.github.io/crosstalk/using.html
- https://bwlewis.github.io/crosstool/
- https://holtzy.github.io/Pimp-my-rmd/
- https://www.datanovia.com/en/blog/top-r-color-palettes-to-know-for-great-data-visualization/
- https://rstudio.github.io/DT/


## To-do List

- Fix the "selected" bug with plotly (see https://github.com/rstudio/crosstalk/issues/16) so only a few models (instead of 1400+) are shown in the `Comparison` tab


## Change Log

- **v0.1**: First Prototype
- **v0.2**: Added `Arbitrage Special` tab.
- **v0.3**: Added `Benchmark` and `Comparison`. Removed `Prototype` and `Arbitrage Special`.

