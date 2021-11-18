STATA = stata -b do
CONFIG = scripts/programs/_config.do
SCENARIOS = all mda192 mda_not192 mda192_female mda_not192_female mda192_male mda_not192_male male female

results/tables/rd_mortality_ols.tex: scripts/6_tables.do $(CONFIG) results/intermediate/mortality_rd.dta results/intermediate/addhealth_rd.dta
	$(STATA) $<
results/intermediate/mortality_rd.dta results/intermediate/addhealth_rd.dta&: scripts/4_analysis.do $(CONFIG) $(foreach scenario, $(SCENARIOS), data/mortality/derived/$(scenario).dta) data/add_health/derived/all.dta data/add_health/derived/male.dta data/add_health/derived/female.dta
	$(STATA) $<
processed/fhwa_8314.dta&: scripts/3_combine_data.do $(CONFIG) data/seer/derived/seer_pop1983_2014st.dta processed/intermediate/mdalaws_monthly8314.dta processed/intermediate/licensed_drivers_1983to2014.dta
	$(STATA) $<
processed/intermediate/mdalaws_monthly8314.dta: scripts/2_clean_data.do $(CONFIG) data/mda/mda_laws_monthly_1983_2014.xlsx
	$(STATA) $<
processed/intermediate/licensed_drivers_1983to2014.dta: scripts/1_import_data.do $(CONFIG) data/fhwa/licensed_drivers_1964-2014_ages16-19.xlsx
	$(STATA) $<