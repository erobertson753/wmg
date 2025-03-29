# Market Share Analysis in Emerging Markets and WMG's Uncorrelated Returns

## Overview
This repository contains the code and data used for an investment memo for Warner Music Groupo (WMG) analyzing market share in emerging markets and WMG's correlation with market-level risk factors. The analysis leverages data from last.fm to assess streaming trends and incorporates market-level factors  to evaluate their impact on WMG's returns from 10/2021-03/2025.

## Repository Structure
- **`retrieve_data.py`** – A Python script that scrapes last.fm for relevant market data.
- **`clean_data.R`** – An R script that collates and processes raw market data into a structured format for analysis.
- **`analysis.R`** – An R script that performs statistical analysis, including correlation tests, to assess the relationships between WMG's market performance and macroeconomic factors.
- **`data/`** – A directory containing cleaned and raw datasets used in the analysis.

## Methodology
1. **Data Retrieval:** The `retrieve_data.py` script scrapes last.fm to gather streaming data for different artists and markets.
2. **Data Processing:** The `clean_data.R` script merges and formats market-level data, ensuring consistency across sources.
3. **Analysis:** The `analysis.R` script conducts statistical tests, including correlation analysis and bear market assessments, to evaluate market performance drivers.

## Requirements
- **Python:** `requests`, `pandas`, `beautifulsoup4`
- **R:** `tidyverse`, `PerformanceAnalytics`, `quantmod`, `corrplot`, `lubridate`, `zoo`

## Usage
1. Run `retrieve_data.py` to collect the latest streaming data.
2. Use `clean_data.R` to preprocess and structure the market-level data.
3. Execute `analysis.R` to generate statistical insights and visualizations.

## License
This project is released under the MIT License.

