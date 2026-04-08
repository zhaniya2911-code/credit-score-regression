# Credit Score Prediction & Financial Analysis (R)

## Project Overview
This project focuses on predicting credit scores and analyzing financial behavior using statistical modeling in **R**. It demonstrates a complete data science pipeline: from aggressive data cleaning and feature engineering to complex regression diagnostics and cross-validation.

## Key Technical Features

### 1. Data Cleaning & Preparation
Real-world financial data is often "messy." In this project, I implemented:
* **Custom Cleaning Functions:** Stripped non-numeric characters and standardized financial fields using `stringr` and `dplyr`.
* **Outlier Handling:** Applied business logic to cap variables like Age and Number of Bank Accounts to realistic ranges.
* **Feature Engineering:** Converted "Credit History Age" into a numeric month-based metric and created interaction terms like the Debt-to-Income (DTI) ratio.

### 2. Exploratory Data Analysis (EDA)
Comprehensive visualization was used to understand data distributions and relationships.

* **Correlation Analysis:** Identified key predictors using a correlation heatmap.
* **Financial Distributions:** Analyzed the skewness of monthly balances and annual income.

### 3. Statistical Modeling
I developed and compared three Linear Regression models:
1. **Baseline Model:** Using primary financial indicators.
2. **Extended Model:** Adding behavioral data (delayed payments, payment history).
3. **Transformed Model (Final):** Utilizing log-transformations to handle skewed distributions and improve model fit.

## Visualizations
*(Below are the insights generated from the R script)*

### Correlation Heatmap
This heatmap reveals the strength of relationships between various financial metrics and the target credit score.
![Correlation Heatmap](./correlation_heatmap.png)

### Distribution of Monthly Balance
Analyzing how balances are spread across the dataset.
![Monthly Balance](./monthlybalance.png)
![Distribution](./dictribution.png)

### Model Diagnostics (Q-Q Plot)
Used to verify the normality of residuals, ensuring the statistical validity of the regression model.
![Q-Q Plot](./qqplot.png)

## Tech Stack
* **Language:** R
* **Libraries:** `tidyverse` (dplyr, ggplot2, tidyr), `caret`, `janitor`, `corrplot`.
* **Methodologies:** Linear Regression, Log Transformation, K-fold Cross-Validation, Residual Analysis.
