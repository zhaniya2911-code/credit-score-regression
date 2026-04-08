# 1. SETUP AND LIBRARIES
# Loading essential packages for data handling, modeling, and visualization
library(tidyverse)
library(janitor)
library(caret)
library(glmnet)
library(rpart)
library(ranger)
library(e1071)
library(doParallel)
library(corrplot)
library(reshape2)

# 2. DATA CLEANING 
# Initial data import and standardized column naming for easier coding
df <- credit_score_dataset %>% clean_names()

# Removing unique identifiers that do not provide predictive value
df_clean <- df %>%
  select(-id, -customer_id, -name, -ssn)

# Helper function to remove non-numeric characters and fix formatting
clean_numeric <- function(x) {
  x <- str_replace_all(x, "[^0-9.\\-]", "") 
  x <- as.numeric(x)
  return(x)
}

# Applying the numeric cleaning function to all financial and count-based columns
df_clean <- df_clean %>%
  mutate(across(c(age, annual_income, num_of_loan, num_of_delayed_payment, 
                  changed_credit_limit, outstanding_debt, amount_invested_monthly, 
                  monthly_balance), clean_numeric))

# Capping outliers for age and account counts based on logical business limits
df_clean <- df_clean %>%
  mutate(
    age = ifelse(age < 14 | age > 100, median(age, na.rm = TRUE), age),
    num_bank_accounts = ifelse(num_bank_accounts < 0 | num_bank_accounts > 20, 
                               median(num_bank_accounts, na.rm = TRUE), num_bank_accounts),
    num_credit_card = ifelse(num_credit_card > 20, median(num_credit_card, na.rm = TRUE), num_credit_card)
  )

# Converting text-based Credit History Age into a total month count for easier math
df_clean <- df_clean %>%
  mutate(
    years = as.numeric(str_extract(credit_history_age, "\\d+(?= Years)")),
    months = as.numeric(str_extract(credit_history_age, "\\d+(?= Months)")),
    credit_history_months = (replace_na(years, 0) * 12) + replace_na(months, 0)
  ) %>%
  select(-years, -months, -credit_history_age)

# Handling missing strings in categorical data and creating a numeric scale for credit scores
df_clean <- df_clean %>%
  mutate(
    occupation = ifelse(occupation == "_______", "Unknown", occupation),
    credit_mix = ifelse(credit_mix == "_", "Standard", credit_mix),
    credit_score_numeric = case_when(
      credit_score == "Poor" ~ 1,
      credit_score == "Standard" ~ 2,
      credit_score == "Good" ~ 3
    )
  )

# Using median imputation to fill any remaining gaps in the numeric columns
df_clean <- df_clean %>%
  mutate(across(where(is.numeric), ~replace_na(., median(., na.rm = TRUE))))

# 3. FEATURE ENGINEERING
# Generating new features to capture ratios and normalize distributions
df_clean <- df_clean %>%
  mutate(
    log_annual_income = log1p(annual_income), # Normalizing skewed income data
    log_outstanding_debt = log1p(outstanding_debt), # Normalizing debt distribution
    income_history_interaction = annual_income * credit_history_months, # High income + long history effect
    dti_ratio = outstanding_debt / (annual_income + 1) # Standard Debt-to-Income calculation
  )

# 4. EXPLORATORY DATA ANALYSIS (EDA)

# Visualizing the distribution of the target variable
ggplot(df_clean, aes(x = monthly_balance)) +
  geom_histogram(bins = 50, fill = "steelblue", color = "white") +
  theme_minimal() +
  labs(title = "Distribution of Monthly Balance", x = "Monthly Balance", y = "Frequency")

# Scatter plot for Income vs. Balance
ggplot(df_clean, aes(x = annual_income, y = monthly_balance)) +
  geom_point(alpha = 0.1, color = "darkblue") +
  geom_smooth(method = "lm", color = "red") +
  theme_minimal() +
  labs(title = "Impact of Annual Income on Monthly Balance")

numeric_vars <- df_clean %>% select(where(is.numeric))
cor_matrix <- cor(numeric_vars, use = "complete.obs")
cor_melted <- melt(cor_matrix)

