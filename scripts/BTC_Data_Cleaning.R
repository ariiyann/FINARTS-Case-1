# =============================================================================
# BTC_Data_Cleaning.R
# Case 1 -- Bitcoin (BTC) monthly log returns
# Part 2: Data Preparation and Cleaning
#
# Author  : Torraye Carl B. Cornago           Group: Case 1 C02 MLR1 4
# Course&Section  : FINARTS_C02               Date : 26 October 2026
# R version / packages: "R version 4.6.1 (2026-06-24)"
#                        packageVersion("tidyverse")‘2.0.0’
# =============================================================================
#
# 1. PURPOSE
# ---------------------------------------------------------------------------
# Prepare a clean, documented monthly dataset for the group's EDA and
# regression. Research question: which financial and economic conditions are
# associated with Bitcoin's monthly log returns? This script ONLY prepares
# data. It does not explore relationships, select variables or estimate any
# regression.
#
# 2. STUDY PERIOD AND FREQUENCY
# ---------------------------------------------------------------------------
# * Analytical sample : January 2018 - December 2025, monthly (96 months).
# * Pre-sample month  : December 2017 is retained ONLY as the base needed to
#                       compute January 2018 returns/changes. It is excluded
#                       from the exported datasets.
# * Month key         : first day of the calendar month (e.g. 2018-01-01).
#
# 3. DATA SOURCES
# ---------------------------------------------------------------------------
# Downloaded by this script (needs internet on the first run):
#   BTC           Yahoo Finance, ticker BTC-USD (daily close)  via quantmod
#   SP500         FRED series SP500
#   USD_Index     FRED series DTWEXBGS (Nominal Broad U.S. Dollar Index)
#   US_10Y_Yield  FRED series DGS10
#   VIX           FRED series VIXCLS
#   WTI           FRED series DCOILWTICO
# Supplied as BSP workbooks, converted without altering values to CSV:
#   BSP_RRP_Rate  BSP "Selected Domestic Interest Rates", MONTHLY sheet,
#                 column "Target RRP Rate (as of end of period)"
#   USD_PHP       BSP "Philippine Peso per US Dollar Rate", DAILY sheet
#   Philippine_M3_growth / Philippine_M3_level
#                 BSP "Depository Corporations Survey", row "M3 (M2 + 3.d)":
#                 published year-on-year % change, and levels (million PHP)
# Raw files are saved in data/raw/ with source and retrieval date and are
# NEVER overwritten with transformed values.
# Retrieval dates: BSP workbooks (Depository Corporations Survey release of
#   August 2026; interest-rate table last saved 15 Oct 2026) were converted to
#   CSV on 25 Oct 2026. FRED / Yahoo files: see the retrieved_on column in
#   data/raw/*.csv (date of the first run of this script).
#
# 4. VARIABLE SUMMARY
# ---------------------------------------------------------------------------
# Variable              Orig. freq.   Monthly method          Transformation        Unit
# BTC_Return            Daily 24/7    Last valid close        ln(P_t / P_t-1)       decimal
# SP500                 Daily         Last valid obs          ln(P_t / P_t-1)       decimal
# USD_Index             Daily         Last valid obs          ln(P_t / P_t-1)       decimal
# US_10Y_Yield          Daily         Last valid obs          Y_t - Y_t-1           % points
# VIX                   Daily         Mean of valid days      none (level)          index pts
# Philippine_M3_growth  Monthly       Reference-month value   per M3_MODE (sec. 6)  % (YoY) or decimal
# BSP_RRP_Rate          Monthly (EoP) Target RRP at month-end R_t - R_t-1           % points
# USD_PHP               Daily         Last valid obs          ln(X_t / X_t-1)       decimal
#                                                             (X = PHP per USD)
# WTI                   Daily         Last valid obs          ln(P_t / P_t-1)       decimal
#
# Units convention: log returns/changes are DECIMALS (0.01 = 1%). Yield and
# policy-rate changes are PERCENTAGE POINTS. VIX is in index points. USD_PHP
# levels are pesos per U.S. dollar. M3 unit depends on M3_MODE.
#
# 5. CLEANING RULES (applied identically to every series)
# ---------------------------------------------------------------------------
# a) Dates are parsed to Date; rows with unparseable dates are counted and
#    dropped (reported in the data-quality report).
# b) Values are converted to numeric after removing commas, % signs and
#    spaces. Source blanks and "." (FRED holiday marker) become NA.
# c) Duplicate dates: the LAST row for a date is kept (documented rule);
#    the number removed is reported per variable.
# d) Non-finite values are set to NA. For series whose logs are required
#    (BTC, SP500, USD_Index, VIX, USD_PHP), values <= 0 are set to NA and
#    counted. Missing values are NEVER replaced by zero or interpolated.
# e) Legitimate extreme market movements are NOT removed or winsorised.
# f) Month-end convention: the last valid (non-NA) observation in the
#    calendar month. VIX is the arithmetic mean of valid daily values.
#    BTC trades 24/7, so its month-end is the last daily close of the month.
# g) Returns are computed on a COMPLETE calendar-month grid starting Dec 2017
#    using lag() only (no future data). A missing month therefore yields NA
#    for that month and the next, never a return spanning a gap. Monthly
#    returns are computed from monthly prices, not by averaging daily returns.
# h) BSP_RRP_Rate uses BSP's published end-of-period target rate, so it is
#    already a month-end level. A carry-forward rule exists (rate stays in
#    force until the next change) only for months with no observation.
# i) Philippine M3 and BSP data are aligned to their own reference months.
#    Preliminary BSP values (flagged "p" / "r") fall in 2026, outside the
#    study window, and do not affect the sample.
#
# 6. PHILIPPINE M3 -- DEFINITION AND OPEN ISSUE
# ---------------------------------------------------------------------------
# The BSP workbook contains both the published YoY % change and levels. The
# definition used must match the group's master metadata dictionary.
#   M3_MODE = "growth_as_provided" : BSP-published YoY % change (percent)
#   M3_MODE = "log_diff"           : ln(M3_t / M3_t-1) from levels (decimal)
#   M3_MODE = "pct_change_mom"     : M3_t / M3_t-1 - 1 from levels (decimal)
# Selected for this run: "growth_as_provided" (BSP-published YoY % change).
# STATUS: [CONFIRM against the master metadata dictionary -- if the dictionary
# specifies a monthly definition, change M3_MODE and rerun.]
# In the delivered dataset M3 values range from 4.71 to 16.21 (percent).
# Caveats if YoY is used: (i) YoY windows overlap by 11 months, producing
# strong autocorrelation relative to monthly returns; (ii) it is expressed in
# percent whereas returns are decimals. No rescaling is done silently.
# Verification done on the BSP file: published YoY equals YoY recomputed from
# the levels (max abs difference 0.0 pp, 2013 onward).
#
# 7. VALIDATION PERFORMED BY THE SCRIPT
# ---------------------------------------------------------------------------
# * Every log-return and first-difference variable is recomputed
#   independently and compared with the pipeline output; the script stops if
#   any absolute difference exceeds 1e-10.
# * The merged dataset has exactly one row per month; duplicates are checked.
# * The number of months is checked against the expected 96.
# * Missing values are reported per variable with the affected months.
# Additional checks on the BSP inputs (done during extraction):
# * Last valid daily USD/PHP in each month equals BSP's own end-of-period
#   figure for all 97 months Dec 2017 - Dec 2025.
# * Dec 2017 BSP target RRP rate is present, so Jan 2018 change is defined.
# Independent re-verification of the delivered outputs (recomputed from
# data/processed/BTC_monthly_levels.csv): every log return, first difference, the VIX
# average and the M3 series match BTC_monthly_cleaned_all.csv (max abs
# difference 1e-16). Worked examples:
#   BTC Jan 2018 : ln(10221.10 / 14156.40) = -0.32571 (file: -0.32571)
#   USD/PHP Jan 2018 : ln(51.421 / 49.923) = 0.02956 (file: 0.02956)
#   US 10Y Jan 2018 : 2.72 - 2.40 = 0.32 pp (file: 0.32)
#   BSP RRP Jun 2018 : 3.50 - 3.25 = +0.25 pp (file: 0.25)
# Output integrity: 96 rows, 2018-01 to 2025-12, contiguous months, zero NA,
# zero duplicate months; BTC_regression_ready.csv is identical to the cleaned
# file (no month excluded).
#
# 8. OBSERVATION COUNTS (from outputs/data_quality/BTC_data_quality_report.csv)
# ---------------------------------------------------------------------------
# Variable        Raw rows  Dup. removed  Missing in source  Rows after cleaning
# BTC_Return         2985        0               0                2953
# SP500              2131        0              79                2109
# USD_Index          2131        0              96                2109
# US_10Y_Yield       2131        0              91                2109
# VIX                2131        0              52                2109
# Philippine_M3       297        0              12                  97
# BSP_RRP_Rate        201        0               0                 192
# USD_PHP           17820        0            5824                2947
# WTI                2131        0              91                2109
# Notes on the counts:
# * Raw rows include data outside the window. FRED series and BTC were
#   downloaded from 2017-11-01; BTC also contains 2 rows after 2025-12-31;
#   the BSP files cover longer histories (USD_PHP from 1978, M3 from 2001).
# * "Rows after cleaning" = rows kept from 2017-12-01 to 2025-12-31 (the
#   pre-sample month plus the study period). BSP_RRP_Rate keeps its earlier
#   history (from 2010-01) because it is a step series with a carry-forward rule.
# * "Missing in source" counts blanks in the whole raw file, not data errors:
#   FRED blanks are market holidays; BSP ".." means no quotation (weekends /
#   holidays, and the pre-2017 history of USD_PHP); the 12 M3 blanks are the
#   first 12 months of 2001-2002, where YoY is "not computed" (outside window).
# * All of these gaps are resolved by the "last valid observation of the
#   month" rule, so no month in the study window is missing (section 9).
# Duplicate dates: none found in any series.
# Non-finite or non-positive values set to NA: none in any series.
# Months in study window: 96 (expected 96)   Complete-case months: 96
# Final sample dates: 2018-01-01 to 2025-12-01 (month keys; Jan 2018 - Dec 2025)
#
# 9. MISSING VALUES (from outputs/data_quality/BTC_missing_value_report.csv)
# ---------------------------------------------------------------------------
# No missing values in the 96-month window for any of the nine variables
# (0 missing, 0% for BTC_Return, SP500, USD_Index, US_10Y_Yield, VIX,
# Philippine_M3_growth, BSP_RRP_Rate, USD_PHP and WTI).
# Why the regression sample can be smaller than 96: a month is excluded from
# BTC_regression_ready.csv if ANY included variable is NA in that month. Here
# no month is excluded (outputs/data_quality/BTC_excluded_months.csv is empty), so the
# regression-ready file has all 96 months. The only observation lost to
# differencing is Dec 2017, which serves purely as the base for Jan 2018.
# Extreme but legitimate movements were KEPT (not winsorised or removed):
#   BTC_Return min -0.474 (2022-06), max +0.472 (2019-05)
#   SP500      min -0.134 (2020-03), max +0.119 (2020-04)
#   WTI        min -0.782 (2020-03), max +0.615 (2020-05)
#   USD_PHP    min -0.041 (2024-08), max +0.052 (2022-06)
#   VIX        range 11.06 - 57.74 (monthly average)
#
# 10. OUTPUT FILES (organized project directories)
# ---------------------------------------------------------------------------
# data/processed/BTC_monthly_cleaned_all.csv   96 months, all variables, NAs preserved
# data/processed/BTC_regression_ready.csv      complete cases only (after documented exclusions)
# outputs/data_quality/BTC_missing_value_report.csv  missing count and months per variable
# outputs/data_quality/BTC_data_quality_report.csv   cleaning log, validation results, units
# outputs/data_quality/BTC_excluded_months.csv       months dropped from the regression file + reason
# data/processed/BTC_monthly_levels.csv        monthly levels before transformation (audit trail)
#
# 11. UNRESOLVED ISSUES / LIMITATIONS
# ---------------------------------------------------------------------------
# * M3 definition must be confirmed against the master metadata dictionary
#   (section 6). [Update: confirmed / still open]
# * BSP workbooks were converted from Excel to CSV by reshaping only; values
#   were not edited. BSP data may be revised after the retrieval date.
# * Yahoo Finance and FRED data may be revised or restated after download.
# * USD_PHP: the BSP daily sheet has blank cells (not ".." markers) for six
#   weekend dates in the window (2018-01-27/28, 2018-06-23/24, 2018-11-24/25).
#   The conversion skipped them, so the file has 2947 rows vs 2953 calendar
#   days. No effect: all month-ends are weekdays with valid quotes, and the
#   monthly values match BSP's own end-of-period figures.
# * M3 growth (if YoY is used) is in percent with overlapping windows; it is
#   not rescaled to decimals. The regression team should account for this.
# * Month-end values are the last VALID observation of each month, which for
#   holiday-affected series can precede the calendar month-end by a few days.

