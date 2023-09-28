capture program drop sim_interval
program sim_interval, eclass
syntax, [nobs(int 1000) bracket(int 5) utype(int 1)]

*** Data Setup
clear
    set obs `nobs'
    gen x1 =runiform()>.5
    gen x2 =rchi2(5)/5
    gen u1 = rnormal()
    gen u2 = (rchi2(5)-5)/sqrt(10)
    
    gen y1 =  x1 + x2 + u1 *exp(.4-0.2*x1+.1*x2 )
    gen y2 =  x1 + x2 + u2 *exp(.4-0.2*x1+.1*x2 )
    
    local rmin1 = -2.5
    local rmax1 = 5.5
    
    local rmin2 = -1.5
    local rmax2 = 6.7
    
    ***
    local toimpute    
    //local bracket = 5
    foreach i in 5 15 {
        foreach j in 1 2 {
            local bw`j' = (`rmax`j''-`rmin`j'')/`i'
            capture drop lmin`j' lmax`j'
 
            gen lmin`j'  = .            if y`j' <`rmin`j''
            gen lmax`j'  = `rmin`j''    if y`j' <`rmin`j''
        replace lmin`j'  = `rmax`j''    if y`j' >`rmax`j''
        replace lmax`j'  = .            if y`j' >`rmax`j''

    
            forvalues k = 1/`i' {
                replace lmin`j' = `rmin`j''+(`k'-1)*`bw`j'' if inrange(y`j',`rmin`j''+(`k'-1)*`bw`j'',`rmin`j''+(`k')*`bw`j'')
                replace lmax`j' = `rmin`j''+(`k'  )*`bw`j'' if inrange(y`j',`rmin`j''+(`k'-1)*`bw`j'',`rmin`j''+(`k')*`bw`j'')
            }
            intreg lmin`j' lmax`j' c.x1 c.x2, het(c.x1 c.x2)
            intreg_mi b`i't`j'_, replace
            gen yb`i't`j'=.
            local toimpute `toimpute' yb`i't`j' = b`i't`j'_*
        }        

    }
    
    tempfile tosave
    save `tosave'
    
    mi import wide, imputed(`toimpute')
    
    qrprocess y1 x1 x2 , q(.10 .5 .9)
    matrix b1=e(b)
	qrprocess y2 x1 x2 , q(.10 .5 .9)
    matrix b2=e(b)
    mi estim, post cmdok:qrprocess  yb5t1 x1 x2 , q(.10 .5 .9)
    matrix b3=e(b)
    mi estim, post cmdok:qrprocess  yb5t2 x1 x2 , q(.10 .5 .9)
    matrix b4=e(b)

    mi estim, post cmdok:qrprocess  yb15t1 x1 x2 , q(.10 .5 .9)
    matrix b5=e(b)
    mi estim, post cmdok:qrprocess  yb15t2 x1 x2 , q(.10 .5 .9)
    matrix b6=e(b)

    local nb1 = "f1q10 "*3 
    local nb2 = "f1q50 "*3 
    local nb3 = "f1q90 "*3
    matrix coleq b1 = `nb1' `nb2' `nb3'

	local nb1 = "f2q10 "*3 
    local nb2 = "f2q50 "*3 
    local nb3 = "f2q90 "*3
    matrix coleq b2 = `nb1' `nb2' `nb3'
	
    forvalues 1 = 3/6 {
    local nb1 = "s`1'q10 "*3 
    local nb2 = "s`1'q50 "*3 
    local nb3 = "s`1'q90 "*3
    matrix coleq b`1' = `nb1' `nb2' `nb3'
    }
    
    matrix b = b1,b2,b3,b4,b5,b6
    ereturn post b
end    
 