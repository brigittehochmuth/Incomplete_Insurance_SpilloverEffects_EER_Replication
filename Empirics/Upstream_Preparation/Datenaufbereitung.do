


********************************************************************************
*** Erstellung der Datensätze:
********************************************************************************


********************************************************************************
** AWFP - Betriebsebene 
********************************************************************************

cap log close
log using "$log\data_a_$date", text replace

** Use quarterly stocks (4th quarter of a year) to obtain annual stocks

use "$awfp\pq214", clear // All workers
gen st_all = st_nml + st_app + st_pr + st_mpt + st_other
label var st_all "Stock: all workers (including part-time, apprentices etc.)
drop st_app st_pr st_mpt st_other // st_nml

merge 1:1 betnr q using "$awfp\pq207" // Stock regular workers
assert _merge != 2
keep if _merge == 3
label var st_eop "Stock: regular workers (std. -end of period- definition)
drop st_male _merge

merge 1:1 betnr q using "$awfp\pq105imp" // imputed wage
assert _merge != 2
drop _merge // dw_imp_p25 dw_imp_p50 dw_imp_p75
replace dw_imp_sd = .n if missing(dw_imp_sd) & st_eop == 1 // missing if st_eop == 1

* data only available at the annual frequency (consistent over year)
gen int a = ceil(q/4)
label var a "index of year"

gen year = 1974 + a
label var year "year"

merge m:1 betnr a using "$awfp\pa102" // location (federal state) and industry
drop if _merge == 2
gen byte state = floor(district/1000)
label var state "federal state"
drop _merge district //   w73_imp w93_imp w03 w08 w73 w93

label define state 1 "Schleswig-Holstein" 2 "Hamburg" ///  
3 "Lower Saxony" 4 "Bremen" 5 "North Rhine-Westfalia" /// 
6 "Hesse" 7 "Rhineland Palatinate" 8 "Baden-Wuerttemberg" 9 "Bavaria" ///  
10 "Saarland" 11 "Berlin" 12 "Brandenburg" 13 "Mecklenburg-West Pomerania" ///  
14 "Saxony" 15 "Saxony-Anhalt" 16 "Thuringia" 

label values state state



** Anual stock dataset

* Stock of fourth quarter of each year == stock for annual dataset
keep if mod(q,4) == 0 // 4th quarter identified by 0
drop q


** Annualy flow dataset

* Inflows

merge 1:1 betnr a using "$awfp\pa307" // inflows
assert _merge != 2
drop in_male _merge

/*
merge 1:1 betnr a using "$awfp\pa314" // inflows all workers
drop if _merge == 2
drop _merge
gen in_all = in_rw + in_app + in_mpt + in_pr + in_other
label var in_all "In: all workers (including part-time, apprentices etc.)"
drop in_rw in_app in_mpt in_pr in_other
*/

merge 1:1 betnr a using "$awfp\pa309c" // decomposition inflows
assert _merge != 2
drop _merge in_ue in_oolf

compress

/*
merge 1:1 betnr a using "$awfp\pa414" // outflows all workers
drop if _merge == 2
drop _merge
gen out_all = out_rw + out_app + out_mpt + out_pr + out_other
label var out_all "Out: all workers (including part-time, apprentices etc.)"
drop out_rw out_app out_mpt out_pr out_other
*/

merge 1:1 betnr a using "$awfp\pa407" // outflows
drop out_male _merge

merge 1:1 betnr a using "$awfp\pa409c" // decomposition outflows
assert _merge != 2
drop _merge out_ue out_oolf

* replace missings by zero (when necessary)
foreach var of varlist st_* out_* in_* {
replace `var' = 0 if missing(`var') 
}

** Impute missings in state and wz

drop w73
*replace w73 = . if w73 == .z | w73 == .n 
replace w93 = . if w93 == .z | w93 == .n 
replace w03 = . if w03 == .z | w03 == .n 
replace w08 = . if w08 == .z | w08 == .n 

sort betnr a
replace state = state[_n-1] if missing(state) & betnr == betnr[_n-1] 
replace w03 = w03[_n-1] if missing(w03) & betnr == betnr[_n-1]
replace w93_imp = w93_imp[_n-1] if missing(w93_imp) & betnr == betnr[_n-1]
replace w08 = w08[_n-1] if missing(w08) & betnr == betnr[_n-1]
replace w73_imp = w73_imp[_n-1] if missing(w73_imp) & betnr == betnr[_n-1]
replace w93 = w93[_n-1] if missing(w93) & betnr == betnr[_n-1]
*replace w73 = w73[_n-1] if missing(w73) & betnr == betnr[_n-1]

gsort betnr -a
replace state = state[_n-1] if missing(state) & betnr == betnr[_n-1] 
replace w03 = w03[_n-1] if missing(w03) & betnr == betnr[_n-1]
replace w93_imp = w93_imp[_n-1] if missing(w93_imp) & betnr == betnr[_n-1]
replace w08 = w08[_n-1] if missing(w08) & betnr == betnr[_n-1]
replace w73_imp = w73_imp[_n-1] if missing(w73_imp) & betnr == betnr[_n-1]
replace w93 = w93[_n-1] if missing(w93) & betnr == betnr[_n-1]
*replace w73 = w73[_n-1] if missing(w73) & betnr == betnr[_n-1]

* Select data in terms of years
keep if year >= 1992 & year <= 2014

sort betnr a
gen st_eop_lag = 0
*gen st_all_lag = 0
gen st_nml_lag = 0
replace st_eop_lag = st_eop[_n-1] if betnr == betnr[_n-1] & a - 1 == a[_n-1]
label var st_eop_lag "lagged stock regular workers"
*replace st_all_lag = st_all[_n-1] if betnr == betnr[_n-1] & a - 1 == a[_n-1]
*label var st_all_lag "lagged stock all workers"
replace st_nml_lag = st_nml[_n-1] if betnr == betnr[_n-1] & a - 1 == a[_n-1]
label var st_nml_lag "lagged stock normal workers (full- and part-time)"

compress

keep if year >= 1993 & year <= 2014 // year >= 2003 & year <= 2008

compress
save "$temp\AWFP_a_93_14", replace
*use "$temp\AWFP_a_93_14", clear
cap log close
clear



********************************************************************************
** IAB-Betriebspanel
********************************************************************************

* Noch IAB_est_panel.do integrieren

cap log close
log using "$log\bp9314_$date", text replace

forv y = 1993 / 2015 {
use "$bp9317\iabbp_`y'", clear

if `y' == 1993 {
rename a08 anteilvor
rename a06b geschvol
rename a60 lohn
rename a15b invest
rename a34leih leiharb
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn a07 a75 a57 invest leiharb hr
rename a75 br
rename a57 uet 
compress
save "$temp\bp`y'", replace
}

