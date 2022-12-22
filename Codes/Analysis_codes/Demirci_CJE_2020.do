*cd "C:\Users\Murat Demirci\Dropbox\OPT -- Labor Market\Results_CJE\Codes"	
cd "C:\Users\chris\OneDrive\Bureau\Author_s_reproduction_package\Data\Analysis_data"

log using Demirci_CJE_2020, replace

clear
use Demirci_CJE_2020.dta  

* The code contains commands that are incompatible with Stata 17 and probably with other versions of Stata. Version 16 is recommended.
* "version 16" syntax allows you to use the features of Stata 16
version 16


*
*** Generating control variables 
	*
	* Field of study dummies 
	tab field_codes,gen(f_)
	
	*
	*calendar year & academic year dummies
	capture drop cyear cy1
	gen cyear=year  
	forvalues y=9/12 {    
	 gen byte cy`y'=0
	 replace cy`y'=1 if `y'==cyear-2000   
	}
	
	*
	* Age-squared to control for potential experience  
	gen age_sqr=age*age

	*
	* Gender
	gen byte female=0
		replace female=1 if sex==2
	gen byte male=0
		replace male=1 if sex==1

	*
	* Race/ethnicity ( Non-hispanic whites, Non-hispanic blacks, Non-hispanic asians, Hispanics, Non-hispanic others)
	gen byte white=0
	 replace white=1 if racesing==1 & hispan==0
	gen byte black=0
	 replace black=1 if racesing==2 & hispan==0
	gen byte asian=0
	 replace asian=1 if racesing==4 & hispan==0
	gen byte hisp=0
	 replace hisp=1 if hispan==1
	gen byte other=0
	 replace other=1 if (racesing==3 | racesing==5) & hispan==0	
  
	*
	* For clustering for each level
	gen field_by_year=0
	 replace field_by_year=field_codes*10000+year
   
	*
	* Citizenship
	gen byte ntv=0
		replace ntv=1 if citizen==0 | citizen==1 
 
  
*** TABLE 1: Summary statistics for recent graduates
***
***  
   gen byte subgroup=0
	replace subgroup=1 if eligible==1 & level==2 & age<=24 & school!=2 & ntv==1		// STEM, bachelor's
	replace subgroup=2 if eligible==0 & level==2 & age<=24 & school!=2 & ntv==1		// Non-STEM, bachelor's

	replace subgroup=3 if eligible==1 & level==3 & age<=28 & school!=2 & ntv==1		// STEM, master's
	replace subgroup=4 if eligible==0 & level==3 & age<=28 & school!=2 & ntv==1		// Non-STEM, master's

	replace subgroup=5 if eligible==1 & level==4 & age<=31 & school!=2 & ntv==1		// STEM, doctorates
	replace subgroup=6 if eligible==0 & level==4 & age<=31 & school!=2 & ntv==1		// Non-STEM, doctorates
  
  gen all=1
  gen ryrwage_wagesample=.
   replace ryrwage_wagesample=ryrwage if wage_sample==1
  table subgroup, c(N all) 
  table subgroup [pw=perwt], c(mean female mean age)
  table subgroup [pw=perwt], c(mean white mean asian mean black mean hisp)
  table subgroup [pw=perwt], c(mean employed mean fyft mean ryrwage_wagesample)