# ---- 0. Packages ------------------------------------------------------------
pkgs <- c("tidyverse", "lubridate", "janitor", "quantmod", "zoo")
for (p in pkgs) if (!requireNamespace(p, quietly = TRUE)) install.packages(p)
suppressPackageStartupMessages(invisible(lapply(pkgs, library, character.only = TRUE)))

# ---- CONFIG -----------------------------------------------------------------
# Resolve paths relative to the repository root, whether this script is run
# from the .Rproj or sourced with the working directory set to scripts/.
find_project_root <- function(start = getwd(), max_up = 8L) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  for (i in 0:max_up) {
    if (dir.exists(file.path(current, "data", "raw")) &&
        dir.exists(file.path(current, "reports")) &&
        file.exists(file.path(current, "README.md"))) return(current)
    parent <- dirname(current)
    if (parent == current) break
    current <- parent
  }
  stop("Project root not found. Open FINARTS-Case-1.Rproj or set the working directory to the repository root.",
       call. = FALSE)
}
PROJECT_ROOT <- find_project_root()
DIR_RAW <- file.path(PROJECT_ROOT, "data", "raw")
DIR_PROCESSED <- file.path(PROJECT_ROOT, "data", "processed")
DIR_QUALITY <- file.path(PROJECT_ROOT, "outputs", "data_quality")
invisible(lapply(c(DIR_RAW, DIR_PROCESSED, DIR_QUALITY),
                 dir.create, recursive = TRUE, showWarnings = FALSE))

