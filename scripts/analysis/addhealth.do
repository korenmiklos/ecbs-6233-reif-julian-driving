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

local adjustedp 1

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
qui foreach scenario in "All" "Male" "Female" {
	
	* Add Health data
	local input_filename = lower("`scenario'")
	use "data/add_health/derived/`input_filename'.dta", clear	

	local outcomes "DriverLicense VehicleMiles_150 VehicleMiles_265 Work4weeks NotEnrolled"	
	
	* Prep data for RD
	prep_data_rd, bandwidth(13)	
	
	* RD regressions (OLS and MSE-optimal)
	foreach y of varlist `outcomes' {
		
		* Skip outcome-scenario combinations not illustrated in paper
		if ( inlist("`y'","Work4weeks","NotEnrolled") & !inlist("`scenario'","All") ) | ( inlist("`y'","VehicleMiles_265") & !inlist("`scenario'","All","Male","Female") ) continue
		
		* Outcome average
		summ `y' if inrange(agemo_mda, -12,-1)
		local mean_y = r(mean)
		
		* Save OLS estimates for select outcomes	
		reg `y' i.post##c.(agemo_mda) i.firstmonth [aweight=tri_wgt], robust
		predict `y'_hat
		if inlist("`y'","DriverLicense","VehicleMiles_150","VehicleMiles_265") {
			regsave using "`results'", addlabel(y,"`y'",rdspec,ols, mean_y, `mean_y', scenario,"`scenario'") `regsave_settings' `replace'
			local replace append
		}
		
		* Save data to use later for a plot with both males and females
		if inlist("`y'","DriverLicense","VehicleMiles_150") & inlist("`scenario'","Male","Female") {
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
		regsave Robust using "`results'", addlabel(y,"`y'",rdspec,rdrobust, b_conv,`=scalar(_b[Conventional])', mean_y, `mean_y', scenario,"`scenario'") `regsave_settings' append
	}

	* Figures - skip figures not illustrated in paper
	keep if inrange(agemo_mda, -12, 12)	

	foreach y in `outcomes' {
		if inlist("`y'","DriverLicense") | !inlist("`scenario'","All") continue
		local filename "`=lower("`y'")'"
	
		graph twoway (scatter `y' agemo_mda, `mformat') (line `y'_hat agemo_mda if agemo_mda <= -1, `lformat') (line `y'_hat agemo_mda if agemo_mda > 0, `lformat')  ///
					, xtitle("Age (in months) since MDA", `xtitlesize') ytitle("", `ytitlesize') xlabel(-12(2)12, `xlabsize') ylabel(, `ylabsize') graphregion(fcolor(white)) legend(off)
		graph export "results/figures/rd_`filename'.pdf", as(pdf) replace
	}
}

* Output regression results
use "`results'", clear
save "results/intermediate/addhealth_rd.dta", replace

* Output figure for driver's license and vehicle miles driven (male/female on same plot)
use "`male_female'", clear

* Driver's license
graph twoway (scatter DriverLicense_Male agemo_mda, `mformat') (line DriverLicense_hat_Male agemo_mda if agemo_mda <= -1, `lformat') (line DriverLicense_hat_Male agemo_mda if agemo_mda > 0, `lformat')  ///
				(scatter DriverLicense_Female agemo_mda, `mformat2') (line DriverLicense_hat_Female agemo_mda if agemo_mda <= -1, `lformat2') (line DriverLicense_hat_Female agemo_mda if agemo_mda > 0, `lformat2') ///	
			, xtitle("Age (in months) since MDA", `xtitlesize') ytitle("", `ytitlesize') xlabel(-12(2)12, `xlabsize') ylabel(, `ylabsize') graphregion(fcolor(white))  legend(cols(4) order(1 "Males" 2 "" 4 "Females" 5 "") `legendsize')
graph export "results/figures/rd_license_male_female.pdf", as(pdf) replace

* Vehicle miles driven
format *Male %12.0fc
graph twoway (scatter VehicleMiles_150_Male agemo_mda, `mformat') (line VehicleMiles_150_hat_Male agemo_mda if agemo_mda <= -1, `lformat') (line VehicleMiles_150_hat_Male agemo_mda if agemo_mda > 0, `lformat')  ///
				(scatter VehicleMiles_150_Female agemo_mda, `mformat2') (line VehicleMiles_150_hat_Female agemo_mda if agemo_mda <= -1, `lformat2') (line VehicleMiles_150_hat_Female agemo_mda if agemo_mda > 0, `lformat2') ///	
			, xtitle("Age (in months) since MDA", `xtitlesize') ytitle("", `ytitlesize') xlabel(-12(2)12, `xlabsize') ylabel(0(500)2500, `ylabsize') graphregion(fcolor(white))  legend(cols(4) order(1 "Males" 2 "" 4 "Females" 5 "") `legendsize')
graph export "results/figures/rd_vmd150_male_female.pdf", as(pdf) replace		

** EOF
