# Elastic-Net-Regression-in-Parallel
AHQR Elastic Net Analysis:This repository contains an R script for analyzing healthcare-related data using Elastic Net regression. The script processes and models relationships between AHQR (Agency for Healthcare Research and Quality) data and environmental exposure data, using ZIP codes as a linking factor.

Features
✔ Data Cleaning & Normalization: Handles missing values, standardizes ZIP codes, and scales data for regression.
✔ Parallel Processing: Utilizes 56 cores for efficient computation.
✔ Elastic Net Regression: Identifies key predictors influencing healthcare outcomes.
✔ Automated CSV Output: Saves results for each outcome variable in the AHQR_Outputs/ directory.

Workflow
Reads and cleans AHQR and exposure data.
Matches ZIP codes and prepares datasets.
Runs Elastic Net regression for each outcome variable.
Extracts model coefficients and saves results.
Aggregates final results into Pediatric_Visits.csv.
Usage
Install required R packages:
r
Copy
Edit
install.packages(c("readr", "tidyverse", "glmnet", "pheatmap", "doParallel", "foreach", "zipcodeR"))
Run the script in R to generate outputs.
Applications
📌 Healthcare Research – Identify environmental factors affecting health outcomes.
📌 Policy Analysis – Support decision-making using predictive modeling.
📌 Epidemiology – Study regional healthcare trends.

Also i added a rjob.sh bash script which can be used to execute the r script on HPC. You need to adjust R script bassed on the available cores.
