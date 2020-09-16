# ==============================================================================
# Download Numerai Data for All Users
# ==============================================================================

# devtools::install_github("Omni-Analytics-Group/Rnumerai", upgrade = "always", force = TRUE)
library(Rnumerai)
pacman::p_load(data.table, tictoc, fst, stringr, anytime, pushoverr)


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
# Check
# ==============================================================================

# Display
cat("[Info]: Checking the latest daily score ...\n")

# initial state
chk_updated <- 0 
n_wait <- 0
n_sleep <- 300 # pause between checks
n_hardstop <- 100

# Main while loop
while (chk_updated == 0) {
  
  # Increase n_wait
  n_wait <- n_wait + 1
  
  # Download latest data for [intergration_test]
  cat("[Info] Wait cycle:", n_wait, "... checking ... ")
  d_int <- download_round_corr("integration_test")
  
  if (max(d_int$Date) >= Sys.Date()) chk_updated <- 1
  
  if (chk_updated == 0) {
    cat("no new daily score yet ... wait for", n_sleep, "seconds\n")
    Sys.sleep(n_sleep)
    
  } else {
    
    if (chk_updated == 1) cat("daily update is ready. Let's go!\n")
    
    # Pushoverr
    pushover(message = "New Daily Score Available",
             title = "Numerati Dashboard",
             user = pushover_user,
             app = pushover_app)

  }

  # hard stop
  if (n_wait >= n_hardstop) {
    
    chk_updated <- 1
    cat("[Info]: HARD STOP :(\n")
    
    # Pushoverr
    pushover(message = "[Error]: Hard Stop",
             title = "Numerati Dashboard",
             user = pushover_user,
             app = pushover_app)
    
  }
  
  
}

# Clean up
rm(d_int)

  
