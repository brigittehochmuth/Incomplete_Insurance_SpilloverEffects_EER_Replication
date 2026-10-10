version 16
set more off

/*
    Great-Recession robustness package based on the current p25 baseline.

    This file updates the earlier rolling-window p25 variant so that Heiko can
    run the full robustness package in one go. Compared with the old version:
    - no Hartz dummy is included in the robustness regressions
    - 3 outcomes are estimated: log_steop, log_wage_sum, log_valueadded
    - 3-year windows use explicit reference windows
    - yearly interaction specifications are added
    - AWFP and all BP baseline variants are run
    - readable text tables are written for each sample/specification

    Specification grid:
    spec_a  3-year windows, 2002-2004 reference window
    spec_b  3-year windows from 2005 onward, 2005-2007 reference window
    spec_c  Yearly interactions from 2005 onward, 2004 reference year
    spec_d1 Yearly interactions for all periods, 1993 reference year
    spec_d2 Yearly interactions for all periods, 1994 reference year
    spec_d3 Yearly interactions for all periods, 2004 reference year

    Note:
    The 3-year window specifications are restricted to 1993-2013 so that every
    observation belongs to a complete 3-year window.
*/

capture which reghdfe
if _rc {
    di as err "reghdfe is not installed. Please install reghdfe before running this file."
    exit 199
}

capture which ftools
if _rc {
    di as err "ftools is not installed. Please install ftools before running this file."
    exit 199
}

capture which estout
if _rc {
    di as err "estout is not installed. Please install estout before running this file."
    exit 199
}

if "$date" == "" {
    global date = "$S_DATE"
}

if "$log" == "" {
    global log = c(pwd)
}

global window_out "$log\rolling_windows_robustness"
cap mkdir "$window_out"

capture confirm file "$temp\AWFP_a_93_14_final_reg.dta"
if _rc {
    di as err "Data file $temp\AWFP_a_93_14_final_reg.dta not found."
    di as err "Define global temp as in the baseline setup before running this file."
    exit 601
}

cap log close
log using "$window_out\Regressionen_p25_windows_robustness_$date", text replace

local all_outcomes "log_steop log_wage_sum log_valueadded"

local keep_spec_a "1.window_all#1.above_mean 2.window_all#1.above_mean 3.window_all#1.above_mean 5.window_all#1.above_mean 6.window_all#1.above_mean 7.window_all#1.above_mean"
local keep_spec_b "2.window_post#1.above_mean 3.window_post#1.above_mean"

local keep_spec_c
forvalues y = 2005/2014 {
    local keep_spec_c "`keep_spec_c' `y'.year#1.above_mean"
}

local keep_spec_d1
forvalues y = 1994/2014 {
    local keep_spec_d1 "`keep_spec_d1' `y'.year#1.above_mean"
}

local keep_spec_d2 "1993.year#1.above_mean"
forvalues y = 1995/2014 {
    local keep_spec_d2 "`keep_spec_d2' `y'.year#1.above_mean"
}

local keep_spec_d3
forvalues y = 1993/2003 {
    local keep_spec_d3 "`keep_spec_d3' `y'.year#1.above_mean"
}
forvalues y = 2005/2014 {
    local keep_spec_d3 "`keep_spec_d3' `y'.year#1.above_mean"
}

