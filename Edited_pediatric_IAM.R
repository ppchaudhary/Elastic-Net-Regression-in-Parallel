library(readr)
library(tidyverse)
library(glmnet)
library(pheatmap)
library(doParallel)  # For parallel processing
library(foreach)     # For foreach loop

# Read and clean the AHQR data frame -----
Dz <- read_csv("AHQR_omni_pediatric_visit_rate.csv", col_types = cols(
  ZipCode = col_character(),
  .default = col_double()  # Assuming other columns are numeric
), show_col_types = FALSE)

# Normalize ZipCodes and convert to characters
Dz$ZipCode <- zipcodeR::normalize_zip(Dz$ZipCode)

# Convert percentages to numerics, replacing all "-" with NA
Dz[, -1] <- sapply(Dz[,-1], function(x) as.numeric(gsub("-", NA, x)))

# Remove rows that have only NA (keeping the first column)
Dz <- Dz[rowSums(!is.na(Dz[,-1])) > 0, ]

# Remove columns with only NA, then replace remaining NA with 0
Dz <- Dz[, colSums(!is.na(Dz)) > 0]  # Keep columns with at least one non-NA
Dz[is.na(Dz)] <- 0

# Read and clean the Exposure data frame ----
Exp <- read_csv("AHQR_Omni_2017_rows_removed.csv",
  col_types = cols(
  ZipCode = col_character(),
  .default = col_double()  # Assuming other columns are numeric
), show_col_types = FALSE)


#Make the row names in this dataframe equal to the zip code column
rownames(Exp) <- zipcodeR::normalize_zip(Exp$ZipCode)

#Pipe x into the function the makes it a matrix- with rows and columns, then keeps the row names, then makes everything a number
Exp <- Exp %>% 
  as.matrix(., rownames = TRUE) 

# Apply and scale both remove the rownames of the matrix so I am saving it as a variable to reset them after these operations 
ZipcodesInOrder <- rownames(Exp)

# make all the columns numeric
Exp <- apply(Exp, 2, as.numeric)

# scale x (eleastic net requires gaussian distribution, scale makes it so)
Exp <- scale(Exp, center = TRUE, scale = TRUE) #code might have a scale feature in there already, need to check.

#Remove the columns with only NaN
Exp <- Exp[,-which(colSums(!is.na(Exp))==0)]

Exp[is.na(Exp)] <- 0

# Set rownames 
rownames(Exp) <- ZipcodesInOrder

Exp <- Exp[,-1]


# Prepare output DataFrame
outputDf <- data.frame(Variable = colnames(Exp)) 
set.seed(123)  # For reproducibility

# Set up parallel processing
numCores <- 56  # Match with the requested number of cores
cl <- makeCluster(numCores)
registerDoParallel(cl)

# Use foreach for parallel processing
results <- foreach(column = 2:ncol(Dz), .packages = c("glmnet", "dplyr", "readr")) %dopar% {
  
  DzColumnTitle <- names(Dz)[column] 
  
  # Filter data for matching zip codes
  y <- Dz[which(Dz$ZipCode %in% rownames(Exp)),] 
  workingX <- Exp[which(rownames(Exp) %in% y$ZipCode), ]
  workingX <- workingX[, -1]  # Remove ZipCode from workingX
  
  # Prepare y for analysis
  y <- as.data.frame(y[, column])
  
  # Fit Elastic Net model
  elastic_net_model <- cv.glmnet(workingX, y[, 1], alpha = 0.5)
  
  # Extract the best lambda
  best_lambda <- elastic_net_model$lambda.min
  
  # Fit final model with the best lambda
  final_model <- glmnet(workingX, y[, 1], alpha = 0.5, lambda = best_lambda)
  
  coef <- coef(final_model, s = "lambda.min")
  coefs <- data.frame(Variable = coef@Dimnames[[1]][coef@i + 1], coefficient = coef@x)
  
  # Rename columns for output
  names(coefs) <- c("Variable", DzColumnTitle)
  
  # Write CSV output (make sure the folder exists)
  write_csv(coefs, paste0("AHQR_Outputs/Pediatric", DzColumnTitle, ".csv"))
  
  coefs
}

# Stop the cluster after completion
stopCluster(cl)

# Combine results into the final output DataFrame
final_outputDf <- Reduce(function(x, y) merge(x, y, by = "Variable", all = TRUE), results)

# Write the final CSV
write.csv(final_outputDf, "Pediatric_Visits.csv", row.names = FALSE)