if `y' == 1994 {
rename b15 anteilvor
rename b13 geschvol
rename b25 lohn
rename b21 invest
rename b44leih leiharb
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn	b14 bz06 invest leiharb hr
rename bz06 br
compress
save "$temp\bp`y'", replace
}

if `y' == 1995 {
rename c15 anteilvor
rename c13 geschvol
rename c64 lohn
rename c21 invest
rename c43leih leiharb
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn c14 cz06 c62 c63 invest leiharb hr
rename cz06 br
rename c62 tv 
rename c63 uet 
compress
save "$temp\bp`y'", replace
}

if `y' == 1996 {
rename d17 anteilvor
rename d12 geschvol
rename d51 lohn
rename d22 invest
rename d37leih leiharb
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn d18 d49 d50 d80 invest leiharb hr // d20ab d20ka d20nb d20ost d20son
rename d80 br
rename d49 tv 
rename d50 uet 
compress
save "$temp\bp`y'", replace
}

if `y' == 1997 {
rename e17 anteilvor
rename e12 geschvol
rename e59 lohn
rename e27a invest
rename e47leih leiharb
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn e18a e71 e57 e58 invest leiharb hr // e18c e18b
rename e71 br
rename e57 tv 
rename e58 uet 
compress
save "$temp\bp`y'", replace
}

if `y' == 1998 {
rename f14 anteilvor
rename f11 geschvol
rename f61 lohn
rename f19b invest
rename f47leih leiharb
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn f15a f15b f15d f59 f60 f67 invest leiharb hr
rename f67 br
rename f59 tv 
rename f60 uet 
compress
save "$temp\bp`y'", replace
}

if `y' == 1999 {
rename g14 anteilvor
rename g11 geschvol
rename g53 lohn
rename g45 uebst
rename g23a invest
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn g16a g16b g16d g79 g50 g52 g51 uebst invest
rename g79 br
rename g50 tv 
rename g52 uet
rename g51 obtv
compress
save "$temp\bp`y'", replace
}

if `y' == 2000 {
rename h17 anteilvor
rename h12 geschvol
rename h45 lohn
rename h19 invest
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn h15a h15b h15d h42 h44 h79 h43 invest
rename h79 br
rename h42 tv 
rename h44 uet
rename h43 obtv
compress
save "$temp\bp`y'", replace
}

if `y' == 2001 {
rename i12 anteilvor
rename i07 geschvol // in DM
rename i71 lohn // in DM
rename i74 uebst
rename i25 invest
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn i11a i11b i11d i82 i67 i69 i68 uebst invest
rename i82 br
rename i67 tv 
rename i69 uet
rename i68 obtv
compress
save "$temp\bp`y'", replace
}

* geschvol and lohn etc. in datasets 93-2001 in DM!
* geschvol and lohn etc. in datasets 2002 onwards in Euro!

if `y' == 2002 {
rename j11 anteilvor
rename j06 geschvol // in Euro! (first had j05)
rename j34 lohn // in Euro!
rename j27 uebst
rename j14 invest
rename j44leih leiharb
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn j10a j10b j10d j76 j30 j32 j31 uebst invest leiharb hr
rename j76 br
rename j30 tv 
rename j32 uet
rename j31 obtv
compress
save "$temp\bp`y'", replace
}

if `y' == 2003 {
rename k14 anteilvor
rename k09 geschvol
rename k77 lohn
rename k28 uebst
rename k17 invest
rename k54 leiharb
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn k13a k13b k13d k72 k73 k80 k75a uebst invest leiharb hr
replace k80 = 2 if k80 == 3 
rename k80 br
rename k72 tv 
rename k73 uet
rename k75a obtv
compress
save "$temp\bp`y'", replace
}

if `y' == 2004 {
rename l14 anteilvor
rename l09 geschvol
rename l68 lohn
rename l24a dalc
rename l62 uebst
rename l16 invest
rename l34leih leiharb
replace dalc = . if dalc == -9
rename hr`y'q hr
gen year = `y'
keep dalc year idnum anteilvor geschvol lohn l13a l13b l13e l64 l65 l66 l88a uebst invest leiharb hr
rename l88a br
rename l64 tv 
rename l66 uet
rename l65 obtv
compress
save "$temp\bp`y'", replace
}

if `y' == 2005 {
rename m13 anteilvor
rename m08 geschvol
rename m59 lohn
rename m23 dalc
replace dalc = . if dalc == -9
rename m19 invest
rename m31leih leiharb
rename hr`y'q hr
gen year = `y'
keep dalc year idnum anteilvor geschvol lohn m12a m12b m12e  m85a m52 m54 m53 invest leiharb hr
compress
rename m85a br
rename m52 tv 
rename m54 uet
rename m53 obtv
save "$temp\bp`y'", replace
}

if `y' == 2006 {
rename n10 anteilvor
rename n08 geschvol // ?
rename n83 lohn
rename n54 uebst
rename n15 invest
rename n25leih leiharb
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn n09a n09b n09e n79 n80 n81 n84a uebst invest leiharb hr
rename n84a br
rename n79 tv 
rename n81 uet
rename n80 obtv
compress
save "$temp\bp`y'", replace
}

if `y' == 2007 {
rename o12 anteilvor
rename o09 geschvol // ?
rename o85 lohn
rename o18 invest
rename o37leih leiharb
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn o10a o10b o10e o86a o81 o82 o83 invest leiharb hr
rename o86a br
rename o81 tv 
rename o83 uet
rename o82 obtv
compress
save "$temp\bp`y'", replace
}

if `y' == 2008 {
rename p13 anteilvor
rename p10 geschvol
rename p63 lohn
rename p22 dalc
replace dalc = . if dalc == -9
rename p80a uebst
rename p19 invest
rename p34leih leiharb
rename hr`y'q hr
gen year = `y'
keep year dalc idnum anteilvor geschvol lohn p11a p11b  p59 p60 p61 p86a uebst invest leiharb hr
rename p86a br
rename p59 tv 
rename p61 uet
rename p60 obtv
compress
save "$temp\bp`y'", replace
}

if `y' == 2009 {
rename q10 anteilvor
rename q07 geschvol
rename q43 lohn
rename q20a dalc
rename q20bb cvd
rename q20bc cne
rename q20bd cci
replace dalc = . if dalc == -9 // ! Question dalc deviates in 2009!
replace cvd = . if cvd == -9 | cvd == 0
replace cne = . if cne == -9 | cne == 0
replace cci = . if cci == -9 | cci == 0
rename q29 uebst
rename q17 invest
rename q52leih leiharb
rename hr`y'q hr
gen year = `y'
keep year dalc cvd cne cci idnum anteilvor geschvol lohn q08a q08b  q84a q39 q40 q41 uebst invest leiharb hr
rename q84a br
rename q39 tv 
rename q41 uet
rename q40 obtv
compress
save "$temp\bp`y'", replace
}

