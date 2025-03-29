# Load necessary libraries
library(tidyverse)
library(PerformanceAnalytics)
library(quantmod)
library(corrplot)
library(lubridate)
library(zoo)

# Load datasets
data <- read_csv("data/data.csv")
cpi_data <- read_csv("data/CPIAUCSL.csv", col_names = c("Date", "CPI"))
fed_rate_data <- read_csv("data/FEDFUNDS.csv", col_names = c("Date", "FedRate"))

# Convert Date columns to Date format
cpi_data$Date <- as.Date(cpi_data$Date, format = "%m/%d/%Y")
fed_rate_data$Date <- as.Date(fed_rate_data$Date, format = "%m/%d/%Y")
data$Date <- as.Date(data$Date)

# Ensure no missing values
cpi_data <- drop_na(cpi_data)
fed_rate_data <- drop_na(fed_rate_data)

# Interpolate CPI and Fed Rate data to daily values
interpolate_data <- function(df, value_col) {
  all_dates <- tibble(Date = seq(min(df$Date), max(df$Date), by = "day"))
  df <- df %>% mutate(MonthStart = floor_date(Date, "month"))
  full_data <- left_join(all_dates %>% mutate(MonthStart = floor_date(Date, "month")), df, by = "MonthStart")
  full_data <- full_data %>% arrange(Date) %>% transmute(Date, !!value_col := as.numeric(.data[[value_col]]))
  full_data$Date <- as.Date(full_data$Date, origin = "1970-01-01")
  return(full_data)
}

cpi_data_full <- interpolate_data(cpi_data, "CPI")
fed_rate_data_full <- interpolate_data(fed_rate_data, "FedRate")

# Merge CPI and Fed Rate data with main dataset
data <- data %>% left_join(cpi_data_full, by = "Date") %>% left_join(fed_rate_data_full, by = "Date")

# Compute excess returns
data <- data %>% mutate(
  WMG_excess = Return_WMG - rate_week_average,
  UMG_excess = Return_UMG - rate_week_average
)

# Save cleaned data
write_csv(data, "data/data_large.csv")

# Correlation analysis
correlation_data <- data %>% select(WMG_excess, UMG_excess, FedRate, sp_returns_excess, CPI) %>% rename(
  "WMG Returns" = WMG_excess,
  "UMG Returns" = UMG_excess,
  "Interest Rates" = FedRate,
  "S&P 500 Returns" = sp_returns_excess,
  "CPI" = CPI
)

correlation_matrix <- cor(correlation_data, use = "complete.obs")
print(correlation_matrix)
corrplot(correlation_matrix, method = "color", type = "upper", tl.cex = 0.8, tl.col = "black", tl.srt = 45)

# Compute correlations and p-values
compute_correlations <- function(dependent_var) {
  factors <- c("sp_returns_excess", "FedRate", "CPI")
  map_df(factors, ~ {
    test <- cor.test(data[[dependent_var]], data[[.x]], use = "complete.obs")
    tibble(Factor = .x, Correlation = test$estimate, P_Value = test$p.value)
  })
}

cor_results_WMG <- compute_correlations("WMG_excess")
cor_results_UMG <- compute_correlations("UMG_excess")
print(cor_results_WMG)
print(cor_results_UMG)

# Bear market analysis
threshold <- quantile(data$sp_returns_excess, 0.25, na.rm = TRUE)
bear_market_data <- filter(data, sp_returns_excess <= threshold)
cor_test_bear <- cor.test(bear_market_data$UMG_excess, bear_market_data$sp_returns_excess, use = "complete.obs")
print(cor_test_bear)
