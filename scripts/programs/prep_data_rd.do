cap program drop prep_data_rd
program define prep_data_rd

	syntax , bandwidth(integer)
	
	isid agemo_mda
	
	* Death rates per 100,000 person-years (divide population by 12 age-months)
	* Account for the fact that there are 12 ages in months in a single calendar month (e.g. 16y0m, 16y1m,.., 16y11m in January 1998) 
	* Note: all death rate vars begin with "cod"
	cap unab death_rate_vars : cod*
	qui foreach  y of local death_rate_vars {
		replace `y'=100000*`y'/(pop/12)
		label var `y' "Deaths per 100,000"
	}	
	
	* Above MDA indicator
	gen post=(agemo_mda>=0)
	
	* Construct weights for triangular kernel with bandwidth of 13
	local bw = `bandwidth'
	gen tri_wgt = 0
	qui forval x = 0/`=`bw'-1' {
		replace tri_wgt=(`bw'-`x')/`bw' if agemo_mda==`x'
	}
	qui forval x = 2/`bw' {
		replace tri_wgt=(`bw'-`x'+1)/`bw' if agemo_mda==-(`x'-1)
	}
	
	* Indicator for first month of driving eligibility
	gen firstmonth=(agemo_mda==0)
end
