capture program drop rep
program rep
	replace `0'
end
program drop sim
program sim, eclass
	clear
	set obs 1000 
	gen x1=rnormal()
	gen x2=rnormal()
	gen x3=rnormal()
	gen  e=rnormal()

	gen y = 1-x1+x2-x3+e*exp(0.1*x1-0.3*x2+0.2*x3)

	local rmin    = -5
	local rmax    =  5.5
	local width5   = (`rmax'-`rmin')/ 5
	local width15  = (`rmax'-`rmin')/15

	gen lmin5  = .   if y <`rmin'
	gen lmin15 = .   if y <`rmin'
	gen lmax5  = `rmin'  if y <`rmin'
	gen lmax15 = `rmin'  if y <`rmin'

	replace lmin5  = `rmax'   if y >`rmax'
	replace lmin15 = `rmax'   if y >`rmax'
	replace lmax5  = .        if y >`rmax'
	replace lmax15 = .        if y >`rmax'

	foreach i in 5   15 {
		forvalues j = 1/`i' {
			replace lmin`i'  = `rmin'+`width`i''*(`j'-1)   if inrange(y,`rmin'+`width`i''*(`j'-1),`rmin'+`width`i''*(`j'))
			replace lmax`i'  = `rmin'+`width`i''*(`j')   if inrange(y,`rmin'+`width`i''*(`j'-1),`rmin'+`width`i''*(`j'))
		}
	}

	global xv0 
	global xv3 x1 x2 x3

	foreach i in 0 3 {
		intreg lmin5  lmax5 ${xv`i'}  , het(${xv`i'})
		intreg_mi m5c`i'
		gen y5c`i'=.
		intreg lmin15 lmax15 ${xv`i'} , het(${xv`i'})	 
		intreg_mi m15c`i'
		gen y15c`i'=.
	}

	local toset
	foreach i in 0 3 {
	 local toset `toset' y5c`i'= m5c`i'* 	 y15c`i'=m15c`i'*
	}
	tempfile save
	save `save'
	mi import wide, imputed(`toset')

	qrprocess y x1 x2 x3, q(.10 .5 .9)
	matrix b1=e(b)
	mi estim, post cmdok:qrprocess y5c0 x1 x2 x3, q(.10 .5 .9)
	matrix b2=e(b)
	mi estim, post cmdok:qrprocess y15c0 x1 x2 x3, q(.10 .5 .9)
	matrix b3=e(b)

	mi estim, post cmdok:qrprocess y5c3 x1 x2 x3, q(.10 .5 .9)
	matrix b4=e(b)
	mi estim, post cmdok:qrprocess y15c3 x1 x2 x3, q(.10 .5 .9)
	matrix b5=e(b)

	local nb1 = "fq10 "*4 
	local nb2 = "fq50 "*4 
	local nb3 = "fq90 "*4
	matrix coleq b1 = `nb1' `nb2' `nb3'

	forvalues 1 = 2/5 {
	local nb1 = "s`1'q10 "*4 
	local nb2 = "s`1'q50 "*4 
	local nb3 = "s`1'q90 "*4
	matrix coleq b`1' = `nb1' `nb2' `nb3'
	}
	
	matrix b = b1,b2,b3,b4,b5
	ereturn post b
end
 
parallel initialize 10
parallel sim, reps(2500):sim
save sim_cov2.dta, replace

