capture program drop sim_interval
program sim_interval, eclass
syntax, [nobs(int 1000) bracket(int 5) utype(int 1)]

*** Data Setup
clear
	set obs `nobs'
	gen x1 =runiform()>.5
	gen x2 =rchi2(5)/5
		if `utype'==1      gen u = rnormal()
	else if `utype'==2 gen u = (rchi2(5)-5)/sqrt(10)
	
	gen y =  x1 + x2 + u *exp(.6-0.5*x1+.1*x2 )
	
	local rmin = -3
	local rmax = 5.5
	//local bracket = 5
	local bw = (`rmax'-`rmin')/`bracket'

	gen lmin = .
	gen lmax = .

	replace lmax = `rmin' if y<=`rmin'
	replace lmin =  .     if y<=`rmin'
	replace lmax =  . 	  if y>=`rmax'
	replace lmin = `rmax' if y>=`rmax'

	forvalues i = 1/`bracket' {
		replace lmin = `rmin'+(`i'-1)*`bw' if inrange(y,`rmin'+(`i'-1)*`bw',`rmin'+(`i')*`bw')
		replace lmax = `rmin'+(`i'  )*`bw' if inrange(y,`rmin'+(`i'-1)*`bw',`rmin'+(`i')*`bw')
	}

** Imputation
	intreg lmin lmax c.x1 c.x2, het(c.x1 c.x2)
	intreg_mi mm, replace

	gen yhat= .
	tempfile tosave
	save `tosave'
	mi import wide, imputed(yhat= mm* )
	
	qrprocess y x1 x2, q(.10 .50 .90)
	matrix b1=e(b)
	mata:st_matrix("v1",diagonal(st_matrix("e(V)"))':^.5)
	mi estimate, cmdok post: qrprocess yhat x1 x2, q(.10 .50 .90)
	matrix b2=e(b)
	mata:st_matrix("v2",diagonal(st_matrix("e(V)"))':^.5)
	matrix coleq b1 =tcq10 tcq10 tcq10 tcq50 tcq50 tcq50 tcq90 tcq90 tcq90
	matrix coleq b2 =scq10 scq10 scq10 scq50 scq50 scq50 scq90 scq90 scq90
	matrix coleq v1 =setcq10 setcq10 setcq10 setcq50 setcq50 setcq50 setcq90 setcq90 setcq90
	matrix coleq v2 =sescq10 sescq10 sescq10 sescq50 sescq50 sescq50 sescq90 sescq90 sescq90
	matrix colname v1 = x1 x2 _cons x1 x2 _cons x1 x2 _cons
	matrix colname v2 = x1 x2 _cons x1 x2 _cons x1 x2 _cons
	matrix b= b1,b2
	matrix v= v1, v2
	
	
	rifhdreg y x1 x2, rif(q(10))
	matrix b1=e(b)
	mata:st_matrix("v1",diagonal(st_matrix("e(V)"))':^.5)
	mi estimate, cmdok post: rifhdreg yhat x1 x2, rif(q(10))
	matrix b2=e(b)
	mata:st_matrix("v2",diagonal(st_matrix("e(V)"))':^.5)	
	matrix coleq b1 =tuq10
	matrix coleq b2 =suq10
	matrix coleq v1 =setuq10
	matrix coleq v2 =sesuq10
	matrix colname v1 = x1 x2 _cons 
	matrix colname v2 = x1 x2 _cons 
	matrix b= b,b1,b2
	matrix v= v, v1, v2
	
	rifhdreg y x1 x2, rif(q(50))
	matrix b1=e(b)
	mata:st_matrix("v1",diagonal(st_matrix("e(V)"))':^.5)
	mi estimate, cmdok post: rifhdreg yhat x1 x2, rif(q(50))
	matrix b2=e(b)
	mata:st_matrix("v2",diagonal(st_matrix("e(V)"))':^.5)
	matrix coleq b1 =tuq50
	matrix coleq b2 =suq50
	matrix coleq v1 =setuq50
	matrix coleq v2 =sesuq50
	matrix colname v1 = x1 x2 _cons 
	matrix colname v2 = x1 x2 _cons 
	matrix b= b,b1,b2
	matrix v= v, v1, v2
	
	rifhdreg y x1 x2, rif(q(90))
	matrix b1=e(b)
		mata:st_matrix("v1",diagonal(st_matrix("e(V)"))':^.5)
	mi estimate, cmdok post: rifhdreg yhat x1 x2, rif(q(90))
	matrix b2=e(b)
		mata:st_matrix("v2",diagonal(st_matrix("e(V)"))':^.5)
	matrix coleq b1 =tuq90
	matrix coleq b2 =suq90
	matrix coleq v1 =setuq90
	matrix coleq v2 =sesuq90
	matrix colname v1 = x1 x2 _cons 
	matrix colname v2 = x1 x2 _cons 
	matrix b= b,b1,b2
	matrix v= v, v1, v2
	matrix b = b,v
	ereturn post b
	
end	
 
parallel initialize 10
parallel sim, reps(2500):sim_interval, bracket(2)
save sim_norm_2.dta, replace
parallel sim, reps(2500):sim_interval, bracket(5)
save sim_norm_5.dta, replace
parallel sim, reps(2500):sim_interval, bracket(10)
save sim_norm_10.dta, replace
parallel sim, reps(2500):sim_interval, bracket(15)
save sim_norm_15.dta, replace

parallel sim, reps(2500):sim_interval, bracket(2) utype(2)
save sim_chi2_2.dta, replace
parallel sim, reps(2500):sim_interval, bracket(5) utype(2)
save sim_chi2_5.dta, replace
parallel sim, reps(2500):sim_interval, bracket(10) utype(2)
save sim_chi2_10.dta, replace
parallel sim, reps(2500):sim_interval, bracket(15) utype(2)
save sim_chi2_15.dta, replace