if `y' == 2010 {
rename r13 anteilvor
rename r10 geschvol
rename r54 lohn
rename r23a dalc
rename r23bb cvd
rename r23bc cne
rename r23bd cci
replace dalc = . if dalc == -9
replace cvd = . if cvd == -9 | cvd == 0
replace cne = . if cne == -9 | cne == 0
replace cci = . if cci == -9 | cci == 0
rename r71a uebst
rename r20 invest
rename r34leih leiharb
rename hr`y'q hr
gen year = `y'
keep year dalc cvd cne cci  idnum anteilvor geschvol lohn r11a r11b  r50 r51 r52 r79a uebst invest leiharb hr
rename r79a br
rename r50 tv 
rename r52 uet
rename r51 obtv
compress
save "$temp\bp`y'", replace
}

if `y' == 2011 {
rename s11 anteilvor
rename s08 geschvol
rename s58 lohn
rename s60 uebst
rename s17 invest
rename s30leih leiharb
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn s09a s09b s77a s52 s53 s56a uebst invest leiharb hr
rename s77a br
rename s52 tv 
rename s53 uet
rename s56a obtv
compress
save "$temp\bp`y'", replace
}

if `y' == 2012 {
rename t11 anteilvor
rename t08 geschvol
rename t52 lohn
rename t55a uebst
rename t21 invest
rename t34leih leiharb
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn t09a t09b t48 t49 t50 t74a uebst invest leiharb hr
rename t74a br
rename t48 tv 
rename t50 uet
rename t49 obtv
compress
save "$temp\bp`y'", replace
}

if `y' == 2013 {
rename u11 anteilvor
rename u08 geschvol
rename u52 lohn
rename u79 uebst
rename u18 invest
rename u31leih leiharb
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn u09b u09a u81a u48 u49 u51a uebst invest leiharb hr
rename u81a br
rename u48 tv 
rename u51a uet
rename u49 obtv
compress
save "$temp\bp`y'", replace
}

if `y' == 2014 {
rename v11 anteilvor
rename v08 geschvol
rename v78 lohn
rename v50a uebst
rename v18 invest
rename v29leih leiharb
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn v09a v09b v73 v75a v74 v79a  uebst invest leiharb hr
rename v79a br
rename v73 tv 
rename v75a uet
rename v74 obtv
compress
save "$temp\bp`y'", replace
}

if `y' == 2015 {
rename w10 anteilvor
rename w07 geschvol
rename w64 lohn
rename w50 uebst
rename w17 invest
rename w30leih leiharb
rename hr`y'q hr
gen year = `y'
keep year idnum anteilvor geschvol lohn w08a w08b uebst invest leiharb hr
compress
save "$temp\bp`y'", replace
}

}

use  "$temp\bp1993", clear
forv y = 1994 / 2015 {
append using "$temp\bp`y'"
}
compress

replace uet = . if uet < 0
replace br = . if br < 0
replace tv = . if tv < 0
replace obtv = . if obtv < 0

replace anteilvor = . if anteilvor == -9
replace anteilvor = . if anteilvor < 0

replace geschvol = . if geschvol == -9
replace geschvol = . if geschvol < 0

replace lohn = . if lohn == -9
replace lohn = . if lohn < 0
replace lohn = . if lohn == 0

replace geschvol = geschvol / 1.95583  if year <= 2001
replace lohn = lohn / 1.95583 if year <= 2001
replace invest = invest / 1.95583 if year <= 2001
replace geschvol = round(geschvol,1)
replace lohn = round(lohn,1)
replace invest = round(invest,1)

su geschvol if year == 2001
su geschvol if year == 2002
su lohn if year == 2001
su lohn if year == 2002
su invest if year == 2001
su invest if year == 2002

label var geschvol "geschvol of year t-1"
label var lohn "lohn of year t"
label var anteilvor "anteilvor of year t-1"
label var year "year"
cap label var dalc "Fifficulties acquiring loan capital"
cap label var cvd "credit volume decreased"
cap label var cne "credit not extended / shortened"
cap label var cci "credit costs increased"

label var uebst "Ueberstunden of year t-1"
label var invest "Investnents of year t-1"
label var leiharb "Leiharbeit"

drop dalc cvd cne cci

compress

gen s_export = .
label var s_export "exportanteil am umsatz; fuer Vorjahr; in %"

replace a07 = . if a07 == -9
replace s_export = a07 if year == 1993
drop a07

replace b14 = . if b14 == -9
replace s_export = b14 if year == 1994
drop b14

replace c14 = . if c14 == -9
replace s_export = c14 if year == 1995
drop c14

replace d18 = . if d18 == -8
replace s_export = d18 if year == 1996
drop d18

replace e18a = . if e18a == -8
replace s_export = e18a if year == 1997
drop e18a

replace f15a = . if f15a == -9 | f15a == -8
replace f15b = . if f15b == -9 | f15b == -8
replace f15d = . if f15d == -9 | f15d == -8
* Start new 2020-08-04
replace f15a = 0 if missing(f15a) & (!missing(f15b) |  !missing(f15d))
replace f15b = 0 if missing(f15b) & (!missing(f15a) |  !missing(f15d))
replace f15d = 0 if missing(f15d) & (!missing(f15b) |  !missing(f15a))
* End new 2020-08-04
gen f15c = 100 - f15a - f15b - f15d
replace f15c = . if missing(f15a) & missing(f15b) & missing(f15d) // new 2020-08-04
replace f15c = 0 if f15c < 0
replace s_export = f15c + f15d if year == 1998
drop f15a f15b f15d f15c

replace g16a = . if g16a == -9 | g16a == -8
replace g16b = . if g16b == -9 | g16b == -8
replace g16d = . if g16d == -9 | g16d == -8
* Start new 2020-08-04
replace g16a = 0 if missing(g16a) & (!missing(g16b) |  !missing(g16d))
replace g16b = 0 if missing(g16b) & (!missing(g16a) |  !missing(g16d))
replace g16d = 0 if missing(g16d) & (!missing(g16b) |  !missing(g16a))
* End new 2020-08-04
gen g16c = 100 - g16a - g16b - g16d
replace g16c = . if missing(g16a) & missing(g16b) & missing(g16d) // new 2020-08-04
replace g16c = 0 if g16c < 0
replace s_export = g16c + g16d if year == 1999
drop g16a g16b g16d g16c

replace h15a = . if h15a == -9 | h15a == -8
replace h15b = . if h15b == -9 | h15b == -8
replace h15d = . if h15d == -9 | h15d == -8
* Start new 2020-08-04
replace h15a = 0 if missing(h15a) & (!missing(h15b) |  !missing(h15d))
replace h15b = 0 if missing(h15b) & (!missing(h15a) |  !missing(h15d))
replace h15d = 0 if missing(h15d) & (!missing(h15b) |  !missing(h15a))
* End new 2020-08-04
gen h15c = 100 - h15a - h15b - h15d
replace h15c = . if missing(h15a) & missing(h15b) & missing(h15d) // new 2020-08-04
replace h15c = 0 if h15c < 0
replace s_export = h15c + h15d if year == 2000
drop h15a h15b h15d h15c

