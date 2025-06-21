clear all
set more off
*set maxvar 32767, perm

*********************************************************
*Title: Genetic Education - UCSD
*Summary: 
*Written by Yeongmi Jeong
*Initial Date Created: 05-15-2024
*Last Date Updated: 
*********************************************************

cd "$path_general"
capture log close
log using "03. Logs\Genetic_Education_UCSD_draft.log", replace 

*-------------------------------------------------------------------------------
*						Load/save/merge data (long) 
*-------------------------------------------------------------------------------
*load
**1. Attention Check (responseid, attntotal, comptotal)
import delimited "$path_Data\UCSD_study_attention_check.csv", clear
save "$path_Data\UCSD_study_attention_check.dta", replace

*2. Main Data
import delimited "$path_Data\UCSD_study_pms_SEM.dem.csv", clear

*merge data --------------------------------------------------------------------
merge 1:1 responseid using "$path_Data\UCSD_study_attention_check.dta"
*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
*						Creation of variables 
*-------------------------------------------------------------------------------
** encode/create/label variables/values

*# Individual ID -------------------------------------------------------------
encode responseid, gen(s_id)
 unique s_id
 duplicates report s_id

*# Study (Biology[1] and Psychology[2]) --------------------------------------
encode sample, gen(study)
 tab study, m
 unique study
 duplicates report study

*# Epistemology (-1, 0, 1, NA) -----------------------------------------------
encode epistemology, gen(epist)
 tab epist, m
 unique epist
 duplicates report epist

*# Ontology (-1, 0, 1, NA) ---------------------------------------------------
encode ontology, gen(ont)
 tab ont, m
 unique ont
 duplicates report ont

*# Treatement conditions (Climate, Full HG, MC, POP) -------------------------
encode condition, gen(TRT)
 tab TRT, m
 unique TRT
 duplicates report TRT

 label define TRTlabel1 1 "Climate" 2 "Full HG" 3 "MC" 4 "PT"
 label define TRTlabel2 1 "Climate" 2 "Full Humane Genetics" 3 "Multifactorial Causation" 4 "Population Thinking"
  label values TRT TRTlabel1

*# Major ---------------------------------------------------------------------
encode major_clean, gen(major_c)
  tab major_c, m
  unique major_c
  duplicates report major_c
  
*# School --------------------------------------------------------------------
rename school School
encode School, gen(school)
 tab school, m 
 unique school
 duplicates report school

*# Male ----------------------------------------------------------------------
rename male Male
gen male = .
 replace male = 1 if (Male == "1")
 replace male = 0 if (Male == "0")

  label define malelabel 0 "Female" 1 "Male" 
  label values male malelabel

  tab male Male, m
  
*# Race ----------------------------------------------------------------------
/*
1. White or European
2. Black or African
3. Asian
4. American Indian or Alaskan Native
5. Native Hawaiian Native or Pacific Islander
6. Latin
7. Middle Eastern or North African
8. Prefer not to say
9. Other or Prefer to self-describe
*/

gen race5 = 0							// OUM/POC
replace race5 = 1 if (race == "1")		// White or European
replace race5 = 2 if (race == "3")		// Asian
replace race5 = 3 if (race == "6")		// Latin
replace race5 = 4 if (race == "2")		// Balck or African American

tab race race5, m

  label define race5label 0 "OUM/POC" 1 "White or European" 2 "Asian" 3 "Latin" 4 "African American" 
  label values race5 race5label
  
tab race5, m

* Race Dummies
recode race5 		 (2 3 4 = 0), copy gen(race_white)
	label var race_white "White or European"
recode race5 (2 = 1) (1 3 4 = 0), copy gen(race_asian)
	label var race_asian "Asian"
recode race5 (3 = 1) (1 2 4 = 0), copy gen(race_latin)
	label var race_latin "Latin"
recode race5 (4 = 1) (1 2 3 = 0), copy gen(race_aa)
	label var race_aa "African American"
recode race5 (0 = 1) (1 2 3 4 = 0), copy gen(race_oum)
	label var race_oum "OUM/POC"
 

*# Political Affiliation -----------------------------------------------------
/*
1. Extremely Liberal to 
~
7. Extremely Conservative
8. Haven't thought about it much
9. Prefer not to answer

WANT:
Liberal (1-3 on the scale)
Moderate (4 on the scale)
Conservative (5-7 on the scale)
Haven't thought about it much (8 on the scale)
*/

** political affiliation (4 categories) --------------------------------------
gen political_aff4 = .							
replace political_aff4 = 1 if (political >= 1 & political <= 3)		// Liberal
replace political_aff4 = 2 if (political == 4)						// Moderate
replace political_aff4 = 3 if (political >= 5 & political <= 7)		// Conservative
replace political_aff4 = 4 if (political == 8)						// Haven't thought about it much

  label define pollabel 1 "Liberal" 2 "Moderate" 3 "Conservative" 4 "Haven't thought about it much" 
  label values political_aff4 pollabel

tab  political  political_aff4, m


** political affiliation (3 categories, categories 2 & 3 are merged) ---------
recode political_aff4 (3=2) (4=3), copy gen(political_aff3)

  label define pollabel_3  1 "Liberal"  2 "Non-Liberal" 3 "Haven't thought about it much"
  label values political_aff3 pollabel_3

tab political_aff4 political_aff3, m


*# Genomics Knowledge (genetics_pm) ------------------------------------------

** generate [GK >= 0] or [GK < 0] 
gen gk_cat2  = .
 replace gk_cat2 = 1 if (genetics_pm >= 0)
 replace gk_cat2 = 2 if (genetics_pm <  0)
 
 label define gkcat2 1 "GK \$\geq$ 0" 2 "GK < 0"
 label values gk_cat2 gkcat2

 tab gk_cat2, m
 tab genetics_pm gk_cat2, m

** generate [GK >= 0.5] or [GK <= -0.5] 
gen gk_cat05  = .
 replace gk_cat05 = 1 if (genetics_pm >= 0.5)
 replace gk_cat05 = 2 if (genetics_pm <= -0.5)
 
 label define gkcat05 1 "High GK ( 0.5 \$\leq$)" 2 "Low GK (\$\leq$ -0.5)"
 label values gk_cat05 gkcat05

 tab gk_cat05, m
 tab genetics_pm gk_cat05, m

** generate [GK < -1], [-1 <= GK <= 1], or [1 < GK]
gen gk_cat3 = .
 replace gk_cat3 = 1 if (genetics_pm > 1)&!missing(genetics_pm)
 replace gk_cat3 = 2 if (genetics_pm >= -1)&(genetics_pm <= 1)&!missing(genetics_pm)
 replace gk_cat3 = 3 if (genetics_pm < -1)&!missing(genetics_pm)
 
 label define gkcat3  		1 "1 $<$ GK (High)" 	2 "-1 \$\leq$ GK \$\leq$ 1 (Middle)" 	3 "GK $<$ -1 (Low)"
 label values gk_cat3 gkcat3

 tab gk_cat3, m
 tab genetics_pm gk_cat3, m

*# cultural theory of risk (ctor_pm) -----------------------------------------


** generate [CTR >= 0] or [CTR < 0] 
gen ctr_cat2  = .
 replace ctr_cat2 = 1 if (ctor_pm >= 0)
 replace ctr_cat2 = 2 if (ctor_pm <  0)
 
 label define ctrcat2 1 "CTR \$\geq$ 0" 2 "CTR < 0"
 label values ctr_cat2 ctrcat2

 tab gk_cat2, m
 tab ctor_pm gk_cat2, m

** generate [CTR >= 0.5] or [CTR <= -0.5] 
gen ctr_cat05  = .
 replace ctr_cat05 = 1 if (ctor_pm >= 0.5)
 replace ctr_cat05 = 2 if (ctor_pm <= -0.5)
 
 label define ctrcat05 1 "High CTR ( 0.5 \$\leq$)" 2 "Low CTR (\$\leq$ -0.5)"
 label values ctr_cat05 ctrcat05

 tab ctr_cat05, m
 tab ctor_pm ctr_cat05, m

** generate [CTR < -1], [-1 <= CTR <= 1], or [1 < CTR]
gen ctr_cat3 = .
 replace ctr_cat3 = 1 if (ctor_pm > 1)&!missing(ctor_pm)
 replace ctr_cat3 = 2 if (ctor_pm >= -1)&(ctor_pm <= 1)&!missing(ctor_pm)
 replace ctr_cat3 = 3 if (ctor_pm < -1)&!missing(ctor_pm)
 
 label define ctrcat3  		1 "1 $<$ CTR (High)" 	2 "-1 \$\leq$ CTR \$\leq$ 1 (Middle)" 	3 "CTR $<$ -1 (Low)"
 label values ctr_cat3 ctrcat3

 tab ctr_cat3, m
 tab ctor_pm ctr_cat3, m

 
*# Attention Checks (attntotal)
label var attntotal "Attention Check (0-1)"
sum attntotal, detail


*# Comprehension Checks (comptotal)
label var comptotal "Comprehension Check (0-1)"
sum comptotal, detail


*# Generate indicator for each intervention relative to CONTROL --------------
tab TRT, m

** 1. at least one genetics education (HG)
gen HG = .
	replace HG = 1 if (TRT != 1)
	replace HG = 0 if (TRT == 1)

tab TRT HG, m

** 2. Full HG (full_HG)
gen full_HG = 1 if (TRT == 2)			// Full HG
	replace full_HG = 0 if (TRT==1)		// Climate

tab TRT full_HG, m
	
** 3. multifactorial causation (MC)
gen MC = 1 if (TRT == 3)				// MC
	replace MC = 0 if (TRT==1)			// Climate

tab TRT MC, m

** 4. population thinking (PT)
gen PT = 1 if (TRT == 4)				// PT
	replace PT = 0 if (TRT==1)			// Climate

tab TRT PT, m



*Label variables -------------------------------------------------------------
label var within_pm			"\makecell{Within Variation}"
label var between_pm		"\makecell{Between Variation}"

label var gen_cau_pm		"\makecell{Genetic \\ Attributions}"
label var env_cau_pm		"\makecell{Environmental \\ Attributions}"
label var cho_cau_pm		"\makecell{Choice Attributions}"

label var gbri_pm			"\makecell{Genetically Based \\ Racism Instrument}"
label var iptgb_pm			"\makecell{Implicit Person Theory of \\ Group Behavior}"
label var gbri_iptgb_pm		"\makecell{Genetic \\ Essentialism}"

label var pos_gen_pm		"\makecell{Genes}"
label var pos_env_pm		"\makecell{Environment}"
label var pos_off_pm		"\makecell{Offensiveness}"
label var pos_acc_pm		"\makecell{Acceptance}"
* ------------------------------------------------------------------------------

 

* ------------------------------------------------------------------------------
* All
preserve

keep full_HG MC PT  ///
	 gbri_iptgb_pm  ///
	 within_pm  between_pm  gen_cau_pm  env_cau_pm  ///
	 male  race_white  genetics_pm  ctor_pm

count

* Save data to use in other software
export delimited using "$path_Data\UCSD_study_cleaned.csv", delimiter(",") nolabel replace 
restore
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------
* full_HG only
preserve

keep full_HG  ///
	 gbri_iptgb_pm  ///
	 within_pm  between_pm  gen_cau_pm  env_cau_pm  ///
	 male  race_white  genetics_pm  ctor_pm

keep if !missing(full_HG)
count	 
	 
* Save data to use in other software
export delimited using "$path_Data\UCSD_study_cleaned_fullHG.csv", delimiter(",") nolabel replace 
restore
* ------------------------------------------------------------------------------
 
*-------------------------------------------------------------------------------
* SEM -> moderated mediator: https://stats.oarc.ucla.edu/stata/faq/how-can-i-do-moderated-mediation-in-stata/


* ##############################################################################
*                              DESCRIPTIVE STATISTICS
* ##############################################################################

*Number of observation (Full)
count if !missing(study)  // Full
 local sample_cnt_full: di %10.0fc `r(N)' 

*Number of observation by MAJOR
count if (study==1)  // Biology
 local sample_cnt_bio: di %10.0fc `r(N)' 
count if (study==2)  // Psychology
 local sample_cnt_psy: di %10.0fc `r(N)' 


*--------------------------[Gender: Male and Female]---------------------------*
 lab var male "\hspace{0.2cm} Male"
recode male (1=0) (0=1), copy gen(female)
 lab var female "\hspace{0.2cm} Female"

tab male female, m

eststo clear
*Summarize
eststo descriptive: estpost summarize	male  female 
eststo descriptive_bio: estpost summarize	male  female if (study == 1)
eststo descriptive_psy: estpost summarize	male  female if (study == 2)
 *Number of observation
 count if !missing(male)
 local sample_cnt_gender: di %10.0fc `r(N)' 


*Table (tex)
esttab  descriptive_bio descriptive_psy  descriptive   ///
	using "$path_Draft_Tables\table_descriptives.tex"  ///
	, replace  ///
	refcat(male "\emph{Gender} {\small (N=`sample_cnt_gender')}:"  ///
		   , nolabel)  ///	
	mgroups("\makecell{Biology\\(N=`sample_cnt_bio')}" "\makecell{Psychology\\(N=`sample_cnt_psy')}" "\makecell{Full\\(N=`sample_cnt_full')}", pattern(1 1 1)  ///
		prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))	///
	cells("mean(pattern(1) fmt(3))")  ///
	posthead("&\multicolumn{3}{c}{Proportion} \\\cmidrule{2-4}")  ///
	collabels(none)  ///
	label nonumber noobs fragment noomitted 
*	cells("mean(pattern(1) fmt(2)) sd(pattern(1) fmt(2)) count(pattern(1) fmt(%10.0fc))")  
*	collabels(\multicolumn{1}{c}{{Proportion}} \multicolumn{1}{c}{{SD}} \multicolumn{1}{c}{{N}})  ///


*Table (rtf)
 lab var male "Male"
 lab var female "Female"
 
esttab  descriptive_bio descriptive_psy   ///
	using "$path_Draft_Tables\table_descriptives.rtf"  ///
	, replace  ///
	refcat(male "Self-Identified Gender (N=`sample_cnt_gender'):"  ///
		   , nolabel)  ///	
	collabels(none)  ///
	cells("mean(pattern(1) fmt(3))")  ///
	mtitles("Biology (N=`sample_cnt_bio')" "Psychology (N=`sample_cnt_psy')")  ///
	mgroups("Proportion", pattern(1))	///
	label nonumber noobs noomitted 

*------------------------------------------------------------------------------

*-------------------------[Race: White and Non-white]--------------------------*
 lab var race_white "\hspace{0.2cm} White"
recode race_white (1=0) (0=1), copy gen(race_nonwhite)
 lab var race_nonwhite "\hspace{0.2cm} Non-White"

tab race5 race_white, m
tab race5 race_nonwhite, m

*Summarize
eststo descriptive: estpost summarize	race_white  race_nonwhite
eststo descriptive_bio: estpost summarize	race_white  race_nonwhite if (study == 1)
eststo descriptive_psy: estpost summarize	race_white  race_nonwhite if (study == 2)
 *Number of observation
 count if !missing(race_white)
 local sample_cnt_race: di %10.0fc `r(N)' 


*Table (tex)
esttab  descriptive_bio descriptive_psy descriptive  ///
	using "$path_Draft_Tables\table_descriptives.tex"  ///
	, append  ///
	refcat(race_white "\emph{Race} {\small (N=`sample_cnt_race')}:"  ///
		   , nolabel)  ///	
	collabels(none)  ///
	cells("mean(pattern(1) fmt(3))")  ///
	label nonumber noobs fragment noomitted nomtitles nonum noline
*	cells("mean(pattern(1) fmt(2)) sd(pattern(1) fmt(2)) count(pattern(1) fmt(%10.0fc))")  ///

*Table (rtf)
lab var race_white "White"
lab var race_nonwhite "Non-White"
 
esttab  descriptive_bio descriptive_psy   ///
	using "$path_Draft_Tables\table_descriptives.rtf"  ///
	, append  ///
	refcat(race_white "Self-Identified Race (N=`sample_cnt_race'):"  ///
		   , nolabel)  ///	
	collabels(none)  ///
	cells("mean(pattern(1) fmt(3))")  ///
	label nonumber noobs noomitted nomtitle

*-------------------------------------------------------------------------------
*----------[Political Affiliation: Liberal, Non-liberal, and Haven't]----------*
recode political_aff3 (2 3=0)		, copy gen(pa_liberal)
 lab var pa_liberal "\hspace{0.2cm} Liberal"
recode political_aff3 (1 3=0) (2=1), copy gen(pa_nonliberal)
 lab var pa_nonliberal "\hspace{0.2cm} Non-liberal"
recode political_aff3 (1 2=0) (3=1), copy gen(pa_havent)
 lab var pa_havent "\hspace{0.2cm} Haven't thought about it much"

tab political_aff3 pa_liberal, m
tab political_aff3 pa_nonliberal, m
tab political_aff3 pa_havent, m

*Summarize
eststo descriptive: estpost summarize	pa_liberal  pa_nonliberal  pa_havent  
eststo descriptive_bio: estpost summarize	pa_liberal  pa_nonliberal  pa_havent  if (study == 1)
eststo descriptive_psy: estpost summarize	pa_liberal  pa_nonliberal  pa_havent  if (study == 2)
 *Number of observation
 count if !missing(political_aff3)
 local sample_cnt_pa: di %10.0fc `r(N)' 


*Table (tex)
esttab  descriptive_bio descriptive_psy descriptive  ///
	using "$path_Draft_Tables\table_descriptives.tex"  ///
	, append  ///
	refcat(pa_liberal "\emph{Political Affiliation} {\small (N=`sample_cnt_pa')}:"  ///
		   , nolabel)  ///	
	collabels(none)  ///
	cells("mean(pattern(1) fmt(3))")  ///
	label nonumber noobs fragment noomitted nomtitles nonum noline
*	cells("mean(pattern(1) fmt(2)) sd(pattern(1) fmt(2)) count(pattern(1) fmt(%10.0fc))")  ///

*Table (rtf)
lab var pa_liberal "Liberal"
lab var pa_nonliberal "Non-liberal"
lab var pa_havent "Haven't thought about it much"
 
esttab  descriptive_bio descriptive_psy   ///
	using "$path_Draft_Tables\table_descriptives.rtf"  ///
	, append  ///
	refcat(pa_liberal "Political Affiliation (N=`sample_cnt_pa'):"  ///
		   , nolabel)  ///	
	collabels(none)  ///
	cells("mean(pattern(1) fmt(3))")  ///
	label nonumber noobs noomitted nomtitle

*-------------------------------------------------------------------------------



*---------------------------[Cultural Theory of Risk]--------------------------*
egen ctr_mean = rowmean(ctr1 ctr2 ctr3 ctr4 ctr5 ctr6)
 lab var ctr_mean "\hspace{0.2cm} Cultural Theory of Risk"

sum ctr_mean

*Summarize
eststo descriptive: estpost summarize	ctr_mean 
eststo descriptive_bio: estpost summarize	ctr_mean if (study == 1)
eststo descriptive_psy: estpost summarize	ctr_mean if (study == 2)
 *Number of observation
 count if !missing(ctr_mean)
 local sample_cnt_ctr: di %10.0fc `r(N)' 

 lab var ctr_mean "Cultural Theory of Risk {\small (N=`sample_cnt_ctr')}"
 
