rm(list = ls())

library(PerformanceAnalytics)
library(quantmod)
library(tidyverse)
library(lmtest)
library(sandwich)

files <- c("WMG", "UMG", "SPOT", "RSVR", "LYV")

returns <- files %>%
  set_names() %>%
  map(~ read.csv(paste0("data/", .x, ".csv"), skip = 6, header = TRUE) %>%
        arrange(desc(row_number())))

returns <- map2(returns, files, function(df, ticker) {
  df <- df %>%
    select(Date, PX_LAST, X..Change) %>%
    rename_with(~ c("Date", paste0("Price_", ticker), paste0("Return_", ticker)))
  
  return(df)
})


returns <- lapply(returns, function(df) {
  df <- df %>%
    mutate(Date = as.Date(Date, format = "%m/%d/%Y")) %>%
    filter(Date >= as.Date("10/24/2021", format = "%m/%d/%Y"))
  df
})


UST <- read.csv("data/ust_weekly_days.csv")
head(UST)
UST <- UST %>%
  mutate(Date = ymd(date)) %>%
  filter(Date >= as.Date("2021-10-24"))

data <- reduce(returns, full_join, by = "Date")
data <- left_join(data, UST, by = "Date")

sp500.data <- read.csv("data/sp500_weekly.csv", header = T)
colnames(sp500.data) <- c("Date", "sp500")
sp500.data <- sp500.data %>%
  mutate(Date = as.Date(Date, format = "%m/%d/%Y")) %>%
  mutate(Date = ymd(Date))

cd.data <- read.csv("data/cd.csv", header = T)

colnames(cd.data) <- c("Date", "cd")
head(cd.data)
cd.data <- cd.data %>%
  select(Date, cd) %>%
  mutate(Date = mdy(Date))

tech.data <- read.csv("data/tech_weekly.csv", header = T)

head(tech.data)
colnames(tech.data) <- c("Date", "tech")
head(tech.data)
tech.data <- tech.data %>%
  select(Date, tech) %>%
  mutate(Date = ymd(Date)) %>%
  mutate(Date = as.Date(Date, format = "%Y-%M-%D"))


data <- left_join(data, sp500.data, by="Date")
data <- left_join(data, cd.data, by="Date")
data <- left_join(data, tech.data, by = "Date")
head(data)

data <- data %>%
  mutate(sp_returns = sp500/lag(sp500))
head(data)

data <- na.omit(data)


#Adjust using market returns to find excess returns

data <- data %>%
  mutate(sp_returns_excess = sp_returns -rate_week_average)
head(data)

write.csv(data, "data/data.csv", row.names = F)