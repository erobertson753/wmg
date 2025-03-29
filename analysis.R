# Load necessary libraries
library(PerformanceAnalytics)
library(quantmod)
library(tidyverse)
library(corrplot)
library(lubridate)
library(zoo)
library(dplyr)
library(readr)
# Load the dataset
data <- read.csv("data/data.csv", header = TRUE)

cpi_data <- read_csv("data/CPIAUCSL.csv", col_names = c("Date", "CPI"))


cpi_data$Date <- as.Date(cpi_data$Date, format = "%m/%d/%Y")


cpi_data <- cpi_data %>% filter(!is.na(Date))

cpi_data$MonthStart <- as.Date(format(cpi_data$Date, "%Y-%m-01"))

all_dates <- data.frame(Date = seq(min(cpi_data$Date), max(cpi_data$Date), by = "day"))

cpi_data_full <- all_dates %>%
  mutate(MonthStart = as.Date(format(Date, "%Y-%m-01"))) %>%
  left_join(cpi_data, by = "MonthStart")

cpi_data_full <- cpi_data_full %>%
  arrange(Date.x)


cpi_data_full <- cpi_data_full %>%
  transmute(Date = Date.x, CPI = as.numeric(CPI))


cpi_data_full <- cpi_data_full %>%
  mutate(Date = ymd(Date))
cpi_data_full$Date <- as.Date(cpi_data_full$Date, origin = "1970-01-01")

data$Date <- as.Date(data$Date)

data <- left_join(data, cpi_data_full, by = "Date")

fed_rate_data <- read_csv("data/FEDFUNDS.csv", col_names = c("Date", "FedRate"))


fed_rate_data$Date <- as.Date(fed_rate_data$Date, format = "%m/%d/%Y")


fed_rate_data <- fed_rate_data %>% filter(!is.na(Date))


fed_rate_data$MonthStart <- as.Date(format(fed_rate_data$Date, "%Y-%m-01"))


all_dates <- data.frame(Date = seq(min(fed_rate_data$Date), max(fed_rate_data$Date), by = "day"))

fed_rate_data_full <- all_dates %>%
  mutate(MonthStart = as.Date(format(Date, "%Y-%m-01"))) %>%
  left_join(fed_rate_data, by = "MonthStart")

fed_rate_data_full <- fed_rate_data_full %>%
  arrange(Date.x)

fed_rate_data_full <- fed_rate_data_full %>%
  transmute(Date = Date.x, FedRate = as.numeric(FedRate))


fed_rate_data_full$Date <- as.Date(fed_rate_data_full$Date, origin = "1970-01-01")


data$Date <- as.Date(data$Date)


data <- left_join(data, fed_rate_data_full, by = "Date")

# Compute excess returns for WMG and UMG
data <- data %>%
  mutate(
    WMG_excess = Return_WMG - rate_week_average,
    UMG_excess = Return_UMG - rate_week_average
  )
write.csv(data, "data/data_large.csv", row.names = F)
colnames(data)



correlation_data <- data %>%
  select(WMG_excess, UMG_excess, FedRate, sp_returns_excess, CPI) %>%
  rename(
    "WMG Returns" = WMG_excess,
    "UMG Returns" = UMG_excess,
    "Interest Rates" = FedRate,
    "S&P 500 Returns" = sp_returns_excess,
    "CPI" = CPI
  )

correlation_matrix <- cor(correlation_data, use = "complete.obs")

print(correlation_matrix)

corrplot(correlation_matrix, 
         method = "color", 
         type = "upper", 
         tl.cex = 0.8, 
         tl.col = "black",  
         tl.srt = 45)  


# Define variables of interest
factors <- c("sp_returns_excess", "FedRate", "CPI")

# Create an empty data frame to store results
cor_results_WMG <- data.frame(Factor = factors, Correlation = NA, P_Value = NA)

# Loop through each factor and compute correlation + p-value
for (i in 1:length(factors)) {
  test <- cor.test(data$WMG_excess, data[[factors[i]]], use = "complete.obs")
  cor_results_WMG$Correlation[i] <- test$estimate
  cor_results_WMG$P_Value[i] <- test$p.value
}

print(cor_results_WMG)


cor_results_UMG <- data.frame(Factor = factors, Correlation = NA, P_Value = NA)

# Loop through each factor and compute correlation + p-value
for (i in 1:length(factors)) {
  test <- cor.test(data$UMG_excess, data[[factors[i]]], use = "complete.obs")
  cor_results_UMG$Correlation[i] <- test$estimate
  cor_results_UMG$P_Value[i] <- test$p.value
}

# Print the correlation table with p-values
print(cor_results_WMG)
print(cor_results_UMG)



# Define the threshold for the worst 25% of S&P excess returns
threshold <- quantile(data$sp_returns_excess, 0.25, na.rm = TRUE)

# Filter data to include only extreme bear market periods
bear_market_data <- subset(data, sp_returns_excess <= threshold)

# Compute correlation and p-value in extreme bear markets
cor_test_bear <- cor.test(bear_market_data$UMG_excess, bear_market_data$sp_returns_excess, use = "complete.obs")

# Print results
print(cor_test_bear)



