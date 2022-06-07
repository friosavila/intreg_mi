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

** Analysis 
ssc install qrprocess
gen logp1k=log(price_1k)
forvalues i = 5 (5) 95 {
	local jj = `i'/100
	qrprocess logp1k bedrooms bathrooms log_liv log_lot floors waterfront view, q(`jj')
	ereturn display
	matrix bb1=nullmat(bb1)\r(table)[1,"q1:"]
	matrix se1=nullmat(se1)\r(table)[2,"q1:"]
	mi estimate, post cmdok:qrprocess log_price bedrooms bathrooms log_liv log_lot floors waterfront view, q(`jj')
	matrix bb2=nullmat(bb2)\r(table)[1,"q1:"]
	matrix se2=nullmat(se2)\r(table)[2,"q1:"]
}


forvalues i = 5 (5) 95 {
	local jj = `i'/100
	rifhdreg logp1k bedrooms bathrooms log_liv log_lot floors waterfront view, rif(q(`i'))
	ereturn display
	matrix qbb1=nullmat(qbb1)\r(table)[1,""]
	matrix qse1=nullmat(qse1)\r(table)[2,""]
	mi estimate, post cmdok:rifhdreg log_price bedrooms bathrooms log_liv log_lot floors waterfront view, rif(q(`i'))
	matrix qbb2=nullmat(qbb2)\r(table)[1,""]
	matrix qse2=nullmat(qse2)\r(table)[2,""]
}