STUDY_START <- as.Date("2018-01-01")
STUDY_END   <- as.Date("2025-12-31")
PRE_START   <- as.Date("2017-12-01")      # pre-sample month for first changes
DL_START    <- "2017-11-01"               # download slightly earlier for safety

# Philippine M3 -- CONFIRM AGAINST THE MASTER METADATA DICTIONARY.
# The BSP workbook provided contains BOTH M3 levels (million PHP) and BSP's
# published YEAR-ON-YEAR % change, so both raw files exist in data/raw/:
#   Philippine_M3_growth.csv : BSP-published YoY % change of M3 (in PERCENT)
#   Philippine_M3_level.csv  : M3 level, million PHP
#   "growth_as_provided" -> uses Philippine_M3_growth.csv as-is (YoY, percent)  [CURRENT SETTING]
#   "log_diff"           -> uses Philippine_M3_level.csv; ln(M3_t / M3_t-1)  (monthly, decimal)
#   "pct_change_mom"     -> uses Philippine_M3_level.csv; M3_t / M3_t-1 - 1  (monthly, decimal)
#   "UNSET"              -> M3 left NA and flagged
# Caution: YoY growth uses overlapping 12-month windows (strong autocorrelation)
# and is in percent, unlike the decimal monthly returns. Document whichever you use.
M3_MODE <- "growth_as_provided"

