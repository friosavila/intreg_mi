frause hhprice, clear
gen logprice = log(price)
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

gen logland=log(landsize)
recode region_code (1 2 =1) (3 4 =3) (5 6 =5 ) (7 8 =7)
global idepvar c.(distance   logland  )##i.type_h bedroom2 bathroom i.car i.region_code
foreach g in 5 7 10 {
	intreg lpi`g'min  lpi`g'max  $idepvar , het( $idepvar)
	intreg_mi i`g'p
}

foreach g in 5 7 10 {
	gen iprice`g'=.
	local toimp  `toimp' iprice`g'=i`g'p*
}
tempfile as
save `as'


mi import wide, imputed(`toimp')

forvalues i = 5(5)95 {
	local ii = `i'/100
	qrprocess logprice distance   logland  i.type_h bedroom2 bathroom car i.region_code, q(`ii')
	qui:ereturn display
	matrix aux = r(table)'
	matrix cqr=nullmat(cqr)\aux,J(10,1,`i') 
	rifhdreg logprice distance   logland  i.type_h bedroom2 bathroom car i.region_code, rif(q(`i'))
	matrix aux = r(table)'
	matrix uqr=nullmat(uqr)\aux,J(12,1,`i') 
}

local g = 10
forvalues i = 5(5)95 {
	local ii = `i'/100
	mi estimate, cmdok post:qrprocess iprice`g' distance   logland  i.type_h bedroom2 bathroom car i.region_code, q(`ii')
	qui:ereturn display
	matrix aux = r(table)'
	matrix i`g'cqr=nullmat(i`g'cqr)\aux,J(10,1,`i') 
	mi estimate, cmdok post:rifhdreg iprice`g'   distance   logland  i.type_h bedroom2 bathroom car i.region_code, rif(q(`i'))
	matrix aux = r(table)'
	matrix i`g'uqr=nullmat(i`g'uqr)\aux,J(12,1,`i') 
}