replace i11a = . if i11a == -9 | i11a == -8
replace i11b = . if i11b == -9 | i11b == -8
replace i11d = . if i11d == -9 | i11d == -8
* Start new 2020-08-04
replace i11a = 0 if missing(i11a) & (!missing(i11b) |  !missing(i11d))
replace i11b = 0 if missing(i11b) & (!missing(i11a) |  !missing(i11d))
replace i11d = 0 if missing(i11d) & (!missing(i11b) |  !missing(i11a))
* End new 2020-08-04
gen i11c = 100 - i11a - i11b - i11d
replace i11c = . if missing(i11a) & missing(i11b) & missing(i11d) // new 2020-08-04
replace i11c = 0 if i11c < 0
replace s_export = i11c + i11d if year == 2001
drop i11a i11b i11d i11c

replace j10a = . if j10a == -9 | j10a == -8
replace j10b = . if j10b == -9 | j10b == -8
replace j10d = . if j10d == -9 | j10d == -8
* Start new 2020-08-04
replace j10a = 0 if missing(j10a) & (!missing(j10b) |  !missing(j10d))
replace j10b = 0 if missing(j10b) & (!missing(j10a) |  !missing(j10d))
replace j10d = 0 if missing(j10d) & (!missing(j10b) |  !missing(j10a))
* End new 2020-08-04
gen j10c = 100 - j10a - j10b - j10d
replace j10c = . if missing(j10a) & missing(j10b) & missing(j10d) // new 2020-08-04
replace j10c = 0 if j10c < 0
replace s_export = j10c + j10d if year == 2002
drop j10a j10b j10d j10c

replace k13a = . if k13a == -9 | k13a == -8
replace k13b = . if k13b == -9 | k13b == -8
replace k13d = . if k13d == -9 | k13d == -8
* Start new 2020-08-04
replace k13a = 0 if missing(k13a) & (!missing(k13b) |  !missing(k13d))
replace k13b = 0 if missing(k13b) & (!missing(k13a) |  !missing(k13d))
replace k13d = 0 if missing(k13d) & (!missing(k13b) |  !missing(k13a))
* End new 2020-08-04
gen k13c = 100 - k13a - k13b - k13d
replace k13c = . if missing(k13a) & missing(k13b) & missing(k13d) // new 2020-08-04
replace k13c = 0 if k13c < 0
replace s_export = k13c + k13d if year == 2003
drop k13a k13b k13d k13c

replace l13a = . if l13a == -9 | l13a == -8
replace l13b = . if l13b == -9 | l13b == -8
replace l13e = . if l13e == -9 | l13e == -8
* Start new 2020-08-04
replace l13a = 0 if missing(l13a) & (!missing(l13b) |  !missing(l13e))
replace l13b = 0 if missing(l13b) & (!missing(l13a) |  !missing(l13e))
replace l13e = 0 if missing(l13e) & (!missing(l13b) |  !missing(l13a))
* End new 2020-08-04
gen l13c = 100 - l13a - l13b - l13e
replace l13c = . if missing(l13a) & missing(l13b) & missing(l13e) // new 2020-08-04
replace l13c = 0 if l13c < 0
replace s_export = l13c + l13e if year == 2004
drop l13a l13b l13e l13c

replace m12a = . if m12a == -9 | m12a == -8
replace m12b = . if m12b == -9 | m12b == -8
replace m12e = . if m12e == -9 | m12e == -8
* Start new 2020-08-04
replace m12a = 0 if missing(m12a) & (!missing(m12b) |  !missing(m12e))
replace m12b = 0 if missing(m12b) & (!missing(m12a) |  !missing(m12e))
replace m12e = 0 if missing(m12e) & (!missing(m12b) |  !missing(m12a))
* End new 2020-08-04
gen m12c = 100 - m12a - m12b - m12e
replace m12c = . if missing(m12a) & missing(m12b) & missing(m12e) // new 2020-08-04
replace m12c = 0 if m12c < 0
replace s_export = m12c + m12e if year == 2005
drop m12a m12b m12e m12c

replace n09a = . if n09a == -9 | n09a == -8
replace n09b = . if n09b == -9 | n09b == -8
replace n09e = . if n09e == -9 | n09e == -8
* Start new 2020-08-04
replace n09a = 0 if missing(n09a) & (!missing(n09b) |  !missing(n09e))
replace n09b = 0 if missing(n09b) & (!missing(n09a) |  !missing(n09e))
replace n09e = 0 if missing(n09e) & (!missing(n09b) |  !missing(n09a))
* End new 2020-08-04
gen n09c = 100 - n09a - n09b - n09e
replace n09c = . if missing(n09a) & missing(n09b) & missing(n09e) // new 2020-08-04
replace n09c = 0 if n09c < 0
replace s_export = n09c + n09e if year == 2006
drop n09a n09b n09e n09c

replace o10a = . if o10a == -9 | o10a == -8
replace o10b = . if o10b == -9 | o10b == -8
replace o10e = . if o10e == -9 | o10e == -8
* Start new 2020-08-04
replace o10a = 0 if missing(o10a) & (!missing(o10b) |  !missing(o10e))
replace o10b = 0 if missing(o10b) & (!missing(o10a) |  !missing(o10e))
replace o10e = 0 if missing(o10e) & (!missing(o10b) |  !missing(o10a))
* End new 2020-08-04
gen o10c = 100 - o10a - o10b - o10e
replace o10c = . if missing(o10a) & missing(o10b) & missing(o10e) // new 2020-08-04
replace o10c = 0 if o10c < 0
replace s_export = o10c + o10e if year == 2007
drop o10a o10b o10e o10c

replace p11a = . if p11a == -9 | p11a == -8
replace p11b = . if p11b == -9 | p11b == -8
* Start new 2020-08-04
replace p11a = 0 if missing(p11a) & !missing(p11b) 
replace p11b = 0 if missing(p11b) & !missing(p11a) 
* End new 2020-08-04
gen p11c = 100 - p11a - p11b
replace p11c = . if missing(p11a) & missing(p11b) // new 2020-08-04
replace p11c = 0 if p11c < 0
replace s_export = p11c if year == 2008
drop p11a p11b p11c

replace q08a = . if q08a == -9 | q08a == -8
replace q08b = . if q08b == -9 | q08b == -8
* Start new 2020-08-04
replace q08a = 0 if missing(q08a) & !missing(q08b) 
replace q08b = 0 if missing(q08b) & !missing(q08a) 
* End new 2020-08-04
gen q08c = 100 - q08a - q08b
replace q08c = . if missing(q08a) & missing(q08b) // new 2020-08-04
replace q08c = 0 if q08c < 0
replace s_export = q08c if year == 2009
drop q08a q08b q08c