*table (tex)
esttab  descriptive_bio  descriptive_psy  descriptive  ///
	using "$path_Draft_Tables\table_descriptives.tex"  ///
	, append  ///
	collabels(none)  ///
	prehead("\hline")  ///
	mgroups("\makecell{Mean \\ (SD)}", pattern(1 0 0)  ///
		prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))	///
	cells("mean(pattern(1) fmt(3))" "sd(pattern(1) fmt(3) par)")  ///
	label nonumber noobs fragment noomitted nomtitles nonum noline

*Table (rtf)
 lab var ctr_mean "Cultural Theory of Risk (N=`sample_cnt_ctr')"
 
esttab  descriptive_bio descriptive_psy   ///
	using "$path_Draft_Tables\table_descriptives.rtf"  ///
	, append  ///
	collabels(none)  ///
	cells("mean(pattern(1) fmt(3))" "sd(pattern(1) fmt(3) par)")  ///
	mgroups("Mean (SD)", pattern(1))	///
	label nonumber noobs noomitted nomtitle

*------------------------------[Genomics Knowledge]----------------------------*
*Summarize
egen gk_mean = rowmean(glai1 glai2 glai4 glai5 glai8 glai17 glai18 glai20)
egen gk_total = rowtotal(glai1 glai2 glai4 glai5 glai8 glai17 glai18 glai20)

*Summarize
eststo descriptive: estpost summarize	gk_total 
eststo descriptive_bio: estpost summarize	gk_total if (study == 1)
eststo descriptive_psy: estpost summarize	gk_total if (study == 2)
 *Number of observation
 count if !missing(gk_total)
 local sample_cnt_gk: di %10.0fc `r(N)' 

 lab var gk_total "Genomics Knowledge {\small (N=`sample_cnt_gk')}"
 
*Table (tex)
esttab  descriptive_bio  descriptive_psy  descriptive  ///
	using "$path_Draft_Tables\table_descriptives.tex"  ///
	, append  ///
	collabels(none)  ///
	cells("mean(pattern(1) fmt(3))" "sd(pattern(1) fmt(3) par)")  ///
	label nonumber noobs fragment noomitted nomtitles nonum noline

*Table (rtf)
 lab var gk_total "Genomics Knowledge (N=`sample_cnt_gk')"
 
esttab  descriptive_bio descriptive_psy   ///
	using "$path_Draft_Tables\table_descriptives.rtf"  ///
	, append  ///
	collabels(none)  ///
	cells("mean(pattern(1) fmt(3))" "sd(pattern(1) fmt(3) par)")  ///
	label nonumber noobs noomitted nomtitle

*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------


* ##############################################################################
*                            BASELINE EQUIVALENCE
* ##############################################################################

eststo clear
*--------------------------[Gender: Male and Female]---------------------------*
eststo base_equi_male: logit male 	ib1.TRT , robust
 test 1.TRT==2.TRT==3.TRT==4.TRT
	scalar ft_st = `r(chi2)'
	estadd scalar ft_st 
	scalar ft_pv = `r(p)'
	estadd scalar ft_pv 
	estadd local method "Logit"
/* Not significantly different
           chi2(  3) =    0.56
         Prob > chi2 =    0.9048
*/

*-------------------------[Race: White and Non-white]--------------------------*
eststo base_equi_white: logit white 	ib1.TRT , robust
 test 1.TRT==2.TRT==3.TRT==4.TRT
	scalar ft_st = `r(chi2)'
	estadd scalar ft_st 
	scalar ft_pv = `r(p)'
	estadd scalar ft_pv 
	estadd local method "Logit"
/* Not significantly different
           chi2(  3) =    4.81
         Prob > chi2 =    0.1865
*/

*---------------------[Study sample: Biology and Pschology]--------------------*
recode study (2=0)		, copy gen(study_bio)
 lab var study_bio "\hspace{0.2cm} Biology Students"
recode study (1=0) (2=1), copy gen(study_psy)
 lab var study_psy "\hspace{0.2cm} Psychology Students"

tab study study_bio, m
tab study study_psy, m

eststo base_equi_study: logit study_bio 	ib1.TRT , robust
 test 1.TRT==2.TRT==3.TRT==4.TRT
	scalar ft_st = `r(chi2)'
	estadd scalar ft_st 
	scalar ft_pv = `r(p)'
	estadd scalar ft_pv 
	estadd local method "Logit"
