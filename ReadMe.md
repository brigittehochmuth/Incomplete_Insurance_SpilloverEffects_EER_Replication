# Replication Files

Hochmuth, Merkl, and Stüber, *Incomplete Insurance and Open-Economy Spillovers of Labor Market Reforms*.

## Model and Descriptive Figures

Extract the ZIP to a short, writable folder. The model needs MATLAB R2026a, Dynare 5.4, and Optimization Toolbox. In MATLAB, run:

```matlab
addpath('C:\dynare-5.4\matlab') % change to your Dynare path
cd('C:\EER\Model')          % change to your extracted folder
MAIN_REPLICATION
```

This produces the model figures and tables in `Model/paper_outputs/Full_Runs/<run-id>/`. It also computes Figure 7 on a longer horizon. Allow about 90 minutes. To resume an interrupted run, use `MAIN_REPLICATION('printed_run_id')`.

For the public-data descriptive figures, run:

```matlab
cd('C:\EER\Descriptives') % change to your extracted folder
MAIN_DESCRIPTIVES
```

Outputs go to `Descriptives/Generated/`. Figure 4 uses the included 1991–2021 OECD current-account and IMF savings inputs. Figure 1 is a supplied institutional schematic. `Descriptives/ReadMe.md` identifies the other inputs.

## Empirical Tables: Restricted Data

The five Stata do-files need licensed AWFP/IAB establishment data in an authorized FDZ environment. Request access through the FDZ of the BA at the IAB: https://fdz.iab.de/en/data-access/on-site-use/. The raw extract, prepared panel, `controlsUpdate.dta`, and log files are **not included** due to restrictions. We use the following version of the IAB Establishment Panel: `IAB Establishment Panel 9317 v1`. The `controlsUpdate.dta` file was merged during panel preparation.

Use Stata 16 with `reghdfe`, `ftools`, and `estout`. Set the path globals used by each do-file (`$awfp`, `$bp9317`, `$betnr_idnum`, `$data`, `$temp`, and `$log`) to the authorized data and output folders; set `$date` for log names. With licensed inputs, `Empirics/Upstream_Preparation/Datenaufbereitung.do` combines AWFP and IAB Establishment Panel files with annual controls and saves `$temp/AWFP_a_93_14_final_reg.dta`.

The table scripts read that panel:

| Paper table | Do-file |
| --- | --- |
| Table 1 | `Empirics/table_1_estim_results/Regressionen_noREER.do` |
| Table 7 | `Empirics/table_8_rolling_windows/Regressionen_windows_p25.do` |
| Table 8 | `Empirics/table_7_china_controls/Regressionen_tb_china.do` and `Regressionen_log_exports_to_china.do`, with the Table 1 baseline |
