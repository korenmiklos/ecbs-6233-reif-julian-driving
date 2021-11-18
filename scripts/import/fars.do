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
tempfile tmp


* Read in the FARS data
local years     "1983  1984  1985  1986  1987  1988  1989  1990  1991  1992  1993  1994  1995  1996  1997  1998  1999  2000  2001  2002  2003  2004  2005  2006  2007  2008  2009  2010  2011  2012  2013  2014"

local run_no = 0
local num_surveys: word count `years'

** Person data
qui forval index = 1/`num_surveys' {

	tokenize `years'
	local year "``index''"
	noi di "Year: `year'"
		
	* Specify variables to keep from this dataset
	local tokeep "state age month per_typ st_case inj_sev"
	
	use "$FARS/person/`year'", clear	
	
	keep `tokeep'
	gen year = `year'
	label var year "Year of crash"
	
	***
	* Append and save
	***
	if `run_no'==1 append using "`tmp'"
	compress
	save "`tmp'", replace
		
	local run_no = 1
	
	ren state staters
}

* Save the data
compress		
save "processed/intermediate/fars_raw_data8314_person.dta", replace
