# ==============================================================================
# Download Numerai Data for All Users
# ==============================================================================

# devtools::install_github("Omni-Analytics-Group/Rnumerai", upgrade = "always", force = TRUE)
library(Rnumerai)
pacman::p_load(data.table, tictoc, fst, stringr, anytime, 
               dplyr, dtplyr, purrr,
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
  tmp_d <- Rnumerai::user_performance(user_name = username)
  new_d <- purrr::map_df(tmp_d$data$v3UserProfile$roundModelPerformances, ~as.data.frame(t(.)))

  # Add user_name
  new_d$user_name <- username

  # Keep just the essential columns
  col_keep <- c("user_name",
                "roundNumber", "roundPayoutFactor", "roundResolved",
                "corr", "corrPercentile", 
                 "tc", "tcPercentile",
                "fnc", "fncPercentile", 
                "fncV3", "fncV3Percentile",
                "mmc", "mmcPercentile", 
                "corrWMetamodel")
  new_d <- as.data.table(new_d[, col_keep])
  
  # Remove rows with NULL
  new_d <- new_d[corr != "NULL"]
  
  # Quick fix corr
  new_d <- new_d[corr == "NULL", corr := NA]
  new_d <- new_d[corrPercentile == "NULL", corrPercentile := NA]

  # Quick fix tc
  new_d <- new_d[tc == "NULL", tc := NA]
  new_d <- new_d[tcPercentile == "NULL", tcPercentile := NA]
  
  # Quick fix fnc
  new_d <- new_d[fnc == "NULL", fnc := NA]
  new_d <- new_d[fncPercentile == "NULL", fncPercentile := NA]
  
  # Quick fix fnv3
  new_d <- new_d[fncV3 == "NULL", fncV3 := NA]
  new_d <- new_d[fncV3Percentile == "NULL", fncV3Percentile := NA]
  
  # Quick fix mmc
  new_d <- new_d[mmc == "NULL", mmc := NA]
  new_d <- new_d[mmcPercentile == "NULL", mmcPercentile := NA]
  
  # Final fix
  new_d <- new_d[corrWMetamodel == "NULL", corrWMetamodel := NA]
  
  
  
  
  # Return
  return(new_d)

}

# Wrapper for foreach
wrapper <- function(n_user) {
  username <- d_lb$Username[n_user]
  tryCatch({tmp_d_round_corr <- download_round_corr(username)}, error = function(e) {cat(" ERROR :",conditionMessage(e), " ")})
  return(tmp_d_round_corr)
}



# ============================================================================
# Download Data in Parallel Mode
# ============================================================================

# Display
cat("\n[Info]: Downloading latest data ... ")
tic()


# New! Using 'foreach' to download data
cl <- makeCluster(n_thread)
registerDoParallel(cl)

d_round_corr <- foreach(n_user = 1:nrow(d_lb),
                        .combine = rbind,
                        .multicombine = TRUE,
                        .packages = c("data.table", "Rnumerai", "dplyr", "dtplyr"),
                        .errorhandling = "remove") %dopar% wrapper(n_user)

# Quick test
# d_round_corr <- foreach(n_user = 1:100,
#                         .combine = rbind,
#                         .multicombine = TRUE,
#                         .packages = c("data.table", "Rnumerai", "dplyr", "dtplyr", "purrr"),
#                         .errorhandling = "remove") %dopar% wrapper(n_user)

stopCluster(cl)
toc()



# ==============================================================================
# Previous Logic (Not Needed Anymore)
# ==============================================================================

if (FALSE) {
  
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
  
  
  
  
  
}