# Source column mapping. For the three BSP files edit date_col / value_col /
# date_orders if your file layout differs (lubridate order strings).
cfg <- tribble(
  ~var,                   ~file,                     ~date_col, ~value_col, ~date_orders,                      ~agg,    ~transform, ~positive, ~carry,
  "BTC_Return",           "BTC.csv",                 "date",    "close",    "ymd",                             "last",  "logret",   TRUE,      FALSE,
  "SP500",                "SP500.csv",               "date",    "value",    "ymd",                             "last",  "logret",   TRUE,      FALSE,
  "USD_Index",            "USD_Index.csv",           "date",    "value",    "ymd",                             "last",  "logret",   TRUE,      FALSE,
  "US_10Y_Yield",         "US_10Y_Yield.csv",        "date",    "value",    "ymd",                             "last",  "diff",     FALSE,     FALSE,
  "VIX",                  "VIX.csv",                 "date",    "value",    "ymd",                             "mean",  "level",    TRUE,      FALSE,
  "Philippine_M3_growth", "Philippine_M3_growth.csv","date",    "value",    "ymd", "last",  "m3",       FALSE,     FALSE,
  "BSP_RRP_Rate",         "BSP_RRP_Rate.csv",        "date",    "value",    "ymd",        "last",  "diff",     FALSE,     TRUE,
  "USD_PHP",              "USD_PHP.csv",             "date",    "value",    "ymd",        "last",  "logret",   TRUE,      FALSE,
  "WTI",                  "WTI.csv",                 "date",    "value",    "ymd",                             "last",  "logret",   FALSE,     FALSE
)
cfg$file[cfg$var == "Philippine_M3_growth"] <-
  if (M3_MODE %in% c("log_diff", "pct_change_mom")) "Philippine_M3_level.csv" else "Philippine_M3_growth.csv"