*** TABLE 2: The percentage of internatioanl students 
***
***    
 label define field_agr 2102 "Computer Sciences"
 label define field_agr 2408 "Electrical Engr.", add
 label define field_agr 2499 "Other Engr.", add
 label define field_agr 3700 "Mathematics", add
 label define field_agr 3600 "Biology", add
 label define field_agr 5000 "Physical Sciences", add
 label define field_agr 5599 "Social Sciences", add
 label define field_agr 6299 "Business", add
 label define field_agr 5200 "Psychology", add 
 label define field_agr 5499 "Education", add 
 label define field_agr 6199 "Medical Sciences", add 
 label define field_agr 9999 "Other", add 
 
 label values field_agr field_agr
 
 preserve 
 collapse (mean) treat2 classsize_2 treat3 classsize_3 treat4 classsize_4 field_agr, by(level year field_codes)
 collapse (sum) treat2 classsize_2 treat3 classsize_3 treat4 classsize_4 , by(level year field_agr)
 forvalues l=2/4 {
  gen ratioFB`l'=treat`l'/classsize_`l'
 }
 
 forvalues l=2/4 {
  table field_agr year if (level==`l'),c(mean ratioFB`l')  
 } 
 restore

 
*** TABLE 3: The effect of international students on Native-Born Recent Graduates at the Master's Level 
***
***
 replace ryrwage=ln(ryrwage)

estimates clear
quietly {
 
 local sample="24y"

 * Definition of samples
 capture drop ms_sample
 gen byte ms_sample=0
	replace ms_sample=1 if age<=28 & level==3 & school!=2
	
*
* Full results	
 forvalues l=3/3 {
	if `l'==3 local level="ms"

	global instrument instextall`l'
	global explanatory cy10-cy12 female white-hisp age age_sqr

	* employment
	foreach vay of varlist employed fyft py { 		 
	 areg `vay' treat`l'_ratio $explanatory [pw=perwt] if `level'_sample==1 & ntv==1, absorb(field_codes) vce(cluster field_by_year)
	 estimates store ols_`vay'_lev`l'

	 ivregress 2sls `vay' f_1-f_45 $explanatory (treat`l'_ratio=$instrument) [pw=perwt] if `level'_sample==1 & ntv==1, vce(cluster field_by_year)
	 estat firststage
	 estimates store iv_`vay'_lev`l'
	}
	

	* annual earnings, conditional on working
	foreach vay of varlist ryrwage {
	 areg `vay' treat`l'_ratio $explanatory [pw=perwt] if `level'_sample==1 & wage_sample==1 & ntv==1, absorb(field_codes) vce(cluster field_by_year)
	 estimates store ols_`vay'_lev`l'

	 ivregress 2sls `vay' f_1-f_45 $explanatory (treat`l'_ratio=$instrument)  [pw=perwt]  if `level'_sample==1 &  wage_sample==1  & ntv==1, vce(cluster field_by_year)
	 estimates store iv_`vay'_lev`l'	 
	}

	* earnings for FYFT, conditional on FTFY working
	foreach vay of varlist ryrwage {
	 areg `vay' treat`l'_ratio $explanatory [pw=perwt] if `level'_sample==1 & wage_sample==1 & ntv==1 & fyft==1, absorb(field_codes) vce(cluster field_by_year)
	 estimates store ols_fyft`vay'_lev`l'

	 ivregress 2sls `vay' f_1-f_45 $explanatory (treat`l'_ratio=$instrument) [pw=perwt]  if `level'_sample==1 & wage_sample==1  & ntv==1 & fyft==1, vce(cluster field_by_year)
	 estimates store iv_fyft`vay'_lev`l'
	}

}

*
* Writing Out
	ssc install estout, replace
	estout * using "results_table3.xls", keep(treat*_ratio) cells(b(fmt(4) star) se(par fmt(4)) t(par fmt(4)) p(par fmt(4))) starlevels(* 0.10 ** 0.05 *** 0.01)  stats(r2 N) replace

}



*** TABLE 4: The effect of international students on Native-Born Experienced Graduates at the Master's Level
***
***
estimates clear
quietly {
 local sample="24y"

forvalues l=3/3 {
 if `l'==3 local level="ms"

 global instrument instextall`l'
 global explanatory cy10-cy12 female white-hisp age age_sqr  

 forvalues a=1/3 {
  if `a'==1 local low=30
  if `a'==1 local high=39
  if `a'==2 local low=40
  if `a'==2 local high=49
  if `a'==3 local low=50
  if `a'==3 local high=59

 *
 * Redefining-sample of interest
 capture drop ms_sample 
 gen byte ms_sample=0
	replace ms_sample=1 if (age>=`low' & age<=`high') & level==3 & school!=2 
*
 foreach vay of varlist employed fyft py {
	ivregress 2sls `vay' f_1-f_45 $explanatory (treat`l'_ratio=$instrument) [pw=perwt] if `level'_sample==1 & ntv>0, vce(cluster field_by_year)
	estimates store s`low'`high'_`vay'_lev`l'
 }
 foreach vay of varlist ryrwage   {
	ivregress 2sls `vay' f_1-f_45  $explanatory (treat`l'_ratio=$instrument)  [pw=perwt]  if `level'_sample==1 & wage_sample==1  & ntv>0, vce(cluster field_by_year)
	estimates store s`low'`high'_`vay'_lev`l'
 }
 foreach vay of varlist ryrwage  {
	ivregress 2sls `vay' f_1-f_45  $explanatory (treat`l'_ratio=$instrument)  [pw=perwt]  if `level'_sample==1 & wage_sample==1  & ntv>0 & fyft==1, vce(cluster field_by_year)
	estimates store s`low'`high'_fyft`vay'_lev`l'
 }
 }
 *
 * printing out
 ssc install estout, replace
 estout * using "results_table4.xls", keep(treat3_ratio) cells(b(fmt(4) star) se(par fmt(4)) t(par fmt(4)) p(par fmt(4))) starlevels(* 0.10 ** 0.05 *** 0.01)  stats(r2 N) replace


}
}



*** TABLE 5: Robustness to the inclusion of measures of labor demand conditions
***
***
*
* State-Year fixed effects  
  gen state_by_year=0
	replace state_by_year=state*10000+year
  tab state_by_year,gen(StYr_)
*
* State-STEM fixed effects
 gen byte STEM_fields=0
	replace STEM_fields=1 if (field_codes==2102 | (field_codes>=2401 & field_codes<=2599) | (field_codes>=3600 & field_codes<=3700) | (field_codes>=5000 & field_codes<=5098))
 gen nonSTEM_fields=(STEM_fields==0)
 forvalues i=1/56 {
  gen byte s`i'=0
	replace s`i'=1 if migplac1==`i'
 }
 forvalues i=1/56 {
  gen s`i'_STEM=s`i'*STEM_fields
  gen s`i'_nonSTEM=s`i'*nonSTEM_fields 
 }
 
set matsize 1000
estimates clear
quietly {

forvalues l=3/3 {
 if `l'==3 local level="ms"
 
forvalues a=0/3 {
  if `a'==0 local low=18
  if `a'==0 local high=28
  if `a'==1 local low=30
  if `a'==1 local high=39
  if `a'==2 local low=40
  if `a'==2 local high=49
  if `a'==3 local low=50
  if `a'==3 local high=59

 *
 * Redefining-sample of interest
 capture drop ms_sample 
 gen byte ms_sample=0
	replace ms_sample=1 if (age>=`low' & age<=`high') & level==3 & school!=2  

 global instrument instextall`l'
 global explanatory cy10-cy12 female white-hisp age age_sqr

*
* adding age- and field-specific GDP measure & state*time & state-STEM fixed effects
 foreach vay of varlist employed fyft py {
	ivregress 2sls `vay' f_1-f_45 gdp_resTrend_`low'`high' StYr_2-StYr_204 s*_STEM  s*_nonSTEM $explanatory (treat`l'_ratio=$instrument) [pw=perwt] if `level'_sample==1 & year>=2009  & ntv==1, vce(cluster field_by_year)
	estimates store iv_`vay'_`a'
 }
 foreach vay of varlist ryrwage   {
	ivregress 2sls `vay' f_1-f_45 gdp_resTrend_`low'`high' StYr_2-StYr_204 s*_STEM s*_nonSTEM $explanatory (treat`l'_ratio=$instrument)  [pw=perwt]  if `level'_sample==1 & year>=2009 & wage_sample==1  & ntv==1, vce(cluster field_by_year)
	estimates store iv_`vay'_`a'
 } 
 foreach vay of varlist ryrwage   {
	ivregress 2sls `vay' f_1-f_45 gdp_resTrend_`low'`high' StYr_2-StYr_204 s*_STEM s*_nonSTEM $explanatory (treat`l'_ratio=$instrument)  [pw=perwt]  if `level'_sample==1 & year>=2009 & wage_sample==1  & ntv==1 & fyft==1, vce(cluster field_by_year)
	estimates store iv_fyft`vay'_`a'
 } 
 }
 
 *
 * PRINTING OUT
 ssc install estout, replace
 estout * using "results_table5.xls", keep(treat3_ratio) cells(b(fmt(4) star) se(par fmt(4)) t(par fmt(4)) p(par fmt(4))) starlevels(* 0.10 ** 0.05 *** 0.01)  stats(r2 N) replace

}
}


*** TABLE 6: Labor market performance of immigrants in ACS
***
***
 gen arvage=0
	replace arvage=yrimmig-birthyr if citizen==3 
 gen tmpst=0
	replace tmpst=1 if citizen==3 & arvage>=18 & arvage<=22   // non-citizens who entered the US at an age between 18 and 22
 gen tmpadult=0
	replace tmpadult=1 if citizen==3 & arvage>=18   // non-citizens who entered the US at an age above 18
	
 gen STEMocc=0
	replace STEMocc=1 if (occ1990>=43 & occ1990<=59) | (occ1990>=64 & occ1990<=68) | (occ1990>=69 & occ1990<=106) | (occ1990>=203 & occ1990<=235)
 gen ITocc=0
	replace ITocc=1 if (occ1990>=64 & occ1990<=68) | occ1990==229	

estimates clear
quietly {

 capture drop ms_sample
 gen byte ms_sample=0
	replace ms_sample=1 if age<=28 & level==3 & school!=2
 
 forvalues l=3/3 {
	if `l'==3 local level="ms"

	global explanatory cy9-cy11 female white-hisp age age_sqr

	foreach vay in ryrwage  {	
	foreach var in "tmpst" "tmpadult" { 	 
	 reg `vay' `var' $explanatory f_1-f_45 [pw=perwt] if wage_sample==1 & `level'_sample==1 & year>=2009 & (`var'==1 | ntv==1),vce(cluster field_by_year)
	 estimates store `vay'_`var'
	}
	}

	foreach vay in STEMocc ITocc {	
	foreach var in "tmpst" "tmpadult" { 	 
	 reg `vay' `var' $explanatory f_1-f_45 [pw=perwt] if `level'_sample==1 & year>=2009 & (`var'==1 | ntv==1),vce(cluster field_by_year)
	 estimates store `vay'_`var'
	}
	}
	
 }	
 *
 * Writing Out
	ssc install estout, replace
	estout * using "results_table6.xls", keep(tmpst tmpadult) cells(b(fmt(4) star) se(par fmt(4)) t(par fmt(4)) p(par fmt(4))) starlevels(* 0.10 ** 0.05 *** 0.01)  stats(r2 N) replace
} 


log close
	
		
******* FIGURES		

 
* FIGURE 1: Trends in Degrees Conferred to International Students, by field and level
clear
use Demirci_CJE_2020_figure1.dta  

quietly {
 foreach var1 in "ba"   {
 foreach var3 in "STEM" {

 twoway (connected `var1'_tmp_`var3' year, lpattern(solid) msymbol(circle) lcolor(black) mcolor(black) yaxis(1)) || /* 
	*/ (connected perc_`var1'_`var3' year, lpattern(shortdash) msymbol(plus) lcolor(black) mcolor(black) yaxis(2)) /* 
	*/  ,graphregion(color(white) fcolor(white)) xlabel(1977(5)2012) /*
  */  title("Bachelor's STEM", size(msmall)) ylabel(,nogrid) xtitle("Year") ytitle("Number of Students (in 1,000)",axis(1)) ytitle("Ratio",axis(2)) /* 
   */ legend (order(1 "Population"  2 "Share of All Class")) 
   graph export figure1_`var1'_`var3'.png, replace 
 }
 }

 foreach var1 in "ba"   {
 foreach var3 in "nonSTEM" {

 twoway (connected `var1'_tmp_`var3' year, lpattern(solid) msymbol(circle) lcolor(black) mcolor(black) yaxis(1)) || /* 
	*/ (connected perc_`var1'_`var3' year, lpattern(shortdash) msymbol(plus) lcolor(black) mcolor(black) yaxis(2)) /* 
	*/  ,graphregion(color(white) fcolor(white)) xlabel(1977(5)2012) /*
  */  title("Bachelor's Non-STEM", size(msmall)) ylabel(,nogrid) xtitle("Year") ytitle("Number of Students (in 1,000)",axis(1)) ytitle("Ratio",axis(2)) /* 
   */ legend (order(1 "Population"  2 "Share of All Class")) 
 graph export figure1_`var1'_`var3'.png, replace 
 }
 }

 foreach var1 in "ma"   {
 foreach var3 in "STEM" {

 twoway (connected `var1'_tmp_`var3' year, lpattern(solid) msymbol(circle) lcolor(black) mcolor(black) yaxis(1)) || /* 
	*/ (connected perc_`var1'_`var3' year, lpattern(shortdash) msymbol(plus) lcolor(black) mcolor(black) yaxis(2)) /* 
	*/  ,graphregion(color(white) fcolor(white)) xlabel(1977(5)2012) /*
  */  title("Master's STEM", size(msmall)) ylabel(,nogrid) xtitle("Year") ytitle("Number of Students (in 1,000)",axis(1)) ytitle("Ratio",axis(2)) /* 
   */ legend (order(1 "Population"  2 "Share of All Class")) 
 graph export figure1_`var1'_`var3'.png, replace 
 }
 }

 foreach var1 in "ma"   {
 foreach var3 in "nonSTEM" {

 twoway (connected `var1'_tmp_`var3' year, lpattern(solid) msymbol(circle) lcolor(black) mcolor(black) yaxis(1)) || /* 
	*/ (connected perc_`var1'_`var3' year, lpattern(shortdash) msymbol(plus) lcolor(black) mcolor(black) yaxis(2)) /* 
	*/  ,graphregion(color(white) fcolor(white)) xlabel(1977(5)2012) /*
  */  title("Master's Non-STEM", size(msmall)) ylabel(,nogrid) xtitle("Year") ytitle("Number of Students (in 1,000)",axis(1)) ytitle("Ratio",axis(2)) /* 
   */ legend (order(1 "Population"  2 "Share of All Class")) 
 graph export figure1_`var1'_`var3'.png, replace 
 }
 }

 foreach var1 in "phd"   {
 foreach var3 in "STEM" {

 twoway (connected `var1'_tmp_`var3' year, lpattern(solid) msymbol(circle) lcolor(black) mcolor(black) yaxis(1)) || /* 
	*/ (connected perc_`var1'_`var3' year, lpattern(shortdash) msymbol(plus) lcolor(black) mcolor(black) yaxis(2)) /* 
	*/  ,graphregion(color(white) fcolor(white)) xlabel(1977(5)2012) /*
  */  title("Doctorate's STEM", size(msmall)) ylabel(,nogrid) xtitle("Year") ytitle("Number of Students (in 1,000)",axis(1)) ytitle("Ratio",axis(2)) /* 
   */ legend (order(1 "Population"  2 "Share of All Class")) 
 graph export figure1_`var1'_`var3'.png, replace 
 }
 }

 foreach var1 in "phd"   {
 foreach var3 in "nonSTEM" {

 twoway (connected `var1'_tmp_`var3' year, lpattern(solid) msymbol(circle) lcolor(black) mcolor(black) yaxis(1)) || /* 
	*/ (connected perc_`var1'_`var3' year, lpattern(shortdash) msymbol(plus) lcolor(black) mcolor(black) yaxis(2)) /* 
	*/  ,graphregion(color(white) fcolor(white)) xlabel(1977(5)2012) /*
  */  title("Doctorate's Non-STEM", size(msmall)) ylabel(,nogrid) xtitle("Year") ytitle("Number of Students (in 1,000)",axis(1)) ytitle("Ratio",axis(2)) /* 
   */ legend (order(1 "Population"  2 "Share of All Class")) 
 graph export figure1_`var1'_`var3'.png, replace 
 }
 }
}


* FIGURE 2: The Labor Supply of International Students on F-visas
clear
use Demirci_CJE_2020_figure2.dta  

* Left Panels
forvalues l=2/4 {
 
 if `l'==2 local level="Bachelor's STEM"
 if `l'==3 local level="Master's STEM"
 if `l'==4 local level="Doctorates STEM"

sort level STEM year
twoway (connected regular year if level==`l' & STEM==1 & year>=2004, lpattern(longdash) msymbol(triangle) mcolor(black) lcolor(black) yaxis(1)) ||  /*	
	*/ (connected ext year if level==`l' & STEM==1 & year>=2004, lpattern(longdash) msymbol(square) mcolor(black) lcolor(black) yaxis(1))   /*
	*/ , graphregion(fcolor(white))  ylabel(,nogrid) xlabel(2004(1)2012) xline(2008,lcolor(black) lwidth(0.5)) title(`level') xtitle("Year") ytitle("Number of Workers",axis(1)) /* 
  */ 	legend (order(1 "Potential on Regular OPT" 2 "Potential on Extended OPT")) 
graph export "figure2_left_lvl`l'.png", replace  
}

* Right Panels
forvalues l=2/4 {
 
 if `l'==2 local level="Bachelor's"
 if `l'==3 local level="Master's"
 if `l'==4 local level="Doctorates"

 if `l'==2 local incr=5000
 if `l'==3 local incr=10000
 if `l'==4 local incr=5000
 
 if `l'==2 local ceil=15000
 if `l'==3 local ceil=30000
 if `l'==4 local ceil=10000

sort level STEM year
twoway (connected actual year if level==`l' & STEM==0 & year<=2012,msymbol(triangle) mcolor(black) lcolor(black) yaxis(1)) ||  /*
 */ (connected actual year if level==`l' & STEM==1 & year<=2012,msymbol(circle) mcolor(black) lcolor(black) yaxis(1)) ||  /*
  */ , graphregion(fcolor(white)) title(`level') ylabel(,nogrid) xlabel(2004(1)2012) ylabel(0(`incr')`ceil') xline(2008,lcolor(black) lwidth(0.5)) xtitle("Year") ytitle("Number of Workers",axis(1)) /* 
   */ legend (order(1 "Actual Supply in Non-STEM" 2 "Actual Supply in STEM" )) 
graph export "figure2_right_lvl`l'.png", replace 

}
