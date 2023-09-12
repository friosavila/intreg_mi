** Load Data
frause hhprice, clear
** Create Log of Price 
gen logprice = log(price)
** Generate groups for 5 7 and 10 groupings
foreach g in 5 7 10 {
	xtile q`g'=price, n(`=(`g'+1)*`g'/2')
	gen qf`g'=0
	local t =0
	forvalues i = `g'(-1)1 {
		replace qf`g'=qf`g'+1 if q`g'>`t'
		local t = `t'+`i'
		display `t'
	}
	local uu = .
	gen lpi`g'max=.
	gen lpi`g'min=.
	forvalues i = 1/`g' {
		sum logprice if qf`g'==`i'
		local ll = `uu'
		local uu = r(max)
		replace lpi`g'max=`uu' if qf`g'==`i' & qf`g'!=`g'
		replace lpi`g'min=`ll' if qf`g'==`i'
	}
}

** Some data cleaning
gen logland=log(landsize)
recode region_code (1 2 =1) (3 4 =3) (5 6 =5 ) (7 8 =7)
global idepvar c.(distance   logland  )##i.type_h bedroom2 bathroom i.car i.region_code

** Estimate imputed values 
foreach g in 5 7 10 {
	intreg lpi`g'min  lpi`g'max  $idepvar , het( $idepvar)
	intreg_mi i`g'p
	gen iprice`g'=.
	local toimp  `toimp' iprice`g'=i`g'p*
}
save tosave, replace

** Import Data into mi
mi import wide, imputed(`toimp')

** Estimates Baseline model using Cqreg and uqreg
forvalues i = 5(5)95 {
	
	qui:qreg logprice distance   logland  i.type_h bedroom2 bathroom car i.region_code, q(`i')
	matrix cqr=nullmat(cqr)\r(table)',J(12,1,`i') 
	rifhdreg logprice distance   logland  i.type_h bedroom2 bathroom car i.region_code, rif(q(`i'))
	matrix uqr=nullmat(uqr)\r(table)',J(12,1,`i') 
}

** Estimates all models using mi data
foreach g in 5 7 10 {
	forvalues i = 5(5)95 {
 		mi estimate, cmdok post:qreg iprice`g' distance   logland  i.type_h bedroom2 bathroom car i.region_code, q(`i')
 		matrix i`g'cqr=nullmat(i`g'cqr)\r(table)',J(12,1,`i') 
		mi estimate, cmdok post:rifhdreg iprice`g'   distance   logland  i.type_h bedroom2 bathroom car i.region_code, rif(q(`i'))
		matrix i`g'uqr=nullmat(i`g'uqr)\r(table)',J(12,1,`i') 
	}
}

capture frame create toplot
frame change toplot
fra install lbsvmat
lbsvmat cqr, row
lbsvmat uqr, row
foreach i in 5 7 10 {
    lbsvmat i`i'cqr
    lbsvmat i`i'uqr
}
save toplot, replace

** Creations of plots

use toplot, clear
set scheme white2
color_style tableau


foreach k in 5 7 10 {  
	local ii = 0
	foreach i in "1.type_h" "bathroom" bedroom2 car {
    local ii = `ii'+1
    two (rarea     cqr5     cqr6 cqr10     if cqr_nm=="`i'", pstyle(p1) color(%50)) ///
        (line      cqr1          cqr10     if cqr_nm=="`i'", pstyle(p1) ) ///
        (rarea i`k'cqr5 i`k'cqr6 cqr10     if cqr_nm=="`i'", pstyle(p2) color(%50)) ///
        (line  i`k'cqr1      i`k'cqr10     if cqr_nm=="`i'", pstyle(p2) ), ///
        legend(order(1 "Fully Observed" 3 "Imputed") pos(12) ring(0) col(2))  ///
        xtitle(Quantile) title(`i')  name(cqr`ii', replace) ///
		title("Coeff of `i'") 

    two (rarea     uqr5     uqr6 cqr10     if cqr_nm=="`i'", pstyle(p1) color(%50)) ///
        (line      uqr1          cqr10     if cqr_nm=="`i'", pstyle(p1) ) ///
        (rarea i`k'uqr5 i`k'uqr6 cqr10     if cqr_nm=="`i'", pstyle(p2) color(%50)) ///
        (line  i`k'uqr1      i`k'cqr10     if cqr_nm=="`i'", pstyle(p2) ), ///
        legend(order(1 "Fully Observed" 3 "Imputed") pos(12) ring(0) col(2))  ///
        xtitle(Quantile) title(`i')  name(uqr`ii', replace) ///
		title("Coeff of `i'") 
  }     
  
  graph combine cqr1 cqr2 cqr3 cqr4, title("Conditional QREG: `k' groups")   imargin(tiny)
  graph export fig_`k'_cqr.png, width(2000) replace 
  graph combine uqr1 uqr2 uqr3 uqr4, title("Unconditional QREG: `k' groups") imargin(tiny)
  graph export fig_`k'_uqr.png, width(2000) replace  
}