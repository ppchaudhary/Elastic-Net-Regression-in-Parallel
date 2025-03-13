#!/bin/bash

#SBATCH --job-name=R_analysis        # Job name
#SBATCH --output=R_analysis.out       # Output file
#SBATCH --error=R_analysis.err        # Error file
#SBATCH --cpus-per-task=56            # Number of CPU cores
#SBATCH --gres=lscratch:500           # Scratch space (temporary storage)
#SBATCH --mem=200G                     # Memory limit
#SBATCH --time=48:00:00                 # Time limit (hh:mm:ss)

# Load the required R module
module load R/4.2

# Set a library path
LIB_PATH="$HOME/Rlibs"

# Create the directory if it doesn't exist
mkdir -p $LIB_PATH

# Change to the correct directory
cd /data/chaudharyp2/R_ETU/Paediatric_visit_parallel_computing/

# Print the current working directory for debugging
echo "Current working directory:"
pwd

# Install the zipcodeR package if it's not already installed
Rscript -e "if (!requireNamespace('zipcodeR', quietly = TRUE)) install.packages('zipcodeR', repos='http://cran.r-project.org', lib='$LIB_PATH')"

# Run the R script and redirect output to a log file
Rscript -e ".libPaths(c('$LIB_PATH', .libPaths())); source('Edited_pediatric_with_specialists.R')" > output.log 2>&1

# Check if the R script ran successfully
if [ $? -ne 0 ]; then
    echo "R script encountered an error."
else
    echo "R script completed successfully."
fi