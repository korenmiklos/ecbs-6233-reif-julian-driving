************
* SCRIPT: 2_clean_data.do
* PURPOSE: Cleans the multiple cause of death and MDA law datasets
************

* Preamble (unnecessary when executing run.do)
do "scripts/programs/_config.do"

************
* Code begins
************

clear
set more off

* Data on minimum driving age laws for restricted license
clear
import excel "data/mda/mda_laws_monthly_1983_2014.xlsx", firstrow

** Minimum driving ages in months
foreach y in "1" "2" "3" "4" {
	
	* Recode minimum driving ages (e.g., change 16.01 to 193 months)
	gen minmda`y'=mda`y'
	
	* Change mda`y' to strings
	tostring mda`y', replace
	
	replace minmda`y'=minmda`y'*12
	replace minmda`y'=16*12+1 if mda`y'=="16.01"
	replace minmda`y'=16*12+3 if mda`y'=="16.03"
	replace minmda`y'=16*12+4 if mda`y'=="16.04"	
	replace minmda`y'=16*12+6 if mda`y'=="16.06"

	replace minmda`y'=15*12+3 if mda`y'=="15.03"	
	replace minmda`y'=15*12+6 if mda`y'=="15.06"
	replace minmda`y'=15*12+9 if mda`y'=="15.09"

	replace minmda`y'=14*12+3 if mda`y'=="14.03"	
	replace minmda`y'=14*12+6 if mda`y'=="14.06"
			
}

** Create full set of state, year, and month
gen start = date("1983-01-15", "YMD")
gen end = date("2015-01-15", "YMD")

* State
gen start_m = mofd(start)
gen ep_end_m = mofd(end)

gen epend_m=1
stset ep_end_m, failure(epend_m) origin(start_m) id(staters)
stsplit month, every(1)

* Year
gen year=ceil((month+1)/12)+1982
replace month=month+1

* Month
forvalues i=1/32 {
	replace month=month-12 if month>=13
}

** Minimum driving age by state, year, and month
** Apply MDA laws by month & MDA changes, using effective dates of the laws
gen mda_months=minmda1
replace mda_months=minmda2 if eff_date_u2!=. & year>yofd(eff_date_u2)
replace mda_months=minmda2 if eff_date_u2!=. & year==yofd(eff_date_u2) & month>month(eff_date_u2)
replace mda_months=minmda2 if eff_date_u2!=. & year==yofd(eff_date_u2) & month==month(eff_date_u2) & day(eff_date_u2)<=15

replace mda_months=minmda3 if eff_date_u3!=. & year>yofd(eff_date_u3)
replace mda_months=minmda3 if eff_date_u3!=. & year==yofd(eff_date_u3) & month>month(eff_date_u3)
replace mda_months=minmda3 if eff_date_u3!=. & year==yofd(eff_date_u3) & month==month(eff_date_u3) & day(eff_date_u3)<=15

replace mda_months=minmda4 if eff_date_u4!=. & year>yofd(eff_date_u4)
replace mda_months=minmda4 if eff_date_u4!=. & year==yofd(eff_date_u4) & month>month(eff_date_u4)
replace mda_months=minmda4 if eff_date_u4!=. & year==yofd(eff_date_u4) & month==month(eff_date_u4) & day(eff_date_u4)<=15

ren month monthdth

* Keep relevant variables
keep staters year monthdth mda_months
sort staters year monthdth

* Label variables
label variable monthdth "Month of death"
label variable year "Year of death"
label variable staters "State fips code"
label variable mda_months "MDA in months"

* Save the data
compress
save "processed/intermediate/mdalaws_monthly8314.dta", replace


** EOF