capture program drop run_robustness_block
program define run_robustness_block
    syntax, SPECID(string) SPECLABEL(string) SAMPLEID(string) SAMPLELABEL(string) ///
        SPECRHS(string asis) KEEPTERMS(string asis) SPECFILTER(string asis) ///
        [SAMPLEFILTER(string asis) EXTRACONTROLS(string asis) WEIGHTVAR(string asis)]

    preserve
        local all_outcomes "log_steop log_wage_sum log_valueadded"

        use "$temp\AWFP_a_93_14_final_reg", clear

        capture confirm variable above_p25
        if _rc {
            di as err "Variable above_p25 is missing in AWFP_a_93_14_final_reg.dta."
            error 111
        }

        capture drop hartziv_above_mean
        capture drop above_mean
        rename hartziv_above_p25 hartziv_above_mean
        rename above_p25 above_mean

        gen int year = a + 1974

        gen byte window_all = .
        replace window_all = 1 if inrange(year, 1993, 1995)
        replace window_all = 2 if inrange(year, 1996, 1998)
        replace window_all = 3 if inrange(year, 1999, 2001)
        replace window_all = 4 if inrange(year, 2002, 2004)
        replace window_all = 5 if inrange(year, 2005, 2007)
        replace window_all = 6 if inrange(year, 2008, 2010)
        replace window_all = 7 if inrange(year, 2011, 2013)
        label define window_all_lbl 1 "1993-1995" 2 "1996-1998" 3 "1999-2001" ///
            4 "2002-2004" 5 "2005-2007" 6 "2008-2010" 7 "2011-2013", replace
        label values window_all window_all_lbl

        gen byte window_post = .
        replace window_post = 1 if inrange(year, 2005, 2007)
        replace window_post = 2 if inrange(year, 2008, 2010)
        replace window_post = 3 if inrange(year, 2011, 2013)
        label define window_post_lbl 1 "2005-2007" 2 "2008-2010" 3 "2011-2013", replace
        label values window_post window_post_lbl

        tempvar touse
        gen byte `touse' = 1
        if "`samplefilter'" != "" {
            replace `touse' = `touse' & (`samplefilter')
        }
        if "`specfilter'" != "" {
            replace `touse' = `touse' & (`specfilter')
        }
        keep if `touse'
        drop `touse'

        bysort betnr: egen so = count(betnr)
        drop if so == 1
        drop so

        count
        if r(N) == 0 {
            di as err "No observations left for `sampleid' / `specid'."
            restore
            exit 2000
        }

        local specrhs_clean : subinstr local specrhs `"""' "", all
        local keepterms_clean : subinstr local keepterms `"""' "", all
        local extracontrols_clean : subinstr local extracontrols `"""' "", all

        local rhs "log_gdp_ger log_gdp_world log_reer `extracontrols_clean' `specrhs_clean' a a_sq"
        local controls_keep "log_gdp_ger log_gdp_world log_reer `extracontrols_clean' a a_sq _cons"
        local outfile "$window_out\robustness_`specid'_`sampleid'_$date.txt"
        local wgt
        if "`weightvar'" != "" {
            local wgt "[aweight = `weightvar']"
        }

        capture estimates drop _all

        di as txt _newline "======================================================================"
        di as txt "Specification: `speclabel'"
        di as txt "Sample: `samplelabel'"
        di as txt "Output: `outfile'"
        di as txt "======================================================================"

        foreach var in `all_outcomes' {
            quietly reghdfe `var' `rhs' `wgt', absorb(betnr) vce(cluster betnr)
            estimates store `var'
        }

        estout `all_outcomes' using "`outfile'", replace ///
            cells(b(star fmt(3)) se(par fmt(3))) ///
            stats(r2 N, fmt(%9.3f %9.0g)) ///
            starlevel(* 0.1 ** 0.05 *** 0.01) ///
            keep(`keepterms_clean' `controls_keep')

        capture estimates drop _all
    restore
end

local bp_only "BP == 1"

local spec_a_rhs "ib4.window_all##i.above_mean"
local spec_b_rhs "ib1.window_post##i.above_mean"
local spec_c_rhs "ib2004.year##i.above_mean"
local spec_d1_rhs "ib1993.year##i.above_mean"
local spec_d2_rhs "ib1994.year##i.above_mean"
local spec_d3_rhs "ib2004.year##i.above_mean"

local spec_a_filter "inrange(year, 1993, 2013)"
local spec_b_filter "inrange(year, 2005, 2013)"
local spec_c_filter "inrange(year, 2004, 2014)"
local spec_d_filter "inrange(year, 1993, 2014)"

di as txt "Starting Great-Recession robustness package (p25 baseline)."
di as txt "All regressions exclude the Hartz IV dummy."

* spec_a: 3-year windows, 2002-2004 reference window
run_robustness_block, specid(spec_a) speclabel("Spec A: 3-year windows, reference window 2002-2004") ///
    sampleid(awfp) samplelabel("AWFP") specrhs("`spec_a_rhs'") ///
    keepterms("`keep_spec_a'") specfilter("`spec_a_filter'")

run_robustness_block, specid(spec_a) speclabel("Spec A: 3-year windows, reference window 2002-2004") ///
    sampleid(bp) samplelabel("BP unweighted") specrhs("`spec_a_rhs'") ///
    keepterms("`keep_spec_a'") specfilter("`spec_a_filter'") samplefilter("`bp_only'")

run_robustness_block, specid(spec_a) speclabel("Spec A: 3-year windows, reference window 2002-2004") ///
    sampleid(bp_weighted) samplelabel("BP weighted") specrhs("`spec_a_rhs'") ///
    keepterms("`keep_spec_a'") specfilter("`spec_a_filter'") samplefilter("`bp_only'") ///
    weightvar(hr)

run_robustness_block, specid(spec_a) speclabel("Spec A: 3-year windows, reference window 2002-2004") ///
    sampleid(bp_inputs) samplelabel("BP unweighted + anteilvor_e") specrhs("`spec_a_rhs'") ///
    keepterms("`keep_spec_a'") specfilter("`spec_a_filter'") samplefilter("`bp_only'") ///
    extracontrols("anteilvor_e")

run_robustness_block, specid(spec_a) speclabel("Spec A: 3-year windows, reference window 2002-2004") ///
    sampleid(bp_inputs_weighted) samplelabel("BP weighted + anteilvor_e") specrhs("`spec_a_rhs'") ///
    keepterms("`keep_spec_a'") specfilter("`spec_a_filter'") samplefilter("`bp_only'") ///
    extracontrols("anteilvor_e") weightvar(hr)

* spec_b: 3-year windows from 2005 onward, 2005-2007 reference window
run_robustness_block, specid(spec_b) speclabel("Spec B: 3-year windows from 2005 onward, reference window 2005-2007") ///
    sampleid(awfp) samplelabel("AWFP") specrhs("`spec_b_rhs'") ///
    keepterms("`keep_spec_b'") specfilter("`spec_b_filter'")

run_robustness_block, specid(spec_b) speclabel("Spec B: 3-year windows from 2005 onward, reference window 2005-2007") ///
    sampleid(bp) samplelabel("BP unweighted") specrhs("`spec_b_rhs'") ///
    keepterms("`keep_spec_b'") specfilter("`spec_b_filter'") samplefilter("`bp_only'")

run_robustness_block, specid(spec_b) speclabel("Spec B: 3-year windows from 2005 onward, reference window 2005-2007") ///
    sampleid(bp_weighted) samplelabel("BP weighted") specrhs("`spec_b_rhs'") ///
    keepterms("`keep_spec_b'") specfilter("`spec_b_filter'") samplefilter("`bp_only'") ///
    weightvar(hr)

run_robustness_block, specid(spec_b) speclabel("Spec B: 3-year windows from 2005 onward, reference window 2005-2007") ///
    sampleid(bp_inputs) samplelabel("BP unweighted + anteilvor_e") specrhs("`spec_b_rhs'") ///
    keepterms("`keep_spec_b'") specfilter("`spec_b_filter'") samplefilter("`bp_only'") ///
    extracontrols("anteilvor_e")

run_robustness_block, specid(spec_b) speclabel("Spec B: 3-year windows from 2005 onward, reference window 2005-2007") ///
    sampleid(bp_inputs_weighted) samplelabel("BP weighted + anteilvor_e") specrhs("`spec_b_rhs'") ///
    keepterms("`keep_spec_b'") specfilter("`spec_b_filter'") samplefilter("`bp_only'") ///
    extracontrols("anteilvor_e") weightvar(hr)

* spec_c: yearly interactions after the reform, 2004 reference year
run_robustness_block, specid(spec_c) speclabel("Spec C: yearly interactions after the reform, reference year 2004") ///
    sampleid(awfp) samplelabel("AWFP") specrhs("`spec_c_rhs'") ///
    keepterms("`keep_spec_c'") specfilter("`spec_c_filter'")

run_robustness_block, specid(spec_c) speclabel("Spec C: yearly interactions after the reform, reference year 2004") ///
    sampleid(bp) samplelabel("BP unweighted") specrhs("`spec_c_rhs'") ///
    keepterms("`keep_spec_c'") specfilter("`spec_c_filter'") samplefilter("`bp_only'")

run_robustness_block, specid(spec_c) speclabel("Spec C: yearly interactions after the reform, reference year 2004") ///
    sampleid(bp_weighted) samplelabel("BP weighted") specrhs("`spec_c_rhs'") ///
    keepterms("`keep_spec_c'") specfilter("`spec_c_filter'") samplefilter("`bp_only'") ///
    weightvar(hr)

run_robustness_block, specid(spec_c) speclabel("Spec C: yearly interactions after the reform, reference year 2004") ///
    sampleid(bp_inputs) samplelabel("BP unweighted + anteilvor_e") specrhs("`spec_c_rhs'") ///
    keepterms("`keep_spec_c'") specfilter("`spec_c_filter'") samplefilter("`bp_only'") ///
    extracontrols("anteilvor_e")

run_robustness_block, specid(spec_c) speclabel("Spec C: yearly interactions after the reform, reference year 2004") ///
    sampleid(bp_inputs_weighted) samplelabel("BP weighted + anteilvor_e") specrhs("`spec_c_rhs'") ///
    keepterms("`keep_spec_c'") specfilter("`spec_c_filter'") samplefilter("`bp_only'") ///
    extracontrols("anteilvor_e") weightvar(hr)

* spec_d1: yearly interactions, all periods, 1993 reference year
run_robustness_block, specid(spec_d1) speclabel("Spec D1: yearly interactions for all periods, reference year 1993") ///
    sampleid(awfp) samplelabel("AWFP") specrhs("`spec_d1_rhs'") ///
    keepterms("`keep_spec_d1'") specfilter("`spec_d_filter'")

run_robustness_block, specid(spec_d1) speclabel("Spec D1: yearly interactions for all periods, reference year 1993") ///
    sampleid(bp) samplelabel("BP unweighted") specrhs("`spec_d1_rhs'") ///
    keepterms("`keep_spec_d1'") specfilter("`spec_d_filter'") samplefilter("`bp_only'")

run_robustness_block, specid(spec_d1) speclabel("Spec D1: yearly interactions for all periods, reference year 1993") ///
    sampleid(bp_weighted) samplelabel("BP weighted") specrhs("`spec_d1_rhs'") ///
    keepterms("`keep_spec_d1'") specfilter("`spec_d_filter'") samplefilter("`bp_only'") ///
    weightvar(hr)

run_robustness_block, specid(spec_d1) speclabel("Spec D1: yearly interactions for all periods, reference year 1993") ///
    sampleid(bp_inputs) samplelabel("BP unweighted + anteilvor_e") specrhs("`spec_d1_rhs'") ///
    keepterms("`keep_spec_d1'") specfilter("`spec_d_filter'") samplefilter("`bp_only'") ///
    extracontrols("anteilvor_e")

run_robustness_block, specid(spec_d1) speclabel("Spec D1: yearly interactions for all periods, reference year 1993") ///
    sampleid(bp_inputs_weighted) samplelabel("BP weighted + anteilvor_e") specrhs("`spec_d1_rhs'") ///
    keepterms("`keep_spec_d1'") specfilter("`spec_d_filter'") samplefilter("`bp_only'") ///
    extracontrols("anteilvor_e") weightvar(hr)

* spec_d2: yearly interactions, all periods, 1994 reference year
run_robustness_block, specid(spec_d2) speclabel("Spec D2: yearly interactions for all periods, reference year 1994") ///
    sampleid(awfp) samplelabel("AWFP") specrhs("`spec_d2_rhs'") ///
    keepterms("`keep_spec_d2'") specfilter("`spec_d_filter'")

run_robustness_block, specid(spec_d2) speclabel("Spec D2: yearly interactions for all periods, reference year 1994") ///
    sampleid(bp) samplelabel("BP unweighted") specrhs("`spec_d2_rhs'") ///
    keepterms("`keep_spec_d2'") specfilter("`spec_d_filter'") samplefilter("`bp_only'")

run_robustness_block, specid(spec_d2) speclabel("Spec D2: yearly interactions for all periods, reference year 1994") ///
    sampleid(bp_weighted) samplelabel("BP weighted") specrhs("`spec_d2_rhs'") ///
    keepterms("`keep_spec_d2'") specfilter("`spec_d_filter'") samplefilter("`bp_only'") ///
    weightvar(hr)

run_robustness_block, specid(spec_d2) speclabel("Spec D2: yearly interactions for all periods, reference year 1994") ///
    sampleid(bp_inputs) samplelabel("BP unweighted + anteilvor_e") specrhs("`spec_d2_rhs'") ///
    keepterms("`keep_spec_d2'") specfilter("`spec_d_filter'") samplefilter("`bp_only'") ///
    extracontrols("anteilvor_e")

run_robustness_block, specid(spec_d2) speclabel("Spec D2: yearly interactions for all periods, reference year 1994") ///
    sampleid(bp_inputs_weighted) samplelabel("BP weighted + anteilvor_e") specrhs("`spec_d2_rhs'") ///
    keepterms("`keep_spec_d2'") specfilter("`spec_d_filter'") samplefilter("`bp_only'") ///
    extracontrols("anteilvor_e") weightvar(hr)

* spec_d3: yearly interactions, all periods, 2004 reference year
run_robustness_block, specid(spec_d3) speclabel("Spec D3: yearly interactions for all periods, reference year 2004") ///
    sampleid(awfp) samplelabel("AWFP") specrhs("`spec_d3_rhs'") ///
    keepterms("`keep_spec_d3'") specfilter("`spec_d_filter'")

run_robustness_block, specid(spec_d3) speclabel("Spec D3: yearly interactions for all periods, reference year 2004") ///
    sampleid(bp) samplelabel("BP unweighted") specrhs("`spec_d3_rhs'") ///
    keepterms("`keep_spec_d3'") specfilter("`spec_d_filter'") samplefilter("`bp_only'")

run_robustness_block, specid(spec_d3) speclabel("Spec D3: yearly interactions for all periods, reference year 2004") ///
    sampleid(bp_weighted) samplelabel("BP weighted") specrhs("`spec_d3_rhs'") ///
    keepterms("`keep_spec_d3'") specfilter("`spec_d_filter'") samplefilter("`bp_only'") ///
    weightvar(hr)

run_robustness_block, specid(spec_d3) speclabel("Spec D3: yearly interactions for all periods, reference year 2004") ///
    sampleid(bp_inputs) samplelabel("BP unweighted + anteilvor_e") specrhs("`spec_d3_rhs'") ///
    keepterms("`keep_spec_d3'") specfilter("`spec_d_filter'") samplefilter("`bp_only'") ///
    extracontrols("anteilvor_e")

run_robustness_block, specid(spec_d3) speclabel("Spec D3: yearly interactions for all periods, reference year 2004") ///
    sampleid(bp_inputs_weighted) samplelabel("BP weighted + anteilvor_e") specrhs("`spec_d3_rhs'") ///
    keepterms("`keep_spec_d3'") specfilter("`spec_d_filter'") samplefilter("`bp_only'") ///
    extracontrols("anteilvor_e") weightvar(hr)

di as txt _newline "Finished Great-Recession robustness package."
di as txt "Tables written to $window_out"

cap log close
clear
