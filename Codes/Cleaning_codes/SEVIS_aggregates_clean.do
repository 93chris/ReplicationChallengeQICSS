*
* STEP 1:  Calculating Class Sizes (i.e., the population of recent college gradautes in each field and year)
*
clear

use "C:\Users\Murat Demirci\Dropbox\OPT -- Labor Market\Submission\CJE\Accepted\MS2019112_Data\Demirci_CJE_2020.dta"

{

* Sample of interest
 gen byte bach_sample=0
	replace bach_sample=1 if age<=24 & level==2
 gen byte ms_sample=0
	replace ms_sample=1 if age<=28 & level==3
 gen byte phd_sample=0
	replace phd_sample=1 if age<=31 & level==4
 gen byte all_sample=0
	replace all_sample=1 if (age<=24 & level==2) | (age<=28 & level==3) | (age<=31 & level==4)
	

* Making codes in line with SEVIS data
	replace field_codes=3611 if degfieldd==4003
	replace field_codes=5098 if degfieldd==4000
	replace field_codes=5003 if degfieldd==5008
	replace field_codes=5098 if degfieldd==4008
	replace field_codes=5901 if degfieldd==5801
	replace field_codes=6000 if degfieldd==6099
	replace field_codes=2404 if degfieldd==2402

* Calculating the class size (i.e., the number of graduates in each year and field)
 capture drop classsize_*
 forvalues i=2/4 { 
	if `i'==2 local level="bach"
	if `i'==3 local level="ms"
	if `i'==4 local level="phd"
	sort field_codes year 
	by field_codes year: gen classsize_`i'=sum(perwt*all*`level'_sample)
	by field_codes year: replace classsize_`i'=classsize_`i'[_N]
 }


* 
 collapse (mean) classsize_2-classsize_4, by (year field_codes) 

 save "C:\Users\Murat Demirci\Dropbox\OPT -- Labor Market\Submission\CJE\Accepted\SSRP\class_sizes.dta", replace
}
 

