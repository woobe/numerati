# ==============================================================================
# Pipeline
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


# Using variable `chk_download` from previous step to determine the following steps
t_now <- Sys.time()

# Force it to render
chk_download = TRUE

if (chk_download) {
  
  # Knit index.Rmd to index.html
  rmarkdown::render("index.Rmd", "html_document")
  # rmarkdown::render("compare_corr.Rmd", "html_document")
  # rmarkdown::render("compare_mmc.Rmd", "html_document")
  # rmarkdown::render("compare_corrmmc.Rmd", "html_document")
  rmarkdown::render("data.Rmd", "html_document")
  
  # Commit and push index.html to github
  txt_comment <- paste("Auto Refresh", t_now)
  system(paste0("git commit -m '", txt_comment, "' index.html"))
  # system(paste0("git commit -m '", txt_comment, "' compare_corr.html"))
  # system(paste0("git commit -m '", txt_comment, "' compare_mmc.html"))
  # system(paste0("git commit -m '", txt_comment, "' compare_corrmmc.html"))
  system(paste0("git commit -m '", txt_comment, "' data.html"))
  system(paste0("git commit -m '", txt_comment, "' data.csv"))
  system("git push")
  
  # Display
  cat("[Info]: index.html pushed to master\n")
  
  # Pushoverr
  pushover(message = paste("[Done]: Auto Data Refresh\n@", t_now),
           title = "Numerati Dashboard",
           user = pushover_user,
           app = pushover_app)
  
} else {
  
  # No change in data, no need to refresh
  cat("[Info]: No need to refresh\n")
  
}

# Write a simple log regardless
d_log <- data.table(chk_download = chk_download, file.info("index.html"))
filename <- paste0("./log/log_", t_now, ".csv")
filename <- str_replace_all(filename, ":", "_")
filename <- str_replace_all(filename, "-", "_")
filename <- str_replace_all(filename, " ", "_")
fwrite(d_log, file = filename)

