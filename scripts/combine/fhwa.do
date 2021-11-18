************
* SCRIPT: 3_combine_data.do
* PURPOSE: Create the final datasets used in the analyses
************

* Preamble (unnecessary when executing run.do)
do "scripts/programs/_config.do"

************
* Code begins
************

clear
set more off

* SEER population
use "data/seer/derived/seer_pop1983_2014st.dta", clear
keep if inrange(age, 16, 19)
	
* Create population variable for each age group
gen pop_16=pop
replace pop_16=0 if age!=16
gen pop_17=pop
replace pop_17=0 if age!=17
gen pop_18=pop
replace pop_18=0 if age!=18
gen pop_19=pop
replace pop_19=0 if age!=19
		
local vars "pop_16 pop_17 pop_18 pop_19"
collapse (sum) `vars', by(year) fast
	
keep year pop_16 pop_17 pop_18 pop_19

* Merge FHWA data
merge 1:1 year using "processed/intermediate/licensed_drivers_1983to2014.dta"
keep if _merge==3
drop _merge

* Label variables
label var pop_16 "Population aged 16"
label var pop_17 "Population aged 17"
label var pop_18 "Population aged 18"
label var pop_19 "Population aged 19"
	
* Save the data
save "processed/fhwa_8314.dta", replace

** EOF
