clear

cd "C:\Users\Murat Demirci\Dropbox\OPT -- Labor Market\Submission\CJE\Accepted\SSRP"

use figure1_raw.dta

*
 rename degreesawardsconferredbyracensfp degrees

* by level of study
 gen byte ba=0
	replace ba=1 if levelofdegreeorotheraward=="Bachelor's Degrees"
 gen byte ma=0
	replace ma=1 if levelofdegreeorotheraward=="Master's Degrees"
 gen byte phd=0
	replace phd=1 if levelofdegreeorotheraward=="Doctorate Degree-Research/Scholarship" | levelofdegreeorotheraward=="Doctorate Degree-Other" | /*
              */ levelofdegreeorotheraward=="Doctorate Degree-Other" | levelofdegreeorotheraward=="Doctorate Degrees"

* by citizenship
 gen byte tmp=0
	replace tmp=1 if citizenshipstandardized=="Temporary Residents"
 gen byte ntv=0
	replace ntv=1 if citizenshipstandardized=="U.S. Citizens and Permanent Residents"


* by field of study
 gen byte STEM=0
	replace STEM=1 if academicdisciplinebroadstandardi=="Engineering" | academicdisciplinebroadstandardi=="Geosciences" | /*
			*/ academicdisciplinebroadstandardi=="Life	Sciences" | academicdisciplinebroadstandardi=="Math and Computer Sciences" | /*
			*/ academicdisciplinebroadstandardi=="Physical Sciences" 
 gen byte nonSTEM=0
	replace nonSTEM=1 if STEM==0
			  
* statistics of interest: by level, citizenship, field graduates
 foreach var1 of varlist ba ma phd {
 foreach var2 of varlist ntv tmp {
 foreach var3 of varlist nonSTEM STEM {
	sort year `var1' `var2' `var3' 
	by year: gen `var1'_`var2'_`var3'=sum(degrees*`var1'*`var2'*`var3')
	by year: replace `var1'_`var2'_`var3'=`var1'_`var2'_`var3'[_N]
 }
 }
 }

 collapse ba_* ma_* phd_*,by(year)

* tmp percentages
 foreach var1 in "ba" "ma" "phd" {
 foreach var3 in "nonSTEM" "STEM" {
	gen perc_`var1'_`var3'=`var1'_tmp_`var3'/(`var1'_tmp_`var3'+`var1'_ntv_`var3')
 }
 }


 drop *_ntv_*		// no need for data of natives for the figure
 
 * converting to in 1,000
 foreach var1 in "ba" "ma" "phd" {
 foreach var3 in "nonSTEM" "STEM" {
	replace `var1'_tmp_`var3'=`var1'_tmp_`var3'*0.001
 }
 }
 
 saveold figure1.dta, replace