replace r11a = . if r11a == -9 | r11a == -8
replace r11b = . if r11b == -9 | r11b == -8
* Start new 2020-08-04
replace r11a = 0 if missing(r11a) & !missing(r11b) 
replace r11b = 0 if missing(r11b) & !missing(r11a) 
* End new 2020-08-04
gen r11c = 100 - r11a - r11b
replace r11c = . if missing(r11a) & missing(r11b) // new 2020-08-04
replace r11c = 0 if r11c < 0
replace s_export = r11c if year == 2010
drop r11a r11b r11c

replace s09a = . if s09a == -9 | s09a == -8
replace s09b = . if s09b == -9 | s09b == -8
* Start new 2020-08-04
replace s09a = 0 if missing(s09a) & !missing(s09b) 
replace s09b = 0 if missing(s09b) & !missing(s09a) 
* End new 2020-08-04
gen s09c = 100 - s09a - s09b
replace s09c = . if missing(s09a) & missing(s09b) // new 2020-08-04
replace s09c = 0 if s09c < 0
replace s_export = s09c if year == 2011
drop s09a s09b s09c

replace t09a = . if t09a == -9 | t09a == -8
replace t09b = . if t09b == -9 | t09b == -8
* Start new 2020-08-04
replace t09a = 0 if missing(t09a) & !missing(t09b) 
replace t09b = 0 if missing(t09b) & !missing(t09a) 
* End new 2020-08-04
gen t09c = 100 - t09a - t09b
replace t09c = . if missing(t09a) & missing(t09b) // new 2020-08-04
replace t09c = 0 if t09c < 0
replace s_export = t09c if year == 2012
drop t09a t09b t09c

replace u09a = . if u09a == -9 | u09a == -8
replace u09b = . if u09b == -9 | u09b == -8
* Start new 2020-08-04
replace u09a = 0 if missing(u09a) & !missing(u09b) 
replace u09b = 0 if missing(u09b) & !missing(u09a) 
* End new 2020-08-04
gen u09c = 100 - u09a - u09b
replace u09c = . if missing(u09a) & missing(u09b) // new 2020-08-04
replace u09c = 0 if u09c < 0
replace s_export = u09c if year == 2013
drop u09a u09b u09c

replace v09a = . if v09a == -9 | v09a == -8
replace v09b = . if v09b == -9 | v09b == -8
* Start new 2020-08-04
replace v09a = 0 if missing(v09a) & !missing(v09b) 
replace v09b = 0 if missing(v09b) & !missing(v09a) 
* End new 2020-08-04
gen v09c = 100 - v09a - v09b
replace v09c = . if missing(v09a) & missing(v09b) // new 2020-08-04
replace v09c = 0 if v09c < 0
replace s_export = v09c if year == 2014
drop v09a v09b v09c

replace w08a = . if w08a == -9 | w08a == -8
replace w08b = . if w08b == -9 | w08b == -8
* Start new 2020-08-04
replace w08a = 0 if missing(w08a) & !missing(w08b) 
replace w08b = 0 if missing(w08b) & !missing(w08a) 
* End new 2020-08-04
gen w08c = 100 - w08a - w08b
replace w08c = . if missing(w08a) & missing(w08b) // new 2020-08-04
replace w08c = 0 if w08c < 0
replace s_export = w08c if year == 2015
drop w08a w08b w08c

replace uebst = . if uebst == -9 | uebst == -8

replace invest = . if invest == -9 | invest == -5 | invest == -4

replace leiharb = . if leiharb == -9 | leiharb == -8


* Shift year, da Abfrage Exportanteil vom Vorjahr, dito: geschvol und anteil vorleistungen, uebst und invest. NICHT aber LOHN!

* Nochmal checken, dass sich  br tv uet obtv leiharb aufs das Befragungsjahr beziehen!

preserve
keep idnum year lohn br tv uet obtv leiharb hr
save "$temp/bp9314_temp", replace
*use "$temp/bp9314_temp", clear
restore
drop lohn br tv uet obtv leiharb

su year
gen year_bp_befragung = year
replace year = year - 1
gen a = (year - 1974)
label var year "Jahr"
label var a "AWFP year index"
label var year_bp_befragung "Jahr der BP Befragung"
label var s_export "exportanteil am umsatz; in %"


merge 1:1 idnum year using "$temp/bp9314_temp"
drop _merge
erase "$temp/bp9314_temp.dta"

**
/*
bysort betnr: egen  uet_mode = mode(uet), min
bysort betnr: egen   br_mode = mode(br), min
bysort betnr: egen   tv_mode = mode(tv), min
bysort betnr: egen obtv_mode = mode(obtv), min

gen tv_mode_2 = tv_mode
replace tv_mode_2 = 4 if tv_mode_2 == 3
replace tv_mode_2 = 3 if tv_mode_2 == 2
replace tv_mode_2 = 2 if ///
obtv_mode == 1 & missing(tv_mode_2) 

label define tv_mode ///
1 "1 branchentarifvertrag" ///
2 "2 Orientierung an branchentarifv." ///
3 "3 haustarif/firmentarif" ///
4 "4 kein tarifvertrag"
label values tv_mode_2 tv_mode
*/
**



* ALLES nach unten geschoben, da hier erst Timing definitiv richtig ist.
*********************************************************
*** BH, define further variables, first create value added of last year (as variables are in t-1), then iterate one year forward

su anteilvor, de
* Anteil Vorleistungen in wenigen Fällen > 100
* Setze diese auf 100
replace anteilvor = 100 if anteilvor > 100 & !missing(anteilvor)
su anteilvor, de

su geschvol, de
gen value_added = geschvol*(100 - anteilvor) // 1 zu 100 geändert, da anteilvor [1-100]
su value_added, de

gen intermediaries = geschvol*anteilvor/100 // /100 ergänzt, da anteilvor [1-100]

su lohn, de
gen labor_share= lohn/value_added
su labor_share, de
***********************************************************



keep if year >= 1993 & year <= 2014



gen s_export_imp = s_export
sort idnum a
replace s_export_imp = (s_export_imp[_n-1]+s_export_imp[_n+1])/2 if ///
missing(s_export_imp) & !missing(s_export_imp[_n-1]) & /// 
!missing(s_export_imp[_n+1]) & idnum == idnum[_n-1] & idnum == idnum[_n+1] & ///
 a - 1 == a[_n-1] & a + 1 == a[_n+1]

 
sort a

count if missing(s_export)
su s_export, de
by a: su s_export, de

count if missing(s_export_imp)
su s_export_imp, de
by a: su s_export_imp, de

count if missing(value_added)
su value_added, de
by a: su value_added, de

count if missing(intermediaries)
su intermediaries, de
by a: su intermediaries, de

count if missing(labor_share)
su labor_share, de
by a: su labor_share, de

compress
save "$temp/bp9314", replace

*use "$temp/bp9314", clear
cap log close