/* Not significantly different
           chi2(  3) =    0.03
         Prob > chi2 =    0.9983
*/
/*
 test 1.TRT==2.TRT==3.TRT==
 test 1.TRT==2.TRT==3.TRT==4.TRT
 test 1.TRT==2.TRT==3.TRT==4.TRT
*/
*----------[Political Affiliation: Liberal, Non-liberal, and Haven't]----------*
eststo base_equi_pa: reg political_aff3 	ib1.TRT , robust
 test 1.TRT==2.TRT==3.TRT==4.TRT
	scalar ft_st = `r(F)'
	estadd scalar ft_st 
	scalar ft_pv = `r(p)'
	estadd scalar ft_pv 
	estadd local method "OLS"
/* Not significantly different
       F(  3,  1815) =    0.31
            Prob > F =    0.8178
*/

*------------------------------[Genomics Knowledge]----------------------------*
eststo base_equi_gk: reg genetics_pm 	ib1.TRT , robust
 test 1.TRT==2.TRT==3.TRT==4.TRT
	scalar ft_st = `r(F)'
	estadd scalar ft_st 
	scalar ft_pv = `r(p)'
	estadd scalar ft_pv 
	estadd local method "OLS"
/* Not significantly different
       F(  3,  2057) =    1.55
            Prob > F =    0.1987
*/
*-------------------------------------------------------------------------------

*---------------------------[Cultural Theory of Risk]--------------------------*
eststo base_equi_ctr: reg ctor_pm 	ib1.TRT , robust
 test 1.TRT==2.TRT==3.TRT==4.TRT
	scalar ft_st = `r(F)'
	estadd scalar ft_st 
	scalar ft_pv = `r(p)'
	estadd scalar ft_pv 
	estadd local method "OLS"
/* Not significantly different
       F(  3,  2057) =    1.66
            Prob > F =    0.1740
*/
*-------------------------------------------------------------------------------

*-------------------------------------------------------------------------------
local keepVars  2.TRT  3.TRT  4.TRT  ///
				_cons

* Table (tex)
esttab  base_equi_male    ///
		base_equi_white    ///
		base_equi_study    ///
		base_equi_pa    ///
		base_equi_gk    ///
		base_equi_ctr    ///
	using "$path_Draft_Tables\table_baseline_equiv.tex", ///
	b(3) se(3) ///
	stat(N r2 method ft_st ft_pv, label("N" "\$R^{2}$" "Estimation Method" "\hline Test Statistic" "Test \$p$-value") fmt(%10.0fc 3 s 3 3)) ///
	mtitles("\makecell{Male}"  "\makecell{White}" "\makecell{Major}" "\makecell{Political \\ Affiliation}" "\makecell{Genetics \\ Knowledge}" "\makecell{Cultural \\ Theory of \\ Risk}") ///
	order(`keepVars') ///
	keep(`keepVars') ///
	coeflabel(2.TRT "Full Humane Genetics"  ///
			  3.TRT "Multifactorial Causation"  ///
			  4.TRT "Population Thinking"  ///
			  _cons "Intercept")  ///
	eqlabels(" " " ")  ///
	label compress fragment noomitted ///
	style(tex) star(* 0.10 ** 0.05 *** 0.01) nonotes ///
	title(\textbf{}) replace
*-------------------------------------------------------------------------------

* Table (rtf)
esttab base_equi_male ///
		base_equi_white    ///
		base_equi_study    ///
		base_equi_pa    ///
		base_equi_gk    ///
		base_equi_ctr    ///
    using "$path_Draft_Tables\table_baseline_equiv.rtf", ///
    replace  ///
	rtf  ///
    b(%9.3f) se(%9.3f) ///
	stat(N r2 method ft_st ft_pv, label("N" "R_sqr" "Estimation Method" "Test Statistic" "Test p-value") fmt(%10.0fc 3 s 3 3)) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    label  compress ///
	eqlabel(none)  ///
	order(`keepVars') ///
	keep(`keepVars') ///
    mtitles("Male"  "White" "Major" "Political Affiliation" "Genetics Knowledge" "Cultural Theory of Risk")  ///
	coeflabel(2.TRT "FHGC"  ///
			  3.TRT "MC"  ///
			  4.TRT "PT"  ///
			  _cons "Intercept")  ///
    title("Baseline Equivalence") 
	*addnotes("Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01")
	*eqlabels("")  

*-------------------------------------------------------------------------------

* ##############################################################################
*                            MAIN EFFECTS (SEM not included)
* ##############################################################################

*# This is for Table XX

* -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
*                                 All TRT together
* -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
tab TRT, m
/*
. tab TRT, m

        TRT |      Freq.     Percent        Cum.
------------+-----------------------------------
    Climate |        515       24.99       24.99  <- 1
    Full HG |        518       25.13       50.12  <- 2
         MC |        514       24.94       75.06  <- 3
         PT |        514       24.94      100.00  <- 4
------------+-----------------------------------
      Total |      2,061      100.00
*/
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------
***# Full Sample & All 4 TRT
eststo TXX_4TRT: reg gbri_iptgb_pm  				ib1.TRT    					, robust //coefl	// Genetic Essentialism
	estadd ysumm

 test 2.TRT==3.TRT==4.TRT
/*
       F(  2,  2057) =    4.19
            Prob > F =    0.0153
*/
 test 2.TRT==3.TRT
/*
       F(  1,  2057) =    8.36
            Prob > F =    0.0039
*/
 test 2.TRT==4.TRT
/*
       F(  1,  2057) =    3.01
            Prob > F =    0.0831
*/
 test 3.TRT==4.TRT
/*
       F(  1,  2057) =    1.24
            Prob > F =    0.2666
*/

* Tabluate	
local keepVars  2.TRT  3.TRT  4.TRT  ///
				_cons

* Table (tex)
esttab  TXX_4TRT  ///
	using "$path_Draft_Tables\table_fullhg_ge_4TRT.tex", ///
	b(3) se(3) ///
	stat(N r2 , label("N" "\$R^{2}$") fmt(%10.0fc 3)) ///
	order(`keepVars') ///
	keep(`keepVars') ///
	mtitle("Genetic Essentialism")	///
	coeflabel(2.TRT "Full Humane Genetics Curriculum"  ///
			  3.TRT "Multifactorial Causation Curriculum"  ///
			  4.TRT "Population Thinking Curriculum"  ///
			  _cons "Intercept")  ///
	label compress fragment noomitted ///
	style(tex) star(* 0.05 ** 0.01 *** 0.001) nonotes ///
	title(\textbf{}) replace
				
				
*Table (rtf)
esttab TXX_4TRT    ///
    using "$path_Draft_Tables\table_all_ge_4TRT.rtf", ///
    replace  ///
	rtf  ///
    b(%9.3f) ci(%9.3f) ///
	stat(N r2, label("N" "R_sqr") fmt(%10.0fc 3)) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    label  compress ///
	eqlabels("")  ///
	order(`keepVars') ///
	keep(`keepVars') ///
    mtitles("Genetic Essentialism")  ///
	coeflabel(2.TRT "Full Humane Genetics Curriculum"  ///
			  3.TRT "Multifactorial Causation Curriculum"  ///
			  4.TRT "Population Thinking Curriculum"  ///
			  _cons "Intercept")  ///
    title("The Effects of All Interventions on Genetic Essentialism") 
	*addnotes("Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01")


*test 2.TRT 3.TRT 4.TRT, mtest(bonferroni)  // Bonferroni correction

* Figure -----------------------------------------------------------------------
coefplot (TXX_4TRT,  /// 
			keep(2.TRT) label("Full Humane Genetics") ///
			lc(cranberry) mc(cranberry) ciopt(recast(rcap) lc(cranberry)) ///
			mlabel(cond(@pval<.001, string(@b,"%9.3f") + "***", ///
				   cond(@pval<.01, string(@b,"%9.3f") + "**", ///
				   cond(@pval<.05, string(@b,"%9.3f") + "*", ///
				   string(@b,"%9.3f")))))  ///
			mlabcolor(cranberry)  ///
		 ) ///
         (TXX_4TRT,  ///
			keep(3.TRT) label("Multifactorial Causation")  ///
			ms(D) lc(navy) mc(navy) ciopt(recast(rcap) lc(navy))  ///
			mlabel(cond(@pval<.001, string(@b,"%9.3f") + "***", ///
				   cond(@pval<.01, string(@b,"%9.3f") + "**", ///
				   cond(@pval<.05, string(@b,"%9.3f") + "*", ///
				   string(@b,"%9.3f")))))  ///
			mlabcolor(navy)  ///
		  ) ///
         (TXX_4TRT, ///
			keep(4.TRT) label("Population Thinking")  ///
			ms(S) lc(black) mc(black) ciopt(recast(rcap) lc(black))  ///
			mlabel(cond(@pval<.001, string(@b,"%9.3f") + "***", ///
				   cond(@pval<.01, string(@b,"%9.3f") + "**", ///
				   cond(@pval<.05, string(@b,"%9.3f") + "*", ///
				   string(@b,"%9.3f")))))  ///
			mlabcolor(black)  ///			
		  ), ///
    name(SEM_4TRT_coef, replace) ///
    vertical ///
    yline(0, lwidth(normal) lpattern(dash) lcolor(red)) ///
    ytitle("Genetic Essentialism", size(medlarge)) ///
    legend(off) ///
    xlabel(1 "Full Humane Genetics" 2 "Multifactorial Causation" 3 "Population Thinking", angle(20))


graph export "$path_Draft_Figures\figure_coefplot_OLS.png", replace
* ------------------------------------------------------------------------------


* # this is for Table XX
* ================= [Treatment Effects Across "Interventions"] =================
** set global variables
global demo 	  i.male   i.race_white  ib2.political_aff3  ib1.study  // i.whiteasian
global baseGene   ctor_pm  genetics_pm
*

* checks
tab race5 race_white, m
tab race race_white, m
* -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
*                                 1. Full HG
* -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
tab TRT full_HG, m
* ------------------------------------------------------------------------------
local TRT 		i.full_HG
local TRT_int 	i.full_HG##ib1.study
* ------------------------------------------------------------------------------

***# Full Sample

***Column 1: FUll HG w/o controls
eststo TXX_C1_Full: reg gbri_iptgb_pm  				`TRT'    					, robust //coefl	// Genetic Essentialism
	estadd ysumm

***Column 2: FUll HG w/o controls & interacted w/ study pool
eststo TXX_C2_Full: reg gbri_iptgb_pm  `TRT_int' 	`TRT'    					, robust //coefl	// Genetic Essentialism
	estadd ysumm

***Column 3: FUll HG w/ controls
eststo TXX_C3_Full: reg gbri_iptgb_pm  				`TRT'  $demo $baseGene    	, robust //coefl	// Genetic Essentialism
	estadd ysumm

***Column 4: Full HG w/ controls & interacted w/ study pool
eststo TXX_C4_Full: reg gbri_iptgb_pm  `TRT_int' 	`TRT'  $demo $baseGene   	, robust coefl	// Genetic Essentialism
*gen sampleInd = e(sample)
	estadd ysumm


***# Biology Students
eststo TXX_Bio: reg gbri_iptgb_pm  `TRT'  $demo $baseGene   if (study == 1), robust //coefl	// Genetic Essentialism
	estadd ysumm

***# Psychology Students
eststo TXX_Psy: reg gbri_iptgb_pm  `TRT'  $demo $baseGene   if (study == 2) , robust coefl	// Genetic Essentialism
	estadd ysumm


* Variables to keep in table
local keepVars  1.full_HG  1.full_HG#2.study  ///
				2.study   ///
				genetics_pm  ///
				1.political_aff3  3.political_aff3 ///
				ctor_pm  ///
				1.race_white  /// 
				1.male   ///
				_cons
* Table (tex)
esttab  TXX_C1_Full  TXX_C2_Full  ///
		TXX_C3_Full  TXX_C4_Full  ///
	using "$path_Draft_Tables\table_fullhg_ge.tex", ///
	b(3) se(3) ///
	stat(ymean N r2 , label("Sample Mean" "Observations" "\$R^{2}$") fmt(3 %10.0fc 3)) ///
	order(`keepVars') ///
	keep(`keepVars') ///
	coeflabel(1.full_HG "Full Humane Genetics"  ///
			  1.full_HG#2.study "Full Humane Genetics$\times$ Psychology Students"   ///
			  2.study "Study Sample: Psychology Students"  ///
			  genetics_pm "Genomics Knowledge"  ///
			  1.political_aff3 "Political Affiliation: Self-Identified Liberal"  ///
			  3.political_aff3 "Political Affiliation: Haven't Thought about it much"  ///
			  ctor_pm "Cultural Theory of Risk"  ///
			  1.race_white "Race: Self-Identified White"  ///
			  1.male "Gender: Self-Identified Men"  ///
			  _cons "Intercept")  ///
	mgroups("Genetic Essentialism", pattern(1 0 0 0)  ///
		prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span}))	///
	label compress fragment noomitted nomtitle ///
	style(tex) star(* 0.10 ** 0.05 *** 0.01) nonotes ///
	title(\textbf{}) replace

* Tabluate	
/*
esttab TXX_C1_Full  TXX_C2_Full  TXX_C4_Full  ///
	using "$path_Draft_Tables\table_fullhg_ge.rtf", ///
	replace  ///
	rtf  ///
    b(%9.3f) se(%9.3f) ///
	stat(N r2, label("N" "R_sqr") fmt(%10.0fc 3)) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label  compress nomtitle ///
	eqlabels("")  ///
	order(`keepVars') ///
	keep(`keepVars') ///
	mgroups("Genetic Essentialism", pattern(1 1 1))	///
	coeflabel(1.full_HG "FHGC"  ///
			  1.full_HG#2.study "FHGC x Psychology Students"   ///
			  2.study "Study Sample: Psychology Students"  ///
			  genetics_pm "Genomics Knowledge"  ///
			  1.political_aff3 "Political Affiliation: Self-Identified Liberal"  ///
			  3.political_aff3 "Political Affiliation: Haven't Thought about it much"  ///
			  ctor_pm "Cultural Theory of Risk"  ///
			  1.race_white "Race: Self-Identified White"  ///
			  1.male "Gender: Self-Identified Men"  ///
			  _cons "Intercept")  ///
    title("The Effects of FHGC on Genetic Essentialism") 
	*addnotes("Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01")
*/

* Variables to keep in table
local keepVars  1.full_HG  ///
				2.study  ///
				1.male   ///
				1.race_white  /// 
				ctor_pm  ///
				genetics_pm  ///
				1.political_aff3  3.political_aff3 ///
				_cons
*Table (rtf)
esttab TXX_C1_Full TXX_C3_Full     ///
	using "$path_Draft_Tables\table_fullhg_ge.rtf", ///
    replace  ///
	rtf  ///
    b(%9.3f) se(%9.3f) ///
	stat(N r2, label("N" "R_sqr") fmt(%10.0fc 3)) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    label  compress nomtitle ///
	eqlabels("")  ///
	order(`keepVars') ///
	keep(`keepVars') ///
	mgroups("Genetic Essentialism", pattern(1 1 1))	///
	coeflabel(1.full_HG "FHGC"  ///
			  2.study "Study Sample: Psychology Subject Pool"  ///
			  1.male "Gender: Self-Identified Men"  ///
			  1.race_white "Race: Self-Identified White"  ///
			  ctor_pm "Cultural Theory of Risk"  ///
			  genetics_pm "Genomics Knowledge"  ///
			  1.political_aff3 "Political Affiliation: Self-Identified Liberal"  ///
			  3.political_aff3 "Political Affiliation: Haven't Thought about it much"  ///
			  _cons "Intercept")  ///
    title("The Effects of FHGC on Genetic Essentialism") 



 lab var full_HG "FHGC"
*#==============================================================================
* 							Moderated Mediation Effects
*#==============================================================================
/*
*# Moderators
	1. Gender
	2. Race
	3. Cultural Theory of Risk (CTR)
	4. Genetics Knowledge (GK)
*/
/*
- A path: TRT -> Mediator
- B path: Mediator -> Genetic Essentialism
*/

*##--------------------------------- Gender ---------------------------------##*
 lab var male "Male"
 
*# Within group variation #*
* A effect 
eststo TXX_wn_Ca: reg within_pm 		i.full_HG##i.male
* B effect
eststo TXX_wn_Cb: reg gbri_iptgb_pm 	c.within_pm##i.male   i.full_HG 


*# Between group variation #*
* A effect 
eststo TXX_bn_Ca: reg between_pm 		i.full_HG##i.male
* B effect
eststo TXX_bn_Cb: reg gbri_iptgb_pm 	c.between_pm##i.male  i.full_HG 


*# Genetic causation #*
* A effect 
eststo TXX_gc_Ca: reg gen_cau_pm 		i.full_HG##i.male
* B effect
eststo TXX_gc_Cb: reg gbri_iptgb_pm 	c.gen_cau_pm##i.male  i.full_HG 


*# Environmental causation #*
* A effect 
eststo TXX_ec_Ca: reg env_cau_pm 		i.full_HG##i.male, coefl
* B effect
eststo TXX_ec_Cb: reg gbri_iptgb_pm 	c.env_cau_pm##i.male  i.full_HG , coefl


*-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-
* List of variables to keep
local keepVars  1.full_HG  ///
				1.male  ///
				1.full_HG#1.male  ///
				within_pm  between_pm  gen_cau_pm  env_cau_pm  ///
				1.male#c.within_pm  ///
				1.male#c.between_pm  ///
				1.male#c.gen_cau_pm  ///
				1.male#c.env_cau_pm  ///
				_cons

* Table: Full and Each TRT Sample
** (tex)
esttab  TXX_wn_Ca  TXX_wn_Cb      ///
		TXX_bn_Ca  TXX_bn_Cb      ///
		TXX_gc_Ca  TXX_gc_Cb      ///
		TXX_ec_Ca  TXX_ec_Cb      ///
	using "$path_Draft_Tables\table_mediators_abpaths_gender.tex",  ///
	b(3) se(3)  ///
	stat(N,  ///
	label("Observations") fmt(%10.0fc))  ///
	mtitle("\makecell{Within \\ Variation}"  "\makecell{Genetic \\ Essentialism}"  ///
		   "\makecell{Between \\ Variation}"  "\makecell{Genetic \\ Essentialism}"  ///
		   "\makecell{Genetic \\ Causation}"  "\makecell{Genetic \\ Essentialism}"  ///
		   "\makecell{Environmental \\ Causation}"  "\makecell{Genetic \\ Essentialism}"  ///
			) ///
	eqlabel(none)  ///
	order(`keepVars')  ///
	keep(`keepVars')  ///
	label compress fragment noomitted  ///
	style(tex) star(* 0.10 ** 0.05 *** 0.01) nonotes  ///
	title(\textbf{}) replace

** (rtf)
esttab  TXX_wn_Ca  TXX_wn_Cb      ///
		TXX_bn_Ca  TXX_bn_Cb      ///
		TXX_gc_Ca  TXX_gc_Cb      ///
		TXX_ec_Ca  TXX_ec_Cb      ///
	using "$path_Draft_Tables\table_mediators_abpaths_gender.rtf",  ///
    replace  ///
	rtf  ///
    b(%9.3f) se(%9.3f) ///
	stat(N r2, label("N" "R_sqr") fmt(%10.0fc 3)) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    label  compress ///
	eqlabels("")  ///
	order(`keepVars') ///
	keep(`keepVars') ///
	mgroups("Genetic Essentialism", pattern(1 1 1))	///
	mtitle("Within Variation"   "Genetic Essentialism"  ///
		   "Between Variation"  "Genetic Essentialism"  ///
		   "Genetic Causation"  "Genetic Essentialism"  ///
		   "Environmental Causation"  "Genetic Essentialism"  ///
			) ///
	coeflabel(1.full_HG "FHGC"  ///
			  1.male "Male"  ///
			  1.full_HG#1.male "FHGC x Self-Identified Men"   ///
			  within_pm  "Within-Group Variation"  ///
			  between_pm "Between-Group Variation"  ///
			  gen_cau_pm "Genetic Causation"  ///
			  env_cau_pm "Environmental Causation"  ///
			  1.male#c.within_pm  "Within-Group Variation x Self-Identified Men"  ///
			  1.male#c.between_pm "Between-Group Variation x Self-Identified Men"  ///
			  1.male#c.gen_cau_pm "Genetic Causation x Self-Identified Men"  ///
			  1.male#c.env_cau_pm "Environmental Causation x Self-Identified Men"  ///
			  _cons "Intercept")  ///
    title("The Effects of XXXX") 

*-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-

*##---------------------------------- Race ----------------------------------##*
 lab var race_white "White"
 
*# Within group variation #*
* A effect 
eststo TXX_wn_Ca: reg within_pm 		i.full_HG##i.race_white
* B effect
eststo TXX_wn_Cb: reg gbri_iptgb_pm 	c.within_pm##i.race_white   i.full_HG 


*# Between group variation #*
* A effect 
eststo TXX_bn_Ca: reg between_pm 		i.full_HG##i.race_white
* B effect
eststo TXX_bn_Cb: reg gbri_iptgb_pm 	c.between_pm##i.race_white  i.full_HG 


*# Genetic causation #*
* A effect 
eststo TXX_gc_Ca: reg gen_cau_pm 		i.full_HG##i.race_white
* B effect
eststo TXX_gc_Cb: reg gbri_iptgb_pm 	c.gen_cau_pm##i.race_white  i.full_HG 


*# Environmental causation #*
* A effect 
eststo TXX_ec_Ca: reg env_cau_pm 		i.full_HG##i.race_white, coefl
* B effect
eststo TXX_ec_Cb: reg gbri_iptgb_pm 	c.env_cau_pm##i.race_white  i.full_HG , coefl


*-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-
* List of variables to keep
local keepVars  1.full_HG  ///
				1.race_white  ///
				1.full_HG#1.race_white  ///
				within_pm  between_pm  gen_cau_pm  env_cau_pm  ///
				1.race_white#c.within_pm  ///
				1.race_white#c.between_pm  ///
				1.race_white#c.gen_cau_pm  ///
				1.race_white#c.env_cau_pm  ///
				_cons

* Table: Full and Each TRT Sample
** (tex)
esttab  TXX_wn_Ca  TXX_wn_Cb      ///
		TXX_bn_Ca  TXX_bn_Cb      ///
		TXX_gc_Ca  TXX_gc_Cb      ///
		TXX_ec_Ca  TXX_ec_Cb      ///
	using "$path_Draft_Tables\table_mediators_abpaths_race.tex",  ///
	b(3) se(3)  ///
	stat(N,  ///
	label("Observations") fmt(%10.0fc))  ///
	mtitle("\makecell{Within \\ Variation}"  "\makecell{Genetic \\ Essentialism}"  ///
		   "\makecell{Between \\ Variation}"  "\makecell{Genetic \\ Essentialism}"  ///
		   "\makecell{Genetic \\ Causation}"  "\makecell{Genetic \\ Essentialism}"  ///
		   "\makecell{Environmental \\ Causation}"  "\makecell{Genetic \\ Essentialism}"  ///
			) ///
	eqlabel(none)  ///
	order(`keepVars')  ///
	keep(`keepVars')  ///
	label compress fragment noomitted  ///
	style(tex) star(* 0.10 ** 0.05 *** 0.01) nonotes  ///
	title(\textbf{}) replace
	
** (rtf)
esttab  TXX_wn_Ca  TXX_wn_Cb      ///
		TXX_bn_Ca  TXX_bn_Cb      ///
		TXX_gc_Ca  TXX_gc_Cb      ///
		TXX_ec_Ca  TXX_ec_Cb      ///
	using "$path_Draft_Tables\table_mediators_abpaths_race.rtf",  ///
    replace  ///
	rtf  ///
    b(%9.3f) se(%9.3f) ///
	stat(N r2, label("N" "R_sqr") fmt(%10.0fc 3)) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    label  compress ///
	eqlabels("")  ///
	order(`keepVars') ///
	keep(`keepVars') ///
	mgroups("Genetic Essentialism", pattern(1 1 1))	///
	mtitle("Within Variation"   "Genetic Essentialism"  ///
		   "Between Variation"  "Genetic Essentialism"  ///
		   "Genetic Causation"  "Genetic Essentialism"  ///
		   "Environmental Causation"  "Genetic Essentialism"  ///
			) ///
	coeflabel(1.full_HG "FHGC"  ///
			  1.race_white "Self-Identified White"  ///
			  1.full_HG#1.race_white "FHGC x Self-Identified White"   ///
			  within_pm  "Within-Group Variation"  ///
			  between_pm "Between-Group Variation"  ///
			  gen_cau_pm "Genetic Causation"  ///
			  env_cau_pm "Environmental Causation"  ///
			  1.race_white#c.within_pm  "Within-Group Variation x Self-Identified White"  ///
			  1.race_white#c.between_pm "Between-Group Variation x Self-Identified White"  ///
			  1.race_white#c.gen_cau_pm "Genetic Causation x Self-Identified White"  ///
			  1.race_white#c.env_cau_pm "Environmental Causation x Self-Identified White"  ///
			  _cons "Intercept")  ///
    title("The Effects of XXXX") 


*-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-


*##------------------------ Cultural Theory of Risk -------------------------##*
*# Within group variation #*
* A effect 
eststo TXX_wn_Ca: reg within_pm 		i.full_HG##c.ctor_pm
* B effect
eststo TXX_wn_Cb: reg gbri_iptgb_pm 	c.within_pm##c.ctor_pm   i.full_HG 


*# Between group variation #*
* A effect 
eststo TXX_bn_Ca: reg between_pm 		i.full_HG##c.ctor_pm
* B effect
eststo TXX_bn_Cb: reg gbri_iptgb_pm 	c.between_pm##c.ctor_pm  i.full_HG 


*# Genetic causation #*
* A effect 
eststo TXX_gc_Ca: reg gen_cau_pm 		i.full_HG##c.ctor_pm
* B effect
eststo TXX_gc_Cb: reg gbri_iptgb_pm 	c.gen_cau_pm##c.ctor_pm  i.full_HG 


*# Environmental causation #*
* A effect 
eststo TXX_ec_Ca: reg env_cau_pm 		i.full_HG##c.ctor_pm, coefl
* B effect
eststo TXX_ec_Cb: reg gbri_iptgb_pm 	c.env_cau_pm##c.ctor_pm  i.full_HG , coefl

*-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-
* List of variables to keep
local keepVars  1.full_HG  ///
				ctor_pm  ///
				1.full_HG#c.ctor_pm  ///
				within_pm  between_pm  gen_cau_pm  env_cau_pm  ///
				c.within_pm#c.ctor_pm  ///
				c.between_pm#c.ctor_pm  ///
				c.gen_cau_pm#c.ctor_pm  ///
				c.env_cau_pm#c.ctor_pm  ///
				_cons

* Table: Full and Each TRT Sample
**(tex)
esttab  TXX_wn_Ca  TXX_wn_Cb      ///
		TXX_bn_Ca  TXX_bn_Cb      ///
		TXX_gc_Ca  TXX_gc_Cb      ///
		TXX_ec_Ca  TXX_ec_Cb      ///
	using "$path_Draft_Tables\table_mediators_abpaths_ctr.tex",  ///
	b(3) se(3)  ///
	stat(N,  ///
	label("Observations") fmt(%10.0fc))  ///
	mtitle("\makecell{Within \\ Variation}"  "\makecell{Genetic \\ Essentialism}"  ///
		   "\makecell{Between \\ Variation}"  "\makecell{Genetic \\ Essentialism}"  ///
		   "\makecell{Genetic \\ Causation}"  "\makecell{Genetic \\ Essentialism}"  ///
		   "\makecell{Environmental \\ Causation}"  "\makecell{Genetic \\ Essentialism}"  ///
			) ///
	eqlabel(none)  ///
	order(`keepVars')  ///
	keep(`keepVars')  ///
	label compress fragment noomitted  ///
	style(tex) star(* 0.10 ** 0.05 *** 0.01) nonotes  ///
	title(\textbf{}) replace

**(rtf)
esttab  TXX_wn_Ca  TXX_wn_Cb      ///
		TXX_bn_Ca  TXX_bn_Cb      ///
		TXX_gc_Ca  TXX_gc_Cb      ///
		TXX_ec_Ca  TXX_ec_Cb      ///
	using "$path_Draft_Tables\table_mediators_abpaths_ctr.rtf",  ///
    replace  ///
	rtf  ///
    b(%9.3f) se(%9.3f) ///
	stat(N r2, label("N" "R_sqr") fmt(%10.0fc 3)) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    label  compress ///
	eqlabels("")  ///
	order(`keepVars') ///
	keep(`keepVars') ///
	mgroups("Genetic Essentialism", pattern(1 1 1))	///
	mtitle("Within Variation"   "Genetic Essentialism"  ///
		   "Between Variation"  "Genetic Essentialism"  ///
		   "Genetic Causation"  "Genetic Essentialism"  ///
		   "Environmental Causation"  "Genetic Essentialism"  ///
			) ///
	coeflabel(1.full_HG "FHGC"  ///
			  ctor_pm "Cultural Theory of Risk"  ///
			  1.full_HG#c.ctor_pm "FHGC x Cultural Theory of Risk"   ///
			  within_pm  "Within-Group Variation"  ///
			  between_pm "Between-Group Variation"  ///
			  gen_cau_pm "Genetic Causation"  ///
			  env_cau_pm "Environmental Causation"  ///
			  c.within_pm#c.ctor_pm  "Within-Group Variation x Cultural Theory of Risk"  ///
			  c.between_pm#c.ctor_pm "Between-Group Variation x Cultural Theory of Risk"  ///
			  c.gen_cau_pm#c.ctor_pm "Genetic Causation x Cultural Theory of Risk"  ///
			  c.env_cau_pm#c.ctor_pm "Environmental Causation x Cultural Theory of Risk"  ///
			  _cons "Intercept")  ///
    title("The Effects of XXXX") 
*-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-


*##--------------------------- Genetics Knowledge ---------------------------##*

*# Within group variation #*
* A effect 
eststo TXX_wn_Ca: reg within_pm 		i.full_HG##c.genetics_pm
* B effect
eststo TXX_wn_Cb: reg gbri_iptgb_pm 	c.within_pm##c.genetics_pm  i.full_HG 


*# Between group variation #*
* A effect 
eststo TXX_bn_Ca: reg between_pm 		i.full_HG##c.genetics_pm
* B effect
eststo TXX_bn_Cb: reg gbri_iptgb_pm 	c.between_pm##c.genetics_pm  i.full_HG 


*# Genetic causation #*
* A effect 
eststo TXX_gc_Ca: reg gen_cau_pm 		i.full_HG##c.genetics_pm
* B effect
eststo TXX_gc_Cb: reg gbri_iptgb_pm 	c.gen_cau_pm##c.genetics_pm  i.full_HG 


*# Environmental causation #*
* A effect 
eststo TXX_ec_Ca: reg env_cau_pm 		i.full_HG##c.genetics_pm, coefl
* B effect
eststo TXX_ec_Cb: reg gbri_iptgb_pm 	c.env_cau_pm##c.genetics_pm  i.full_HG, coefl


*-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-
* List of variables to keep
local keepVars  1.full_HG  ///
				genetics_pm  ///
				1.full_HG#c.genetics_pm  ///
				within_pm  between_pm  gen_cau_pm  env_cau_pm  ///
				c.within_pm#c.genetics_pm  ///
				c.between_pm#c.genetics_pm  ///
				c.gen_cau_pm#c.genetics_pm  ///
				c.env_cau_pm#c.genetics_pm  ///
				_cons

* Table: Full and Each TRT Sample
**(tex)
esttab  TXX_wn_Ca  TXX_wn_Cb      ///
		TXX_bn_Ca  TXX_bn_Cb      ///
		TXX_gc_Ca  TXX_gc_Cb      ///
		TXX_ec_Ca  TXX_ec_Cb      ///
	using "$path_Draft_Tables\table_mediators_abpaths_gk.tex",  ///
	b(3) se(3)  ///
	stat(N,  ///
	label("Observations") fmt(%10.0fc))  ///
	mtitle("\makecell{Within \\ Variation}"  "\makecell{Genetic \\ Essentialism}"  ///
		   "\makecell{Between \\ Variation}"  "\makecell{Genetic \\ Essentialism}"  ///
		   "\makecell{Genetic \\ Causation}"  "\makecell{Genetic \\ Essentialism}"  ///
		   "\makecell{Environmental \\ Causation}"  "\makecell{Genetic \\ Essentialism}"  ///
			) ///
	eqlabel(none)  ///
	order(`keepVars')  ///
	keep(`keepVars')  ///
	label compress fragment noomitted  ///
	style(tex) star(* 0.10 ** 0.05 *** 0.01) nonotes  ///
	title(\textbf{}) replace
	
**(rtf)
esttab  TXX_wn_Ca  TXX_wn_Cb      ///
		TXX_bn_Ca  TXX_bn_Cb      ///
		TXX_gc_Ca  TXX_gc_Cb      ///
		TXX_ec_Ca  TXX_ec_Cb      ///
	using "$path_Draft_Tables\table_mediators_abpaths_gk.rtf",  ///
    replace  ///
	rtf  ///
    b(%9.3f) se(%9.3f) ///
	stat(N r2, label("N" "R_sqr") fmt(%10.0fc 3)) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    label  compress ///
	eqlabels("")  ///
	order(`keepVars') ///
	keep(`keepVars') ///
	mgroups("Genetic Essentialism", pattern(1 1 1))	///
	mtitle("Within Variation"   "Genetic Essentialism"  ///
		   "Between Variation"  "Genetic Essentialism"  ///
		   "Genetic Causation"  "Genetic Essentialism"  ///
		   "Environmental Causation"  "Genetic Essentialism"  ///
			) ///
	coeflabel(1.full_HG "FHGC"  ///
			  genetics_pm "Genetics Knowledge"  ///
			  1.full_HG#c.genetics_pm "FHGC x Genetics Knowledge"   ///
			  within_pm  "Within-Group Variation"  ///
			  between_pm "Between-Group Variation"  ///
			  gen_cau_pm "Genetic Causation"  ///
			  env_cau_pm "Environmental Causation"  ///
			  c.within_pm#c.genetics_pm  "Within-Group Variation x Genetics Knowledge"  ///
			  c.between_pm#c.genetics_pm "Between-Group Variation x Genetics Knowledge"  ///
			  c.gen_cau_pm#c.genetics_pm "Genetic Causation x Genetics Knowledge"  ///
			  c.env_cau_pm#c.genetics_pm "Environmental Causation x Genetics Knowledge"  ///
			  _cons "Intercept")  ///
    title("The Effects of XXXX") 

*-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-


	

	
	
	
* ##############################################################################
*                               INDIRECT EFFECTS
* ##############################################################################

* ==============================================================================
** Table XX. Structural Equation Modelin (SEM) ---------------------------------
* ==============================================================================
*  Want to test the 'INDIRECT' effects of 'INTERVENTIONS' via each 'MEDIATOR' using...

*# -----------------------------------------------------------------------------
* 						Structural Equation Modeling (SEM)
*# -----------------------------------------------------------------------------
/* NOTE: These models parameterize covariances between endogenous mediators */

/* NOTE:
-https://stats.oarc.ucla.edu/stata/faq/how-can-i-do-mediation-analysis-with-the-sem-command/
-https://davidakenny.net/cm/mediate.htm
-https://www.stata.com/features/structural-equation-modeling/
-https://www.stata.com/manuals/semexample42g.pdf
-https://www.statalist.org/forums/forum/general-stata-discussion/general/1580778-how-can-i-calculate-mediation-using-bootstrapping
-https://www.statalist.org/forums/forum/general-stata-discussion/general/1541029-bootstrapped-indirect-effects-through-multiple-mediators-using-sem
*/
/* Multiple Mediators
-https://stackoverflow.com/questions/77611149/mediation-analysis-with-multiple-mediators
-https://statisticsconsulting.us/multiple-mediation-in-stata/
-https://stats.stackexchange.com/questions/578778/in-a-mediation-analysis-with-multiple-mediators-can-the-indirect-effects-be-add
*/

			
** Bootstrap Settings ------------
local NoR  5000
local SEED 880816
** -------------------------------

* ------------------------------------------------------------------------------
*								     Mediation
* ------------------------------------------------------------------------------

* Example code
  sem (full_HG -> within_pm  between_pm  gen_cau_pm  env_cau_pm)   ///
	  (within_pm  between_pm  gen_cau_pm  env_cau_pm full_HG -> gbri_iptgb_pm)   ///
	  ,   ///
	  ginvariant(none) nocapslatent coefl ///
	  cov(e.gen_cau_pm*e.env_cau_pm  ///
		  e.gen_cau_pm*e.within_pm  e.gen_cau_pm*e.between_pm   ///
		  e.env_cau_pm*e.within_pm  e.env_cau_pm*e.between_pm   ///
		  e.within_pm*e.between_pm)  

nlcom (_b[within_pm:full_HG]*_b[gbri_iptgb_pm:within_pm])
nlcom (_b[between_pm:full_HG]*_b[gbri_iptgb_pm:between_pm])
nlcom (_b[gen_cau_pm:full_HG]*_b[gbri_iptgb_pm:gen_cau_pm])
nlcom (_b[env_cau_pm:full_HG]*_b[gbri_iptgb_pm:env_cau_pm])

nlcom (_b[within_pm:full_HG]*_b[gbri_iptgb_pm:within_pm]) +  ///
	  (_b[between_pm:full_HG]*_b[gbri_iptgb_pm:between_pm]) +  ///
	  (_b[gen_cau_pm:full_HG]*_b[gbri_iptgb_pm:gen_cau_pm]) +  ///
	  (_b[env_cau_pm:full_HG]*_b[gbri_iptgb_pm:env_cau_pm])
* Example code


* ------------------------------------------------------------------------------
* [BEGIN] Bootstrap: Program and Settings --------------------------------------[BEGIN]
* ------------------------------------------------------------------------------
** Program
capture program drop bootstrap_SEM
program bootstrap_SEM, rclass

  syntax varlist [if] [in]
  args TRT

  sem (`TRT' -> within_pm  between_pm  gen_cau_pm  env_cau_pm)   ///
	  (within_pm  between_pm  gen_cau_pm  env_cau_pm `TRT' -> gbri_iptgb_pm)   ///
	  `if' `in'	,   ///
	  ginvariant(none) nocapslatent  ///
	  cov(e.gen_cau_pm*e.env_cau_pm  ///
		  e.gen_cau_pm*e.within_pm  e.gen_cau_pm*e.between_pm   ///
		  e.env_cau_pm*e.within_pm  e.env_cau_pm*e.between_pm   ///
		  e.within_pm*e.between_pm)  
		  
return scalar indirect_within 	= (_b[within_pm:`TRT']*_b[gbri_iptgb_pm:within_pm])
return scalar indirect_between 	= (_b[between_pm:`TRT']*_b[gbri_iptgb_pm:between_pm])
return scalar indirect_gene 	= (_b[gen_cau_pm:`TRT']*_b[gbri_iptgb_pm:gen_cau_pm])
return scalar indirect_env 		= (_b[env_cau_pm:`TRT']*_b[gbri_iptgb_pm:env_cau_pm])

return scalar indirect_total 	= (_b[within_pm:`TRT']*_b[gbri_iptgb_pm:within_pm]) +  ///
								  (_b[between_pm:`TRT']*_b[gbri_iptgb_pm:between_pm]) +  ///
								  (_b[gen_cau_pm:`TRT']*_b[gbri_iptgb_pm:gen_cau_pm]) +  ///
								  (_b[env_cau_pm:`TRT']*_b[gbri_iptgb_pm:env_cau_pm])

/*		
  estat teffects	
   mat direct = r(direct)
   mat indirect = r(indirect)
  
  return scalar indirect_within	 	 =	 el(direct, 1, 1)*el(direct, 1, 5)
  return scalar indirect_between	 =	 el(direct, 1, 2)*el(direct, 1, 6)
  return scalar indirect_gene		 =	 el(direct, 1, 3)*el(direct, 1, 7)
  return scalar indirect_env		 =	 el(direct, 1, 4)*el(direct, 1, 8)
  
  return scalar indirect_total	 	 = 	 el(direct, 1, 1)*el(direct, 1, 5)   ///
									   + el(direct, 1, 2)*el(direct, 1, 6)   ///
									   + el(direct, 1, 3)*el(direct, 1, 7)   ///
									   + el(direct, 1, 4)*el(direct, 1, 8)  

  return scalar indirect_total_cal 	 =	 el(indirect, 1, 9) 
*/
end
* ------------------------------------------------------------------------------
* [EDN] Bootstrap: Program and Settings ----------------------------------------[END]
* ------------------------------------------------------------------------------


* ------------------------------------------------------------------------------
*# Across THREE treatments
* ------------------------------------------------------------------------------
***# Full HG
bootstrap    ///
		r(indirect_within) r(indirect_between) r(indirect_gene) r(indirect_env) r(indirect_total)  ///
		, bca seed(`SEED') reps(`NoR'): bootstrap_SEM  full_HG 

eststo TXX_SEM_FHG: estat boot, nor percentile bc bca

***# MC
bootstrap    ///
		r(indirect_within) r(indirect_between) r(indirect_gene) r(indirect_env) r(indirect_total)  ///
		, bca seed(`SEED') reps(`NoR'): bootstrap_SEM  MC  

eststo TXX_SEM_MC: estat boot, nor percentile bc bca

***# PT
bootstrap    ///
		r(indirect_within) r(indirect_between) r(indirect_gene) r(indirect_env) r(indirect_total)  ///
		, bca seed(`SEED') reps(`NoR'): bootstrap_SEM  PT  

eststo TXX_SEM_PT: estat boot, nor percentile bc bca


  
* ------------------------------------------------------------------------------
* Summarize MODEL 2, 3, 5 results in [TABLES] 
* ------------------------------------------------------------------------------
*#Within
local keepVars  _bs_1 

* Table (tex)
esttab  TXX_SEM_FHG  TXX_SEM_MC  TXX_SEM_PT     ///
    using "$path_Draft_Tables\table_SEM_TRT.tex", ///
    cells("b(pattern(1 1 1)fmt(%10.4fc)) ci_bc[ll](pattern(1 1 1) fmt(%10.4fc))  ci_bc[ul](pattern(1 1 1) fmt(%10.4fc))") ///	
	mgroups("Full Humane Genetics"  "Multifactorial Causation"  "Population Thinking"  ///
			, pattern(1  1  1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
	collabel("Indirect Effects" "\makecell{BC 95\$\%$ CI \\ Lower bnd}" "\makecell{BC 95\$\%$ CI \\ Upper bnd}")  ///
	coeflabel(_bs_1 "Within-Group Variation"  ///
			  )   ///
	substitute("\_" "_")  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) replace

* Table (rtf)
esttab  TXX_SEM_FHG  TXX_SEM_MC  TXX_SEM_PT     ///
    using "$path_Draft_Tables\table_SEM_TRT.rtf", ///
    cells("b(pattern(1 1 1)fmt(%10.4fc)) ci_bc[ll](pattern(1 1 1) fmt(%10.4fc))  ci_bc[ul](pattern(1 1 1) fmt(%10.4fc))") ///	
	mgroups("Full Humane Genetics"  "Multifactorial Causation"  "Population Thinking"  ///
			, pattern(1 1 1)) ///
    collabel("Indirect Effects" "BC 95% CI - Lower" "BC 95% CI - Upper") ///
	coeflabel(_bs_1 "Within-Group Variation"  ///
			  )   ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	replace


*#Between
local keepVars  _bs_2

* Table (tex)
esttab  TXX_SEM_FHG  TXX_SEM_MC  TXX_SEM_PT     ///
    using "$path_Draft_Tables\table_SEM_TRT.tex", ///
    cells("b(pattern(1 1 1)fmt(%10.4fc)) ci_bc[ll](pattern(1 1 1) fmt(%10.4fc))  ci_bc[ul](pattern(1 1 1) fmt(%10.4fc))") ///	
    collabel(none) ///
	coeflabel(_bs_2 "Between-Group Variation"  ///
			  )   ///
	substitute("\_" "_")  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append

* Table (rtf)
esttab  TXX_SEM_FHG  TXX_SEM_MC  TXX_SEM_PT     ///
    using "$path_Draft_Tables\table_SEM_TRT.rtf", ///
    cells("b(pattern(1 1 1)fmt(%10.4fc)) ci_bc[ll](pattern(1 1 1) fmt(%10.4fc))  ci_bc[ul](pattern(1 1 1) fmt(%10.4fc))") ///	
    collabel(none) ///
	coeflabel(_bs_2 "Between-Group Variation"  ///
			  )   ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	append


*#Genetic
local keepVars  _bs_3

* Table (tex)
esttab  TXX_SEM_FHG  TXX_SEM_MC  TXX_SEM_PT     ///
    using "$path_Draft_Tables\table_SEM_TRT.tex", ///
    cells("b(pattern(1 1 1)fmt(%10.4fc)) ci_bc[ll](pattern(1 1 1) fmt(%10.4fc))  ci_bc[ul](pattern(1 1 1) fmt(%10.4fc))") ///	
    collabel(none) ///
	coeflabel(_bs_3 "Genetic Causation"  ///
			  )   ///
	substitute("\_" "_")  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append

* Table (rtf)
esttab  TXX_SEM_FHG  TXX_SEM_MC  TXX_SEM_PT     ///
    using "$path_Draft_Tables\table_SEM_TRT.rtf", ///
    cells("b(pattern(1 1 1)fmt(%10.4fc)) ci_bc[ll](pattern(1 1 1) fmt(%10.4fc))  ci_bc[ul](pattern(1 1 1) fmt(%10.4fc))") ///	
    collabel(none) ///
	coeflabel(_bs_3 "Genetic Causation"  ///
			  )   ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	append
	

*#Environmental
local keepVars  _bs_4

* Table (tex)
esttab  TXX_SEM_FHG  TXX_SEM_MC  TXX_SEM_PT     ///
    using "$path_Draft_Tables\table_SEM_TRT.tex", ///
    stat(N, label("Observations") fmt(%10.0fc)) ///
    cells("b(pattern(1 1 1)fmt(%10.4fc)) ci_bc[ll](pattern(1 1 1) fmt(%10.4fc))  ci_bc[ul](pattern(1 1 1) fmt(%10.4fc))") ///	
    collabel(none) ///
	coeflabel(_bs_4 "Environmental Causation"  ///
			  )   ///
	substitute("\_" "_")  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append

* Table (rtf)
esttab  TXX_SEM_FHG  TXX_SEM_MC  TXX_SEM_PT     ///
    using "$path_Draft_Tables\table_SEM_TRT.rtf", ///
    stat(N, label("Observations") fmt(%10.0fc)) ///
    cells("b(pattern(1 1 1)fmt(%10.4fc)) ci_bc[ll](pattern(1 1 1) fmt(%10.4fc))  ci_bc[ul](pattern(1 1 1) fmt(%10.4fc))") ///	
    collabel(none) ///
	coeflabel(_bs_4 "Environmental Causation"  ///
			  )   ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	append
	

* ------------------------------------------------------------------------------
* Figure
local keepVars  _bs_1  _bs_2  _bs_3  _bs_4

coefplot (TXX_SEM_FHG,  label("Full Humane Genetics") lc(cranberry) ci(ci_bc) mc(cranberry) ciopt(recast(rcap) lc(cranberry)))  ///
		 (TXX_SEM_MC,  label("Multifactorial Causation") ms(D) lc(navy) ci(ci_bc) mc(navy) ciopt(recast(rcap) lc(navy)))  ///
		 (TXX_SEM_PT,  label("Population Thinking") ms(S) lc(black) ci(ci_bc) mc(black) ciopt(recast(rcap) lc(black)))  ///
		 , name(SEM_FHG_coef, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 ytitle("Genetic Essentialism", size(medlarge)) ///
		 legend(position(6) row(1) region(lcolor(black)))  ///
		 keep(`keepVars')  ///
		 coeflabel(_bs_1 = "Within Variation"  ///
				   _bs_2 = "Between Variation"   ///
				   _bs_3 = "Genes"  ///
				   _bs_4 = "Environment"  ///
				   , angle(20)  ///
				   )   
				   
*		 title("Full Humane Genetics", size(med))  

	graph export "$path_Draft_Figures\figure_coefplot_SEM.png", replace
* ------------------------------------------------------------------------------




	
	
* ------------------------------------------------------------------------------
*								 Moderated Mediation
*								Model 5: A and B path
* ------------------------------------------------------------------------------
/*
NOTE: There is a single moderator variable that moderates both
	1) The path between the independent variable and mediator variable &
	2) The path between the mediator variable and dependent variable.
*/

/*
# FORMULA #
MED = a0 + a1*TRT + a2*MOD + a3*TRT*MOD
GE = b0 + b1*MED + b2*TRT + b3*MOD + b4*TRT*MOD + b5*MED*MOD
conditional indirect effect = (b1 + b5*MOD)(a1 + a3*MOD)
*/

* ----------------------------------------------------------------------------
* [BEGIN] Model 5 Bootstrap: Program and Settings ----------------------------[BEGIN]
* ----------------------------------------------------------------------------
** Program 1
capture program drop bootstrap_SEM_M5_cont
program bootstrap_SEM_M5_cont, rclass

  syntax varlist [if] [in]
  args  TRT  MOD  modtrt  //modmed
 
  summarize `MOD'  // w
  local m=r(mean)  // `m'
  local s=r(sd)  // `s'

  *create interaction terms btw moderator (`MOD') and 4 mediators
  gen MOD_within = `MOD'*within_pm
  gen MOD_between = `MOD'*between_pm
  gen MOD_gen = `MOD'*gen_cau_pm
  gen MOD_env = `MOD'*env_cau_pm
  
  *estimate model
  sem (`TRT'  `MOD'  `modtrt' -> within_pm  between_pm  gen_cau_pm  env_cau_pm   gbri_iptgb_pm)   ///
	  (within_pm   between_pm   gen_cau_pm  env_cau_pm  ///
	   MOD_within  MOD_between  MOD_gen     MOD_env ///
	  `TRT'  `MOD'  `modtrt'  -> gbri_iptgb_pm)   ///
	  `if' `in'	,   ///
	  nocapslatent  ///
	  cov(e.gen_cau_pm*e.env_cau_pm  ///
		  e.gen_cau_pm*e.within_pm  e.gen_cau_pm*e.between_pm   ///
		  e.env_cau_pm*e.within_pm  e.env_cau_pm*e.between_pm   ///
		  e.within_pm*e.between_pm)  

/* MEAN - 2 SD */
  *Within
  return scalar wv_cielw_2 = (_b[within_pm:`TRT']+(`m'-2*`s')*_b[within_pm:`modtrt'])*(_b[gbri_iptgb_pm:within_pm]+(`m'-2*`s')*_b[gbri_iptgb_pm:MOD_within])  
  *Between
  return scalar bv_cielw_2 = (_b[between_pm:`TRT']+(`m'-2*`s')*_b[between_pm:`modtrt'])*(_b[gbri_iptgb_pm:between_pm]+(`m'-2*`s')*_b[gbri_iptgb_pm:MOD_between])  
  *Genetic
  return scalar gc_cielw_2 = (_b[gen_cau_pm:`TRT']+(`m'-2*`s')*_b[gen_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:gen_cau_pm]+(`m'-2*`s')*_b[gbri_iptgb_pm:MOD_gen])  
  *Environmental
  return scalar ec_cielw_2 = (_b[env_cau_pm:`TRT']+(`m'-2*`s')*_b[env_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:env_cau_pm]+(`m'-2*`s')*_b[gbri_iptgb_pm:MOD_env])  	
  *#TOTAL
  return scalar total_cielw_2 = (_b[within_pm:`TRT']+(`m'-2*`s')*_b[within_pm:`modtrt'])*(_b[gbri_iptgb_pm:within_pm]+(`m'-2*`s')*_b[gbri_iptgb_pm:MOD_within]) +  ///
							  (_b[between_pm:`TRT']+(`m'-2*`s')*_b[between_pm:`modtrt'])*(_b[gbri_iptgb_pm:between_pm]+(`m'-2*`s')*_b[gbri_iptgb_pm:MOD_between]) +  ///
							  (_b[gen_cau_pm:`TRT']+(`m'-2*`s')*_b[gen_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:gen_cau_pm]+(`m'-2*`s')*_b[gbri_iptgb_pm:MOD_gen]) +  ///
							  (_b[env_cau_pm:`TRT']+(`m'-2*`s')*_b[env_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:env_cau_pm]+(`m'-2*`s')*_b[gbri_iptgb_pm:MOD_env])
  
/* MEAN - 1 SD */
  *Within
  return scalar wv_cielw = (_b[within_pm:`TRT']+(`m'-`s')*_b[within_pm:`modtrt'])*(_b[gbri_iptgb_pm:within_pm]+(`m'-`s')*_b[gbri_iptgb_pm:MOD_within])  
  *Between
  return scalar bv_cielw = (_b[between_pm:`TRT']+(`m'-`s')*_b[between_pm:`modtrt'])*(_b[gbri_iptgb_pm:between_pm]+(`m'-`s')*_b[gbri_iptgb_pm:MOD_between])  
  *Genetic
  return scalar gc_cielw = (_b[gen_cau_pm:`TRT']+(`m'-`s')*_b[gen_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:gen_cau_pm]+(`m'-`s')*_b[gbri_iptgb_pm:MOD_gen])  
  *Environmental
  return scalar ec_cielw = (_b[env_cau_pm:`TRT']+(`m'-`s')*_b[env_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:env_cau_pm]+(`m'-`s')*_b[gbri_iptgb_pm:MOD_env])  	
  *#TOTAL
  return scalar total_cielw = (_b[within_pm:`TRT']+(`m'-`s')*_b[within_pm:`modtrt'])*(_b[gbri_iptgb_pm:within_pm]+(`m'-`s')*_b[gbri_iptgb_pm:MOD_within]) +  ///
							  (_b[between_pm:`TRT']+(`m'-`s')*_b[between_pm:`modtrt'])*(_b[gbri_iptgb_pm:between_pm]+(`m'-`s')*_b[gbri_iptgb_pm:MOD_between]) +  ///
							  (_b[gen_cau_pm:`TRT']+(`m'-`s')*_b[gen_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:gen_cau_pm]+(`m'-`s')*_b[gbri_iptgb_pm:MOD_gen]) +  ///
							  (_b[env_cau_pm:`TRT']+(`m'-`s')*_b[env_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:env_cau_pm]+(`m'-`s')*_b[gbri_iptgb_pm:MOD_env])
  
/* MEAN */
  *Within
  return scalar wv_ciemn = (_b[within_pm:`TRT']+(`m')*_b[within_pm:`modtrt'])*(_b[gbri_iptgb_pm:within_pm]+(`m')*_b[gbri_iptgb_pm:MOD_within])   
  *Between
  return scalar bv_ciemn = (_b[between_pm:`TRT']+(`m')*_b[between_pm:`modtrt'])*(_b[gbri_iptgb_pm:between_pm]+(`m')*_b[gbri_iptgb_pm:MOD_between])  
  *Genetic
  return scalar gc_ciemn = (_b[gen_cau_pm:`TRT']+(`m')*_b[gen_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:gen_cau_pm]+(`m')*_b[gbri_iptgb_pm:MOD_gen])  
  *Environmental
  return scalar ec_ciemn = (_b[env_cau_pm:`TRT']+(`m')*_b[env_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:env_cau_pm]+(`m')*_b[gbri_iptgb_pm:MOD_env])  
  *#TOTAL
  return scalar total_ciemn = (_b[within_pm:`TRT']+(`m')*_b[within_pm:`modtrt'])*(_b[gbri_iptgb_pm:within_pm]+(`m')*_b[gbri_iptgb_pm:MOD_within]) +  ///
							  (_b[between_pm:`TRT']+(`m')*_b[between_pm:`modtrt'])*(_b[gbri_iptgb_pm:between_pm]+(`m')*_b[gbri_iptgb_pm:MOD_between]) +  ///
							  (_b[gen_cau_pm:`TRT']+(`m')*_b[gen_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:gen_cau_pm]+(`m')*_b[gbri_iptgb_pm:MOD_gen]) +  ///
							  (_b[env_cau_pm:`TRT']+(`m')*_b[env_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:env_cau_pm]+(`m')*_b[gbri_iptgb_pm:MOD_env])

/* MEAN + 1 SD */
  *Within
  return scalar wv_ciehi = (_b[within_pm:`TRT']+(`m'+`s')*_b[within_pm:`modtrt'])*(_b[gbri_iptgb_pm:within_pm]+(`m'+`s')*_b[gbri_iptgb_pm:MOD_within])  
  *Between
  return scalar bv_ciehi = (_b[between_pm:`TRT']+(`m'+`s')*_b[between_pm:`modtrt'])*(_b[gbri_iptgb_pm:between_pm]+(`m'+`s')*_b[gbri_iptgb_pm:MOD_between])  
  *Genetic
  return scalar gc_ciehi = (_b[gen_cau_pm:`TRT']+(`m'+`s')*_b[gen_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:gen_cau_pm]+(`m'+`s')*_b[gbri_iptgb_pm:MOD_gen])  
  *Environmental
  return scalar ec_ciehi = (_b[env_cau_pm:`TRT']+(`m'+`s')*_b[env_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:env_cau_pm]+(`m'+`s')*_b[gbri_iptgb_pm:MOD_env])  
  *#TOTAL
  return scalar total_ciehi = (_b[within_pm:`TRT']+(`m'+`s')*_b[within_pm:`modtrt'])*(_b[gbri_iptgb_pm:within_pm]+(`m'+`s')*_b[gbri_iptgb_pm:MOD_within]) +  ///
							  (_b[between_pm:`TRT']+(`m'+`s')*_b[between_pm:`modtrt'])*(_b[gbri_iptgb_pm:between_pm]+(`m'+`s')*_b[gbri_iptgb_pm:MOD_between]) +  ///
							  (_b[gen_cau_pm:`TRT']+(`m'+`s')*_b[gen_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:gen_cau_pm]+(`m'+`s')*_b[gbri_iptgb_pm:MOD_gen]) +  ///
							  (_b[env_cau_pm:`TRT']+(`m'+`s')*_b[env_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:env_cau_pm]+(`m'+`s')*_b[gbri_iptgb_pm:MOD_env])

/* MEAN + 2 SD */
  *Within
  return scalar wv_ciehi_2 = (_b[within_pm:`TRT']+(`m'+2*`s')*_b[within_pm:`modtrt'])*(_b[gbri_iptgb_pm:within_pm]+(`m'+2*`s')*_b[gbri_iptgb_pm:MOD_within])  
  *Between
  return scalar bv_ciehi_2 = (_b[between_pm:`TRT']+(`m'+2*`s')*_b[between_pm:`modtrt'])*(_b[gbri_iptgb_pm:between_pm]+(`m'+2*`s')*_b[gbri_iptgb_pm:MOD_between])  
  *Genetic
  return scalar gc_ciehi_2 = (_b[gen_cau_pm:`TRT']+(`m'+2*`s')*_b[gen_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:gen_cau_pm]+(`m'+2*`s')*_b[gbri_iptgb_pm:MOD_gen])  
  *Environmental
  return scalar ec_ciehi_2 = (_b[env_cau_pm:`TRT']+(`m'+2*`s')*_b[env_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:env_cau_pm]+(`m'+2*`s')*_b[gbri_iptgb_pm:MOD_env])  
  *#TOTAL
  return scalar total_ciehi_2 = (_b[within_pm:`TRT']+(`m'+2*`s')*_b[within_pm:`modtrt'])*(_b[gbri_iptgb_pm:within_pm]+(`m'+2*`s')*_b[gbri_iptgb_pm:MOD_within]) +  ///
							  (_b[between_pm:`TRT']+(`m'+2*`s')*_b[between_pm:`modtrt'])*(_b[gbri_iptgb_pm:between_pm]+(`m'+2*`s')*_b[gbri_iptgb_pm:MOD_between]) +  ///
							  (_b[gen_cau_pm:`TRT']+(`m'+2*`s')*_b[gen_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:gen_cau_pm]+(`m'+2*`s')*_b[gbri_iptgb_pm:MOD_gen]) +  ///
							  (_b[env_cau_pm:`TRT']+(`m'+2*`s')*_b[env_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:env_cau_pm]+(`m'+2*`s')*_b[gbri_iptgb_pm:MOD_env])


drop MOD_within  MOD_between  MOD_gen  MOD_env
end

** Program 2
capture program drop bootstrap_SEM_M5_disc
program bootstrap_SEM_M5_disc, rclass

  syntax varlist [if] [in]
  args  TRT  MOD  modtrt  
 
  summarize `MOD'  // w
  local m=r(mean)  // `m'
  local s=r(sd)  // `s'
  
  *create interaction terms btw moderator (`MOD') and 4 mediators
  gen MOD_within = `MOD'*within_pm
  gen MOD_between = `MOD'*between_pm
  gen MOD_gen = `MOD'*gen_cau_pm
  gen MOD_env = `MOD'*env_cau_pm
  
  *estimate model
  sem (`TRT'  `MOD'  `modtrt' -> within_pm  between_pm  gen_cau_pm  env_cau_pm   gbri_iptgb_pm)   ///
	  (within_pm   between_pm   gen_cau_pm  env_cau_pm  ///
	   MOD_within  MOD_between  MOD_gen     MOD_env ///
	  `TRT'  `MOD'  `modtrt'  -> gbri_iptgb_pm)   ///
	  `if' `in'	,   ///
	  nocapslatent  ///
	  cov(e.gen_cau_pm*e.env_cau_pm  ///
		  e.gen_cau_pm*e.within_pm  e.gen_cau_pm*e.between_pm   ///
		  e.env_cau_pm*e.within_pm  e.env_cau_pm*e.between_pm   ///
		  e.within_pm*e.between_pm)  

/* 1 */
  *Within
  return scalar wv_cie_1 = (_b[within_pm:`TRT']+(1)*_b[within_pm:`modtrt'])*(_b[gbri_iptgb_pm:within_pm]+(1)*_b[gbri_iptgb_pm:MOD_within])   
  *Between
  return scalar bv_cie_1 = (_b[between_pm:`TRT']+(1)*_b[between_pm:`modtrt'])*(_b[gbri_iptgb_pm:between_pm]+(1)*_b[gbri_iptgb_pm:MOD_between])  
  *Genetic
  return scalar gc_cie_1 = (_b[gen_cau_pm:`TRT']+(1)*_b[gen_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:gen_cau_pm]+(1)*_b[gbri_iptgb_pm:MOD_gen])  
  *Environmental
  return scalar ec_cie_1 = (_b[env_cau_pm:`TRT']+(1)*_b[env_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:env_cau_pm]+(1)*_b[gbri_iptgb_pm:MOD_env])  
  *#TOTAL
  return scalar total_cie_1 = (_b[within_pm:`TRT']+(1)*_b[within_pm:`modtrt'])*(_b[gbri_iptgb_pm:within_pm]+(1)*_b[gbri_iptgb_pm:MOD_within]) +  ///
							  (_b[between_pm:`TRT']+(1)*_b[between_pm:`modtrt'])*(_b[gbri_iptgb_pm:between_pm]+(1)*_b[gbri_iptgb_pm:MOD_between]) +  ///
							  (_b[gen_cau_pm:`TRT']+(1)*_b[gen_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:gen_cau_pm]+(1)*_b[gbri_iptgb_pm:MOD_gen]) +  ///
							  (_b[env_cau_pm:`TRT']+(1)*_b[env_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:env_cau_pm]+(1)*_b[gbri_iptgb_pm:MOD_env])

/* 0 */
  *Within
  return scalar wv_cie_0 = (_b[within_pm:`TRT']+(0)*_b[within_pm:`modtrt'])*(_b[gbri_iptgb_pm:within_pm]+(0)*_b[gbri_iptgb_pm:MOD_within])   
  *Between
  return scalar bv_cie_0 = (_b[between_pm:`TRT']+(0)*_b[between_pm:`modtrt'])*(_b[gbri_iptgb_pm:between_pm]+(0)*_b[gbri_iptgb_pm:MOD_between])  
  *Genetic
  return scalar gc_cie_0 = (_b[gen_cau_pm:`TRT']+(0)*_b[gen_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:gen_cau_pm]+(0)*_b[gbri_iptgb_pm:MOD_gen])  
  *Environmental
  return scalar ec_cie_0 = (_b[env_cau_pm:`TRT']+(0)*_b[env_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:env_cau_pm]+(0)*_b[gbri_iptgb_pm:MOD_env])  
  *#TOTAL
  return scalar total_cie_0 = (_b[within_pm:`TRT']+(0)*_b[within_pm:`modtrt'])*(_b[gbri_iptgb_pm:within_pm]+(0)*_b[gbri_iptgb_pm:MOD_within]) +  ///
							  (_b[between_pm:`TRT']+(0)*_b[between_pm:`modtrt'])*(_b[gbri_iptgb_pm:between_pm]+(0)*_b[gbri_iptgb_pm:MOD_between]) +  ///
							  (_b[gen_cau_pm:`TRT']+(0)*_b[gen_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:gen_cau_pm]+(0)*_b[gbri_iptgb_pm:MOD_gen]) +  ///
							  (_b[env_cau_pm:`TRT']+(0)*_b[env_cau_pm:`modtrt'])*(_b[gbri_iptgb_pm:env_cau_pm]+(0)*_b[gbri_iptgb_pm:MOD_env])

  
drop MOD_within  MOD_between  MOD_gen  MOD_env
end
* ------------------------------------------------------------------------------
* [EDN] Bootstrap: Program and Settings ----------------------------------------[END]
* ------------------------------------------------------------------------------

*#Treatment variable
local TRT full_HG  // [CHANGE HERE]

* ------------------------------------------------------------------------------
*##------------------------------- Gender (male) ----------------------------##*
* ------------------------------------------------------------------------------
*Model 5: A&B path
*drop  MOD_TRT  MOD_MED
*##-------------------- Genetics Knowledge (genetics_pm) --------------------##*

*Normal theory estimation using the delta method for model .
local MOD male  // [CHANGE HERE]

 ** Moderator by iv interaction
  gen MOD_TRT = `MOD'*`TRT'
  local modtrt MOD_TRT

***# Full Sample
bootstrap   ///
			r(wv_cie_1) r(bv_cie_1) r(gc_cie_1) r(ec_cie_1) r(total_cie_1)  ///
			r(wv_cie_0) r(bv_cie_0) r(gc_cie_0) r(ec_cie_0) r(total_cie_0)  ///
			, bca seed(`SEED') reps(`NoR'): bootstrap_SEM_M5_disc `TRT' `MOD' `modtrt'

eststo TXX_FHG_M5_gd: estat boot, nor percentile bc bca
* ------------------------------------------------------------------------------
drop MOD_TRT


*Count sample size by subsample
levelsof male, local(genders)  // collects all the unique values (levels) of the variable [male] and store them in a local macro called [genders].
foreach i of local genders {
		count if !missing(full_HG)&(male == `i')
		local gender_N`i'=r(N)
}


*Calculating BC p-value


  
* ------------------------------------------------------------------------------
* Summarize MODEL 2, 3, 5 results in [TABLES] for Gender
* ------------------------------------------------------------------------------
*#Within
local keepVars  _bs_1  _bs_6

* Table (tex)
esttab  TXX_FHG_M5_gd       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gender.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	mgroups("\makecell{Gender}"  ///
			, pattern(1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
	collabel("Indirect Effects" "\makecell{BC 95\$\%$ CI \\ Lower bnd}" "\makecell{BC 95\$\%$ CI \\ Upper bnd}")  ///
	coeflabel(_bs_1 "\hspace{.5cm} Self-Identified Men"  ///
			  _bs_6 "\hspace{.5cm} Self-Identified Women"  ///
			  )   ///
	refcat(_bs_1 "\textit{Within-Group Variation}", nolabel)  ///
	substitute("\_" "_")  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) replace
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  
*cells("b(pattern(1)fmt(%10.3fc)star) ci_bc[ll](pattern(1) fmt(%10.3fc))  ci_bc[ul](pattern(1) fmt(%10.3fc))")

* Table (rtf)
esttab TXX_FHG_M5_gd ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gender.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
    mgroups("Gender (Obs. of Men=`gender_N1', Obs. of Women=`gender_N0')", pattern(1)) ///  
    collabel("Indirect Effects" "BC 95% CI - Lower" "BC 95% CI - Upper") ///
    coeflabel(_bs_1 "Self-Identified Men"  ///
              _bs_6 "Self-Identified Women") ///  
    refcat(_bs_1 "Within-Group Variation", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    replace

* ------------------------------------------------------------------------------
*#Between
local keepVars  _bs_2  _bs_7

* Table (tex)
esttab  TXX_FHG_M5_gd       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gender.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	coeflabel(_bs_2 "\hspace{.5cm} Self-Identified Men"  ///
			  _bs_7 "\hspace{.5cm} Self-Identified Women"  ///
			  )   ///
	refcat(_bs_2 "\textit{Between-Group Variation}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_gd ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gender.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
	collabel(none) ///
    coeflabel(_bs_2 "Self-Identified Men"  ///
              _bs_7 "Self-Identified Women") ///  
    refcat(_bs_2 "Between-Group Variation", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append

* ------------------------------------------------------------------------------
*#Genetic
local keepVars  _bs_3  _bs_8

* Table 
esttab  TXX_FHG_M5_gd       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gender.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	coeflabel(_bs_3 "\hspace{.5cm} Self-Identified Men"  ///
			  _bs_8 "\hspace{.5cm} Self-Identified Women"  ///
			  )   ///
	refcat(_bs_3 "\textit{Genetic Attribution}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_gd ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gender.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
	collabel(none) ///
    coeflabel(_bs_3 "Self-Identified Men"  ///
              _bs_8 "Self-Identified Women") ///  
    refcat(_bs_3 "Genetic Attribution", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append

* ------------------------------------------------------------------------------
*#Environmental
local keepVars  _bs_4  _bs_9

* Table 
esttab  TXX_FHG_M5_gd       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gender.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
    stat(N, label("Observations") fmt(%10.0fc)) ///
	coeflabel(_bs_4 "\hspace{.5cm} Self-Identified Men"  ///
			  _bs_9 "\hspace{.5cm} Self-Identified Women"  ///
			  )   ///
	refcat(_bs_4 "\textit{Environmental Attribution}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_gd ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gender.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
    stat(N, label("Observations") fmt(%10.0fc)) ///
	collabel(none) ///
    coeflabel(_bs_4 "Self-Identified Men"  ///
              _bs_9 "Self-Identified Women") ///  
    refcat(_bs_4 "Environmental Attribution", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append

* ------------------------------------------------------------------------------
/*
*#Total
local keepVars  _bs_5  _bs_10

* Table 
esttab  TXX_FHG_M5_gd       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gender.tex", ///
    cells("b(pattern(1)fmt(%10.3fc)star) ci_bc[ll](pattern(1) fmt(%10.3fc))  ci_bc[ul](pattern(1) fmt(%10.3fc))") ///	
    stat(N, label("Observations") fmt(%10.0fc)) ///
	coeflabel(_bs_5 "\hspace{2.5cm} Self-Identified Men"  ///
			  _bs_10 "\hspace{2.5cm} Self-Identified Women"  ///
			  )   ///
	refcat(_bs_5 "\textit{Total Indirect Effects}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  
 
* Table (rtf)
esttab TXX_FHG_M5_gd ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gender.rtf", ///
    cells("b(pattern(1)fmt(%10.3fc)star) ci_bc[ll](pattern(1) fmt(%10.3fc))  ci_bc[ul](pattern(1) fmt(%10.3fc))") ///    
    stat(N, label("Observations") fmt(%10.0fc)) ///
	collabel(none) ///
    coeflabel(_bs_5 "Self-Identified Men"  ///
              _bs_10 "Self-Identified Women") ///  
    refcat(_bs_5 "Total Indirect Effects", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append 
 
* ------------------------------------------------------------------------------
* Figure
local GRAPH TXX_FHG_M5_gd
coefplot (`GRAPH',  label("Self-Identified Men")  ///
			keep(_bs_1 _bs_2 _bs_3 _bs_4 _bs_5)  ///
			lc(navy) mc(navy) ci(ci_bc) ciopt(recast(rcap) lc(navy)))  ///
		 (`GRAPH',  label("Self-Identified Women")  ///
			keep(_bs_6 _bs_7 _bs_8 _bs_9 _bs_10)  ///
			rename(_bs_6=_bs_1 _bs_7=_bs_2 _bs_8=_bs_3 _bs_9=_bs_4 _bs_10=_bs_5)  ///
			ms(D) lc(cranberry) ci(ci_bc) mc(cranberry) ciopt(recast(rcap) lc(cranberry)))  ///
		 , name(SEM_FHG_coef_gd, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 ytitle("Indirect Effects", size(medlarge)) ///
		 title("Full Humane Genetics Curriculum", size(med))  ///
		 legend(position(6) row(1) region(lcolor(black)))  ///
		 coeflabel(_bs_1 = "Within-Group Variation"  ///
				   _bs_2 = "Between-Group Variation"   ///
				   _bs_3 = "Genetic Attribution"  ///
				   _bs_4 = "Environmental Attribution"  ///
				   _bs_5 = "Total Indirect Effects", angle(35))   

	graph export "$path_Figures\figure_coefplot_FHG_SEM_gender.png", replace
* ------------------------------------------------------------------------------
*/

* ------------------------------------------------------------------------------
* Figure
local GRAPH TXX_FHG_M5_gd
coefplot (`GRAPH',  label("Self-Identified Men (N=`gender_N1')")  ///
			keep(_bs_1 _bs_2 _bs_3 _bs_4)  ///
			lc(navy) mc(navy) ci(ci_bc) ciopt(recast(rcap) lc(navy)))  ///
		 (`GRAPH',  label("Self-Identified Women (N=`gender_N0')")  ///
			keep(_bs_6 _bs_7 _bs_8 _bs_9)  ///
			rename(_bs_6=_bs_1 _bs_7=_bs_2 _bs_8=_bs_3 _bs_9=_bs_4)  ///
			ms(D) lc(cranberry) ci(ci_bc) mc(cranberry) ciopt(recast(rcap) lc(cranberry)))  ///
		 , name(SEM_FHG_coef_gd, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 ytitle("Genetic Essentialism", size(medlarge)) ///
		 title("Full Humane Genetics Curriculum", size(med))  ///
		 legend(position(6) row(1) region(lcolor(black)))  ///
		 coeflabel(_bs_1 = "Within-Group Variation"  ///
				   _bs_2 = "Between-Group Variation"   ///
				   _bs_3 = "Genetic Attribution"  ///
				   _bs_4 = "Environmental Attribution"  ///
				   , angle(35)  ///
				   )   

	graph export "$path_Draft_Figures\figure_coefplot_FHG_SEM_gender.png", replace
* ------------------------------------------------------------------------------
* Figure to combine
local GRAPH TXX_FHG_M5_gd
coefplot (`GRAPH',  label("Self-Identified Men (N=`gender_N1')")  ///
			keep(_bs_1 _bs_2 _bs_3 _bs_4)  ///
			lc(navy) mc(navy) ci(ci_bc) ciopt(recast(rcap) lc(navy)) msize(vsmall))  ///
		 (`GRAPH',  label("Self-Identified Women (N=`gender_N0')")  ///
			keep(_bs_6 _bs_7 _bs_8 _bs_9)  ///
			rename(_bs_6=_bs_1 _bs_7=_bs_2 _bs_8=_bs_3 _bs_9=_bs_4)  ///
			ms(D) lc(cranberry) ci(ci_bc) mc(cranberry) ciopt(recast(rcap) lc(cranberry)) msize(vsmall))  ///
		 , name(SEM_FHG_coef_gd_c, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 legend(position(6) row(1) region(lcolor(black)) size(vsmall))  ///
		 title("Gender", size(small)) ///
		 coeflabel(_bs_1 = "Within"  ///
				   _bs_2 = "Between"   ///
				   _bs_3 = "Genes"  ///
				   _bs_4 = "Environment"  ///
				   , angle(35) labsize(vsmall)  ///
				   )      
* ------------------------------------------------------------------------------


* ------------------------------------------------------------------------------
*##---------------------------- Race (race_white) ---------------------------##*
* ------------------------------------------------------------------------------
*Model 5: A&B path
*drop  MOD_TRT  MOD_MED
*##---------------------------- Race (race_white) ---------------------------##*

*Normal theory estimation using the delta method for model .
local MOD race_white  // [CHANGE HERE]

 ** Moderator by iv interaction
  gen MOD_TRT = `MOD'*`TRT'
  local modtrt MOD_TRT

***# Full Sample
bootstrap   ///
			r(wv_cie_1) r(bv_cie_1) r(gc_cie_1) r(ec_cie_1) r(total_cie_1)  ///
			r(wv_cie_0) r(bv_cie_0) r(gc_cie_0) r(ec_cie_0) r(total_cie_0)  ///
			, bca seed(`SEED') reps(`NoR'): bootstrap_SEM_M5_disc `TRT' `MOD' `modtrt'

eststo TXX_FHG_M5_rc: estat boot, nor percentile bc bca
* ------------------------------------------------------------------------------
drop MOD_TRT

*Count sample size by subsample
levelsof race_white, local(race)  // collects all the unique values (levels) of the variable [race_white] and store them in a local macro called [race].
foreach i of local race {
		count if !missing(full_HG)&(race_white == `i')
		local white_N`i'=r(N)
}


* ------------------------------------------------------------------------------
* Summarize MODEL 2, 3, 5 results in [TABLES] for Race
* ------------------------------------------------------------------------------
*#Within
local keepVars  _bs_1  _bs_6

* Table (tex)
esttab  TXX_FHG_M5_rc       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_race.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	mgroups("\makecell{Race}"  ///
			, pattern(1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
	collabel("Indirect Effects" "\makecell{BC 95\$\%$ CI \\ Lower bnd}" "\makecell{BC 95\$\%$ CI \\ Upper bnd}")  ///
	coeflabel(_bs_1 "\hspace{.5cm} Self-Identified White"  ///
			  _bs_6 "\hspace{.5cm} Self-Identified Non-White"  ///
			  )   ///
	refcat(_bs_1 "\textit{Within-Group Variation}", nolabel)  ///
	substitute("\_" "_")  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) replace
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_rc ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_race.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
    mgroups("Race (Obs. of White=`white_N1', Obs. of Non-White=`white_N0')", pattern(1)) ///  
    collabel("Indirect Effects" "BC 95% CI - Lower" "BC 95% CI - Upper") ///
    coeflabel(_bs_1 "Self-Identified White"  ///
              _bs_6 "Self-Identified Non-White") ///  
    refcat(_bs_1 "Within-Group Variation", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    replace

* ------------------------------------------------------------------------------
*#Between
local keepVars  _bs_2  _bs_7

* Table (tex)
esttab  TXX_FHG_M5_rc       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_race.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	coeflabel(_bs_2 "\hspace{.5cm} Self-Identified White"  ///
			  _bs_7 "\hspace{.5cm} Self-Identified Non-White"  ///
			  )   ///
	refcat(_bs_2 "\textit{Between-Group Variation}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_rc ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_race.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
	collabel(none) ///
    coeflabel(_bs_2 "Self-Identified White"  ///
              _bs_7 "Self-Identified Non-White") ///  
    refcat(_bs_2 "Between-Group Variation", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append

* ------------------------------------------------------------------------------
*#Genetic
local keepVars  _bs_3  _bs_8

* Table (tex)
esttab  TXX_FHG_M5_rc       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_race.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	coeflabel(_bs_3 "\hspace{.5cm} Self-Identified White"  ///
			  _bs_8 "\hspace{.5cm} Self-Identified Non-White"  ///
			  )   ///
	refcat(_bs_3 "\textit{Genetic Attribution}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_rc ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_race.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
	collabel(none) ///
    coeflabel(_bs_3 "Self-Identified White"  ///
              _bs_8 "Self-Identified Non-White") ///  
    refcat(_bs_3 "Genetic Attribution", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append
	
* ------------------------------------------------------------------------------
*#Environmental
local keepVars  _bs_4  _bs_9

* Table (tex)
esttab  TXX_FHG_M5_rc       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_race.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
    stat(N, label("Observations") fmt(%10.0fc)) ///
	coeflabel(_bs_4 "\hspace{.5cm} Self-Identified White"  ///
			  _bs_9 "\hspace{.5cm} Self-Identified Non-White"  ///
			  )   ///
	refcat(_bs_4 "\textit{Environmental Attribution}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_rc ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_race.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
    stat(N, label("Observations") fmt(%10.0fc)) ///
	collabel(none) ///
    coeflabel(_bs_4 "Self-Identified White"  ///
              _bs_9 "Self-Identified Non-White") ///  
    refcat(_bs_4 "Environmental Attribution", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append

* ------------------------------------------------------------------------------
/*
*#Total
local keepVars  _bs_5  _bs_10

* Table (tex)
esttab  TXX_FHG_M5_rc       ///
    using "$path_Tables\table_FHG_SEM_M5_race.tex", ///
    cells("b(pattern(1)fmt(%10.3fc)star) ci_bc[ll](pattern(1) fmt(%10.3fc))  ci_bc[ul](pattern(1) fmt(%10.3fc))") ///	
    stat(N, label("Observations") fmt(%10.0fc)) ///
	coeflabel(_bs_5 "\hspace{2.5cm} Self-Identified White"  ///
			  _bs_10 "\hspace{2.5cm} Self-Identified Non-White"  ///
			  )   ///
	refcat(_bs_5 "\textit{Total Indirect Effects}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  
 
 * Table (rtf)
esttab TXX_FHG_M5_rc ///
    using "$path_Tables\table_FHG_SEM_M5_race.rtf", ///
    cells("b(pattern(1)fmt(%10.3fc)star) ci_bc[ll](pattern(1) fmt(%10.3fc))  ci_bc[ul](pattern(1) fmt(%10.3fc))") ///    
    stat(N, label("Observations") fmt(%10.0fc)) ///
	collabel(none) ///
    coeflabel(_bs_5 "Self-Identified White"  ///
              _bs_10 "Self-Identified Non-White") ///  
    refcat(_bs_5 "Total Indirect Effects", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append 

* ------------------------------------------------------------------------------
* Figure
local GRAPH TXX_FHG_M5_rc
coefplot (`GRAPH',  label("Self-Identified White")  ///
			keep(_bs_1 _bs_2 _bs_3 _bs_4 _bs_5)  ///
			lc(navy) mc(navy) ci(ci_bc) ciopt(recast(rcap) lc(navy)))  ///
		 (`GRAPH',  label("Self-Identified Non-White")  ///
			keep(_bs_6 _bs_7 _bs_8 _bs_9 _bs_10)  ///
			rename(_bs_6=_bs_1 _bs_7=_bs_2 _bs_8=_bs_3 _bs_9=_bs_4 _bs_10=_bs_5)  ///
			ms(D) lc(cranberry) ci(ci_bc) mc(cranberry) ciopt(recast(rcap) lc(cranberry)))  ///
		 , name(SEM_FHG_coef_rc, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 ytitle("Indirect Effects", size(medlarge)) ///
		 title("Full Humane Genetics Curriculum", size(med))  ///
		 legend(position(6) row(1) region(lcolor(black)))  ///
		 coeflabel(_bs_1 = "Within-Group Variation"  ///
				   _bs_2 = "Between-Group Variation"   ///
				   _bs_3 = "Genetic Attribution"  ///
				   _bs_4 = "Environmental Attribution"  ///
				   _bs_5 = "Total Indirect Effects", angle(35))   

	graph export "$path_Figures\figure_coefplot_FHG_SEM_race.png", replace
* ------------------------------------------------------------------------------
*/


* ------------------------------------------------------------------------------
* Figure
local GRAPH TXX_FHG_M5_rc
coefplot (`GRAPH',  label("Self-Identified White (N=`white_N1')")  ///
			keep(_bs_1 _bs_2 _bs_3 _bs_4)  ///
			lc(navy) mc(cranberry) ci(ci_bc) ciopt(recast(rcap) lc(cranberry)))  ///
		 (`GRAPH',  label("Self-Identified Non-White (N=`white_N0')")  ///
			keep(_bs_6 _bs_7 _bs_8 _bs_9)  ///
			rename(_bs_6=_bs_1 _bs_7=_bs_2 _bs_8=_bs_3 _bs_9=_bs_4)  ///
			ms(D) lc(navy) ci(ci_bc) mc(navy) ciopt(recast(rcap) lc(navy)))  ///
		 , name(SEM_FHG_coef_rc, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 ytitle("Genetic Essentialism", size(medlarge)) ///
		 title("Full Humane Genetics Curriculum", size(med))  ///
		 legend(position(6) row(1) region(lcolor(black)))  ///
		 coeflabel(_bs_1 = "Within-Group Variation"  ///
				   _bs_2 = "Between-Group Variation"   ///
				   _bs_3 = "Genetic Attribution"  ///
				   _bs_4 = "Environmental Attribution"  ///
				   , angle(35)  ///
				   )   

	graph export "$path_Draft_Figures\figure_coefplot_FHG_SEM_race.png", replace
* ------------------------------------------------------------------------------
* Figure to combine
local GRAPH TXX_FHG_M5_rc
coefplot (`GRAPH',  label("Self-Identified White (N=`white_N1')")  ///
			keep(_bs_1 _bs_2 _bs_3 _bs_4)  ///
			lc(navy) mc(cranberry) ci(ci_bc) ciopt(recast(rcap) lc(cranberry)) msize(vsmall))  ///
		 (`GRAPH',  label("Self-Identified Non-White (N=`white_N0')")  ///
			keep(_bs_6 _bs_7 _bs_8 _bs_9)  ///
			rename(_bs_6=_bs_1 _bs_7=_bs_2 _bs_8=_bs_3 _bs_9=_bs_4)  ///
			ms(D) lc(navy) ci(ci_bc) mc(navy) ciopt(recast(rcap) lc(navy)) msize(vsmall))  ///
		 , name(SEM_FHG_coef_rc_c, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 legend(position(6) row(1) region(lcolor(black)) size(vsmall))  ///
		 title("Race", size(small)) ///
		 coeflabel(_bs_1 = "Within"  ///
				   _bs_2 = "Between"   ///
				   _bs_3 = "Genes"  ///
				   _bs_4 = "Environment"  ///
				   , angle(35) labsize(vsmall)  ///
				   )   

	graph export "$path_Draft_Figures\figure_coefplot_FHG_SEM_race.png", replace
* ------------------------------------------------------------------------------



* ------------------------------------------------------------------------------
*##------------------- Cultural Theory of Risk (ctor_pm) --------------------##*
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------
*Model 5: A&B path
* ------------------------------------------------------------------------------
*drop  MOD_TRT  MOD_MED
*##------------------- Cultural Theory of Risk (ctor_pm) --------------------##*

*Normal theory estimation using the delta method for model .
local MOD ctor_pm  // [CHANGE HERE]

 ** Moderator by iv interaction
  gen MOD_TRT = `MOD'*`TRT'
  local modtrt MOD_TRT
  
***# Full Sample
bootstrap   ///
			r(wv_cielw)   r(bv_cielw)   r(gc_cielw)   r(ec_cielw)   r(total_cielw)  ///
			r(wv_ciemn)   r(bv_ciemn)   r(gc_ciemn)   r(ec_ciemn)   r(total_ciemn)  ///
			r(wv_ciehi)	  r(bv_ciehi)   r(gc_ciehi)   r(ec_ciehi)   r(total_ciehi)  ///
			r(wv_cielw_2) r(bv_cielw_2) r(gc_cielw_2) r(ec_cielw_2) r(total_cielw_2)  ///
			r(wv_ciehi_2) r(bv_ciehi_2) r(gc_ciehi_2) r(ec_ciehi_2) r(total_ciehi_2)  ///
			, bca seed(`SEED') reps(`NoR'): bootstrap_SEM_M5_cont `TRT' `MOD' `modtrt'
			
eststo TXX_FHG_M5_ctor: estat boot, nor percentile bc bca
* ------------------------------------------------------------------------------
drop MOD_TRT



* ------------------------------------------------------------------------------
* Summarize MODEL 5 results in [TABLES] for CTR
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------
*                      Moderator: (mean-sd), (mean),(mean+sd)
* ------------------------------------------------------------------------------
*#Within
local keepVars  _bs_1  _bs_6  _bs_11    

* Table (tex)
esttab  TXX_FHG_M5_ctor       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_ctr.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	mgroups("\makecell{Cultural Theory of Risk}"  ///
			, pattern(1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
	collabel("Indirect Effects" "\makecell{BC 95\$\%$ CI \\ Lower bnd}" "\makecell{BC 95\$\%$ CI \\ Upper bnd}")  ///
	coeflabel(_bs_1 "\hspace{2.5cm} \$\overline{W}-SD_W$"  ///
			  _bs_6 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_11 "\hspace{2.5cm} \$\overline{W}+SD_W$"  ///
			  )   ///
	refcat(_bs_1 "\textit{Within-Group Variation}", nolabel)  ///
	substitute("\_" "_")  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) replace
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_ctor ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_ctr.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
    mgroups("Cultural Theory of Risk", pattern(1)) ///  
    collabel("Indirect Effects" "BC 95% CI - Lower" "BC 95% CI - Upper") ///
	coeflabel(_bs_1 "Mean-SD"  ///
			  _bs_6 "Mean"  ///
			  _bs_11 "Mean+SD"  ///
			  )   ///
    refcat(_bs_1 "Within-Group Variation", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    replace

* ------------------------------------------------------------------------------
*#Between
local keepVars  _bs_2  _bs_7  _bs_12    

* Table (tex)
esttab  TXX_FHG_M5_ctor       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_ctr.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	coeflabel(_bs_2 "\hspace{2.5cm} \$\overline{W}-SD_W$"  ///
			  _bs_7 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_12 "\hspace{2.5cm} \$\overline{W}+SD_W$"  ///
			  )   ///
	refcat(_bs_2 "\textit{Between-Group Variation}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_ctor ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_ctr.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
	collabel(none) ///
	coeflabel(_bs_2 "Mean-SD"  ///
			  _bs_7 "Mean"  ///
			  _bs_12 "Mean+SD"  ///
			  )   ///
    refcat(_bs_2 "Between-Group Variation", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append

* ------------------------------------------------------------------------------
*#Genetic
local keepVars  _bs_3  _bs_8  _bs_13    

* Table (tex)
esttab  TXX_FHG_M5_ctor       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_ctr.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	coeflabel(_bs_3 "\hspace{2.5cm} \$\overline{W}-SD_W$"  ///
			  _bs_8 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_13 "\hspace{2.5cm} \$\overline{W}+SD_W$"  ///
			  )   ///
	refcat(_bs_3 "\textit{Genetic Attribution}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  


* Table (rtf)
esttab TXX_FHG_M5_ctor ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_ctr.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
	collabel(none) ///
	coeflabel(_bs_3 "Mean-SD"  ///
			  _bs_8 "Mean"  ///
			  _bs_13 "Mean+SD"  ///
			  )   ///
    refcat(_bs_3 "Genetic Attribution", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append

* ------------------------------------------------------------------------------
*#Environmental
local keepVars  _bs_4  _bs_9  _bs_14    

* Table (tex)
esttab  TXX_FHG_M5_ctor       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_ctr.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
    stat(N, label("Observations") fmt(%10.0fc)) ///
	coeflabel(_bs_4 "\hspace{2.5cm} \$\overline{W}-SD_W$"  ///
			  _bs_9 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_14 "\hspace{2.5cm} \$\overline{W}+SD_W$"  ///
			  )   ///
	refcat(_bs_4 "\textit{Environmental Attribution}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_ctor ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_ctr.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
    stat(N, label("Observations") fmt(%10.0fc)) ///
	collabel(none) ///
	coeflabel(_bs_4 "Mean-SD"  ///
			  _bs_9 "Mean"  ///
			  _bs_14 "Mean+SD"  ///
			  )   ///
    refcat(_bs_4 "Environmental Attribution", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append

* ------------------------------------------------------------------------------
/*
*#Total
local keepVars  _bs_5  _bs_10  _bs_15    

* Table (tex)
esttab  TXX_FHG_M5_ctor       ///
    using "$path_Tables\table_FHG_SEM_M5_ctr.tex", ///
    cells("b(pattern(1)fmt(%10.3fc)star) ci_bc[ll](pattern(1) fmt(%10.3fc))  ci_bc[ul](pattern(1) fmt(%10.3fc))") ///	
    stat(N, label("Observations") fmt(%10.0fc)) ///
	coeflabel(_bs_5 "\hspace{2.5cm} \$\overline{W}-SD_W$"  ///
			  _bs_10 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_15 "\hspace{2.5cm} \$\overline{W}+SD_W$"  ///
			  )   ///
	refcat(_bs_5 "\textit{Total Indirect Effects}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_ctor ///
    using "$path_Tables\table_FHG_SEM_M5_ctr.rtf", ///
    cells("b(pattern(1)fmt(%10.3fc)star) ci_bc[ll](pattern(1) fmt(%10.3fc))  ci_bc[ul](pattern(1) fmt(%10.3fc))") ///    
    stat(N, label("Observations") fmt(%10.0fc)) ///
	collabel(none) ///
	coeflabel(_bs_5 "Mean-SD"  ///
			  _bs_10 "Mean"  ///
			  _bs_15 "Mean+SD"  ///
			  )   ///
    refcat(_bs_5 "Total Indirect Effects", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append 
* ------------------------------------------------------------------------------
* Figure
local GRAPH TXX_FHG_M5_ctor
coefplot (`GRAPH',  label("Mean-SD")  ///
			keep(_bs_1 _bs_2 _bs_3 _bs_4 _bs_5)  ///
			lc(navy) mc(navy) ci(ci_bc) ciopt(recast(rcap) lc(navy)))  ///
		 (`GRAPH',  label("Mean")  ///
			keep(_bs_6 _bs_7 _bs_8 _bs_9 _bs_10)  ///
			rename(_bs_6=_bs_1 _bs_7=_bs_2 _bs_8=_bs_3 _bs_9=_bs_4 _bs_10=_bs_5)  ///
			ms(D) lc(cranberry) ci(ci_bc) mc(cranberry) ciopt(recast(rcap) lc(cranberry)))  ///
		 (`GRAPH',  label("Mean+SD")  ///
			keep(_bs_11 _bs_12 _bs_13 _bs_14 _bs_15)  ///
			rename(_bs_11=_bs_1 _bs_12=_bs_2 _bs_13=_bs_3 _bs_14=_bs_4 _bs_15=_bs_5)  ///
			ms(T) lc(black) mc(black) ci(ci_bc) ciopt(recast(rcap) lc(black)))  ///
		 , name(SEM_FHG_coef_ctr, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 ytitle("Indirect Effects", size(medlarge)) ///
		 title("Full Humane Genetics Curriculum", size(med))  ///
		 legend(position(6) row(1) region(lcolor(black)))  ///
		 coeflabel(_bs_1 = "Within-Group Variation"  ///
				   _bs_2 = "Between-Group Variation"   ///
				   _bs_3 = "Genetic Attribution"  ///
				   _bs_4 = "Environmental Attribution"  ///
				   _bs_5 = "Total Indirect Effects", angle(35))   

	graph export "$path_Figures\figure_coefplot_FHG_SEM_ctr.png", replace
* ------------------------------------------------------------------------------
*/
* ------------------------------------------------------------------------------
* Figure
local GRAPH TXX_FHG_M5_ctor
coefplot (`GRAPH',  label("Mean-SD")  ///
			keep(_bs_1 _bs_2 _bs_3 _bs_4)  ///
			lc(navy) mc(navy) ci(ci_bc) ciopt(recast(rcap) lc(navy)))  ///
		 (`GRAPH',  label("Mean")  ///
			keep(_bs_6 _bs_7 _bs_8 _bs_9)  ///
			rename(_bs_6=_bs_1 _bs_7=_bs_2 _bs_8=_bs_3 _bs_9=_bs_4)  ///
			ms(D) lc(cranberry) ci(ci_bc) mc(cranberry) ciopt(recast(rcap) lc(cranberry)))  ///
		 (`GRAPH',  label("Mean+SD")  ///
			keep(_bs_11 _bs_12 _bs_13 _bs_14)  ///
			rename(_bs_11=_bs_1 _bs_12=_bs_2 _bs_13=_bs_3 _bs_14=_bs_4)  ///
			ms(T) lc(black) mc(black) ci(ci_bc) ciopt(recast(rcap) lc(black)))  ///
		 , name(SEM_FHG_coef_ctr, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 ytitle("Genetic Essentialism", size(medlarge)) ///
		 title("Full Humane Genetics Curriculum", size(med))  ///
		 legend(position(6) row(1) region(lcolor(black)))  ///
		 coeflabel(_bs_1 = "Within-Group Variation"  ///
				   _bs_2 = "Between-Group Variation"   ///
				   _bs_3 = "Genetic Attribution"  ///
				   _bs_4 = "Environmental Attribution"  ///
				   , angle(35)  ///
				   )   

	graph export "$path_Draft_Figures\figure_coefplot_FHG_SEM_ctr.png", replace
* ------------------------------------------------------------------------------
* Figure to combine
local GRAPH TXX_FHG_M5_ctor
coefplot (`GRAPH',  label("Mean-SD")  ///
			keep(_bs_1 _bs_2 _bs_3 _bs_4)  ///
			lc(navy) mc(navy) ci(ci_bc) ciopt(recast(rcap) lc(navy)) msize(vsmall))  ///
		 (`GRAPH',  label("Mean")  ///
			keep(_bs_6 _bs_7 _bs_8 _bs_9)  ///
			rename(_bs_6=_bs_1 _bs_7=_bs_2 _bs_8=_bs_3 _bs_9=_bs_4)  ///
			ms(D) lc(cranberry) ci(ci_bc) mc(cranberry) ciopt(recast(rcap) lc(cranberry)) msize(vsmall))  ///
		 (`GRAPH',  label("Mean+SD")  ///
			keep(_bs_11 _bs_12 _bs_13 _bs_14)  ///
			rename(_bs_11=_bs_1 _bs_12=_bs_2 _bs_13=_bs_3 _bs_14=_bs_4)  ///
			ms(T) lc(black) mc(black) ci(ci_bc) ciopt(recast(rcap) lc(black)) msize(vsmall))  ///
		 , name(SEM_FHG_coef_ctr_c, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 legend(position(6) row(1) region(lcolor(black)) size(vsmall))  ///
		 title("Cultural Theory of Risk", size(small)) ///
		 coeflabel(_bs_1 = "Within"  ///
				   _bs_2 = "Between"   ///
				   _bs_3 = "Genes"  ///
				   _bs_4 = "Environment"  ///
				   , angle(35) labsize(vsmall)  ///
				   )      
* ------------------------------------------------------------------------------



* ------------------------------------------------------------------------------
*                      Moderator: (mean-2sd), (mean),(mean+2sd)
* ------------------------------------------------------------------------------
*#Within
local keepVars  _bs_16  _bs_6  _bs_21    

* Table (tex)
esttab  TXX_FHG_M5_ctor       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_ctr_2.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	mgroups("\makecell{Cultural Theory of Risk}"  ///
			, pattern(1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
	collabel("Indirect Effects" "\makecell{BC 95\$\%$ CI \\ Lower bnd}" "\makecell{BC 95\$\%$ CI \\ Upper bnd}")  ///
	coeflabel(_bs_16 "\hspace{2.5cm} \$\overline{W}-2SD_W$"  ///
			  _bs_6 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_21 "\hspace{2.5cm} \$\overline{W}+2SD_W$"  ///
			  )   ///
	refcat(_bs_16 "\textit{Within-Group Variation}", nolabel)  ///
	substitute("\_" "_")  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) replace
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_ctor ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_ctr_2.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
    mgroups("Cultural Theory of Risk", pattern(1)) ///  
    collabel("Indirect Effects" "BC 95% CI - Lower" "BC 95% CI - Upper") ///
	coeflabel(_bs_16 "Mean-2SD"  ///
			  _bs_6 "Mean"  ///
			  _bs_21 "Mean+2SD"  ///
			  )   ///
    refcat(_bs_16 "Within-Group Variation", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    replace

* ------------------------------------------------------------------------------
*#Between
local keepVars  _bs_17  _bs_7  _bs_22    

* Table (tex)
esttab  TXX_FHG_M5_ctor       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_ctr_2.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	coeflabel(_bs_17 "\hspace{2.5cm} \$\overline{W}-2SD_W$"  ///
			  _bs_7 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_22 "\hspace{2.5cm} \$\overline{W}+2SD_W$"  ///
			  )   ///
	refcat(_bs_17 "\textit{Between-Group Variation}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_ctor ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_ctr_2.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
	collabel(none) ///
	coeflabel(_bs_17 "Mean-2SD"  ///
			  _bs_7 "Mean"  ///
			  _bs_22 "Mean+2SD"  ///
			  )   ///
    refcat(_bs_17 "Between-Group Variation", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append

* ------------------------------------------------------------------------------
*#Genetic
local keepVars  _bs_18  _bs_8  _bs_23    

* Table (tex)
esttab  TXX_FHG_M5_ctor       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_ctr_2.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	coeflabel(_bs_18 "\hspace{2.5cm} \$\overline{W}-2SD_W$"  ///
			  _bs_8 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_23 "\hspace{2.5cm} \$\overline{W}+2SD_W$"  ///
			  )   ///
	refcat(_bs_18 "\textit{Genetic Causation}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_ctor ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_ctr_2.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
	collabel(none) ///
	coeflabel(_bs_18 "Mean-2SD"  ///
			  _bs_8 "Mean"  ///
			  _bs_23 "Mean+2SD"  ///
			  )   ///
    refcat(_bs_18 "Genetic Attribution", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append

* ------------------------------------------------------------------------------
*#Environmental
local keepVars  _bs_19  _bs_9  _bs_24    

* Table (tex)
esttab  TXX_FHG_M5_ctor       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_ctr_2.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
    stat(N, label("Observations") fmt(%10.0fc)) ///
	coeflabel(_bs_19 "\hspace{2.5cm} \$\overline{W}-2SD_W$"  ///
			  _bs_9 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_24 "\hspace{2.5cm} \$\overline{W}+2SD_W$"  ///
			  )   ///
	refcat(_bs_19 "\textit{Environmental Causation}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_ctor ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_ctr_2.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
    stat(N, label("Observations") fmt(%10.0fc)) ///
	collabel(none) ///
	coeflabel(_bs_19 "Mean-2SD"  ///
			  _bs_9 "Mean"  ///
			  _bs_24 "Mean+2SD"  ///
			  )   ///
    refcat(_bs_19 "Environmental Attribution", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append
	
* ------------------------------------------------------------------------------
/*
*#Total
local keepVars  _bs_20  _bs_10  _bs_25    

* Table (tex)
esttab  TXX_FHG_M5_ctor       ///
    using "$path_Tables\table_FHG_SEM_M5_ctr_2.tex", ///
    cells("b(pattern(1)fmt(%10.3fc)star) ci_bc[ll](pattern(1) fmt(%10.3fc))  ci_bc[ul](pattern(1) fmt(%10.3fc))") ///	
    stat(N, label("Observations") fmt(%10.0fc)) ///
	coeflabel(_bs_20 "\hspace{2.5cm} \$\overline{W}-2SD_W$"  ///
			  _bs_10 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_25 "\hspace{2.5cm} \$\overline{W}+2SD_W$"  ///
			  )   ///
	refcat(_bs_20 "\textit{Total}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  
 
* Table (rtf)
esttab TXX_FHG_M5_ctor ///
    using "$path_Tables\table_FHG_SEM_M5_ctr_2.rtf", ///
    cells("b(pattern(1)fmt(%10.3fc)star) ci_bc[ll](pattern(1) fmt(%10.3fc))  ci_bc[ul](pattern(1) fmt(%10.3fc))") ///    
    stat(N, label("Observations") fmt(%10.0fc)) ///
	collabel(none) ///
	coeflabel(_bs_20 "Mean-2SD"  ///
			  _bs_10 "Mean"  ///
			  _bs_25 "Mean+2SD"  ///
			  )   ///
    refcat(_bs_20 "Total Indirect Effects", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append 

* ------------------------------------------------------------------------------
* Figure
local GRAPH TXX_FHG_M5_ctor
coefplot (`GRAPH',  label("Mean-2SD")  ///
			keep(_bs_16 _bs_17 _bs_18 _bs_19 _bs_20)  ///
			lc(navy) mc(navy) ci(ci_bc) ciopt(recast(rcap) lc(navy)))  ///
		 (`GRAPH',  label("Mean")  ///
			keep(_bs_6 _bs_7 _bs_8 _bs_9 _bs_10)  ///
			rename(_bs_6=_bs_16 _bs_7=_bs_17 _bs_8=_bs_18 _bs_9=_bs_19 _bs_10=_bs_20)  ///
			ms(D) lc(cranberry) ci(ci_bc) mc(cranberry) ciopt(recast(rcap) lc(cranberry)))  ///
		 (`GRAPH',  label("Mean+2SD")  ///
			keep(_bs_21 _bs_22 _bs_23 _bs_24 _bs_25)  ///
			rename(_bs_21=_bs_16 _bs_22=_bs_17 _bs_23=_bs_18 _bs_24=_bs_19 _bs_25=_bs_20)  ///
			ms(T) lc(black) mc(black) ci(ci_bc) ciopt(recast(rcap) lc(black)))  ///
		 , name(SEM_FHG_coef_ctr_2, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 ytitle("Indirect Effects", size(medlarge)) ///
		 title("Full Humane Genetics Curriculum", size(med))  ///
		 legend(position(6) row(1) region(lcolor(black)))  ///
		 coeflabel(_bs_16 = "Within-Group Variation"  ///
				   _bs_17 = "Between-Group Variation"   ///
				   _bs_18 = "Genetic Attribution"  ///
				   _bs_19 = "Environmental Attribution"  ///
				   _bs_20 = "Total Indirect Effects", angle(35))   

	graph export "$path_Figures\figure_coefplot_FHG_SEM_ctr_2.png", replace
* ------------------------------------------------------------------------------
*/

* ------------------------------------------------------------------------------
* Figure
local GRAPH TXX_FHG_M5_ctor
coefplot (`GRAPH',  label("Mean-2SD")  ///
			keep(_bs_16 _bs_17 _bs_18 _bs_19)  ///
			lc(navy) mc(navy) ci(ci_bc) ciopt(recast(rcap) lc(navy)))  ///
		 (`GRAPH',  label("Mean")  ///
			keep(_bs_6 _bs_7 _bs_8 _bs_9)  ///
			rename(_bs_6=_bs_16 _bs_7=_bs_17 _bs_8=_bs_18 _bs_9=_bs_19)  ///
			ms(D) lc(cranberry) ci(ci_bc) mc(cranberry) ciopt(recast(rcap) lc(cranberry)))  ///
		 (`GRAPH',  label("Mean+2SD")  ///
			keep(_bs_21 _bs_22 _bs_23 _bs_24)  ///
			rename(_bs_21=_bs_16 _bs_22=_bs_17 _bs_23=_bs_18 _bs_24=_bs_19)  ///
			ms(T) lc(black) mc(black) ci(ci_bc) ciopt(recast(rcap) lc(black)))  ///
		 , name(SEM_FHG_coef_ctr_2, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 ytitle("Genetic Essentialism", size(medlarge)) ///
		 title("Full Humane Genetics Curriculum", size(med))  ///
		 legend(position(6) row(1) region(lcolor(black)))  ///
		 coeflabel(_bs_16 = "Within-Group Variation"  ///
				   _bs_17 = "Between-Group Variation"   ///
				   _bs_18 = "Genetic Attribution"  ///
				   _bs_19 = "Environmental Attribution"  ///
				   _bs_20 = "Total Indirect Effects", angle(35))   

	graph export "$path_Draft_Figures\figure_coefplot_FHG_SEM_ctr_2.png", replace
* ------------------------------------------------------------------------------


* ------------------------------------------------------------------------------
*##-------------------- Genetics Knowledge (genetics_pm) --------------------##*
* ------------------------------------------------------------------------------
*Model 5: A&B path
*drop  MOD_TRT  MOD_MED
*##-------------------- Genetics Knowledge (genetics_pm) --------------------##*

*Normal theory estimation using the delta method for model .
local MOD genetics_pm  // [CHANGE HERE]

 ** Moderator by iv interaction
  gen MOD_TRT = `MOD'*`TRT'
  local modtrt MOD_TRT
    
***# Full Sample
bootstrap   ///
			r(wv_cielw) r(bv_cielw) r(gc_cielw) r(ec_cielw) r(total_cielw)  ///
			r(wv_ciemn) r(bv_ciemn) r(gc_ciemn) r(ec_ciemn) r(total_ciemn)  ///
			r(wv_ciehi) r(bv_ciehi) r(gc_ciehi) r(ec_ciehi) r(total_ciehi)  ///
			r(wv_cielw_2) r(bv_cielw_2) r(gc_cielw_2) r(ec_cielw_2) r(total_cielw_2)  ///
			r(wv_ciehi_2) r(bv_ciehi_2) r(gc_ciehi_2) r(ec_ciehi_2) r(total_ciehi_2)  ///
			, bca seed(`SEED') reps(`NoR'): bootstrap_SEM_M5_cont `TRT' `MOD' `modtrt'
			
eststo TXX_FHG_M5_gk: estat boot, nor percentile bc bca
* ------------------------------------------------------------------------------
drop MOD_TRT

* ------------------------------------------------------------------------------
* Summarize MODEL 5 results in [TABLES] for GK
* ------------------------------------------------------------------------------
* ------------------------------------------------------------------------------
*                      Moderator: (mean-sd), (mean),(mean+sd)
* ------------------------------------------------------------------------------
*#Within
local keepVars  _bs_1  _bs_6  _bs_11    

* Table (tex)
esttab  TXX_FHG_M5_gk       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gk.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	mgroups("\makecell{Genetics Knowledge}"  ///
			, pattern(1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
	collabel("Indirect Effects" "\makecell{BC 95\$\%$ CI \\ Lower bnd}" "\makecell{BC 95\$\%$ CI \\ Upper bnd}")  ///
	coeflabel(_bs_1 "\hspace{2.5cm} \$\overline{W}-S_W$"  ///
			  _bs_6 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_11 "\hspace{2.5cm} \$\overline{W}+S_W$"  ///
			  )   ///
	refcat(_bs_1 "\textit{Within-Group Variation}", nolabel)  ///
	substitute("\_" "_")  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) replace
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_gk ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gk.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
    mgroups("Genetics Knowledge", pattern(1)) ///  
    collabel("Indirect Effects" "BC 95% CI - Lower" "BC 95% CI - Upper") ///
	coeflabel(_bs_1 "Mean-SD"  ///
			  _bs_6 "Mean"  ///
			  _bs_11 "Mean+SD"  ///
			  )   ///
    refcat(_bs_1 "Within-Group Variation", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    replace

* ------------------------------------------------------------------------------
*#Between
local keepVars  _bs_2  _bs_7  _bs_12    

* Table (tex)
esttab  TXX_FHG_M5_gk       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gk.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	coeflabel(_bs_2 "\hspace{2.5cm} \$\overline{W}-S_W$"  ///
			  _bs_7 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_12 "\hspace{2.5cm} \$\overline{W}+S_W$"  ///
			  )   ///
	refcat(_bs_2 "\textit{Between-Group Variation}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_gk ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gk.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
	collabel(none) ///
	coeflabel(_bs_2 "Mean-SD"  ///
			  _bs_7 "Mean"  ///
			  _bs_12 "Mean+SD"  ///
			  )   ///
    refcat(_bs_2 "Between-Group Variation", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append

* ------------------------------------------------------------------------------
*#Genetic
local keepVars  _bs_3  _bs_8  _bs_13    

* Table (tex)
esttab  TXX_FHG_M5_gk       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gk.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	coeflabel(_bs_3 "\hspace{2.5cm} \$\overline{W}-S_W$"  ///
			  _bs_8 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_13 "\hspace{2.5cm} \$\overline{W}+S_W$"  ///
			  )   ///
	refcat(_bs_3 "\textit{Genetic Causation}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_gk ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gk.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
	collabel(none) ///
	coeflabel(_bs_3 "Mean-SD"  ///
			  _bs_8 "Mean"  ///
			  _bs_13 "Mean+SD"  ///
			  )   ///
    refcat(_bs_3 "Genetic Attribution", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append

* ------------------------------------------------------------------------------
*#Environmental
local keepVars  _bs_4  _bs_9  _bs_14    

* Table (tex)
esttab  TXX_FHG_M5_gk       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gk.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
    stat(N, label("Observations") fmt(%10.0fc)) ///
	coeflabel(_bs_4 "\hspace{2.5cm} \$\overline{W}-S_W$"  ///
			  _bs_9 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_14 "\hspace{2.5cm} \$\overline{W}+S_W$"  ///
			  )   ///
	refcat(_bs_4 "\textit{Environmental Causation}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_gk ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gk.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
    stat(N, label("Observations") fmt(%10.0fc)) ///
	collabel(none) ///
	coeflabel(_bs_4 "Mean-SD"  ///
			  _bs_9 "Mean"  ///
			  _bs_14 "Mean+SD"  ///
			  )   ///
    refcat(_bs_4 "Environmental Attribution", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append

* ------------------------------------------------------------------------------
/*
*#Total
local keepVars  _bs_5  _bs_10  _bs_15    

* Table (tex)
esttab  TXX_FHG_M5_gk       ///
    using "$path_Tables\table_FHG_SEM_M5_gk.tex", ///
    cells("b(pattern(1)fmt(%10.3fc)star) ci_bc[ll](pattern(1) fmt(%10.3fc))  ci_bc[ul](pattern(1) fmt(%10.3fc))") ///	
    stat(N, label("Observations") fmt(%10.0fc)) ///
	coeflabel(_bs_5 "\hspace{2.5cm} \$\overline{W}-S_W$"  ///
			  _bs_10 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_15 "\hspace{2.5cm} \$\overline{W}+S_W$"  ///
			  )   ///
	refcat(_bs_5 "\textit{Total}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  
 
* Table (rtf)
esttab TXX_FHG_M5_gk ///
    using "$path_Tables\table_FHG_SEM_M5_gk.rtf", ///
    cells("b(pattern(1)fmt(%10.3fc)star) ci_bc[ll](pattern(1) fmt(%10.3fc))  ci_bc[ul](pattern(1) fmt(%10.3fc))") ///    
    stat(N, label("Observations") fmt(%10.0fc)) ///
	collabel(none) ///
	coeflabel(_bs_5 "Mean-SD"  ///
			  _bs_10 "Mean"  ///
			  _bs_15 "Mean+SD"  ///
			  )   ///
    refcat(_bs_5 "Total Indirect Effects", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append 

* ------------------------------------------------------------------------------
* Figure
local GRAPH TXX_FHG_M5_gk
coefplot (`GRAPH',  label("Mean-SD")  ///
			keep(_bs_1 _bs_2 _bs_3 _bs_4 _bs_5)  ///
			lc(navy) mc(navy) ci(ci_bc) ciopt(recast(rcap) lc(navy)))  ///
		 (`GRAPH',  label("Mean")  ///
			keep(_bs_6 _bs_7 _bs_8 _bs_9 _bs_10)  ///
			rename(_bs_6=_bs_1 _bs_7=_bs_2 _bs_8=_bs_3 _bs_9=_bs_4 _bs_10=_bs_5)  ///
			ms(D) lc(cranberry) ci(ci_bc) mc(cranberry) ciopt(recast(rcap) lc(cranberry)))  ///
		 (`GRAPH',  label("Mean+SD")  ///
			keep(_bs_11 _bs_12 _bs_13 _bs_14 _bs_15)  ///
			rename(_bs_11=_bs_1 _bs_12=_bs_2 _bs_13=_bs_3 _bs_14=_bs_4 _bs_15=_bs_5)  ///
			ms(T) lc(black) mc(black) ci(ci_bc) ciopt(recast(rcap) lc(black)))  ///
		 , name(SEM_FHG_coef_gk, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 ytitle("Indirect Effects", size(medlarge)) ///
		 title("Full Humane Genetics Curriculum", size(med))  ///
		 legend(position(6) row(1) region(lcolor(black)))  ///
		 coeflabel(_bs_1 = "Within-Group Variation"  ///
				   _bs_2 = "Between-Group Variation"   ///
				   _bs_3 = "Genetic Attribution"  ///
				   _bs_4 = "Environmental Attribution"  ///
				   _bs_5 = "Total Indirect Effects", angle(35))   

	graph export "$path_Figures\figure_coefplot_FHG_SEM_gk.png", replace
* ------------------------------------------------------------------------------
*/

* ------------------------------------------------------------------------------
* Figure
local GRAPH TXX_FHG_M5_gk
coefplot (`GRAPH',  label("Mean-SD")  ///
			keep(_bs_1 _bs_2 _bs_3 _bs_4)  ///
			lc(navy) mc(navy) ci(ci_bc) ciopt(recast(rcap) lc(navy)))  ///
		 (`GRAPH',  label("Mean")  ///
			keep(_bs_6 _bs_7 _bs_8 _bs_9)  ///
			rename(_bs_6=_bs_1 _bs_7=_bs_2 _bs_8=_bs_3 _bs_9=_bs_4)  ///
			ms(D) lc(cranberry) ci(ci_bc) mc(cranberry) ciopt(recast(rcap) lc(cranberry)))  ///
		 (`GRAPH',  label("Mean+SD")  ///
			keep(_bs_11 _bs_12 _bs_13 _bs_14)  ///
			rename(_bs_11=_bs_1 _bs_12=_bs_2 _bs_13=_bs_3 _bs_14=_bs_4)  ///
			ms(T) lc(black) mc(black) ci(ci_bc) ciopt(recast(rcap) lc(black)))  ///
		 , name(SEM_FHG_coef_gk, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 ytitle("Genetic Essentialism", size(medlarge)) ///
		 title("Full Humane Genetics Curriculum", size(med))  ///
		 legend(position(6) row(1) region(lcolor(black)))  ///
		 coeflabel(_bs_1 = "Within-Group Variation"  ///
				   _bs_2 = "Between-Group Variation"   ///
				   _bs_3 = "Genetic Attribution"  ///
				   _bs_4 = "Environmental Attribution"  ///
				   , angle(35)  ///
				   )   

	graph export "$path_Draft_Figures\figure_coefplot_FHG_SEM_gk.png", replace
* ------------------------------------------------------------------------------
* Figure to combine
local GRAPH TXX_FHG_M5_gk
coefplot (`GRAPH',  label("Mean-SD")  ///
			keep(_bs_1 _bs_2 _bs_3 _bs_4)  ///
			lc(navy) mc(navy) ci(ci_bc) ciopt(recast(rcap) lc(navy)) msize(vsmall))  ///
		 (`GRAPH',  label("Mean")  ///
			keep(_bs_6 _bs_7 _bs_8 _bs_9)  ///
			rename(_bs_6=_bs_1 _bs_7=_bs_2 _bs_8=_bs_3 _bs_9=_bs_4)  ///
			ms(D) lc(cranberry) ci(ci_bc) mc(cranberry) ciopt(recast(rcap) lc(cranberry)) msize(vsmall))  ///
		 (`GRAPH',  label("Mean+SD")  ///
			keep(_bs_11 _bs_12 _bs_13 _bs_14)  ///
			rename(_bs_11=_bs_1 _bs_12=_bs_2 _bs_13=_bs_3 _bs_14=_bs_4)  ///
			ms(T) lc(black) mc(black) ci(ci_bc) ciopt(recast(rcap) lc(black)) msize(vsmall))  ///
		 , name(SEM_FHG_coef_gk_c, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 legend(position(6) row(1) region(lcolor(black)) size(vsmall))  ///
		 title("Genetics Knowledge", size(small)) ///
		 coeflabel(_bs_1 = "Within"  ///
				   _bs_2 = "Between"   ///
				   _bs_3 = "Genes"  ///
				   _bs_4 = "Environment"  ///
				   , angle(35) labsize(vsmall)  ///
				   )     
* ------------------------------------------------------------------------------


* ------------------------------------------------------------------------------
*                      Moderator: (mean-2sd), (mean),(mean+2sd)
* ------------------------------------------------------------------------------
*#Within
local keepVars  _bs_16  _bs_6  _bs_21    

* Table (tex)
esttab  TXX_FHG_M5_gk       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gk_2.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	mgroups("\makecell{Genetics Knowledge}"  ///
			, pattern(1) ///
			prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
	collabel("Indirect Effects" "\makecell{BC 95\$\%$ CI \\ Lower bnd}" "\makecell{BC 95\$\%$ CI \\ Upper bnd}")  ///
	coeflabel(_bs_16 "\hspace{2.5cm} \$\overline{W}-2SD_W$"  ///
			  _bs_6 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_21 "\hspace{2.5cm} \$\overline{W}+2SD_W$"  ///
			  )   ///
	refcat(_bs_16 "\textit{Within-Group Variation}", nolabel)  ///
	substitute("\_" "_")  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) replace
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_gk ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gk_2.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
    mgroups("Genetics Knowledge", pattern(1)) ///  
    collabel("Indirect Effects" "BC 95% CI - Lower" "BC 95% CI - Upper") ///
	coeflabel(_bs_16 "Mean-2SD"  ///
			  _bs_6 "Mean"  ///
			  _bs_21 "Mean+2SD"  ///
			  )   ///
    refcat(_bs_16 "Within-Group Variation", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    replace

* ------------------------------------------------------------------------------
*#Between
local keepVars  _bs_17  _bs_7  _bs_22    

* Table (tex)
esttab  TXX_FHG_M5_gk       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gk_2.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	coeflabel(_bs_17 "\hspace{2.5cm} \$\overline{W}-2SD_W$"  ///
			  _bs_7 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_22 "\hspace{2.5cm} \$\overline{W}+2SD_W$"  ///
			  )   ///
	refcat(_bs_17 "\textit{Between-Group Variation}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_gk ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gk_2.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
	collabel(none) ///
	coeflabel(_bs_17 "Mean-2SD"  ///
			  _bs_7 "Mean"  ///
			  _bs_22 "Mean+2SD"  ///
			  )   ///
    refcat(_bs_17 "Between-Group Variation", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append

* ------------------------------------------------------------------------------
*#Genetic
local keepVars  _bs_18  _bs_8  _bs_23    

* Table (tex)
esttab  TXX_FHG_M5_gk       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gk_2.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
	coeflabel(_bs_18 "\hspace{2.5cm} \$\overline{W}-2SD_W$"  ///
			  _bs_8 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_23 "\hspace{2.5cm} \$\overline{W}+2SD_W$"  ///
			  )   ///
	refcat(_bs_18 "\textit{Genetic Causation}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_gk ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gk_2.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
	collabel(none) ///
	coeflabel(_bs_18 "Mean-2SD"  ///
			  _bs_8 "Mean"  ///
			  _bs_23 "Mean+2SD"  ///
			  )   ///
    refcat(_bs_18 "Genetic Attribution", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append

* ------------------------------------------------------------------------------
*#Environmental
local keepVars  _bs_19  _bs_9  _bs_24    

* Table (tex)
esttab  TXX_FHG_M5_gk       ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gk_2.tex", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///	
    stat(N, label("Observations") fmt(%10.0fc)) ///
	coeflabel(_bs_19 "\hspace{2.5cm} \$\overline{W}-2SD_W$"  ///
			  _bs_9 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_24 "\hspace{2.5cm} \$\overline{W}+2SD_W$"  ///
			  )   ///
	refcat(_bs_19 "\textit{Environmental Causation}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum noobs ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_gk ///
    using "$path_Draft_Tables\table_FHG_SEM_M5_gk_2.rtf", ///
    cells("b(pattern(1)fmt(%10.4fc)) ci_bc[ll](pattern(1) fmt(%10.4fc))  ci_bc[ul](pattern(1) fmt(%10.4fc))") ///    
    stat(N, label("Observations") fmt(%10.0fc)) ///
	collabel(none) ///
	coeflabel(_bs_19 "Mean-2SD"  ///
			  _bs_9 "Mean"  ///
			  _bs_24 "Mean+2SD"  ///
			  )   ///
    refcat(_bs_19 "Environmental Attribution", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append

* ------------------------------------------------------------------------------
/*
*#Total
local keepVars  _bs_20  _bs_10  _bs_25    

* Table (tex)
esttab  TXX_FHG_M5_gk       ///
    using "$path_Tables\table_FHG_SEM_M5_gk_2.tex", ///
    cells("b(pattern(1)fmt(%10.3fc)star) ci_bc[ll](pattern(1) fmt(%10.3fc))  ci_bc[ul](pattern(1) fmt(%10.3fc))") ///	
    stat(N, label("Observations") fmt(%10.0fc)) ///
	coeflabel(_bs_20 "\hspace{2.5cm} \$\overline{W}-2SD_W$"  ///
			  _bs_10 "\hspace{2.5cm} \$\overline{W}$"  ///
			  _bs_25 "\hspace{2.5cm} \$\overline{W}+2SD_W$"  ///
			  )   ///
	refcat(_bs_20 "\textit{Total}", nolabel)  ///
	substitute("\_" "_")  ///
	collabels(none)  ///
    order(`keepVars')  ///
    keep(`keepVars')  ///
	label compress fragment noomitted nomtitle nonum ///
	style(tex) nostar nonotes ///
	title(\textbf{}) append
*	rename(_bs_7 _bs_1   _bs_8 _bs_2   _bs_9 _bs_3   _bs_10 _bs_4   _bs_11 _bs_5)  

* Table (rtf)
esttab TXX_FHG_M5_gk ///
    using "$path_Tables\table_FHG_SEM_M5_gk_2.rtf", ///
    cells("b(pattern(1)fmt(%10.3fc)star) ci_bc[ll](pattern(1) fmt(%10.3fc))  ci_bc[ul](pattern(1) fmt(%10.3fc))") ///    
    stat(N, label("Observations") fmt(%10.0fc)) ///
	collabel(none) ///
	coeflabel(_bs_20 "Mean-2SD"  ///
			  _bs_10 "Mean"  ///
			  _bs_25 "Mean+2SD"  ///
			  )   ///
    refcat(_bs_20 "Total Indirect Effects", nolabel)  ///  
    order(`keepVars')  ///
    keep(`keepVars')  ///  
    label compress noomitted nomtitle nonum noobs ///  
    nostar nonotes ///  
    append 
	
* ------------------------------------------------------------------------------
* Figure
local GRAPH TXX_FHG_M5_gk
coefplot (`GRAPH',  label("Mean-2SD")  ///
			keep(_bs_16 _bs_17 _bs_18 _bs_19 _bs_20)  ///
			lc(navy) mc(navy) ci(ci_bc) ciopt(recast(rcap) lc(navy)))  ///
		 (`GRAPH',  label("Mean")  ///
			keep(_bs_6 _bs_7 _bs_8 _bs_9 _bs_10)  ///
			rename(_bs_6=_bs_16 _bs_7=_bs_17 _bs_8=_bs_18 _bs_9=_bs_19 _bs_10=_bs_20)  ///
			ms(D) lc(cranberry) ci(ci_bc) mc(cranberry) ciopt(recast(rcap) lc(cranberry)))  ///
		 (`GRAPH',  label("Mean+2SD")  ///
			keep(_bs_21 _bs_22 _bs_23 _bs_24 _bs_25)  ///
			rename(_bs_21=_bs_16 _bs_22=_bs_17 _bs_23=_bs_18 _bs_24=_bs_19 _bs_25=_bs_20)  ///
			ms(T) lc(black) mc(black) ci(ci_bc) ciopt(recast(rcap) lc(black)))  ///
		 , name(SEM_FHG_coef_gk_2, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 ytitle("Indirect Effects", size(medlarge)) ///
		 title("Full Humane Genetics Curriculum", size(med))  ///
		 legend(position(6) row(1) region(lcolor(black)))  ///
		 coeflabel(_bs_16 = "Within-Group Variation"  ///
				   _bs_17 = "Between-Group Variation"   ///
				   _bs_18 = "Genetic Attribution"  ///
				   _bs_19 = "Environmental Attribution"  ///
				   _bs_20 = "Total Indirect Effects", angle(35))   

	graph export "$path_Figures\figure_coefplot_FHG_SEM_gk_2.png", replace
* ------------------------------------------------------------------------------
*/
	
* ------------------------------------------------------------------------------
* Figure
local GRAPH TXX_FHG_M5_gk
coefplot (`GRAPH',  label("Mean-2SD")  ///
			keep(_bs_16 _bs_17 _bs_18 _bs_19)  ///
			lc(navy) mc(navy) ci(ci_bc) ciopt(recast(rcap) lc(navy)))  ///
		 (`GRAPH',  label("Mean")  ///
			keep(_bs_6 _bs_7 _bs_8 _bs_9)  ///
			rename(_bs_6=_bs_16 _bs_7=_bs_17 _bs_8=_bs_18 _bs_9=_bs_19)  ///
			ms(D) lc(cranberry) ci(ci_bc) mc(cranberry) ciopt(recast(rcap) lc(cranberry)))  ///
		 (`GRAPH',  label("Mean+2SD")  ///
			keep(_bs_21 _bs_22 _bs_23 _bs_24)  ///
			rename(_bs_21=_bs_16 _bs_22=_bs_17 _bs_23=_bs_18 _bs_24=_bs_19)  ///
			ms(T) lc(black) mc(black) ci(ci_bc) ciopt(recast(rcap) lc(black)))  ///
		 , name(SEM_FHG_coef_gk_2, replace)  ///
		 nolabels vertical    ///
		 yline(0, lwidth(normal) lpattern(dash) lcolor(red))  ///
		 ytitle("Genetic Essentialism", size(medlarge)) ///
		 title("Full Humane Genetics Curriculum", size(med))  ///
		 legend(position(6) row(1) region(lcolor(black)))  ///
		 coeflabel(_bs_16 = "Within-Group Variation"  ///
				   _bs_17 = "Between-Group Variation"   ///
				   _bs_18 = "Genetic Attribution"  ///
				   _bs_19 = "Environmental Attribution"  ///
				   , angle(35)  ///
				   )   

	graph export "$path_Draft_Figures\figure_coefplot_FHG_SEM_gk_2.png", replace
* ------------------------------------------------------------------------------


* Combine four graphs.
graph combine SEM_FHG_coef_gd_c  SEM_FHG_coef_rc_c  SEM_FHG_coef_ctr_c  SEM_FHG_coef_gk_c,  ///
	  ycommon rows(2)  ///
	  l1title("Genetic Essentialism")
	
	graph export "$path_Draft_Figures\figure_coefplot_FHG_SEM_allmod.png", replace


