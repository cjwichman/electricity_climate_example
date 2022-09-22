* Prof. Wichman's electricity use data
* example for ECON4803 -- Economics of Climate Change
* data downloaded from Georgia Power


* this code requires the following packages 
* run these commands if not already installed
/* 
ssc install outreg2
ssc install parmest
ssc install eclplot
 */


* change this to directory to your machine
global dir = "/Users/casey/Dropbox/teaching/_FALL2022/ECON4803CW1/misc/energy_data/"
cd $dir



* pull in raw daily kwh data downloaded from Georgia Power
forv i = 1/23 {
	import excel using "rawdata/k`i'.xlsx", clear first
	rename Cost kwh
	destring kwh HighTemp LowTemp, replace force
	save "cleandata/kwh`i'.dta", replace
}

* append files together
clear
forv i = 1/23{
	append using "cleandata/kwh`i'.dta"
}

* drop recent observations with missing values
drop if missing(kwh)
drop if missing(HighTemp)
drop if missing(LowTemp)

* create some useful variables
g date = date(Day,"YMD")
g dow = dow(date)

g year = year(date)
g month = month(date)
g day = day(date)

sort date
g dayofsample = _n
g atemp = 0.5*(HighTemp + LowTemp)


lab var kwh "Daily elec. use (kwh)"
lab var atemp "Ave. daily temp (deg F)"
lab var dayofsample "Days since Nov. 6, 2020"

compress
save "cleandata/kwh_combined.dta", replace
export delimited "cleandata/kwh_combined.csv", replace




use "cleandata/kwh_combined.dta", replace

** generate kwh over time figure
#delimit;
twoway 
(scatter kwh dayofsample, 
	msymbol(Oh) mcol(dknavy) plotregion(lcolor(none))
	text(50 25 "Nov 2020")
	text(50 290 "Sep 2021"))
(line atemp dayofsample, lcol(red) yaxis(2))
;
#delimit cr
graph export "output/kwh_over_time.pdf", replace


* scatter plot of kwh vs. temp
#delimit;
twoway 
(scatter kwh atemp, 
	msymbol(Oh) mcol(dknavy) plotregion(lcolor(none)))
;
#delimit cr
graph export "output/kwh_temp_scatter.pdf", replace



* scatter plot of kwh vs. temp + quadratic fit
#delimit;
twoway 
(scatter kwh atemp, 
	msymbol(Oh) mcol(dknavy) plotregion(lcolor(none)))
(qfit kwh atemp, 
	lcolor(maroon) lwidth(thick)),
ytitle("Daily elec. use (kwh)")
;
#delimit cr
graph export "output/kwh_temp_scatter2.pdf", replace


* simulate simple 10degF climate change shift
g atemp_future = atemp+10 // weather shifted rightwards by 10 deg

#delimit;
twoway 
(hist atemp, frac lcolor(gs12) fcolor(gs12)) 
(hist atemp_future, frac fcolor(none) lcolor(red)), 
	xlabel(0(20)100)
	legend(off) xtitle("Ave. Temp.") plotregion(lcolor(none))
	xsize(10) ysize(4) scale(1.5)
	text(0.14 50 "Climate shifts temperature rightward {&rarr}")
;
#delimit cr
graph export "output/temp_hist.pdf", replace 








use "cleandata/kwh_combined.dta", replace
* estimate regressions
reg kwh atemp i.dow, r
outreg2 using "output/regresults.xls", replace excel label


reg kwh c.atemp##c.atemp i.dow, r
outreg2 using "output/regresults.xls", excel label
predict kwh_now, xb


g atemp_future = atemp+10 // weather shifted rightwards by 10 deg
replace atemp = atemp_future
predict kwh_future, xb

* summarize climate impacts (change in kwhs due to increased temperatures)
g climate_damages = kwh_future - kwh_now 
sum climate_damages
hist climate_damages

* pct change
sum kwh_now, meanonly
local mm = r(mean)
sum climate_damages, meanonly
local nn = r(mean)

di `nn'/`mm'


* plot temp-squared prediction
use "cleandata/kwh_combined.dta", replace
sum atemp
reg kwh c.atemp##c.atemp i.dow, r
qui margins, at(atemp=(1(1)100)) post noestimcheck level(90)
parmest, norestore level(90)
split parm, parse(".")
rename parm1 tempdegrees
destring tempdegrees, replace

#delimit;
eclplot estimate min90 max90 tempdegrees, 
	eplot(connected) estopts(msym(O) msize(small) mcol(dknavy))
	rplot(rarea)  ciopts(col(eltblue))
	ytitle("Predicted daily elec. use (kwh)")
	xtitle("Ave. daily temperature (deg F)")
	xline(30, lcol(black)) xline(85.5, lcol(black))
	text(145 58 "{&larr}  observed data {&rarr} ")
	plotregion(lcolor(none))
;
#delimit cr 
graph export "output/predicted_kwh.pdf", replace
