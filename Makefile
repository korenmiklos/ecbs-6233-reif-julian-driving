STATA = stata -b do
CONFIG = scripts/programs/_config.do
FIGURE_UTILS = scripts/programs/clean_var_names.do
SCENARIOS = all mda192 mda_not192 mda192_female mda_not192_female mda192_male mda_not192_male male female

all: results/tables/rd_mortality_ols.tex results/tables/appendix_data_addhealth.tex results/tables/appendix_data_mda.tex results/tables/appendix_data_icd_codes.tex
results/tables/rd_mortality_ols.tex: scripts/analysis/rd_mortality_ols.do $(CONFIG) $(FIGURE_UTILS) results/intermediate/mortality_rd.dta results/intermediate/addhealth_rd.dta results/intermediate/adjustedp.dta
	$(STATA) $<
# Data tables for Add Health, MDA laws, and ICD codes were created manually
results/tables/appendix_data_addhealth.tex: data/add_health/appendix_data_addhealth.tex
	cp $< $@
results/tables/appendix_data_mda.tex: data/mda/appendix_data_mda.tex
	cp $< $@
results/tables/appendix_data_icd_codes.tex: data/icd_codes/appendix_data_icd_codes.tex
	cp $< $@
results/intermediate/mortality_rd.dta: scripts/analysis/mortality.do $(CONFIG) $(foreach scenario, $(SCENARIOS), data/mortality/derived/$(scenario).dta) 
	$(STATA) $<
results/intermediate/addhealth_rd.dta: scripts/analysis/addhealth.do scripts/programs/prep_data_rd.do $(CONFIG) data/add_health/derived/all.dta data/add_health/derived/male.dta data/add_health/derived/female.dta
	$(STATA) $<
processed/fhwa_8314.dta: scripts/combine/fhwa.do $(CONFIG) data/seer/derived/seer_pop1983_2014st.dta processed/intermediate/licensed_drivers_1983to2014.dta
	$(STATA) $<
processed/intermediate/mdalaws_monthly8314.dta: scripts/clean/mdalaw.do $(CONFIG) data/mda/mda_laws_monthly_1983_2014.xlsx
	$(STATA) $<
processed/intermediate/licensed_drivers_1983to2014.dta: scripts/import/fhwa.do $(CONFIG) data/fhwa/licensed_drivers_1964-2014_ages16-19.xlsx
	$(STATA) $<