STATA = stata -b do
CONFIG = scripts/programs/_config.do

processed/fhwa_8314.dta processed/fars_8314.dta processed/mortality_mda_combined8314st.dta processed/mortality_mda_combined8314nt.dta &: scripts/3_combine_data.do $(CONFIG) data/seer/derived/seer_pop1983_2014st.dta processed/intermediate/cdc_mortality_data83to14st.dta processed/intermediate/mdalaws_monthly8314.dta processed/intermediate/fars_raw_data8314_person.dta processed/intermediate/licensed_drivers_1983to2014.dta
	$(STATA) $<

processed/intermediate/mdalaws_monthly8314.dta processed/intermediate/cdc_mortality_data83to14st.dta &: scripts/2_clean_data.do $(CONFIG) processed/intermediate/cdc_mortality8314_raw_ageunit.dta data/mda/mda_laws_monthly_1983_2014.xlsx
	$(STATA) $<
processed/intermediate/licensed_drivers_1983to2014.dta: scripts/1_import_data.do $(CONFIG) data/fhwa/licensed_drivers_1964-2014_ages16-19.xlsx
	$(STATA) $<