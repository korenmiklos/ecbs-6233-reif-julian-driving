* Standardized cleaning of variable names
program drop _all
program clean_varnames 

	local indent "\ \ \ \"

	* Mortality
	replace `1' = "All causes" if `1'=="any"
	replace `1' = "External causes" if `1'=="external"
	replace `1' = "`indent' Motor vehicle accident" if `1'=="MVA"
	replace `1' = "`indent' Suicide and accident" if `1'=="sa"
	replace `1' = "`indent' `indent' Firearm" if `1'=="sa_firearms" | `1'=="firearms"
	replace `1' = "`indent' `indent' Poisoning" if `1'=="sa_poisoning" | `1'=="poisoning"
	replace `1' = "`indent' `indent' `indent' Drug overdose" if `1'=="sa_poisoning_subst" | `1'=="poisoning_subst"
	replace `1' = "`indent' `indent' `indent' Carbon monoxide and other gases" if `1'=="sa_poisoning_gas" | `1'=="poisoning_gas"
	replace `1' = "`indent' `indent' Drowning" if `1'=="sa_drowning" | `1'=="drowning"
	replace `1' = "`indent' `indent' Other" if `1'=="sa_other" | `1'=="other"
	replace `1' = "`indent' Homicide" if `1'=="homicide"
	replace `1' = "`indent' Other external" if `1'=="extother"
	replace `1' = "Internal causes" if `1'=="internal"
	
	* Add Health
	replace `1' = "Has driver's license" if `1'=="DriverLicense"
	replace `1' = "Miles driven (miles/yr) (baseline)" if `1'=="VehicleMiles_150"
	replace `1' = "Miles driven (miles/yr) (alternate)" if `1'=="VehicleMiles_265"
	
	* Heterogeneity	
	replace `1' = subinstr(`1',"WhiteMale",      "White male",     1)
	replace `1' = subinstr(`1',"WhiteFemale",    "White female",   1)
	replace `1' = subinstr(`1',"NonwhiteMale",   "Nonwhite male",  1)
	replace `1' = subinstr(`1',"NonwhiteFemale", "Nonwhite female",1)
	
	replace `1' = "Full sample" if strpos(`1',"All") & !strpos(`1',"causes")
	
	replace `1' = "`indent' MDA is 16"   if `1'=="mda192"
	replace `1' = "`indent' MDA is not 16"   if `1'=="mda_not192"

	replace `1' = "January"   if `1'=="birmonth1" | `1'=="birmonth1_Female"
	replace `1' = "February"  if `1'=="birmonth2" | `1'=="birmonth2_Female"
	replace `1' = "March"     if `1'=="birmonth3" | `1'=="birmonth3_Female"
	replace `1' = "April"     if `1'=="birmonth4" | `1'=="birmonth4_Female"
	replace `1' = "May"       if `1'=="birmonth5" | `1'=="birmonth5_Female"
	replace `1' = "June"      if `1'=="birmonth6" | `1'=="birmonth6_Female"
	replace `1' = "July"      if `1'=="birmonth7" | `1'=="birmonth7_Female"
	replace `1' = "August"    if `1'=="birmonth8" | `1'=="birmonth8_Female"
	replace `1' = "September" if `1'=="birmonth9" | `1'=="birmonth9_Female"
	replace `1' = "October"   if `1'=="birmonth10" | `1'=="birmonth10_Female"
	replace `1' = "November"  if `1'=="birmonth11" | `1'=="birmonth11_Female"
	replace `1' = "December"  if `1'=="birmonth12" | `1'=="birmonth12_Female"
	
end

* Destring with a sigfig() option [code taken from regsave_tbl] - used for formatting decimals in the tables
program gtostring

	syntax varlist, sigfig(numlist integer min=1 max=1 >=1 <=20) [force replace gen(passthru)]
	
	if "`sigfig'"!=""   {
		if "`format'"!="" {
			di as error "Cannot specify both the sigfig and format options."
			exit 198					
		}
		local format "%18.`sigfig'gc"
	}
	
	tostring `varlist', `force' `replace' format(`format') `gen'

	qui foreach table of varlist `varlist' {
	
		cap confirm string var `table'
		if !_rc {

			tempvar tmp diff tail numast intvar orig lngth
			
			gen `intvar' = `table'=="."
			gen `orig' = `table'
					
			gen     `tmp' = subinstr(`table',".","",1)
			replace `tmp' = subinstr(`tmp',".","",1)
			replace `tmp' = subinstr(`tmp',"(","",1)
			replace `tmp' = subinstr(`tmp',")","",1)
			replace `tmp' = subinstr(`tmp',"[","",1)
			replace `tmp' = subinstr(`tmp',"]","",1)
			replace `tmp' = subinstr(`tmp',"*","",.)
			replace `tmp' = subinstr(`tmp',"-","",.)
			
			* Remove leading zero's following the decimal point (they don't count towards sig figs)
			gen `lngth' = length(`tmp')
			summ `lngth'
			forval x = `r(max)'(-1)1 {
				replace `tmp' = subinstr(`tmp', "0"*`x',"",1) if substr(`tmp',1,`x')=="0"*`x'
			}
			
			gen `diff' = `sigfig' - length(`tmp')
			gen `tail' = "0"*`diff'
			gen `numast' = length(`table') - length(subinstr(`table', "*", "", .))

			* Leading zero's
			replace `table' = "0"  + `table' if substr(`table',1,1)=="."
			replace `table' = subinstr(`table',"-.","-0.",1)   if substr(`table',1,2)=="-."
			replace `table' = subinstr(`table',"(.","(0.",1)   if substr(`table',1,2)=="(."
			replace `table' = subinstr(`table',"[.","[0.",1)   if substr(`table',1,2)=="[."
			replace `table' = subinstr(`table',"(-.","(-0.",1) if substr(`table',1,3)=="(-."
			replace `table' = subinstr(`table',"[-.","[-0.",1) if substr(`table',1,3)=="[-."

			* Trailing zero's (note: asterisks can't occur with ")" or "]", because those are only for stderrs/tstats/ci)
			replace `table' = `table' +       `tail'                                                 if strpos(`table',".")!=0 & strpos(`table',"*")==0 & substr(`table',1,1)!="(" & substr(`table',1,1)!="[" & !mi(`tail')
			replace `table' = `table' + "." + `tail'                                                 if strpos(`table',".")==0 & strpos(`table',"*")==0 & substr(`table',1,1)!="(" & substr(`table',1,1)!="[" & !mi(`tail')
			
			replace `table' = substr(`table',1,length(`table')-`numast') +       `tail' + "*"*`numast'     if strpos(`table',".")!=0 & strpos(`table',"*")!=0 & substr(`table',1,1)!="(" & substr(`table',1,1)!="[" & !mi(`tail')
			replace `table' = substr(`table',1,length(`table')-`numast') + "." + `tail' + "*"*`numast'     if strpos(`table',".")==0 & strpos(`table',"*")!=0 & substr(`table',1,1)!="(" & substr(`table',1,1)!="[" & !mi(`tail')
			
			replace `table' = subinstr(`table',")",`tail'+")",1) if strpos(`table',".")!=0 & substr(`table',1,1)=="("
			replace `table' = subinstr(`table',"]",`tail'+"]",1) if strpos(`table',".")!=0 & substr(`table',1,1)=="["
			
			* Variables that were stored as integers (or missing) are exact and shouldn't be altered
			replace `table' = `orig' if `intvar'==1
			replace `table' = "" if `table'=="."
					
			drop `tmp' `diff' `tail' `numast' `intvar' `orig'
		}
	}
end