********************************************************************************


cap log close
log using "$log\bp9314_betnr_list_$date", text replace

* Generate betnr list for IAB Establishment Panel (BP)

forv y = 1993 / 2014 {
use "$bp9317\iabbp_`y'", clear
keep idnum
gen year = `y'
compress
save "$temp\BP_idnum_`y'", replace
}

use "$temp\BP_idnum_1993", clear
forv y = 1994 / 2014 {
append using "$temp\BP_idnum_`y'"
}
compress
save "$temp\BP_idnum_year", replace 


forv y = 1993 / 2014 {
erase "$temp\BP_idnum_`y'.dta"
}

*use "$betnr_idnum\betnr_idnum_9317", clear

*use "$temp\BP_idnum_year", clear
merge m:1 idnum using "$betnr_idnum\betnr_idnum_9317"
keep if _merge == 3
drop _merge

duplicates drop
drop if missing(betnr)
sort idnum year
assert year != year[_n-1] if idnum == idnum[_n-1]

tab betnr if (betnr == betnr[_n-1] & year == year[_n-1]) | (betnr == betnr[_n+1] & year == year[_n+1])

drop if idnum == 79537
drop if idnum == 4536
drop if betnr == 35753888

drop if betnr == 57245449 | betnr == 87418931
drop if idnum == 84884 | idnum == 84883 | idnum == 4143 | idnum == 56081

sort betnr year
assert year != year[_n-1] if betnr == betnr[_n-1]

sort idnum betnr 
assert betnr == betnr[_n-1] if idnum == idnum[_n-1]

drop year
duplicates drop

compress
save "$temp\betnr_idnum_year", replace
*use  "$temp\betnr_idnum_year", clear
cap log close


********************************************************************************


cap log close
log using "$log\bp9314_AWFP_$date", text replace

* Zusammenspielen von Betriebspanel und AWFP

use "$temp/bp9314", clear

merge m:1 idnum using "$temp\betnr_idnum_year"
keep if _merge == 3
drop _merge 

replace a = year - 1974

sort betnr a
count if (betnr==betnr[_n-1] & a==a[_n-1]) | (betnr==betnr[_n+1] & a==a[_n+1])


drop if idnum == 79537
drop if idnum == 4536
drop if betnr == 35753888

drop if betnr == 57245449 | betnr == 87418931
drop if idnum == 84884 | idnum == 84883 | idnum == 4143 | idnum == 56081

compress
save "$temp/bp9314_clean", replace

********************************************************************************
********************************************************************************
********************************************************************************

use "$temp/bp9314_clean", clear

*merge 1:1 a betnr using "$awfp\pa102"
merge 1:1 a betnr using "$temp\AWFP_a_93_14", keepusing(w93_imp w93) // w73 w73_imp w03 w08 w93
*keep if _merge == 3
drop if _merge == 2
drop _merge

drop if idnum == 79537
drop if idnum == 4536
drop if betnr == 35753888

drop if betnr == 57245449 | betnr == 87418931
drop if idnum == 84884 | idnum == 84883 | idnum == 4143 | idnum == 56081

compress
save "$temp\BP_s_export_wz_year", replace

use "$temp\BP_s_export_wz_year", clear

replace w93_imp = floor(w93_imp/10)
bysort betnr: egen w93_2 = mode(w93_imp), maxmode
sort betnr year
replace w93_2 = w93_2[_n-1] if missing(w93_2) & betnr == betnr[_n-1] 
gsort betnr -year
replace w93_2 = w93_2[_n-1] if missing(w93_2) &  betnr == betnr[_n-1]

drop if missing(w93_2)
drop if missing(s_export)

tab w93_2, mis
su s_export, de
su s_export [aweight = hr], de


preserve
keep if inrange(year,1993,2004)
keep a s_export w93_2
collapse (mean) s_export (p25) s_export25 = s_export, by(a)
gen c = 1
collapse (mean) s_export s_export25, by(c)
su s_export
global m_s_export = r(mean)
dis $m_s_export
su s_export25
global m_s_export25 = r(mean)
dis $m_s_export25
restore

preserve
keep if inrange(year,1993,2004)
keep a s_export w93_2 hr
collapse (mean) s_export (p25) s_export25 = s_export [aweight = hr], by(a)
gen c = 1
collapse (mean) s_export s_export25, by(c)
su s_export
global m_s_export_w = r(mean)
dis $m_s_export_w
su s_export25
global m_s_export25_w = r(mean)
dis $m_s_export25_w
restore

preserve
keep a s_export w93_2
gen c = 1
collapse (sum) c (mean) s_export (p25) s_export25 = s_export, by(a w93_2)
collapse (sum) c (mean) s_export s_export25, by(w93_2)
compress
save "$temp\BP_s_export_wz93_2", replace
restore

preserve
keep a s_export w93_2 hr
gen c = 1
collapse (sum) c (mean) s_export (p25) s_export25 = s_export [aweight = hr], by(a w93_2)
collapse (sum) c (mean) s_export s_export25, by(w93_2)
compress
rename s_export s_export_w
rename s_export25 s_export25_w
rename c c_w
save "$temp\BP_s_export_wz93_2_w", replace
restore

use "$temp\BP_s_export_wz93_2_w", clear
merge 1:1 w93_2 using "$temp\BP_s_export_wz93_2"
drop _merge
gen m_s_export = $m_s_export
gen m_s_export_w = $m_s_export_w

gen m_s_export25 = $m_s_export25
gen m_s_export25_w = $m_s_export25_w

su c, de
corr s_export s_export_w
corr s_export s_export_w if c <= 81
corr s_export s_export_w if c > 81 & c < 20570 
corr s_export s_export_w if c >= 20570

corr s_export25 s_export25_w
corr s_export25 s_export25_w if c <= 81
corr s_export25 s_export25_w if c > 81 & c < 20570 
corr s_export25 s_export25_w if c >= 20570


su c_w, de
corr c c_w

gen above_mean   = (s_export   > m_s_export)
gen above_mean_w = (s_export_w > m_s_export_w) 

gen above_p25   = (s_export25   > m_s_export25)
gen above_p25_w = (s_export25_w > m_s_export25_w) 

compress
save "$temp\BP_s_export_wz93", replace
*use "$temp\BP_s_export_wz93", clear

********************************************************************************


use "$temp\AWFP_a_93_14", clear


* Merge firm specific export shares
merge 1:1 betnr a using "$temp/bp9314_clean"
drop if _merge == 2
gen BP = (_merge==3)
cap drop _merge 

cap drop year_bp_befragung 
cap drop w73 
cap drop w73_imp 
*cap drop w93_imp // district


compress



drop if idnum == 79537
drop if idnum == 4536
drop if betnr == 35753888

drop if betnr == 57245449 | betnr == 87418931
drop if idnum == 84884 | idnum == 84883 | idnum == 4143 | idnum == 56081

