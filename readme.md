# `intreg_mi`: Module for imputation based on Heteroskedastic Interval Regression Approach

This repository provides various examples on the use of the `Stata` command `intreg_mi`, for the analysis of interval-censored data.

The purpose of the program is to facilitate the analysis of interval censored, providing an easy to use command that allows to obtained imputed data, which can be analyzed using standard `Stata` commands, specifically their Multiple Imputation suit `mi`.

## Installation

The command can be installed directly from my github repository using the following command:

```stata
net install intreg_mi, from(https://friosavila.github.io/stpackages)
** or 
net install fra, from(https://friosavila.github.io/stpackages)
fra install intreg_mi
```

## Examples

The following examples are provided:

- Example 1: 
  - Title: Wage analysis using "Swiss Labor Market Survey 1998" data.
  - Data source: Jann, B. (2003). The Swiss Labor Market Survey 1998 (SLMS 98). Schmollers Jahrbuch : Zeitschrift für Wirtschaftsund Sozialwissenschaften, 123(2), 329-335. <https://nbn-resolving.org/urn:nbn:de:0168-ssoar-409467>
  
- Example 2:
  - Title: Melrbourne Housing Market
  - Data source: <https://www.kaggle.com/datasets/dansbecker/melbourne-housing-snapshot>
    Data has been adapted and clean. Currently from `frause`
  
- Example 3:
  - Title: Wage analysis using Merged Outgoing Rotation Groups (MORG) 2018
  - Data Source: <https://data.nber.org/morg/annual/>

- Example 4:
  - Title: Housing Prices: King County, USA
  - Data Source: <https://www.kaggle.com/datasets/harlfoxem/housesalesprediction>

- Example 5:
  - Title: Poverty analysis using ASEC-CPS 2018
  - Data Source: Ipums March 2018 ASEC-CPS. Analysis at household Level