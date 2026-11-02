# FINARTS Case 1: Bitcoin (BTC)

Members: Artus, Calalang, Cornago, Meneses



This project examines the association between **Bitcoin's monthly log returns** and selected global and Philippine financial and economic indicators using **multiple linear regression (MLR)** in R. The repository contains the source datasets, cleaning code, exploratory data analysis (EDA), regression and diagnostics, and a combined R Markdown report.



## 1\. Case specifications

|Item|Assigned specification|
|-|-|
|**Case**|Case 1 — Bitcoin (BTC)|
|**Theme**|Cryptocurrency|
|**Dependent variable**|BTC monthly log return|
|**Research question**|Which financial and economic conditions are associated with BTC monthly log return? The group should refine this into a precise empirical question before estimating the final model.|
|**Economic focus**|Crypto returns and domestic/global financial conditions|



**Refined research question used in this project:** To what extent are global financial-market conditions and Philippine monetary and exchange-rate conditions associated with Bitcoin's monthly log returns?



### Assigned candidate regressors

|#|Candidate regressor|Dataset variable code|Expected transformation|Source route|
|-|-|-|-|-|
|1|S\&P 500 return|`SP500`|Monthly log return|FRED SP500 / Yahoo `^GSPC`|
|2|USD index return|`USD\_Index`|Monthly log return|FRED DTWEXBGS|
|3|U.S. 10Y Treasury-yield change|`US\_10Y\_Yield`|Month-end first difference|FRED DGS10|
|4|VIX|`VIX`|Monthly average|FRED VIXCLS / CBOE|
|5|Philippine M3 growth|`Philippine\_M3\_growth`|See master metadata dictionary|See source guide|
|6|BSP RRP rate change|`BSP\_RRP\_Rate`|Month-end first difference|BSP|
|7|USD/PHP change|`USD\_PHP`|Monthly log change|BSP monthly exchange-rate statistics|
|8|WTI return|`WTI`|Monthly log return|FRED DCOILWTICO / EIA|



**Student modeling expectation:** Begin with a literature/theory-justified baseline, inspect the data, estimate the multiple regression, evaluate coefficient significance and economic significance, diagnose model problems, and refine the specification where warranted. The final model should not be determined solely by statistical significance.



**Special note for Bitcoin:** Bitcoin trades continuously, unlike Philippine equities. The supplied dataset therefore uses a standardized monthly calendar and month-end price construction before calculating the monthly log return.



## 2\. Project design

* **Study period:** January 2018–December 2025 (96 monthly observations in the regression-ready dataset).
* **Dependent variable in the dataset:** `BTC\_Return` (monthly log return, expressed as a decimal).
* **Baseline model:** S\&P 500 return, USD index return, U.S. 10-year yield change, VIX, and WTI return.
* **Expanded model:** The baseline predictors plus Philippine M3 growth, BSP RRP rate change, and USD/PHP change.
* **Analysis:** Data preparation, EDA, OLS regression, coefficient/model significance, economic significance, regression diagnostics, and robustness/sensitivity checks.
* **Scope:** The analysis examines statistical **associations**, not causal effects or return forecasts.



## 3\. Repository structure

```text
FINARTS-Case-1/
├── data/
│   ├── raw/                      Original source CSVs
│   └── processed/                Monthly and regression-ready datasets
├── scripts/
│   └── BTC\_Data\_Cleaning.R       Data cleaning and transformation
├── reports/
│   ├── BTC\_Master\_Report.Rmd     Full research report (main submission)
│   ├── BTC\_EDA.Rmd               Detailed EDA
│   └── BTC\_MLR\_Report.Rmd        Detailed MLR and diagnostics
├── references/                   Literature review PDF
├── outputs/
│   ├── data\_quality/             Cleaning and missing-value checks
│   ├── eda/                      EDA HTML, plots, and tables
│   ├── mlr/                      MLR HTML, plots, and tables
│   └── master/                   Combined HTML report
├── FINARTS-Case-1.Rproj          Shared RStudio project file
├── .gitignore
└── README.md
```

The **master report** includes the group's full research background/RRL, a brief cleaning summary, and the detailed EDA, regression, and diagnostics. The standalone Rmd files are retained for separate review and reproducibility. The data-cleaning script does not run automatically when rendering the reports.



## 4\. Requirements and setup

1. Install **R** and **RStudio**.
2. Clone or download the repository and extract it.
3. Install the required packages once in the RStudio Console:

```r
install.packages(c(
  "tidyverse", "lubridate", "janitor", "quantmod", "zoo", "xts",
  "skimr", "moments", "PerformanceAnalytics", "corrplot", "GGally",
  "car", "tseries", "patchwork", "flextable", "ggrepel",
  "knitr", "rmarkdown", "lmtest", "sandwich"
))
```

## 5\. Run the project

Knit `BTC_Master_Report.Rmd`.

**Main result:** `outputs/master/BTC_Master_Report.html`. The compiled EDA and MLR code also writes its detailed figures/tables into `outputs/eda/` and `outputs/mlr/`.

### 

