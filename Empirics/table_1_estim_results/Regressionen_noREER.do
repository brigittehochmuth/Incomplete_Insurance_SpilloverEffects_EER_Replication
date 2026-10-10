cap log close
log using "$log\Regressionen_mean_$date", text replace


*** Nur Betriebe mit durchschnittlich >= 10 nml worker
* Neu: Anteil Vorleistungen (anteilvor_e) [0,100] als independed variable in BP regressionen
* Neu: Alle Regressionen auch mit above_p25 statt above_mean

********************************************************************************

use "$temp\AWFP_a_93_14_final_reg", clear

* Define depended variables
local varlist = "log_steop log_stall log_stnml log_wage_sum log_wage_avg log_valueadded log_rev log_profitability log_invest log_JCR_e log_JDR_e"

* Define independed variables
local ind_varlist = "log_gdp_ger log_gdp_world i.hartziv i.hartziv_above_mean"


********************************************************************************

*** Regressionen mit AWFP

* Identify and drop singleton observations
bysort betnr: egen so = count(betnr)
tab so, mis
drop if so == 1
drop so




** trend and trend squared
foreach var in `varlist' {
qui reghdfe `var' `ind_varlist' a a_sq, absorb(betnr) vce(cluster betnr)
qui estimates store `var'
} 

estout log_steop log_stall log_stnml log_wage_sum, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_wage_avg log_valueadded log_rev log_profitability, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world 1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_invest log_JCR_e log_JDR_e, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)


********************************************************************************


*** Regressionen nur mit BP

keep if BP == 1

* Identify and drop singleton observations
bysort betnr: egen so = count(betnr)
tab so, mis
drop if so == 1
drop so


** trend and trend squared
* For BP == 1
foreach var in `varlist' {
qui reghdfe `var' `ind_varlist' a a_sq if BP == 1, absorb(betnr) vce(cluster betnr)
qui estimates store `var'
} 

estout log_steop log_stall log_stnml log_wage_sum, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_wage_avg log_valueadded log_rev log_profitability, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_invest log_JCR_e log_JDR_e, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)

*** new 2021-09-05 using weights


** trend and trend squared
* For BP == 1
foreach var in `varlist' {
qui reghdfe `var' `ind_varlist' a a_sq [aweight = hr] if BP == 1, absorb(betnr) vce(cluster betnr)
qui estimates store `var'
} 

estout log_steop log_stall log_stnml log_wage_sum, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_wage_avg log_valueadded log_rev log_profitability, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_invest log_JCR_e log_JDR_e, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)



** Anteil Vorleistungen als zusätzliche Kontrollvariable
* Define independed variables
local ind_varlist = "log_gdp_ger log_gdp_world  i.hartziv i.hartziv_above_mean anteilvor_e"

** trend and trend squared
* For BP == 1
foreach var in `varlist' {
qui reghdfe `var' `ind_varlist' a a_sq if BP == 1, absorb(betnr) vce(cluster betnr)
qui estimates store `var'
} 

estout log_steop log_stall log_stnml log_wage_sum, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_wage_avg log_valueadded log_rev log_profitability, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_invest log_JCR_e log_JDR_e, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)

*** new 2021-09-05 using weights


** trend and trend squared
* For BP == 1
foreach var in `varlist' {
qui reghdfe `var' `ind_varlist' a a_sq [aweight = hr] if BP == 1, absorb(betnr) vce(cluster betnr)
qui estimates store `var'
} 

estout log_steop log_stall log_stnml log_wage_sum, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_wage_avg log_valueadded log_rev log_profitability, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_invest log_JCR_e log_JDR_e, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)




*************************************************************************************************************


* Neu: Alle Regressionen auch mit above_p25 statt above_mean

********************************************************************************

cap log close
log using "$log\Regressionen_p25_$date", text replace

use "$temp\AWFP_a_93_14_final_reg", clear

***** RENAME VARIABLES
drop hartziv_above_mean above_mean
rename hartziv_above_p25 hartziv_above_mean
rename above_p25 above_mean

* Define depended variables
local varlist = "log_steop log_stall log_stnml log_wage_sum log_wage_avg log_valueadded log_rev log_profitability log_invest log_JCR_e log_JDR_e"

* Define independed variables
local ind_varlist = "log_gdp_ger log_gdp_world  i.hartziv i.hartziv_above_mean"


********************************************************************************

*** Regressionen mit AWFP

* Identify and drop singleton observations
bysort betnr: egen so = count(betnr)
tab so, mis
drop if so == 1
drop so



** trend and trend squared
foreach var in `varlist' {
qui reghdfe `var' `ind_varlist' a a_sq, absorb(betnr) vce(cluster betnr)
qui estimates store `var'
} 

estout log_steop log_stall log_stnml log_wage_sum, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_wage_avg log_valueadded log_rev log_profitability, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_invest log_JCR_e log_JDR_e, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)


********************************************************************************


*** Regressionen nur mit BP

keep if BP == 1

* Identify and drop singleton observations
bysort betnr: egen so = count(betnr)
tab so, mis
drop if so == 1
drop so



** trend and trend squared
* For BP == 1
foreach var in `varlist' {
qui reghdfe `var' `ind_varlist' a a_sq if BP == 1, absorb(betnr) vce(cluster betnr)
qui estimates store `var'
} 

estout log_steop log_stall log_stnml log_wage_sum, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_wage_avg log_valueadded log_rev log_profitability, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_invest log_JCR_e log_JDR_e, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)

*** new 2021-09-05 using weights


** trend and trend squared
* For BP == 1
foreach var in `varlist' {
qui reghdfe `var' `ind_varlist' a a_sq [aweight = hr] if BP == 1, absorb(betnr) vce(cluster betnr)
qui estimates store `var'
} 

estout log_steop log_stall log_stnml log_wage_sum, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_wage_avg log_valueadded log_rev log_profitability, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_invest log_JCR_e log_JDR_e, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)



** Anteil Vorleistungen als zusätzliche Kontrollvariable
* Define independed variables
local ind_varlist = "log_gdp_ger log_gdp_world  i.hartziv i.hartziv_above_mean anteilvor_e"

** trend and trend squared
* For BP == 1
foreach var in `varlist' {
qui reghdfe `var' `ind_varlist' a a_sq if BP == 1, absorb(betnr) vce(cluster betnr)
qui estimates store `var'
} 

estout log_steop log_stall log_stnml log_wage_sum, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_wage_avg log_valueadded log_rev log_profitability, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_invest log_JCR_e log_JDR_e, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)

*** new 2021-09-05 using weights

** trend and trend squared
* For BP == 1
foreach var in `varlist' {
qui reghdfe `var' `ind_varlist' a a_sq [aweight = hr] if BP == 1, absorb(betnr) vce(cluster betnr)
qui estimates store `var'
} 

estout log_steop log_stall log_stnml log_wage_sum, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_wage_avg log_valueadded log_rev log_profitability, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)
estout log_invest log_JCR_e log_JDR_e, cells(b(star fmt(3)) se(par fmt(3))) stats(r2 N, fmt(%9.3f %9.0g)) starlevel(* 0.1 ** 0.05 *** 0.01) keep(log_gdp_ger log_gdp_world  1.hartziv 1.hartziv_above_mean a a_sq _cons)

cap log close
clear











