*
* STEP 1:  Preparing the data for Figure 2
*

clear
use "C:\Users\Murat Demirci\Dropbox\OPT -- Labor Market\Data\2004-2013SEVIS.dta"			// This is the student-level data obtained with FOIA request. I am not allowed to share it. 
 
quietly {

*
* Sample Restrictions
drop if level==1
drop if cis2==60 | cis2==28 | (cis2>=32 & cis2<=37) | cis2==53 | cis2==2 | cis2==8 | cis2==20 | cis2==95 | cis2==21 | cis2==29
drop if country=="SAMOA"
drop if cis6_blncd==.
drop if elig==2
drop if status_update<sch_enddate

capture drop STEM
gen byte STEM=0
replace STEM=1 if elig>=1


*
* 1) The ACTUAL stock of FB in each year, weighted by the number of days worked in each calendar year 
*
quietly {
forvalues i=2004/2012 {
 gen wg=0
	replace wg=(status_update-td(1,1,`i'))/365 if sch_enddate<td(1,1,`i') & status_update>=td(1,1,`i') & status_update<=td(31,12,`i') & exit_imp1==0
	replace wg=(status_update-sch_enddate)/365 if sch_enddate>=td(1,1,`i') & sch_enddate<=td(31,12,`i') & status_update>=td(1,1,`i') & status_update<=td(31,12,`i') & exit_imp1==0
	replace wg=1 if sch_enddate<td(1,1,`i') & status_update>td(31,12,`i') & exit_imp1==0
	replace wg=(td(31,12,`i')-sch_enddate)/365 if sch_enddate>=td(1,1,`i') & sch_enddate<=td(31,12,`i') & status_update>td(31,12,`i') & exit_imp1==0
	replace wg=0 if status_update<sch_enddate
	
	sort level STEM
	by level STEM: gen actual_`i'=sum(wg)
	by level STEM: replace actual_`i'=actual_`i'[_N]
	drop wg
}
}

*
* 2) The POTENTIAL stock, including the extension
*
gen byte pretreat_period12=0
 replace pretreat_period12=1 if (elig==1 | elig==0) & (((sch_enddate<td(8,2,2007)) | (sch_enddate>=td(8,2,2007) & status_update<td(8,4,2008))))    
 replace pretreat_period12=1 if (elig==2 ) & (((sch_enddate<td(12,3,2010)) | (sch_enddate>=td(12,3,2010) & status_update>=td(12,5,2011)))) 
 replace pretreat_period12=1 if (elig==3 ) & (((sch_enddate<td(11,3,2011)) | (sch_enddate>=td(11,3,2011) & status_update>=td(11,5,2012))))

gen status_update_feasible=0
 replace status_update_feasible=sch_enddate+61+365 if elig==0 | pretreat_period12==1
 replace status_update_feasible=sch_enddate+61+870 if (elig>=1 & elig<=3) & pretreat_period12==0

quietly {
forvalues i=2004/2012 {
 gen wg=0
	replace wg=(status_update_feasible-td(1,1,`i'))/365 if sch_enddate<td(1,1,`i') & status_update_feasible>=td(1,1,`i') & status_update_feasible<=td(31,12,`i') & exit_imp1==0
	replace wg=(status_update_feasible-sch_enddate)/365 if sch_enddate>=td(1,1,`i') & sch_enddate<=td(31,12,`i') & status_update_feasible>=td(1,1,`i') & status_update_feasible<=td(31,12,`i') & exit_imp1==0
	replace wg=1 if sch_enddate<td(1,1,`i') & status_update_feasible>td(31,12,`i') & exit_imp1==0
	replace wg=(td(31,12,`i')-sch_enddate)/365 if sch_enddate>=td(1,1,`i') & sch_enddate<=td(31,12,`i') & status_update_feasible>td(31,12,`i') & exit_imp1==0
	replace wg=0 if status_update_feasible<sch_enddate
	
	sort level STEM
	by level STEM: gen feasible_`i'=sum(wg)
	by level STEM: replace feasible_`i'=feasible_`i'[_N]
	drop wg
}
}


*
* 3) The POTENTIAL stock, only under the OPT extension  (INSTRUMENT is this)
* 
gen sch_enddate_ext=0
replace sch_enddate_ext=sch_enddate+365  

quietly {
forvalues i=2004/2012 {
 gen wg=0
	replace wg=(status_update_feasible-td(1,1,`i'))/365 if sch_enddate_ext<td(1,1,`i') & status_update_feasible>=td(1,1,`i') & status_update_feasible<=td(31,12,`i') & exit_imp1==0
	replace wg=(status_update_feasible-sch_enddate_ext)/365 if sch_enddate_ext>=td(1,1,`i') & sch_enddate_ext<=td(31,12,`i') & status_update_feasible>=td(1,1,`i') & status_update_feasible<=td(31,12,`i') & exit_imp1==0
	replace wg=1 if sch_enddate_ext<td(1,1,`i') & status_update_feasible>td(31,12,`i') & exit_imp1==0
	replace wg=(td(31,12,`i')-sch_enddate_ext)/365 if sch_enddate_ext>=td(1,1,`i') & sch_enddate_ext<=td(31,12,`i') & status_update_feasible>td(31,12,`i') & exit_imp1==0
	replace wg=0 if status_update_feasible<sch_enddate_ext
	replace wg=0 if elig==0 | pretreat_period12==1

	sort level STEM
	by level STEM: gen ext_`i'=sum(wg)
	by level STEM: replace ext_`i'=ext_`i'[_N]
	drop wg
}
}



collapse (mean)  actual_* feasible_* ext_*,by(level STEM)

*
* reshape for figures
gen id=_n
reshape long actual_ feasible_ ext_,i(id) j(year)

rename actual_ actual
rename ext_ ext
gen regular=feasible_-ext
drop feasible_

sort level STEM year

drop id
saveold "C:\Users\mudemirci\Dropbox\OPT -- Labor Market\Results_CJE\figure2.dta",replace
}

