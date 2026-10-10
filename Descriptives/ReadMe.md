# Descriptive Figures

Run `MAIN_DESCRIPTIVES` in this directory in MATLAB. This route uses macroeconomic data and performs no model solve or data download. Generated files go to `Generated/`; reference figures are in `../Reference_Exhibits/`. Figure 4 is exported as `Figure_04_Current_Account_Savings_1991_2021` from the 31-year inputs described below.

| Paper Figure | Retained Input and Generator | Provenance |
| --- | --- | --- |
| 1 | `../Reference_Exhibits/Figure_01_Hartz_IV_Benefits.pdf` | Manual institutional schematic supplied as a vector PDF. |
| 2 | Selected public macro series in `descriptive_figures/data_intro_update.m`; `figure_intro_precsaving.m` | 1991-2019. Manuscript sources: Deutsche Bundesbank and Destatis. |
| 3 | `descriptive_figures/figure_ca_euro.m`, matrix `dat_fig2`; workbook `data/Bundesbank_Sector_And_Country_Accounts.xlsx`, `Grafik!A2:D26` | 1995–2019. The ULC series uses `100*(Germany index / Eurozone index - 1)` and equals approximately -0.6936 in 2005 and zero in 2015. |
| 4 | `data/figure4_oecd_imf_1991_2021.csv`; `figure_ca_savings.m` | 1991–2021. Current account: OECD Main Economic Indicators `B6BLTT02.DEU.ST.A`. Savings: IMF April 2024 WEO `NGSD_NGDP`, Germany, percent of GDP. |
| 5 | Selected public compensation/value-added series in `descriptive_figures/data_intro_update.m`; `figure_intro_precsaving.m` | Eurostat, Gross value added and income by industry. |
| 11 | Explicit country data matrices in `descriptive_figures/AustriaFranceGermany_version2_BH.m` | 1999-2021. Manuscript sources: OECD current account, unemployment and investment; IMF savings. |
| 12-13 | `data/differentaccounts.mat`; `descriptive_figures/create_figure.m` | 1991-2019 Bundesbank series, traced to the workbook and ranges below. |

## Figure 4 Data Sources

The OECD current-account series is from an October 31, 2024 archive of the OECD Main Economic Indicators annual series `B6BLTT02.DEU.ST.A`; the OECD series definition is current-account balance as a percentage of GDP. The IMF savings series is `NGSD_NGDP` from the April 2024 World Economic Outlook database.

The OECD archived copy was retrieved from DBnomics' OECD/KEI archive ([https://db.nomics.world/OECD/KEI](https://db.nomics.world/OECD/KEI)), indexed 31 October 2024. OECD's series definition appears in [https://one.oecd.org/document/SDD/DOC%282023%293/en/pdf](https://one.oecd.org/document/SDD/DOC%282023%293/en/pdf). The IMF April 2024 release is [https://www.imf.org/en/publications/weo/weo-database/2024/april](https://www.imf.org/en/publications/weo/weo-database/2024/april); its archived table was accessed through the World Bank reproducibility repository at [https://reproducibility.worldbank.org/catalog/219/related-materials](https://reproducibility.worldbank.org/catalog/219/related-materials).

## Sector and Country Accounts

The file `Bundesbank_Sector_And_Country_Accounts.xlsx` is an unchanged copy of the historical `2407 BoP Different Actors.xlsx`. It records the original Bundesbank series identifiers in the first row.

For Figure 12, `Finanzierungssalden!K3:N31` contains household, government, nonfinancial-firm and financial-firm net lending in percent of GDP. Each column divides the corresponding nominal series in B:E by GDP in G and multiplies by 100.

For Figure 13, `Ländergruppen!X3:X31`, `Y3:Y31` and `O3:O31` contain the Eurozone, rest-of-world and overall current account ratios. The household/Eurozone correlation over all 29 annual observations is 0.8216965528, which rounds to the reported 0.82.