# NOTE on WTI: prices were negative on 2020-04-20 (real event). A log return is
# undefined when a month-end price <= 0, so positive = FALSE here only so the
# observation is not silently deleted; the log is then NA and is reported.

# ---- STEP 1a. Reproducible downloads (FRED + Yahoo) --------------------------
fred_series <- c(SP500 = "SP500", USD_Index = "DTWEXBGS", US_10Y_Yield = "DGS10",
                 VIX = "VIXCLS", WTI = "DCOILWTICO")

download_fred <- function(file, id) {
  path <- file.path(DIR_RAW, file)
  if (file.exists(path)) { message("Exists, skipping download: ", file); return(invisible()) }
  url <- sprintf("https://fred.stlouisfed.org/graph/fredgraph.csv?id=%s&cosd=%s&coed=%s",
                 id, DL_START, as.character(STUDY_END))
  raw <- tryCatch(read_csv(url, col_types = cols(.default = "c"), show_col_types = FALSE),
                  error = function(e) { warning("FRED download failed for ", id, ": ", conditionMessage(e)); NULL })
  if (is.null(raw)) return(invisible())
  names(raw) <- c("date", "value")                 # FRED: observation_date/DATE + series id
  raw <- raw %>% mutate(series_id = id, source = "FRED", source_url = url,
                        retrieved_on = as.character(Sys.Date()))
  write_csv(raw, path)                              # raw values kept as text, untouched
  message("Downloaded ", file, " (", nrow(raw), " rows)")
}
iwalk(fred_series, ~ download_fred(paste0(.y, ".csv"), .x))

