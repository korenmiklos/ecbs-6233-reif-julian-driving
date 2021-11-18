************
* SCRIPT: 4_analysis.do
* PURPOSE: Estimate RD regressions
************

* Preamble (unnecessary when executing run.do)
do "scripts/programs/_config.do"

************
* Code begins
************

clear
set more off
tempfile results male_female
local regsave_settings "tstat pval ci cmdline"

***
* Formatting settings for graphs
***
* Titles and label formatting
local xtitlesize "size(medlarge)"
local ytitlesize "size(medlarge)"
local xlabsize "labsize(medium)"
local ylabsize "labsize(medium)"
	
* Marker and line fit formatting
local mformat "msym(oh) mcol(red) msize(medlarge)"
local mformat2 "msym(sh) mcol(blue) msize(medlarge)"
local mformat3 "msym(x) mcol(green) msize(medlarge)"
local lformat "clcolor(black) lwidth(medthick)"
local lformat2 "clcolor(black) lwidth(medthick) lpattern(dash)"
local legendsize "size(medlarge)"

***
* Standardized preperation code for the RD regressions
***
do "scripts/programs/prep_data_rd.do"

*****
** Heterogeneity regressions (including the main regression)
*****

local replace replace
local run_male_female = 0
qui foreach scenario in "All" "mda192" "mda_not192" "mda192_Female" "mda_not192_Female" "mda192_Male" "mda_not192_Male" "Male" "Female" {

	* Main data for analysis
	local input_filename = lower("`scenario'")
	use "data/mortality/derived/`input_filename'.dta", clear
	
	* Causes of death
	unab outcomes : cod_*

	* Prep data for RD	
	prep_data_rd, bandwidth(13)
	
	* RD regressions (OLS and MSE-optimal)
	foreach y of varlist `outcomes' {
		
		* Skip outcome-scenario combinations not illustrated in paper
		if !inlist("`y'","cod_MVA","cod_sa_poisoning") & (strpos("`scenario'","mda")|strpos("`scenario'","birmonth")|!inlist("`scenario'","All","Male","Female")) continue

		* Outcome average
		summ `y' if inrange(agemo_mda, -12,-1)
		local mean_y = r(mean)
		
		summ `y' if inrange(agemo_mda, -1,-1)
		local mean_y_month = r(mean)
		
		reg `y' i.post##c.(agemo_mda) i.firstmonth [aweight= tri_wgt], robust
		predict `y'_hat
		regsave using "`results'", addlabel(y,"`y'",rdspec,ols, mean_y, `mean_y', mean_y_month, `mean_y_month', scenario,"`scenario'") `regsave_settings' `replace'
		local replace append
		
		* Save data to use later for a plot with both males and females
		if inlist("`y'","cod_any","cod_MVA") & inlist("`scenario'","Male","Female") {
			preserve
				keep if inrange(agemo_mda, -12, 12)	
				keep `y' `y'_hat agemo_mda
				ren (`y' `y'_hat) (`y'_`scenario' `y'_hat_`scenario')
				
				if `run_male_female'==1 merge 1:1 agemo_mda using "`male_female'", assert(match) nogenerate
				save "`male_female'", replace
				local run_male_female = 1
			restore
		}			
	
		rdbwselect `y' agemo_mda, p(1) kernel(triangular) covs(firstmonth) c(0)
		rdrobust `y' agemo_mda, p(1) kernel(triangular) covs(firstmonth) c(0) h(`e(h_mserd)') b(`e(b_mserd)') all
		
		regsave Robust using "`results'", addlabel(y,"`y'",rdspec,rdrobust, b_conv, `=scalar(_b[Conventional])', mean_y, `mean_y', mean_y_month, `mean_y_month', scenario,"`scenario'") `regsave_settings' append
	}

	* Figures - skip scenarios not illustrated in paper
	keep if inrange(agemo_mda, -12, 12)
		
	if !inlist("`scenario'", "Male", "Female") continue
	local filename `=lower("`scenario'")'
		
	* Figure: all causes, external, internal
	graph twoway (scatter cod_any agemo_mda, `mformat') (line cod_any_hat agemo_mda if agemo_mda <= -1, `lformat') (line cod_any_hat agemo_mda if agemo_mda > 0, `lformat') ///
					(scatter cod_external agemo_mda, `mformat2') (line cod_external_hat agemo_mda if agemo_mda <= -1, `lformat') (line cod_external_hat agemo_mda if agemo_mda > 0, `lformat') /// 
					(scatter cod_internal agemo_mda, `mformat3') (line cod_internal_hat agemo_mda if agemo_mda <= -1, `lformat') (line cod_internal_hat agemo_mda if agemo_mda > 0, `lformat') ///
					, xtitle("Age (in months) since MDA", `xtitlesize') ytitle("Deaths per 100,000", `ytitlesize') xlabel(-12(2)12, `xlabsize') ylabel(, `ylabsize' gmax gmin) graphregion(fcolor(white)) legend(order(1 "All" 4 "External" 7 "Internal") `legendsize')
	if inlist("`scenario'", "Male", "Female") graph export "results/figures/rd_any_ext_int_`filename'.pdf", as(pdf) replace
	
	* Figures by heterogeneity specifications
	foreach y of varlist `outcomes' {
		local filename : subinstr local y "cod_" ""	
		local filename `=lower("`filename'_`scenario'")'
		
		
		* Output figures illustrated in paper
		if ( strpos("`scenario'","mda") ) continue
		if inlist("`y'","cod_any","cod_external","cod_internal","cod_MVA","cod_homicide")|inlist("`y'","cod_sa","cod_sa_firearms","cod_sa_other","cod_acct_poisoning","cod_suicide_poisoning") continue
		graph twoway (scatter `y' agemo_mda,  `mformat') (line `y'_hat agemo_mda if agemo_mda <= -1, `lformat') (line `y'_hat agemo_mda if agemo_mda > 0, `lformat')  ///
				, xtitle("Age (in months) since MDA") ytitle("Deaths per 100,000") xlabel(-12(2)12) graphregion(fcolor(white)) legend(off)				 			
		graph export "results/figures/rd_`filename'.pdf", as(pdf) replace
		
	}
}