cap drop idnum 

compress
save "$temp\AWFP_a_93_14_V2", replace // V2 == mit BP Variablen
*use "$temp\AWFP_a_93_14_V2", clear
cap log close
clear


********************************************************************************

use "$temp\AWFP_a_93_14_V2", clear

gen temp = floor(w93_imp/10)
bysort betnr: egen w93_2 = mode(temp), maxmode
drop temp
sort betnr year
replace w93_2 = w93_2[_n-1] if missing(w93_2) & betnr == betnr[_n-1] 
gsort betnr -year
replace w93_2 = w93_2[_n-1] if missing(w93_2) & betnr == betnr[_n-1]

merge m:1 w93_2 using "$temp\BP_s_export_wz93"
tab w93_2 if _merge == 1
drop _merge 

tab BP, mis

compress
save "$temp\AWFP_a_93_14_V2_2", replace // V2 == mit BP Variablen
*use "$temp\AWFP_a_93_14_V2_2", clear

********************************************************************************
********************************************************************************



gen dw_imp_sum = dw_imp_mean * st_eop

gen JT = st_eop - st_eop_lag
label var JT "Job turnover"

gen JC = 0
label var JC "Job creation"
replace JC =     JT  if JT > 0

gen JD = 0
label var JD "Job destruction"
replace JD = abs(JT) if JT < 0

drop JT

gen N = (st_eop + st_eop_lag)/2
label var N "(st_eop + st_eop_lag)/2"

gen JCR_e = JC / N
label var JCR_e "Job creation rate"

gen JDR_e = JD / N
label var JDR_e "Job destruction rate"

drop JC JD

gen inR_e = in_e / N
label var inR_e "Inflow rate from employment"

gen outR_e = out_e / N
label var outR_e "Outflow rate into employment"

********************************************************************************
*** BH, add value added, intermediaries here!!

rename labor_share labor_share_e 
gen lohn_e = lohn // lohn aus BP
gen dw_imp_sum_e = dw_imp_sum
gen value_added_e = value_added

rename geschvol revenues
gen revenues_e = revenues

gen export = s_export_imp*revenues
gen export_e = export

gen profitability= value_added - lohn 
gen profitability_e = profitability

tab uebst, mis
su leiharb, de

gen invest_e = invest
rename dw_imp_mean dw_imp_mean_e
rename in_e in_from_empl
rename out_e out_to_empl

gen est = 1
label var est "Anzahl Betriebe"

cap drop _merge

* UPDATEN!
merge m:1 year using "$data\controlsUpdate.dta"
keep if _merge == 3
drop _merge

compress
save "$temp\AWFP_a_93_14_V3", replace
*use "$temp\AWFP_a_93_14_V3", clear

tab w93_2, mis
drop if inrange(w93_2,1,14)
drop if inrange(w93_2,95,99)
drop if missing(w93_2)
tab w93_2, mis

drop w93 w03 w08 w93_imp // dw_imp_sd

compress
save "$temp\AWFP_a_93_14_final", replace


********************************************************************************

*use "$temp\AWFP_a_93_14_final", clear


rename log_real_gdp_ger log_gdp_ger 
rename log_real_gdp_world log_gdp_world
rename log_reer_ger log_reer

gen double wage_sum = st_eop* dw_imp_mean_e

gen log_steop         = log(st_eop)
gen log_stall         = log(st_all)
gen log_stnml         = log(st_nml)
gen log_wage_sum      = log(wage_sum)
gen log_wage_avg      = log(dw_imp_mean_e)
gen log_valueadded    = log(value_added_e)
gen log_rev           = log(revenues_e)
gen log_profitability = log(profitability_e)
gen log_invest        = log(invest_e)
gen log_JCR_e         = log(JCR_e)
gen log_JDR_e         = log(JDR_e)


gen byte hartziv = (year>=2005)

gen a_sq = a*a

gen hartziv_above_mean = (hartziv==1 & above_mean==1)
gen hartziv_above_p25  = (hartziv==1 & above_p25==1)

keep log_steop log_stall log_stnml log_wage_sum log_wage_avg log_valueadded log_rev log_profitability log_invest log_JCR_e log_JDR_e log_gdp_ger log_gdp_world log_reer hartziv hartziv_above_mean betnr BP a a_sq hr above_mean st_nml wage_sum hartziv_above_p25 above_p25 anteilvor value_added_e revenues_e w93_2

rename anteilvor anteilvor_e

compress
save "$temp\AWFP_a_93_14_final_reg_full", replace

bysort betnr: egen mean_stnml = mean(st_nml)
su mean_stnml, de
keep if mean_stnml >= 10

compress
save "$temp\AWFP_a_93_14_final_reg", replace


keep w93_2 above_mean
collapse (mean) above_mean, by(w93_2)
tab w93_2 above_mean, mis


********************************************************************************

*use betnr a above_mean st_nml using  "$temp\AWFP_a_93_14_final_reg_full", clear // bet 19.3% 33.2% st_nml above mean
use betnr a above_mean st_nml wage_sum using  "$temp\AWFP_a_93_14_final_reg", clear

gen year = a + 1974
su year
keep if year <= 2004

gen c = 1 
collapse (sum) anzahl_betriebe = c st_nml wage_sum (mean) mean_stnml = st_nml, by(above_mean)

bysort above_mean: tab anzahl_betriebe
bysort above_mean: tab st_nml
bysort above_mean: tab mean_stnml

set obs 3
replace above_mean = . in 3
replace anzahl_betriebe = 100 / (anzahl_betriebe[_n-1] + anzahl_betriebe[_n-2]) *  anzahl_betriebe[_n-1] if missing(above_mean)
replace st_nml = 100 / (st_nml[_n-1] + st_nml[_n-2]) *  st_nml[_n-1] if missing(above_mean)
replace wage_sum = 100 / (wage_sum[_n-1] + wage_sum[_n-2]) *  wage_sum[_n-1] if missing(above_mean)


compress
save "$temp\share_above_mean", replace // 29.2% betriebe , 36.8% st_nml, 44.5 wage_sum above mean



use betnr a above_p25 st_nml wage_sum using  "$temp\AWFP_a_93_14_final_reg", clear

gen year = a + 1974
su year
keep if year <= 2004

gen c = 1 
collapse (sum) anzahl_betriebe = c st_nml wage_sum (mean) mean_stnml = st_nml, by(above_p25)

bysort above_p25: tab anzahl_betriebe
bysort above_p25: tab st_nml
bysort above_p25: tab mean_stnml

set obs 3
replace above_p25 = . in 3
replace anzahl_betriebe = 100 / (anzahl_betriebe[_n-1] + anzahl_betriebe[_n-2]) *  anzahl_betriebe[_n-1] if missing(above_p25)
replace st_nml = 100 / (st_nml[_n-1] + st_nml[_n-2]) *  st_nml[_n-1] if missing(above_p25)
replace wage_sum = 100 / (wage_sum[_n-1] + wage_sum[_n-2]) *  wage_sum[_n-1] if missing(above_p25)