download_btc <- function() {
  path <- file.path(DIR_RAW, "BTC.csv")
  if (file.exists(path)) { message("Exists, skipping download: BTC.csv"); return(invisible()) }
  x <- tryCatch(suppressWarnings(getSymbols("BTC-USD", src = "yahoo", from = as.Date(DL_START),
                                            to = STUDY_END + 2, auto.assign = FALSE)),
                error = function(e) { warning("Yahoo BTC-USD download failed: ", conditionMessage(e)); NULL })
  if (is.null(x)) return(invisible())
  df <- tibble(date = as.character(index(x)), as_tibble(coredata(x)))
  names(df) <- c("date", "open", "high", "low", "close", "volume", "adjusted")
  df %>% mutate(source = "Yahoo Finance BTC-USD", retrieved_on = as.character(Sys.Date())) %>%
    write_csv(path)
  message("Downloaded BTC.csv (", nrow(df), " rows)")
}
download_btc()

# ---- STEP 1b. BSP files (manual downloads, already converted to raw CSVs) ----
# BSP has no stable public API. The three CSVs below were extracted from the
# BSP workbooks (BSP_RRP_Rate.xls, Philippine_M3_Growth.xlsx, USD_PHP.xlsx).
# Layouts (date = ISO date; value = numeric):
#   BSP_RRP_Rate.csv : MONTHLY "Target RRP Rate (as of end of period)", % p.a.
#   USD_PHP.csv      : DAILY PHP per USD; blank value = no quotation (".." in BSP file)
#   Philippine_M3_growth.csv / Philippine_M3_level.csv : monthly, date = reference month
# To replace a file, keep the columns `date` and `value` (or edit cfg).

# ---- STEP 2. Import ----------------------------------------------------------
read_raw <- function(r) {
  path <- file.path(DIR_RAW, r$file)
  if (!file.exists(path)) { warning("MISSING raw file: ", r$file, " -> ", r$var, " will be NA"); return(NULL) }
  raw <- read_csv(path, col_types = cols(.default = "c"), show_col_types = FALSE) %>% clean_names()
  dc <- make_clean_names(r$date_col); vc <- make_clean_names(r$value_col)
  if (!all(c(dc, vc) %in% names(raw)))
    stop(r$file, ": columns '", dc, "' / '", vc, "' not found. Found: ", paste(names(raw), collapse = ", "))
  tibble(date = as.Date(parse_date_time(raw[[dc]], orders = r$date_orders, quiet = TRUE)),
         value_raw = raw[[vc]])
}

# ---- STEP 3. Clean + validate each series ------------------------------------
clean_series <- function(r, raw) {
  n_raw <- nrow(raw)
  n_bad_date <- sum(is.na(raw$date))
  d <- raw %>% filter(!is.na(date)) %>%
    mutate(value = suppressWarnings(as.numeric(gsub("[,%[:space:]]", "", value_raw))))
  n_unparsed <- sum(is.na(d$value) & !is.na(d$value_raw) & d$value_raw != "" & d$value_raw != ".")
  n_missing_src <- sum(is.na(d$value))                       # blanks / "." (e.g. holidays)
  n_nonfinite <- sum(!is.na(d$value) & !is.finite(d$value))
  d$value[!is.finite(d$value)] <- NA
  # Duplicate rule: same date -> keep the LAST row in file order
  n_dup <- sum(duplicated(d$date, fromLast = TRUE))
  d <- d %>% filter(!duplicated(date, fromLast = TRUE)) %>% arrange(date)
  # Invalid values: non-positive where logs are required (set NA, NOT zero)
  n_nonpos <- if (r$positive) sum(d$value <= 0, na.rm = TRUE) else 0
  if (r$positive) d$value[!is.na(d$value) & d$value <= 0] <- NA
  lower <- if (r$carry) as.Date("1900-01-01") else PRE_START   # RRP needs earlier step
  d <- d %>% filter(date >= lower, date <= STUDY_END)
  list(data = d,
       log = tibble(variable = r$var, n_raw_rows = n_raw, n_unparsed_dates = n_bad_date,
                    n_duplicate_dates_removed = n_dup, n_missing_in_source = n_missing_src,
                    n_unparseable_values = n_unparsed, n_nonfinite = n_nonfinite,
                    n_nonpositive_set_NA = n_nonpos, n_rows_after_cleaning = nrow(d),
                    first_date = as.character(min(d$date)), last_date = as.character(max(d$date))))
}