* Output regression results
use "`results'", clear
save "results/intermediate/mortality_rd.dta", replace

* Output main figure for all causes and MVA (male/female on same plot)
use "`male_female'", clear

* All causes
graph twoway (scatter cod_any_Male agemo_mda, `mformat') (line cod_any_hat_Male agemo_mda if agemo_mda <= -1, `lformat') (line cod_any_hat_Male agemo_mda if agemo_mda > 0, `lformat')  ///
				(scatter cod_any_Female agemo_mda, `mformat2') (line cod_any_hat_Female agemo_mda if agemo_mda <= -1, `lformat2') (line cod_any_hat_Female agemo_mda if agemo_mda > 0, `lformat2') ///
			, xtitle("Age (in months) since MDA", `xtitlesize') ytitle("Deaths per 100,000", `ytitlesize') xlabel(-12(2)12, `xlabsize') ylabel(20(15)80, `ylabsize') graphregion(fcolor(white)) legend(cols(4) order(1 "Males" 2 "" 4 "Females" 5 "") `legendsize')
graph export "results/figures/rd_any_male_female.pdf", as(pdf) replace

* MVA
graph twoway (scatter cod_MVA_Male agemo_mda, `mformat') (line cod_MVA_hat_Male agemo_mda if agemo_mda <= -1, `lformat') (line cod_MVA_hat_Male agemo_mda if agemo_mda > 0, `lformat')  ///
				(scatter cod_MVA_Female agemo_mda, `mformat2') (line cod_MVA_hat_Female agemo_mda if agemo_mda <= -1, `lformat2') (line cod_MVA_hat_Female agemo_mda if agemo_mda > 0, `lformat2') ///	
			, xtitle("Age (in months) since MDA", `xtitlesize') ytitle("Deaths per 100,000", `ytitlesize') xlabel(-12(2)12, `xlabsize') ylabel(, `ylabsize') graphregion(fcolor(white))  legend(cols(4) order(1 "Males" 2 "" 4 "Females" 5 "") `legendsize')
graph export "results/figures/rd_mva_male_female.pdf", as(pdf) replace	

** EOF
