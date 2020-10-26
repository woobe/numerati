# Setup

install.packages("pacman")

pacman::p_load(devtools, data.table, tictoc, fst, stringr, anytime,
               rmarkdown, crosstalk, htmltools,
               ggplot2, plotly, scales, ggpubr, ggthemes, ggdark, wesanderson)

devtools::install_github("Omni-Analytics-Group/Rnumerai", upgrade = "always", force = TRUE)

# https://rlesur.github.io/klippy/index.html
# remotes::install_github("rlesur/klippy")