# ---- STEP 4. Monthly frequency -------------------------------------------------
to_monthly <- function(d, r) {
  d <- d %>% filter(!is.na(value)) %>% mutate(month = floor_date(date, "month"))
  m <- if (r$agg == "mean") {
    d %>% group_by(month) %>% summarise(value = mean(value), n_days = n(), .groups = "drop")
  } else {                       # last valid observation of the month
    d %>% group_by(month) %>% slice_tail(n = 1) %>% ungroup() %>% select(month, value)
  }
  grid <- tibble(month = seq(PRE_START, floor_date(STUDY_END, "month"), by = "month"))
  out <- grid %>% left_join(m %>% select(month, value), by = "month")
  # RRP is a step function: rate stays in force until the next change, so a
  # month with no announcement carries the previous rate (documented rule).
  if (r$carry) {
    pre <- d %>% filter(month < PRE_START) %>% slice_tail(n = 1) %>% pull(value)
    if (is.na(out$value[1]) && length(pre) == 1) out$value[1] <- pre
    out <- out %>% fill(value, .direction = "down")
  }
  out
}

# ---- STEP 5. Run pipeline: levels (monthly) ------------------------------------
logs <- list(); levels_list <- list()
for (i in seq_len(nrow(cfg))) {
  r <- as.list(cfg[i, ]); r$date_orders <- cfg$date_orders[[i]]
  raw <- read_raw(r)
  if (is.null(raw)) {
    levels_list[[r$var]] <- tibble(month = seq(PRE_START, floor_date(STUDY_END, "month"), by = "month"),
                                   value = NA_real_)
    logs[[r$var]] <- tibble(variable = r$var, n_raw_rows = 0, first_date = NA_character_)
    next
  }
  cl <- clean_series(r, raw)
  logs[[r$var]] <- cl$log
  levels_list[[r$var]] <- to_monthly(cl$data, r)
}
levels_wide <- imap(levels_list, ~ rename(.x, !!.y := value)) %>% reduce(left_join, by = "month")

# ---- STEP 6. Transformations (only past data: lag(), never lead()) -----------
logret <- function(x) log(x) - log(lag(x))
dfm <- levels_wide %>% arrange(month)
for (i in seq_len(nrow(cfg))) {
  v <- cfg$var[i]; tf <- cfg$transform[i]
  dfm[[v]] <- switch(tf,
    logret = logret(levels_wide[[v]]),
    diff   = levels_wide[[v]] - lag(levels_wide[[v]]),
    level  = levels_wide[[v]],
    m3     = switch(M3_MODE,
               growth_as_provided = levels_wide[[v]],
               log_diff           = logret(levels_wide[[v]]),
               pct_change_mom     = levels_wide[[v]] / lag(levels_wide[[v]]) - 1,
               { warning("M3_MODE is UNSET: Philippine_M3_growth left NA. ",
                         "Check master metadata dictionary and set M3_MODE."); NA_real_ }))
}
dfm <- dfm %>% rename(date = month)

# ---- STEP 7. Verify transformations independently ------------------------------
chk <- function(v, f) {
  lev <- levels_wide[[v]]; calc <- f(lev); ok <- !is.na(calc)
  ref <- c(NA, diff(if (v %in% c("US_10Y_Yield", "BSP_RRP_Rate")) lev else log(lev)))
  if (!any(ok)) return(NA)
  max(abs(dfm[[v]][ok] - ref[ok]), na.rm = TRUE)
}
checks <- tibble(
  check = c("max_abs_err_BTC", "max_abs_err_SP500", "max_abs_err_USD_Index",
            "max_abs_err_US_10Y", "max_abs_err_RRP", "max_abs_err_USD_PHP", "max_abs_err_WTI"),
  value = c(chk("BTC_Return", logret), chk("SP500", logret), chk("USD_Index", logret),
            chk("US_10Y_Yield", identity), chk("BSP_RRP_Rate", identity),
            chk("USD_PHP", logret), chk("WTI", logret)))
