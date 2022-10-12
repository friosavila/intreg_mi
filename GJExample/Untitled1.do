use "C:\Users\Fernando\Documents\GitHub\intreg_mi\GJExample\pricehouse.dta" 

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

** Graph

gen logprice=log(price_1k)

gen price_gp=price_g+rnormal()*0.1

set scheme white2
color_style bay
two ( scatter logprice price_gp, color(%10) xaxis(1)  yaxis(1) xscale(range(-1 8) axis(1)) pstyle(p1) ) /// 
	(kdensity logprice, horizontal xaxis(2) xlabel( none , axis(2) )    pstyle(p2) ) ///
	(histogram price_g, discrete yaxis(2) xaxis(2) xscale(range(-1 8) axis(2)) ylabel( none , axis(2) )  yscale( range(0 1)  axis(2))  pstyle(p3)) , ///
	legend(order(2 "Observed data" 3 "Censored Data"))  xtitle("", axis(2)) xtitle("", axis(1)) ///
	ytitle("", axis(2)) ytitle("", axis(1)) ///
	xlabel(1 "<200k" 2 "200-300k" 3 "300-400k" ///
		   4 "400-500k" 5 "500-600k" 6 "600-800k" ///
		   7 "800-1000k" 8 ">1000k" , axis(1) alt) ///
	ylabel(`=log(100)' "100k" `=log(200)' "200k" `=log(300)' "300k" `=log(400)' "400k" ///
		   `=log(500)' "500k" `=log(600)' "600k" `=log(800)' "800k" ///
		   `=log(1000)' "1000k" `=log(1500)' "1500k" `=log(2500)' "2500k" `=log(5000)' "5000k" , axis(1)  ) ///
	xsize(10)	ysize(6)



gen log_ll=log(price_ll)
gen log_uu=log(price_uu)

gen log_liv=log(sqft_living)
gen log_lot=log(sqft_lot)
gen age_hs = 2015-yr_built
gen renov = yr_renovated!=0
** Regression
intreg log_ll log_uu  bedrooms bathrooms log_liv log_lot floors waterfront view condition grade age_hs  renov, het(bedrooms bathrooms log_liv log_lot floors waterfront view condition grade age_hs  renov)
** Imputation
intreg_mi log_price, reps(10)
gen log_price=.
** Setup
tempfile temp
save `temp'

mi import wide , imputed(log_price=log_price1-log_price10)
mi passive:gen price_1k_hat=exp(log_price)

** Graphs

joy_plot logprice log_price1 log_price2 log_price3 log_price4, dadj(2) notext ///
		legend(order(1 "True Data" 2 "Imp1" 3 "Imp2" 4 "Imp3" 5 "Imp4")) range(4 9)

xtile qage=age, n(5)		
rifmean price_1k, over(qage) rif(gini) scale(100)
mi estimate, cmdok post: rifmean price_1k_hat, over(qage) rif(gini) scale(100)

** Analysis 
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

*******************************************************************

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
color_style bay, n(2)
foreach i in 1 2 3 4 5 6 7 8 {
 	replace cil1=cqbb1`i' - 1.96 * cqse1`i'
	replace ciu1=cqbb1`i' + 1.96 * cqse1`i'
	replace cil2=cqbb2`i' - 1.96 * cqse2`i'
	replace ciu2=cqbb2`i' + 1.96 * cqse2`i'
	local tlt:variable label cqbb1`i'
	two (rarea cil1 ciu1 q, pstyle(p1) color(%30)) (line cqbb1`i' q, pstyle(p1)) ///
		(rarea cil2 ciu2 q, pstyle(p2) color(%30)) (line cqbb2`i' q, pstyle(p2)) , ///
		legend(order(1 "Observed data" 3 "Imputed Data") row(1))  name(m`i', replace) ///
		title(`tlt')
} 
grc1leg m1 m2 m3 m4 m5 m6 m7 m8, nocopies cols(4)   altshrink
graph export nfig3.png, width(2000) replace

foreach i in 1 2 3 4 5 6 7 8 {
 	replace cil1=uqbb1`i' - 1.96 * uqse1`i'
	replace ciu1=uqbb1`i' + 1.96 * uqse1`i'
	replace cil2=uqbb2`i' - 1.96 * uqse2`i'
	replace ciu2=uqbb2`i' + 1.96 * uqse2`i'
	local tlt:variable label cqbb1`i'
	two (rarea cil1 ciu1 q, pstyle(p1) color(%30)) (line uqbb1`i' q, pstyle(p1)) ///
		(rarea cil2 ciu2 q, pstyle(p2) color(%30)) (line uqbb2`i' q, pstyle(p2)) , ///
		legend(order(1 "Observed data" 3 "Imputed Data") row(1))  name(m`i', replace) ///
		title(`tlt')
} 
grc1leg m1 m2 m3 m4 m5 m6 m7 m8, nocopies cols(4)   altshrink
graph expor nfig4.png, width(2000) replace

graph combine m1 m2 m3 m4 m5 m6 m7 m8, nocopies cols(4) xsize(16) ysize(9) altshrink
}
