************
* SCRIPT: 1_import_data.do
* PURPOSE: imports the raw data and saves it in Stata readable format
************

* Preamble (unnecessary when executing run.do)
do "scripts/programs/_config.do"

************
* Code begins
************

clear
set more off

***************************************************
******** Federal Highway Administration ***********
***************************************************
* Licensed driver counts by age from FHWA
import excel "data/fhwa/licensed_drivers_1964-2014_ages16-19.xlsx", firstrow clear

* Drop unnecessary years to save space (keep only 1983-2014)
keep if inrange(year, 1983, 2014)

* Label variables
label var year "Year"
label var total_16 "Drivers aged 16"
label var total_17 "Drivers aged 17"
label var total_18 "Drivers aged 18"
label var total_19 "Drivers aged 19"

* Save the data
compress		
save "processed/intermediate/licensed_drivers_1983to2014.dta", replace

** EOF
