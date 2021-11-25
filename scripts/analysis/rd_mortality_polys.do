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

* Mortality RD estimates for robustness checks
use "results/intermediate/mortality_rd_robustness.dta", clear
drop if mi(order_poly)

* For rdrobust, we will use the point estimate from "conventional" estimate and inference from "robust" bias-correction
replace coef = b_conv

* Variable formatting
gtostring ci_lower ci_upper, force replace sigfig(3)
gen ci = "[" + ci_lower + ", " + ci_upper + "]"

preserve

local run_no = 0
foreach y in sa_poisoning MVA any {
qui foreach scen in "Female" "Male" "All" {

	* MSE-optimal linear
	regsave_tbl if scenario=="`scen'" & y=="cod_`y'" & rdspec=="rdrobust" & order_poly==1, name(linear) `reg_settings'
	keep if inlist(var,"Robust_coef","ci")
	replace var = "`y'_`scen'" if var=="Robust_coef"
	replace var = "`y'_`scen'_ci" if var=="ci"
	if `run_no'==1 append using "`table'"
	gen sortorder = _n
	local run_no = 1	
	save "`table'", replace
	restore, preserve

	* MSE-optimal quadratic
	regsave_tbl if scenario=="`scen'" & y=="cod_`y'" & rdspec=="rdrobust" & order_poly==2, name(quadratic) `reg_settings'
	keep if inlist(var,"Robust_coef","ci")
	replace var = "`y'_`scen'" if var=="Robust_coef"
	replace var = "`y'_`scen'_ci" if var=="ci"
	merge 1:m var using "`table'", assert(match using) nogenerate
	save "`table'", replace
	restore, preserve
	
	* MSE-optimal cubic
	regsave_tbl if scenario=="`scen'" & y=="cod_`y'" & rdspec=="rdrobust" & order_poly==3, name(cubic) `reg_settings'
	keep if inlist(var,"Robust_coef","ci")
	replace var = "`y'_`scen'" if var=="Robust_coef"
	replace var = "`y'_`scen'_ci" if var=="ci"
	merge 1:m var using "`table'", assert(match using) nogenerate
	save "`table'", replace
	restore, preserve
	
	* Mean (same for different orders of polynomials)
	keep if scenario=="`scen'" & y=="cod_`y'" & order_poly==1
	keep mean_y
	gen var = "`y'_`scen'"
	merge 1:m var using "`table'", assert(match using) nogenerate	
	sort sortorder
	drop sortorder
	
	save "`table'", replace
	restore, preserve
}	
}

restore, not
use "`table'", clear

***
* Table formatting
***

order var mean_y linear quadratic cubic
gtostring mean_y, force replace sigfig(3)
replace mean_y = "" if mean_y=="."

replace var = "" if strpos(var,"_ci")
replace var = "" if strpos(var,"_bw")
replace var = subinstr(var,"MVA_","",1)
replace var = subinstr(var,"sa_poisoning_","",1)
replace var = subinstr(var,"any_","",1)
clean_varnames var
replace var = "\addlinespace[1ex] " + var if !mi(var)

* Create panels
ingap 1 7 13 
replace var = "A. All deaths" in 1 if mi(var)
replace var = "B. Motor vehicle fatalities" in 8 if mi(var)
replace var = "C. Poisoning deaths" in 15 if mi(var)

* Label variables
label var linear "Linear"
label var quadratic "Quadratic"
label var cubic "Cubic"
label var mean_y "Mean"
label var var "Subgroup"

* Output table
local title "Effect of driving eligibility on mortality using different polynomial approximations"
local headerlines "& & & \multicolumn{1}{c}{RD estimate}" "\cmidrule(lr){3-5}"
local fn "Notes: The dependent variable is deaths per 100,000 person-years. Column (1) reports means of the dependent variable one year before reaching the minimum driving age (MDA). Columns (2)--(4) report estimates of \(\beta\) from equation (\ref{E - RD1}) using different polynomial approximations: linear (our preferred specification), quadratic, and cubic. `fn_bracket' `fn_asterisk'"

texsave using "results/tables/rd_mortality_polys.tex", varlabels marker("tab:rd_mortality_polys") size(footnotesize) align(lCcCcCc) headerlines("`headerlines'") bold("A. " "B. " "C. ") title("`title'") hlines(1 8 15)  footnote("`fn'", size(scriptsize)) `texsave_settings'

** EOF
