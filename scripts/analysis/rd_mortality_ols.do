************
* SCRIPT: 6_tables.do
* PURPOSE: Create LaTeX tables from the outputted results
************

* Preamble (unnecessary when executing run.do)
do "scripts/programs/_config.do"
do "scripts/programs/clean_var_names.do"
************
* Code begins
************

clear
set more off
tempfile t table male_female

local reg_settings "parentheses(stderr) asterisk(5 1) sigfig(3)"
local texsave_settings "replace autonumber nofix"

local fn_bracket "Robust, bias-corrected 95\% confidence intervals are reported in brackets."
local fn_asterisk "A */** indicates significance at the 5\%/1\% level using conventional inference."
local fn_familyp "Family-wise \(p\)-values, reported in braces, adjust for the number of outcome variables in each family and for the number of subgroups."

local fn_col2_ols "Column (2) reports OLS estimates from a model employing a bandwidth of 24 months and reports robust standard errors in parentheses."
local fn_col3_mse "Column (3) reports MSE-optimal estimates and reports robust, bias-corrected 95\% confidence intervals in brackets."

***********************************************************************
* OLS: Effect of driving eligibility on teenage driving and mortality
***********************************************************************

* Main mortality RD estimates
use "results/intermediate/mortality_rd.dta", clear

* Add Health RD estimates
append using "results/intermediate/addhealth_rd.dta"
replace scenario = "All" if mi(scenario)

keep if inlist(var,"1.post")

* Adjusted p-values
merge 1:1 var y rdspec scenario using "results/intermediate/adjustedp.dta", nogenerate keep(match master)

* Remove "cod_" from the variable y
replace y = subinstr(y,"cod_","",1)

preserve

local run_no = 0
qui foreach y in extother homicide sa_other sa_drowning sa_poisoning_gas sa_poisoning_subst sa_poisoning sa_firearms sa MVA external internal any VehicleMiles_265 VehicleMiles_150 DriverLicense {

	* OLS: full sample
	regsave_tbl if y=="`y'" & rdspec=="ols" & scenario=="All", name(full) `reg_settings'
	keep if inlist(var,"1.post_coef","1.post_stderr","psidak")
	replace var = "`y'_coef" if var=="1.post_coef"
	replace var = "`y'_stderr" if var=="1.post_stderr"
	replace var = "`y'_adjp" if var=="psidak"

	if `run_no'==1 append using "`table'"
	gen sortorder = _n
	local run_no = 1	
	save "`table'", replace
	restore, preserve

	* OLS: males
	regsave_tbl if y=="`y'" & rdspec=="ols" & scenario=="Male", name(male) `reg_settings'
	keep if inlist(var,"1.post_coef","1.post_stderr","psidak")
	replace var = "`y'_coef" if var=="1.post_coef"
	replace var = "`y'_stderr" if var=="1.post_stderr"
	replace var = "`y'_adjp" if var=="psidak"
	merge 1:1 var using "`table'", assert(match using) nogenerate
	save "`table'", replace
	restore, preserve
	
	* OLS: females
	regsave_tbl if y=="`y'" & rdspec=="ols" & scenario=="Female", name(female) `reg_settings'
	keep if inlist(var,"1.post_coef","1.post_stderr","psidak")
	replace var = "`y'_coef" if var=="1.post_coef"
	replace var = "`y'_stderr" if var=="1.post_stderr"
	replace var = "`y'_adjp" if var=="psidak"
	merge 1:1 var using "`table'", assert(match using) nogenerate
	save "`table'", replace
	restore, preserve

	* Mean (same for OLS and rdrobust)
	keep if y=="`y'" & rdspec=="ols" & inlist(scenario,"All","Male","Female")
	keep mean_y scenario
	ren mean_y mean_y_
	gen var = "`y'_coef"
	reshape wide mean_y_, i(var) j(scenario) str
	merge 1:1 var using "`table'", assert(match using) nogenerate
	sort sortorder
	drop sortorder
	save "`table'", replace
	restore, preserve
}

restore, not
use "`table'", clear
drop if inlist(var,"DriverLicense_adjp","VehicleMiles_150_adjp","VehicleMiles_265_adjp")

***
* Table formatting
***

order var mean_y_All full mean_y_Male male mean_y_Female female
gtostring mean_y*, force replace sigfig(3)
replace mean_y_All    = "" if mean_y_All=="."
replace mean_y_Male   = "" if mean_y_Male=="."
replace mean_y_Female = "" if mean_y_Female=="."

foreach v in male female full {
	replace `v' = "\(<\)0.0001" if real(`v')<0.0001 & strpos(var,"adjp")
	replace `v' = "\(<\)0.001" if real(`v')<0.001 & strpos(var,"adjp")
	replace `v' = "\(<\)0.01" if real(`v')<0.01 & strpos(var,"adjp")	
	replace `v' = "\{"+ `v' +"\}" if strpos(var,"adjp")
	label var `v' "RD"
}

replace var = "" if strpos(var,"_stderr")
replace var = "" if strpos(var,"_adjp")
replace var = subinstr(var,"_coef","",1)
clean_varnames var
replace var = "\addlinespace[1ex] " + var if !mi(var)

* Create panels
ingap 1 7
replace var = "A. Driving" in 1 if mi(var)
replace var = "B. Mortality" in 8 if mi(var)

* Label variables
label var full "RD"
label var male "RD"
label var female "RD"
label var mean_y_All "Mean"
label var mean_y_Male "Mean"
label var mean_y_Female "Mean"
label var var "Outcome variable"

* Output table
local title "OLS estimates of effect of driving eligibility on teenage driving and mortality"
local headerlines "& \multicolumn{2}{c}{Full sample} & \multicolumn{2}{c}{Male} & \multicolumn{2}{c}{Female}" "\cmidrule(lr){2-3} \cmidrule(lr){4-5} \cmidrule(lr){6-7}"
local fn "Notes: This table replicates Table \ref{tab:rd_mortality} but uses an OLS estimator with a bandwidth of 24 months instead of an MSE-optimal estimator. Columns (1), (3), and (5) report means of the dependent variable one year before reaching the minimum driving age (MDA). Columns (2), (4), and (6) report OLS estimates of \(\beta\) from equation (\ref{E - RD1}). Robust standard errors are reported in parentheses.  `fn_asterisk' `fn_familyp'"

texsave using "results/tables/rd_mortality_ols.tex", size(scriptsize) align(lCcCcCc) headerlines("`headerlines'") varlabels marker("tab:rd_mortality_ols")  bold("A. " "B. ") title("`title'") hlines(1 8) footnote("`fn'", size(scriptsize)) `texsave_settings'


** EOF
