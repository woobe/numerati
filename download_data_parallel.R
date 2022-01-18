# ==============================================================================
# Download Numerai Data for All Users
# ==============================================================================

# devtools::install_github("Omni-Analytics-Group/Rnumerai", upgrade = "always", force = TRUE)
library(Rnumerai)
pacman::p_load(data.table, tictoc, fst, stringr, anytime, 
               dplyr, dtplyr,
               foreach, parallel, doParallel)

# Parameters
n_thread <- detectCores()


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
  tmp_d <- Rnumerai::performance_over_time(username = username,
                                           metric = "Round_Correlation",
                                           merge = FALSE,
                                           round_aggregate = FALSE)
  
  # Extract the table
  d <- as.data.table(tmp_d$data)

  # Remove rows with NAs
  d <- d[!is.na(Date)]
  
  # Sort by round
  d <- d[order(rank(Round_Number, Date))]
  
  # Keep only the last record per round
  d[, max_record := .N, by = Round_Number]
  d[, n_record := 1:max_record, by = Round_Number]
  d <- d[n_record == max_record,]
  
  # Clean up
  d[, max_record := NULL]
  d[, n_record := NULL]

  # Return
  return(d)

}

# Wrapper for foreach
wrapper <- function(n_user) {
  username <- d_lb$Username[n_user]
  tryCatch({tmp_d_round_corr <- download_round_corr(username)}, error = function(e) {cat(" ERROR :",conditionMessage(e), " ")})
  return(tmp_d_round_corr)
}





# ==============================================================================
# Check if we already have the latest data
# ==============================================================================

# clean up first
if (exists("d_round_corr")) rm(d_round_corr)

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


# ==============================================================================
# After first check, proceed to download / reload
# ==============================================================================

if (chk_download) {
  
  # Timer
  t_start <- proc.time()

  # Make a copy first
  chk_backup <- file.exists("./data/round_corr_backup.fst")
  if (chk_backup) file.remove("./data/round_corr_backup.fst")
  if (chk_latest) file.copy(from = "./data/round_corr_latest.fst", to = "./data/round_corr_backup.fst")
  if (chk_latest) file.remove("./data/round_corr_latest.fst")
  
  # Display
  cat("\n[Info]: Downloading latest data ... ")
  tic()
  
  # ============================================================================
  # New! Using 'foreach' to download data
  # ============================================================================
  
  cl <- makeCluster(n_thread)
  registerDoParallel(cl)
  
  d_round_corr <- foreach(n_user = 1:nrow(d_lb),
                          .combine = rbind, 
                          .multicombine = TRUE,
                          .packages = c("data.table", "Rnumerai", "dplyr", "dtplyr"),
                          .errorhandling = "remove") %dopar% wrapper(n_user)
  
  stopCluster(cl)
  toc()
  

  # ============================================================================
  # Summary
  # ============================================================================
  
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

  cat("\n[Info]: You already have the latest data. No need to download :)\n")

  # Load data
  d_round_corr <- read_fst("./data/round_corr_latest.fst")

}