stopifnot(all(is.na(checks$value) | checks$value < 1e-10))

# ---- STEP 8. Study window + merge validation ---------------------------------
clean_all <- dfm %>% filter(date >= STUDY_START, date <= floor_date(STUDY_END, "month")) %>%
  select(date, all_of(cfg$var))
stopifnot(!anyDuplicated(clean_all$date))
n_months <- nrow(clean_all)
if (n_months != 96) warning("Expected 96 months, got ", n_months)

# ---- STEP 9. Missing-value + data-quality reports ----------------------------
miss <- map_dfr(cfg$var, function(v) {
  idx <- is.na(clean_all[[v]])
  tibble(variable = v, n_months = n_months, n_missing = sum(idx),
         pct_missing = round(100 * mean(idx), 2),
         missing_months = paste(format(clean_all$date[idx], "%Y-%m"), collapse = " "))
})
dq <- bind_rows(
  bind_rows(logs) %>% pivot_longer(-variable, names_to = "check", values_transform = as.character) %>%
    mutate(section = "cleaning_log"),
  checks %>% mutate(variable = "ALL", value = as.character(value), section = "transformation_check"),
  tibble(variable = "ALL", check = c("n_months_in_sample", "sample_start", "sample_end", "duplicate_months"),
         value = c(n_months, as.character(min(clean_all$date)), as.character(max(clean_all$date)),
                   as.character(sum(duplicated(clean_all$date)))), section = "merge_validation"),
  tibble(variable = "ALL", check = "units", section = "documentation",
         value = paste("Log returns/changes in DECIMALS (0.01 = 1%); US_10Y_Yield and BSP_RRP_Rate",
                       "changes in percentage points; VIX in index points; USD_PHP in PHP per USD;",
                       "M3 per M3_MODE =", M3_MODE,
                       if (M3_MODE == "growth_as_provided") "(YoY change in PERCENT, not decimal)" else "(decimal)"))
) %>% select(section, variable, check, value)

# ---- STEP 10. Regression-ready (complete cases) -------------------------------
avail <- cfg$var[colSums(!is.na(clean_all[cfg$var])) > 0]
dropped <- setdiff(cfg$var, avail)
if (length(dropped)) warning("Variables with NO data excluded from complete-case set: ",
                             paste(dropped, collapse = ", "))
reg <- clean_all %>% select(date, all_of(avail)) %>% drop_na()
excluded <- clean_all %>% select(date, all_of(avail)) %>% filter(!complete.cases(.)) %>%
  mutate(missing_vars = apply(select(., all_of(avail)), 1, function(z) paste(avail[is.na(z)], collapse = ", "))) %>%
  select(date, missing_vars)

# ---- STEP 11. Export -------------------------------------------------------------
write_csv(clean_all, file.path(DIR_PROCESSED, "BTC_monthly_cleaned_all.csv"), na = "")
write_csv(reg,       file.path(DIR_PROCESSED, "BTC_regression_ready.csv"))
write_csv(miss,      file.path(DIR_QUALITY, "BTC_missing_value_report.csv"))
write_csv(dq,        file.path(DIR_QUALITY, "BTC_data_quality_report.csv"))
write_csv(excluded,  file.path(DIR_QUALITY, "BTC_excluded_months.csv"))
write_csv(levels_wide %>% rename(date = month),
          file.path(DIR_PROCESSED, "BTC_monthly_levels.csv"), na = "")

cat("\n==== SUMMARY ====\n",
    "Months in study window:", n_months, "\n",
    "Complete-case months  :", nrow(reg), "\n",
    "Sample                :", format(min(clean_all$date)), "to", format(max(clean_all$date)), "\n\n")
print(miss %>% select(-missing_months))
