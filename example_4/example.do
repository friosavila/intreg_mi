** required

ssc install qrprocess, replace
ssc install rif, replace
ssc install palettes, replace
ssc install colrspace  , replace
ssc install grstyle, replace
ssc install color_style, replace
net install fra, from(https://friosavila.github.io/stpackages)
fra install lbsvmat, replace
ssc install frause

** Price housing

use pricehouse, clear

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
	matrix cqbb1=nullmat(cqbb1)\r(table)[1,"q1:"]
	matrix cqse1=nullmat(cqse1)\r(table)[2,"q1:"]
	mi estimate, post cmdok:qrprocess log_price bedrooms bathrooms log_liv log_lot floors waterfront view, q(`jj')
	matrix cqbb2=nullmat(cqbb2)\r(table)[1,"q1:"]
	matrix cqse2=nullmat(cqse2)\r(table)[2,"q1:"]
}

** Analysis : U Quantile regression
forvalues i = 5 (5) 95 {
	local jj = `i'/100
	rifhdreg logp1k bedrooms bathrooms log_liv log_lot floors waterfront view, rif(q(`i'))
	ereturn display
	matrix uqbb1=nullmat(uqbb1)\r(table)[1,""]
	matrix uqse1=nullmat(uqse1)\r(table)[2,""]
	mi estimate, post cmdok:rifhdreg log_price bedrooms bathrooms log_liv log_lot floors waterfront view, rif(q(`i'))
	matrix uqbb2=nullmat(uqbb2)\r(table)[1,""]
	matrix uqse2=nullmat(uqse2)\r(table)[2,""]
}



** Plotting
capture frame create new
frame  new:{
	clear
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
		legend(order(1 "Observed data" 3 "Imputed Data") pos(6) col(2))  name(m`i', replace) ///
		title(`tlt')
} 
graph combine m1 m2 m3 m4 m5 m6 m7 m8, xsize(16) ysize(9) iscale(0.5)
graph export fig1.png, width(2000) replace

foreach i in 1 2 3 4 5 6 7 8 {
 	replace cil1=uqbb1`i' - 1.96 * uqse1`i'
	replace ciu1=uqbb1`i' + 1.96 * uqse1`i'
	replace cil2=uqbb2`i' - 1.96 * uqse2`i'
	replace ciu2=uqbb2`i' + 1.96 * uqse2`i'
	local tlt:variable label cqbb1`i'
	two (rarea cil1 ciu1 q, pstyle(p1) color(%50)) (line uqbb1`i' q, pstyle(p1)) ///
		(rarea cil2 ciu2 q, pstyle(p2) color(%50)) (line uqbb2`i' q, pstyle(p2)) , ///
		legend(order(1 "Observed data" 3 "Imputed Data") pos(6) col(2))  name(m`i', replace) ///
		title(`tlt')
} 
grc1leg m1 m2 m3 m4 m5 m6 m7 m8,   cols(4) xsize(16) ysize(9) iscale(0.5)
graph export fig2.png, width(2000) replace
}
 



