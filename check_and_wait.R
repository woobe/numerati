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
n_hardstop <- 144 # wait for 12 hours max
if (weekdays(Sys.Date()) == "Saturday") n_hardstop <- 48 # i.e. wait for 4 hours only on Sat

# Main while loop
source("./set_key.R")

while (chk_updated == 0) {
  
  # hard stop
  if (n_wait > n_hardstop) {
    
    chk_updated <- 1
    cat("[Info]: HARD STOP :(\n")
    
    # Pushoverr
    pushover(message = "[Error]: Hard Stop",
             title = "Numerati Dashboard",
             user = pushover_user,
             app = pushover_app)
    
  }
  
  # Download latest data for [intergration_test]
  cat("[Info] Wait cycle:", n_wait, "... checking ... ")
  d_int <- download_round_corr("integration_test")
  
  # Old logic
  # d_int$Date <- anytime::anydate(d_int$Date)
  # if (max(d_int$Date) >= Sys.Date()) chk_updated <- 1
  
  # New logic
  if (file.exists("./data/round_corr_latest.fst")) d_previous <- read_fst("./data/round_corr_latest.fst")
  if (max(d_int$Date) > max(d_previous$Date)) chk_updated <- 1

  # Continue to wait
  if (chk_updated == 0) {
    
    cat("no new daily score yet ... wait for", n_sleep, "seconds\n")
    Sys.sleep(n_sleep)
    
    # Increase n_wait
    n_wait <- n_wait + 1
    
  } else {
    
    if (chk_updated == 1) cat("daily update is ready. Let's go!\n")
    
    # Pushoverr
    pushover(message = "New Daily Score Available",
             title = "Numerati Dashboard",
             user = pushover_user,
             app = pushover_app)

  }
  
  
  
}

# Clean up
rm(d_int)

  
