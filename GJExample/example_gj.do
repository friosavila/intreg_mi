** Extra
ssc install color_style
color_style bay

use pricehouse

*** Data preparation
gen price_1k = price/1000

recode price_1k (0/200 = 1) (200/300=2) (300/400=3) (400/500=4) (500/600=5) (600/800=6) (800/1000=7) (1000/999999=8), gen(price_g)

gen     price_ll = 0     if price_g==1
replace price_ll = 200   if price_g==2 
replace price_ll = 300   if price_g==3
replace price_ll = 400   if price_g==4
replace price_ll = 500   if price_g==5
replace price_ll = 600   if price_g==6
replace price_ll = 800   if price_g==7
replace price_ll = 1000  if price_g==8

gen     price_uu = 200   if price_g==1
replace price_uu = 300   if price_g==2 
replace price_uu = 400   if price_g==3
replace price_uu = 500   if price_g==4
replace price_uu = 600   if price_g==5
replace price_uu = 800   if price_g==6
replace price_uu = 1000  if price_g==7
replace price_uu = .     if price_g==8

gen log_ll=log(price_ll)
gen log_uu=log(price_uu)

gen log_liv=log(sqft_living)
gen log_lot=log(sqft_lot)
gen age_hs = 2015-yr_built
gen renov = yr_renovated!=0
/******************************************************************************/
** This is the core.
** Interval Regression
intreg log_ll log_uu  bedrooms bathrooms log_liv log_lot floors waterfront view condition grade age_hs  renov, het(bedrooms bathrooms log_liv log_lot floors waterfront view condition grade age_hs  renov)
** Imputation Code:
intreg_mi log_price, reps(10)
gen log_price=.
** Setup
tempfile temp
save `temp'

** Importing into Wide MI format
mi import wide , imputed(log_price=log_price1-log_price10)
** create a variable based on imputed ones (passive)
mi passive:gen price_1k_hat=exp(log_price)
/******************************************************************************/
** Analysis : C Quantile regression
ssc install qrprocess
gen logp1k=log(price_1k)
forvalues i = 5 (5) 95 {
	local jj = `i'/100
	qrprocess logp1k bedrooms bathrooms log_liv log_lot floors waterfront view, q(`jj')
	ereturn display
	matrix cqbb1=nullmat(bb1)\r(table)[1,"q1:"]
	matrix cqse1=nullmat(se1)\r(table)[2,"q1:"]
	mi estimate, post cmdok:qrprocess log_price bedrooms bathrooms log_liv log_lot floors waterfront view, q(`jj')
	matrix cqbb2=nullmat(bb2)\r(table)[1,"q1:"]
	matrix cqse2=nullmat(se2)\r(table)[2,"q1:"]
}

** Analysis : U Quantile regression
forvalues i = 5 (5) 95 {
	local jj = `i'/100
	rifhdreg logp1k bedrooms bathrooms log_liv log_lot floors waterfront view, rif(q(`i'))
	ereturn display
	matrix uqbb1=nullmat(qbb1)\r(table)[1,""]
	matrix uqse1=nullmat(qse1)\r(table)[2,""]
	mi estimate, post cmdok:rifhdreg log_price bedrooms bathrooms log_liv log_lot floors waterfront view, rif(q(`i'))
	matrix uqbb2=nullmat(qbb2)\r(table)[1,""]
	matrix uqse2=nullmat(qse2)\r(table)[2,""]
}

matrix coleq bb1=""
matrix coleq se1=""

** Plotting
frame create new
frame  new:{
ssc install lbsvmat
lbsvmat cqbb1
lbsvmat cqse1
lbsvmat uqbb1
lbsvmat uqse1
lbsvmat cqbb2
lbsvmat cqse2
lbsvmat uqbb2
lbsvmat uqse2

gen cil1=.
gen ciu1=.
gen cil2=.
gen ciu2=.
gen q=_n*5
label var cqbb11 "#Bedrooms" 
label var cqbb12 "#Bathrooms"  
label var cqbb13 "Log Sqrft Living Area"   
label var cqbb14 "Log Sqrft Lot Area"   
label var cqbb15 "#Floors"
label var cqbb16 "Close to Waterfront" 
label var cqbb17 "Has a view"
label var cqbb18 "Constant"
color_style tableau
foreach i in 1 2 3 4 5 6 7 8 {
 	replace cil1=cqbb1`i' - 1.96 * cqse1`i'
	replace ciu1=cqbb1`i' + 1.96 * cqse1`i'
	replace cil2=cqbb2`i' - 1.96 * cqse2`i'
	replace ciu2=cqbb2`i' + 1.96 * cqse2`i'
	local tlt:variable label cqbb1`i'
	two (rarea cil1 ciu1 q, pstyle(p1) color(%50)) (line cqbb1`i' q, pstyle(p1)) ///
		(rarea cil2 ciu2 q, pstyle(p2) color(%50)) (line cqbb2`i' q, pstyle(p2)) , ///
		legend(order(1 "Observed data" 3 "Imputed Data"))  name(m`i', replace) ///
		title(`tlt')
} 
graph combine m1 m2 m3 m4 m5 m6 m7 m8, nocopies cols(4) xsize(16) ysize(9) altshrink


foreach i in 1 2 3 4 5 6 7 8 {
 	replace cil1=uqbb1`i' - 1.96 * uqse1`i'
	replace ciu1=uqbb1`i' + 1.96 * uqse1`i'
	replace cil2=uqbb2`i' - 1.96 * uqse2`i'
	replace ciu2=uqbb2`i' + 1.96 * uqse2`i'
	local tlt:variable label cqbb1`i'
	two (rarea cil1 ciu1 q, pstyle(p1) color(%50)) (line uqbb1`i' q, pstyle(p1)) ///
		(rarea cil2 ciu2 q, pstyle(p2) color(%50)) (line uqbb2`i' q, pstyle(p2)) , ///
		legend(order(1 "Observed data" 3 "Imputed Data"))  name(m`i', replace) ///
		title(`tlt')
} 
graph combine m1 m2 m3 m4 m5 m6 m7 m8, nocopies cols(4) xsize(16) ysize(9) altshrink
}
****
** Case of Grenada
** already imputed
use "H:\My Drive\GJExample\pool_grenada.dta", clear
gen wage=.
tempfile m1
save `m1'
mi import wide, imputed(wage=imp_wage_1 imp_wage_2 imp_wage_3 imp_wage_4 imp_wage_5 imp_wage_6 imp_wage_7 imp_wage_8 imp_wage_9 imp_wage_10 imp_wage_11 imp_wage_12 imp_wage_13 imp_wage_14 imp_wage_15 imp_wage_16 imp_wage_17 imp_wage_18 imp_wage_19 imp_wage_20) 

encode gg, gen(ggroup)
mi estimate, cmdok: rifmean wage [pw=wgt], over(ggroup) rif(gini)
coefplot, vertical xlabel(1 "2013" 3 "2015" 5 "2017" 7 "2018q3" 9 "2019q1" 11 "2019q3" 13 "2020q2" 15 "2020q4" 17 "2021q2") title("Wage Gini in Grenada")




