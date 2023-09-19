clear all
** Load Packages
/*ssc install qrprocess, replace
ssc install palettes, replace
ssc install colrspace  , replace
ssc install grstyle, replace
ssc install color_style, replace
ssc install rif, replace
net install fra, from(https://friosavila.github.io/stpackages)
fra install lbsvmat, replace*/
** Load Data
frause oaxaca, clear

gen mstatus = 1     if single==1
replace mstatus = 2 if married==1
replace mstatus = 3 if divorced==.
 
** Analyzing Hourly wages
** Define number of groups: local g
sum lnwage, meanonly
local mmin=r(min)
local mmax=r(max)

** Equidistant groups
foreach g in 5 7 10 {
    local delta = (`mmax' - `mmin')/`g'
    gen lnwage`g' = 0
    gen lnwage`g'_min = .
    gen lnwage`g'_max = .
    forvalues i = 1/`g' {
        replace lnwage`g' = lnwage`g'+1 if lnwage>=`mmin'+(`i'-1)*`delta' 
        replace lnwage`g'_min = `mmin'+(`i'-1)*`delta' if lnwage`g'==`i'
        replace lnwage`g'_max = lnwage`g'_min+`delta'  if lnwage`g'==`i'
        if `i'== 1 replace lnwage`g'_min=.  if lnwage`g'==`i'
        if `i'==`g' replace lnwage`g'_max=. if lnwage`g'==`i'
    }
}  

 
 
global indepvar  educ exper tenure female age agesq i.mstatus
local toimp 
foreach i in 5 7 10 {
    global depvar   lnwage`i'_min lnwage`i'_max 
    qui:intreg $depvar $indepvar  , het($indepvar)
    intreg_mi i`i'var, seed(111)
    gen ivar`i'=.
    local toimp `toimp' ivar`i' = i`i'var*
}

save tosave, replace

use tosave, replace

mi import wide, imputed(`toimp')


capture matrix drop _all
** Estimates Baseline model using Cqreg and uqreg
global depvar0 lnwage
global indvar0 educ exper tenure female age

forvalues i = 5(5)95 {
	local ii = `i'/100
	qrprocess     $depvar0 $indvar0  , q(`ii') 
	qui:ereturn display
	matrix cqr = nullmat(cqr)\r(table)',J(6,1,`i')
	rifhdreg $depvar0 $indvar0  , rif(q(`i'))
	matrix uqr = nullmat(uqr)\r(table)',J(6,1,`i')
}

foreach j in 5 7 10 {
	forvalues i = 5(5)95 {
		local ii = `i'/100
		mi estimate, cmdok post:qrprocess     ivar`j' $indvar0  , q(`ii')  
		matrix i`j'cqr = nullmat(i`j'cqr)\r(table)',J(6,1,`i')
		mi estimate, cmdok post:rifhdreg ivar`j' $indvar0  , rif(q(`i'))
		matrix i`j'uqr = nullmat(i`j'uqr)\r(table)',J(6,1,`i')
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
	foreach i in educ exper female age {
    local ii = `ii'+1
 
    two (rarea     cqr5     cqr6 cqr10     if cqr_nm=="`i'", pstyle(p1) color(%50)) ///
        (line      cqr1          cqr10     if cqr_nm=="`i'", pstyle(p1) ) ///
        (rarea i`k'cqr5 i`k'cqr6 cqr10     if cqr_nm=="`i'", pstyle(p2) color(%50)) ///
        (line  i`k'cqr1      i`k'cqr10     if cqr_nm=="`i'", pstyle(p2) ), ///
        legend(order(1 "Fully Observed" 3 "Imputed") pos(12) ring(0) col(2))  ///
        xtitle(Quantile) title(`i')  name(cqr`ii', replace) ///
		title("Coeff of `i'") 

    two (rarea     uqr5     uqr6 uqr10     if uqr_nm=="`i'", pstyle(p1) color(%50)) ///
        (line      uqr1          uqr10     if uqr_nm=="`i'", pstyle(p1) ) ///
        (rarea i`k'uqr5 i`k'uqr6 uqr10     if uqr_nm=="`i'", pstyle(p2) color(%50)) ///
        (line  i`k'uqr1      i`k'uqr10     if uqr_nm=="`i'", pstyle(p2) ), ///
        legend(order(1 "Fully Observed" 3 "Imputed") pos(12) ring(0) col(2))  ///
        xtitle(Quantile) title(`i')  name(uqr`ii', replace) ///
		title("Coeff of `i'") 
  }     
  
  graph combine cqr1 cqr2 cqr3 cqr4, title("Conditional QREG: `k' groups")   imargin(tiny)
  graph export fig_`k'_cqr.png, width(2000) replace 
  graph combine uqr1 uqr2 uqr3 uqr4, title("Unconditional QREG: `k' groups") imargin(tiny)
  graph export fig_`k'_uqr.png, width(2000) replace  
} 