*
* STEP 2:  Calculating the Statistics of International students from student-level SEVIS data 
*
 clear
 use "C:\Users\Murat Demirci\Dropbox\OPT -- Labor Market\Data\2004-2013SEVIS.dta"			// This is the student-level data obtained with FOIA request. I am not allowed to share it. 
 
 {


* Exclude students at associate programs & restrict to starting classes 2004-2013, and exclude American land, such as American Samoa
 drop if level==1
 drop if country=="SAMOA"
 keep if ayear>=2004 & ayear<=2013 
 
* Converting cis6 codes of SEVIS into the ACS' fieldd codes, and making them balanced over time as explained in the Online Appendix.
 quietly do xwalk_from_cis6_to_ACSfieldd.do
 gen field_codes=fieldd
	replace field_codes=3611 if fieldd==4003
	replace field_codes=5098 if fieldd==4000
	replace field_codes=5003 if fieldd==5008
	replace field_codes=5098 if fieldd==4008
	replace field_codes=5901 if fieldd==5801
	replace field_codes=6000 if fieldd==6099
	replace field_codes=2404 if fieldd==2402


*
* 1) The actual stock of foreign student supply with OPT
 quietly {
 forvalues i=2005/2012 {
  local i_1=`i'-1
  gen wg=0
	replace wg=(status_update-td(1,7,`i_1'))/365 if sch_enddate<td(1,7,`i_1') & status_update>=td(1,7,`i_1') & status_update<=td(30,6,`i') & exit_imp1==0
	replace wg=(status_update-sch_enddate)/365 if sch_enddate>=td(1,7,`i_1') & sch_enddate<=td(30,6,`i') & status_update>=td(1,7,`i_1') & status_update<=td(30,6,`i') & exit_imp1==0
	replace wg=1 if sch_enddate<td(1,7,`i-1') & status_update>td(30,6,`i') & exit_imp1==0
	replace wg=(td(30,6,`i')-sch_enddate)/365 if sch_enddate>=td(1,7,`i_1') & sch_enddate<=td(30,6,`i') & status_update>td(30,6,`i') & exit_imp1==0
	replace wg=0 if status_update<sch_enddate
  sort level ayear field_codes
  by level ayear field_codes: gen stock_`i'=sum(wg)
  by level ayear field_codes: replace stock_`i'=stock_`i'[_N]
  drop wg
 }
 }
 
 
*
* 2) The potential stock of foreign students under the new OPT schemes
* 
* note: elig=1 for fields became eligible in 2008, elig=2 for those became eligible in 2011, and elig=3 for those became eligible in 2012. 
*
 gen byte pretreat_period12=0
	replace pretreat_period12=1 if (elig==1 | elig==0) & (((sch_enddate>=td(1,1,2004) & sch_enddate<td(8,2,2007)) | (sch_enddate>=td(8,2,2007) & status_update<td(8,4,2008)))) 
	replace pretreat_period12=1 if (elig==2 ) & (((sch_enddate>=td(1,1,2004) & sch_enddate<td(12,3,2010)) | (sch_enddate>=td(12,3,2010) & status_update>=td(12,5,2011)))) 
	replace pretreat_period12=1 if (elig==3 ) & (((sch_enddate>=td(1,1,2004) & sch_enddate<td(11,3,2011)) | (sch_enddate>=td(11,3,2011) & status_update>=td(11,5,2012)))) 

 capture drop status_update_feasible
 gen status_update_feasible=0
	replace status_update_feasible=sch_enddate+61+365 if elig==0 | pretreat_period12==1
	replace status_update_feasible=sch_enddate+61+870 if (elig>=1 & elig<=3) & pretreat_period12==0

 quietly {
 forvalues i=2005/2012 {
 foreach var of varlist all  {  
  local i_1=`i'-1
  gen wg=0
	replace wg=(status_update_feasible-td(1,7,`i_1'))/365 if sch_enddate<td(1,7,`i_1') & status_update_feasible>=td(1,7,`i_1') & status_update_feasible<=td(30,6,`i') & exit_imp1==0
	replace wg=(status_update_feasible-sch_enddate)/365 if sch_enddate>=td(1,7,`i_1') & sch_enddate<=td(30,6,`i') & status_update_feasible>=td(1,7,`i_1') & status_update_feasible<=td(30,6,`i') & exit_imp1==0
	replace wg=1 if sch_enddate<td(1,7,`i_1') & status_update_feasible>td(30,6,`i') & exit_imp1==0
	replace wg=(td(30,6,`i')-sch_enddate)/365 if sch_enddate>=td(1,7,`i_1') & sch_enddate<=td(30,6,`i') & status_update_feasible>td(30,6,`i') & exit_imp1==0
	replace wg=0 if status_update_feasible<sch_enddate
  sort level ayear field_codes
  by level ayear field_codes: gen feas`var'_`i'=sum(wg*`var')
  by level ayear field_codes: replace feas`var'_`i'=feas`var'_`i'[_N]
  drop wg
 }
 }
 }


* 3)  The potential stock of foreign students under the extended OPT terms
*
 gen sch_enddate_ext=0
	replace sch_enddate_ext=sch_enddate+365 
 quietly {
 forvalues i=2005/2012 {
 foreach var of varlist all  { 
  local i_1=`i'-1
  gen wg=0
	replace wg=(status_update_feasible-td(1,7,`i_1'))/365 if sch_enddate_ext<td(1,7,`i_1') & status_update_feasible>=td(1,7,`i_1') & status_update_feasible<=td(30,6,`i') & exit_imp1==0
	replace wg=(status_update_feasible-sch_enddate_ext)/365 if sch_enddate_ext>=td(1,7,`i_1') & sch_enddate_ext<=td(30,6,`i') & status_update_feasible>=td(1,7,`i_1') & status_update_feasible<=td(30,6,`i') & exit_imp1==0
	replace wg=1 if sch_enddate_ext<td(1,7,`i_1') & status_update_feasible>td(30,6,`i') & exit_imp1==0
	replace wg=(td(30,6,`i')-sch_enddate_ext)/365 if sch_enddate_ext>=td(1,7,`i_1') & sch_enddate_ext<=td(30,6,`i') & status_update_feasible>td(30,6,`i') & exit_imp1==0
	replace wg=0 if status_update_feasible<sch_enddate_ext
	replace wg=0 if elig==0 | pretreat_period12==1
  sort level ayear field_codes
  by level ayear field_codes: gen ext`var'_`i'=sum(wg*`var')
  by level ayear field_codes: replace ext`var'_`i'=ext`var'_`i'[_N]
  drop wg
 }
 }
 }


collapse (mean) stock_* feas* ext*,by(level ayear field_codes)
}


*
* NOTE THAT: The code above calculates the supply seperately for each starting class. 
* Below, I accumulate the supply from each classes for each calendar year between 2009-2012, and reshape it for merging with the ACS data. 


{

* Actual Supply 
*
forvalues t=2009/2012 {
 gen treat_`t'=0
 gen ayears=1
 sort level field_codes 
 by level field_codes: replace treat_`t'=sum(stock_`t'*ayears)
 by level field_codes: replace treat_`t'=treat_`t'[_N]
 drop ayears
}

* Potential Supply under all OPT
*
forvalues t=2009/2012 {
foreach var in "all" { 
 local t_1=`t'-1
 gen inst`var'_`t'=0
 gen ayears=1
 sort level field_codes 
 by level field_codes: replace inst`var'_`t'=sum(feas`var'_`t'*ayears)
 by level field_codes: replace inst`var'_`t'=inst`var'_`t'[_N]
 drop ayears
}
}

* Potential Supply under extension period
*
forvalues t=2009/2012 {
foreach var in "all" {	 
 local t_1=`t'-1
 gen instext`var'_`t'=0
 gen ayears=1
 sort level field_codes 
 by level field_codes: replace instext`var'_`t'=sum(ext`var'_`t'*ayears)
 by level field_codes: replace instext`var'_`t'=instext`var'_`t'[_N]
 drop ayears
}
}


collapse (mean) treat_* install_*  instextall_*, by (level field_codes)  


* First need to convert from wide to long (to take years from top row to columns)
 egen id=group(level field_codes)
 drop if id==.
 reshape long treat_ install_  instextall_ , i(id) j(year)  
 rename treat_ treat
 rename install_ install
 rename instextall_ instextall

 drop id

* Second need to convert from long to wide 
 egen id=group(field_codes year)
 reshape wide treat install instextall, i(id) j(level)  
 drop id

* replacing no obs. cases with zero
 forvalues l=2/4 {
 foreach var of varlist  treat`l' install`l'  {  
	replace `var'=0 if `var'==.
 }
 }

}

*
* Below, we calculate the variables of interest by the field aggregation of interest. 
*


{
 
 
  merge 1:1 year field_codes using "C:\Users\Murat Demirci\Dropbox\OPT -- Labor Market\Submission\CJE\Accepted\SSRP\class_sizes.dta"

* list year field_codes if _merge==2 			// only 4 obs. not matched from SEVIS, b/c there is no foreign student there. Replace them with 0
 foreach var of varlist treat2- instextall4 {
	replace `var'=0 if `var'==.
 }
 drop _merge

*
* field codes for the analysis (see the Online Appendix for the name of each field)
*
quietly {
 gen field_codes2=field_codes
	replace field_codes2=1199 if (field_codes>=1100 & field_codes<=1101) | (field_codes==1302) 
	replace field_codes2=1103 if (field_codes>=1103 & field_codes<=1106) | (field_codes>=1301 & field_codes<=1303) 
	replace field_codes2=1401 if field_codes==1401   
	replace field_codes2=1501 if field_codes==1501   
	replace field_codes2=1901 if (field_codes>=1901 & field_codes<=2001)  
	replace field_codes2=2102 if (field_codes>=2100 & field_codes<=2107)  
	replace field_codes2=4901 if field_codes==2201 
	replace field_codes2=2399 if (field_codes>=2300 & field_codes<=2399)  
	replace field_codes2=2401 if field_codes==2401   
	replace field_codes2=2405 if field_codes==2405   
	replace field_codes2=2406 if field_codes==2403   
	replace field_codes2=2408 if field_codes==2407   
	replace field_codes2=2412 if field_codes==2412   
	replace field_codes2=2414 if field_codes==2414   
	replace field_codes2=2499 if (field_codes==2400 | field_codes==2402 | field_codes==2404 | (field_codes>=2409 & field_codes<=2411) | field_codes==2413 | (field_codes>=2415 & field_codes<=2419))
	replace field_codes2=2599 if (field_codes>=2500 & field_codes<=2599)  
	replace field_codes2=2601 if (field_codes>=2600 & field_codes<=2699)  
	replace field_codes2=3301 if (field_codes>=3200 & field_codes<=3399)  
	replace field_codes2=3401 if (field_codes>=3400 & field_codes<=3499)
	replace field_codes2=3600 if field_codes==3600
	replace field_codes2=3699 if (field_codes>=3601 & field_codes<=3699)  
	replace field_codes2=3700 if (field_codes>=3701 & field_codes<=3799) 
	replace field_codes2=2599 if field_codes==3801 | field_codes==5102
	replace field_codes2=5098 if (field_codes>=4001 & field_codes<=4099) 
	replace field_codes2=4101 if field_codes==4101   
	replace field_codes2=4801 if field_codes2==4901   
	replace field_codes2=5003 if field_codes==5003   
	replace field_codes2=5007 if field_codes==5001   
	replace field_codes2=5000 if (field_codes==5002 | field_codes==5004 | field_codes==5005 | field_codes==5006 | field_codes==5008) 
	replace field_codes2=5200 if (field_codes>=5200 & field_codes<=5299)
	replace field_codes2=5301 if field_codes==5301   
	replace field_codes2=5401 if (field_codes>=5400 & field_codes<=5499)
	replace field_codes2=5301 if field_codes==1102   
	replace field_codes2=5507 if field_codes==5502 | field_codes==5503 
	replace field_codes2=5506 if field_codes==5505   
	replace field_codes2=5599 if field_codes==5500 | field_codes==5504 | field_codes==3501
	replace field_codes2=2599 if (field_codes>=5601 & field_codes<=5901)
	replace field_codes2=6099 if (field_codes>=6000 & field_codes<=6099) 
	replace field_codes2=6107 if field_codes==6107 
	replace field_codes2=6199 if (field_codes>=6100 & field_codes<=6199) & field_codes!=6107
	replace field_codes2=6200 if field_codes==6200
	replace field_codes2=6201 if field_codes==6201
	replace field_codes2=6203 if field_codes==6203
	replace field_codes2=6206 if field_codes==6206
	replace field_codes2=6207 if field_codes==6207
	replace field_codes2=6299 if field_codes==6202 | field_codes==6204 | field_codes==6205 | (field_codes>=6209 & field_codes<=6299)
	replace field_codes2=6402 if field_codes==6403

* Further adjustments for master's, if any
 gen field_codes3=field_codes2
 

* Further adjustments for phds's, if any
 gen field_codes4=field_codes2
	replace field_codes4=4101 if field_codes2==1199
	replace field_codes4=5599 if field_codes2==1401
	replace field_codes4=5599 if field_codes2==1501
	replace field_codes4=2499 if field_codes2==2401 | field_codes2==2406 | field_codes2==2412
	replace field_codes4=2499 if field_codes2==2599
	replace field_codes4=4101 if field_codes2==2901
	replace field_codes4=3301 if field_codes2==2601
	replace field_codes4=5599 if field_codes2==3401
	replace field_codes4=4101 if field_codes2==5301
	replace field_codes4=4101 if field_codes2==5401
	replace field_codes4=6299 if field_codes2>=6200 & field_codes<=6299
}


*
* Getting sum in each agg. category 
 forvalues l=2/4 {
 sort year field_codes`l'
 foreach var of varlist treat`l' install`l' instextall`l' classsize_`l' {  // cnt_`l' classsize_`l' treat`l'-instextindia`l'
	by year field_codes`l': replace `var'=sum(`var')
	by year field_codes`l': replace `var'=`var'[_N]
 }
 }

 
*
* Now, collapse the data in SEVIS to field_codes ACS again to be able merge with the ACS data
 order year field_codes 
 global allvar treat2- field_codes4
 collapse (mean) $allvar,by(year field_codes)

 drop if field_codes==0
 
* Let's get the ratios to merge 
 gen all=1
 forvalues i=2/4 {
 sort year field_codes
 foreach var of varlist treat`i' {		
	gen `var'_ratio=(`var'/classsize_`i')*100
 }
 }


*
* In the ACS, field codes are at field_codes2 and field_codes3 level. So, I collapse these data into these levels.
 global allvar treat2- classsize_4 treat2_ratio- treat4_ratio
 collapse (mean) $allvar,by(year field_codes2)

 rename field_codes2 field_codes



 save "C:\Users\Murat Demirci\Dropbox\OPT -- Labor Market\Submission\CJE\Accepted\SSRP\SEVIS_aggregates.dta", replace  
 
// note that: classsize_2 classsize_3 classsize_4 treat2 treat3 instextall3 treat4 treat3_ratio in Demirci_CJE_2020.dta comes from this file. 
}


