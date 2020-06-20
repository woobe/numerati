# ==============================================================================
# Download Numerai Data for All Users
# ==============================================================================

# devtools::install_github("Omni-Analytics-Group/Rnumerai", upgrade = "always", force = TRUE)
library(Rnumerai)
pacman::p_load(data.table, tictoc, fst, stringr, anytime)


# ==============================================================================
# Download and Reformat Leaderboard
# ==============================================================================

d_lb <- leaderboard()
d_lb$Username <- as.character(d_lb$Username)
d_lb$Tier <- as.character(d_lb$Tier)
d_lb$NMR_Staked <- as.numeric(as.character(d_lb$NMR_Staked))
write_fst(d_lb, path = "./data/leaderboard_latest.fst")


# ==============================================================================
# Helper function(s)
# ==============================================================================

# Download and Clean Round Correlation Data for One User
download_round_corr <- function(username) {

  # Download data
  tmp_d <- performance_over_time(username = username,
                                 metric = "Round_Correlation",
                                 merge = FALSE,
                                 round_aggregate = FALSE)

  # Extract the table
  d <- as.data.table(tmp_d$data)

  # Remove rows with NAs
  d <- d[!is.na(Date)]

  # Sort by round and then date
  setorderv(d, cols = c("Round_Number", "Date"))

  # Return
  return(d)

}


# ==============================================================================
# Download Data
# ==============================================================================

# clean up first
if (exists("d_round_corr")) rm(d_round_corr)

# Check if we already have the latest data
chk_latest <- file.exists("./data/round_corr_latest.fst")

if (!chk_latest) {

  chk_download <- TRUE

  } else {

  # load existing data
  d_latest <- as.data.table(read_fst("./data/round_corr_latest.fst"))
  d_latest[, Date := anydate(Date)]
  max_date_latest <- max(d_latest$Date)

  # Download latest integration_test
  d_int <- as.data.table(download_round_corr("integration_test"))
  d_int[, Date := anydate(Date)]
  max_date_int <- max(d_int$Date)

  # Check if the dates are the same
  if (max_date_latest == max_date_int) chk_download <- FALSE else chk_download <- TRUE

  # Clean up
  rm(d_int, d_latest)

}


# After first check, proceed to download / reload
if (chk_download) {

  # Make a copy first
  chk_backup <- file.exists("./data/round_corr_backup.fst")
  if (chk_backup) file.remove("./data/round_corr_backup.fst")
  if (chk_latest) file.copy(from = "./data/round_corr_latest.fst", to = "./data/round_corr_backup.fst")
  if (chk_latest) file.remove("./data/round_corr_latest.fst")

  # Loop through all users
  for (n_user in 1:length(d_lb$Username)) {

    # Timer
    tic()

    # Display info
    username <- d_lb$Username[n_user]
    cat("[Info]: Downloading Round Correlation Data for User", n_user, "/", nrow(d_lb), "[", username, "] ... ")

    # Download data
    if (exists("tmp_d_round_corr")) rm(tmp_d_round_corr)
    tryCatch({tmp_d_round_corr <- download_round_corr(username)}, error = function(e) {cat(" ERROR :",conditionMessage(e), " ")})

    # If tmp_d_round_corr exists
    if (exists("tmp_d_round_corr")) {

      # Store
      if (!exists("d_round_corr")) {
        d_round_corr <- tmp_d_round_corr
      } else {
        d_round_corr <- rbind(d_round_corr, tmp_d_round_corr)
      }

      # Clean up & Timer
      rm(username, tmp_d_round_corr)

    }

    # Timer
    toc()

  }

  # Summary
  cat("\n\n[Info]: Data Summary:\n")
  cat("Unique Users:", length(unique(d_round_corr$Username)), "\n")
  cat("Total Number of Records:", nrow(d_round_corr), "\n")
  cat("First Round:", min(d_round_corr$Round_Number), "\n")
  cat("Latest Round:", max(d_round_corr$Round_Number), "\n")

  # Save as fst with date info
  tic()
  cat("\n[Info]: Saving Data ... ")
  write.fst(d_round_corr, path = "./data/round_corr_latest.fst", compress = 100)
  toc()

} else {

  cat("[Info]: You already have the latest data. No need to download :)\n")

  # Load data
  d_round_corr <- read_fst("./data/round_corr_latest.fst")

}