# Heatmap
ggplot(cor_melted, aes(Var1, Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0, 
                       limit = c(-1, 1), name = "Correlation") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "Correlation Heatmap", x = "", y = "")


# Scatter plot for Debt vs. Balance
ggplot(df_clean, aes(x = outstanding_debt, y = monthly_balance)) +
  geom_point(alpha = 0.1, color = "darkred") +
  geom_smooth(method = "lm", color = "yellow") +
  theme_minimal() +
  labs(title = "Outstanding Debt vs Monthly Balance")

# Boxplot comparing balance across different credit mix categories
ggplot(df_clean, aes(x = credit_mix, y = monthly_balance, fill = credit_mix)) +
  geom_boxplot() +
  theme_minimal() +
  labs(title = "Monthly Balance by Credit Mix Type")


# MODELING

df_model2 <- df_clean %>%
  mutate(
    log_income = log1p(annual_income),
    log_debt   = log1p(outstanding_debt)
  )

m1 <- lm(
    credit_score_numeric ~
    annual_income +
    outstanding_debt +
    credit_utilization_ratio +
    credit_history_months +
    age,
  data = df_model2
)

summary(m1)

m2 <- lm(
  credit_score_numeric ~
    annual_income +
    outstanding_debt +
    credit_utilization_ratio +
    credit_history_months +
    age +
    num_of_delayed_payment +
    delay_from_due_date +
    payment_of_min_amount +
    credit_mix,
  data = df_model2
)

summary(m2)

m3 <- lm(
  credit_score_numeric ~
    log_income +
    log_debt +
    credit_utilization_ratio +
    credit_history_months +
    age +
    num_of_delayed_payment +
    delay_from_due_date +
    payment_of_min_amount +
    credit_mix,
  data = df_model2
)



set.seed(123)
train_ctrl <- trainControl(method = "cv", number = 3)

cv_m1 <- train(credit_score_numeric ~ annual_income + outstanding_debt + 
                 credit_utilization_ratio + credit_history_months + age, 
               data = df_model2, method = "lm", trControl = train_ctrl)

cv_m2 <- train(credit_score_numeric ~ annual_income + outstanding_debt + 
                 credit_utilization_ratio + credit_history_months + age + 
                 num_of_delayed_payment + delay_from_due_date + 
                 payment_of_min_amount + credit_mix, 
               data = df_model2, method = "lm", trControl = train_ctrl)

cv_m3 <- train(credit_score_numeric ~ log_income + log_debt + 
                 credit_utilization_ratio + credit_history_months + age + 
                 num_of_delayed_payment + delay_from_due_date + 
                 payment_of_min_amount + credit_mix, 
               data = df_model2, method = "lm", trControl = train_ctrl)


cv_results <- data.frame(
  Model = c("M1: Baseline", "M2: Extended", "M3: Transformed"),
  
  # Root Mean Squared Error
  RMSE = c(cv_m1$results$RMSE, cv_m2$results$RMSE, cv_m3$results$RMSE),
  
  # R-Squared (Percentage of variance explained)
  Rsquared = c(cv_m1$results$Rsquared, cv_m2$results$Rsquared, cv_m3$results$Rsquared),
  
  # Mean Absolute Error (Average magnitude of the errors)
  MAE = c(cv_m1$results$MAE, cv_m2$results$MAE, cv_m3$results$MAE)
)
print(cv_results)

anova_test <- anova(m1, m2, m3)
print(anova_test)

summary_m3 <- summary(m3)
conf_intervals <- confint(m3, level = 0.95)
results_report <- cbind(Estimate = coef(m3), 
                        StdError = summary_m3$coefficients[,2],
                        conf_intervals,
                        PValue = summary_m3$coefficients[,4])
print(round(results_report, 4))


# Diagnostic Plots
par(mfrow=c(1,2))
# Residual plot
plot(predict(m3), residuals(m3), 
     main="Residuals vs Fitted", xlab="Fitted Values", ylab="Residuals", col="blue")
abline(h=0, col="red", lwd=2)
# QQ Plot
qqnorm(residuals(m3))
qqline(residuals(m3), col="red", lwd=2)