compress
save "$temp\share_above_p25", replace // 11.46% betriebe , 20.93% st_nml, 26.03 wage_sum above mean



use betnr a above_mean value_added_e revenues_e st_nml wage_sum using  "$temp\AWFP_a_93_14_final_reg", clear

*drop if missing(value_added_e)
*drop if missing(revenues_e)

gen year = a + 1974
su year
keep if year <= 2004

gen c = 1 
collapse (sum) anzahl_betriebe = c st_nml value_added_e revenues_e wage_sum, by(above_mean)

set obs 3
replace above_mean = . in 3

replace anzahl_betriebe = 100 / (anzahl_betriebe[_n-1] + anzahl_betriebe[_n-2]) *  anzahl_betriebe[_n-1] if missing(above_mean)

replace st_nml = 100 / (st_nml[_n-1] + st_nml[_n-2]) *  st_nml[_n-1] if missing(above_mean)

replace value_added_e = 100 / (value_added_e[_n-1] + value_added_e[_n-2]) *  value_added_e[_n-1] if missing(above_mean)

replace revenues_e = 100 / (revenues_e[_n-1] + revenues_e[_n-2]) *  revenues_e[_n-1] if missing(above_mean)

replace wage_sum = 100 / (wage_sum[_n-1] + wage_sum[_n-2]) *  wage_sum[_n-1] if missing(above_mean)

compress
save "$temp\share_above_p50_new", replace 
* 29.2% betriebe , 36.8% st_nml, 44.5 wage_sum above mean
* 12.4% reveneus; 72.2% value_added

/*
use "$temp\AWFP_a_93_14_final", clear

** Aggregierte Datensätze AWFP
preserve
collapse (sum) est st_eop st_eop_lag st_all st_nml dw_imp_sum lohn in_from_empl out_to_empl value_added revenues export profitability invest ///
(mean) dw_imp_sd dw_imp_mean_e dw_imp_sum_e lohn_e value_added_e revenues_e export_e profitability_e s_export_imp s_export JCR_e JDR_e inR_e outR_e labor_share_e invest_e, by(a)
gen labor_share = lohn / value_added
gen JT = st_eop - st_eop_lag
label var JT "Job turnover"
gen JC = 0
label var JC "Job creation"
replace JC =     JT  if JT > 0
gen JD = 0
label var JD "Job destruction"
replace JD = abs(JT) if JT < 0
drop JT
gen N = (st_eop + st_eop_lag)/2
label var N "(st_eop + st_eop_lag)/2"
gen JCR = JC / N
label var JCR "Job creation rate"
gen JDR = JD / N
label var JDR "Job destruction rate"
gen inR = in_from_empl / N
label var inR_e "Inflow rate from employment"
gen outR = out_to_empl / N
label var outR_e "Outflow rate into employment"
gen dw_imp_mean = dw_imp_sum / st_eop
compress
save "$temp\AWFP_by_a", replace
restore 

preserve
collapse (sum) est st_eop st_eop_lag st_all st_nml dw_imp_sum lohn in_from_empl out_to_empl value_added revenues export profitability invest ///
(mean) dw_imp_sd dw_imp_mean_e dw_imp_sum_e lohn_e value_added_e revenues_e export_e profitability_e s_export_imp s_export JCR_e JDR_e inR_e outR_e labor_share_e invest_e, by(a above_mean)
gen labor_share = lohn / value_added
gen JT = st_eop - st_eop_lag
label var JT "Job turnover"
gen JC = 0
label var JC "Job creation"
replace JC =     JT  if JT > 0
gen JD = 0
label var JD "Job destruction"
replace JD = abs(JT) if JT < 0
drop JT
gen N = (st_eop + st_eop_lag)/2
label var N "(st_eop + st_eop_lag)/2"
gen JCR = JC / N
label var JCR "Job creation rate"
gen JDR = JD / N
label var JDR "Job destruction rate"
gen inR = in_from_empl / N
label var inR_e "Inflow rate from employment"
gen outR = out_to_empl / N
label var outR_e "Outflow rate into employment"
gen dw_imp_mean = dw_imp_sum / st_eop
compress
save "$temp\AWFP_by_a_mean", replace
restore 


** Aggregierte Datensätze BP
keep if BP == 1

preserve
collapse (sum) est st_eop st_eop_lag st_all st_nml dw_imp_sum lohn in_from_empl out_to_empl value_added revenues export profitability invest ///
(mean) dw_imp_sd dw_imp_mean_e dw_imp_sum_e lohn_e value_added_e revenues_e export_e profitability_e s_export_imp s_export JCR_e JDR_e inR_e outR_e labor_share_e invest_e, by(a)
gen labor_share = lohn / value_added
gen JT = st_eop - st_eop_lag
label var JT "Job turnover"
gen JC = 0
label var JC "Job creation"
replace JC =     JT  if JT > 0
gen JD = 0
label var JD "Job destruction"
replace JD = abs(JT) if JT < 0
drop JT
gen N = (st_eop + st_eop_lag)/2
label var N "(st_eop + st_eop_lag)/2"
gen JCR = JC / N
label var JCR "Job creation rate"
gen JDR = JD / N
label var JDR "Job destruction rate"
gen inR = in_from_empl / N
label var inR_e "Inflow rate from employment"
gen outR = out_to_empl / N
label var outR_e "Outflow rate into employment"
gen dw_imp_mean = dw_imp_sum / st_eop
compress
save "$temp\BP_by_a", replace
restore 

preserve
collapse (sum) est st_eop st_eop_lag st_all st_nml dw_imp_sum lohn in_from_empl out_to_empl value_added revenues export profitability invest ///
(mean) dw_imp_sd dw_imp_mean_e dw_imp_sum_e lohn_e value_added_e revenues_e export_e profitability_e s_export_imp s_export JCR_e JDR_e inR_e outR_e labor_share_e invest_e, by(a above_mean)
gen labor_share = lohn / value_added
gen JT = st_eop - st_eop_lag
label var JT "Job turnover"
gen JC = 0
label var JC "Job creation"
replace JC =     JT  if JT > 0
gen JD = 0
label var JD "Job destruction"
replace JD = abs(JT) if JT < 0
drop JT
gen N = (st_eop + st_eop_lag)/2
label var N "(st_eop + st_eop_lag)/2"
gen JCR = JC / N
label var JCR "Job creation rate"
gen JDR = JD / N
label var JDR "Job destruction rate"
gen inR = in_from_empl / N
label var inR_e "Inflow rate from employment"
gen outR = out_to_empl / N
label var outR_e "Outflow rate into employment"
gen dw_imp_mean = dw_imp_sum / st_eop
compress
save "$temp\BP_by_a_mean", replace
restore 
*/

cap log close
clear
