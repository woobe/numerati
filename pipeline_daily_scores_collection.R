# ==============================================================================
# Pipeline for Collecting Daily Scores
# ==============================================================================

# Making sure
setwd("/home/joe/Repo/numerati")

# Git pull
system("git pull")

# Preload
pacman::p_load(data.table, stringr, pushoverr)
library(Rnumerai)

# API key
source("set_key.R") # (don't upload to GitHub)


# Check and wait for latest data
# source("check_and_wait.R")


# Download latest data
source("download_data_parallel.R")


# Write to CSV 
fwrite(d_round_corr, file = "data_with_tc.csv")


# Read CSV
d_load <- fread("data_with_tc.csv")
# d_load <- fread("data_with_tc.csv.gz")

# Round some columns
col_round <- c("roundPayoutFactor", 
               "corr", "corrPercentile", 
               "tc", "tcPercentile",
               "fnc", "fncPercentile", 
               "fncV3", "fncV3Percentile",
               "mmc", "mmcPercentile", 
               "corrWMetamodel")
d_load[,(col_round) := round(.SD, 8), .SDcols = col_round]


# Write again
fwrite(d_load, file = "data_with_tc.csv")

# Compress
system("pigz --best --force --verbose data_with_tc.csv")

# Write parquet
library(arrow)
arrow::write_parquet(d_load, "data_with_tc.parquet",
                     compression = "gzip",
                     compression_level = 9)

# Git push
t_now <- Sys.time()
txt_comment <- paste("Auto Refresh", t_now, "CEST")
system(paste0("git commit -m '", txt_comment, "' data_with_tc.csv.gz"))
system(paste0("git commit -m '", txt_comment, "' data_with_tc.parquet"))
system("git push")





