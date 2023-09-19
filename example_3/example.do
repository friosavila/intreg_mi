clear all

ssc install qrprocess, replace
ssc install rif, replace
ssc install palettes, replace
ssc install colrspace  , replace
ssc install grstyle, replace
ssc install color_style, replace
net install fra, from(https://friosavila.github.io/stpackages)
fra install lbsvmat, replace
ssc install frause


** Load Data
use https://data.nber.org/morg/annual/morg18, clear
drop if earnhre==.

gen mstatus = 1 if inlist(marital,1,2,3)
replace mstatus = 2 if marital == 7 
replace mstatus = 3 if mstatus ==.
 
** Analyzing Hourly wages
** First create logHourly wages
gen logwage = log(earnhre/100)
** vet
gen vet0 = 0
replace vet0 = 1 if vet1==1 | vet2==1 | vet3==1 | vet4==1 

** Data is censored on high wages. but will assume its 
** Define number of groups: local g
sum logwage, meanonly
local mmin=r(min)
local mmax=r(max)

** Equidistant groups
foreach g in 5 7 10 {
    local delta = (`mmax' - `mmin')/`g'
    gen logwage`g' = 0
    gen logwage`g'_min = .
    gen logwage`g'_max = .
    forvalues i = 1/`g' {
        replace logwage`g' = logwage`g'+1 if logwage>=`mmin'+(`i'-1)*`delta' 
        replace logwage`g'_min = `mmin'+(`i'-1)*`delta' if logwage`g'==`i'
        replace logwage`g'_max = logwage`g'_min+`delta'  if logwage`g'==`i'
        if `i'== 1 replace logwage`g'_min=.  if logwage`g'==`i'
        if `i'==`g' replace logwage`g'_max=. if logwage`g'==`i'
    }
}  

gen age2 = (age-40)*(age-40)
gen 	raced = 1 if race==1
replace raced = 2 if race==2
replace raced = 3 if raced==.

gen 	hgrade = 1 if grade92<=38  
replace hgrade = 2 if inlist(grade92,39)
replace hgrade = 3 if inlist(grade92,40)
replace hgrade = 4 if inlist(grade92,41,42,43)
replace hgrade = 5 if inlist(grade92,44,45,46)


gen hourslw2=hourslw^2
gen less35 = hourslw<35
global indepvar  minsamp age age2 i.sex i.hgrade  i.otc i.unionmme ///
				 chldpres ownchild i.pfamrel i.mstatus

 foreach i in 5 7 10 {
    global depvar   logwage`i'_min logwage`i'_max 
    qui:intreg $depvar $indepvar [pw=earnwt ], het($indepvar)
    intreg_mi i`i'var, seed(111)
    gen ivar`i'=.
    local toimp `toimp' ivar`i' = i`i'var*
}

save tosave, replace
use tosave, replace

** Import Data into mi
 foreach i in 5 7 10 {
 
    local toimp `toimp' ivar`i' = i`i'var*
}
mi import wide, imputed(`toimp')


capture matrix drop _all
** Estimates Baseline model using Cqreg and uqreg
global depvar0 logwage
global indvar0 age age2 i.sex i.hgrade  i.unionmme i.mstatus chldpres

forvalues i = 5(5)95 {
	local ii = `i'/100
	qrprocess     $depvar0 $indvar0 [pw=earnwt ] , q(`ii') 
	qui:ereturn display
	matrix cqr = nullmat(cqr)\r(table)',J(12,1,`i')
	rifhdreg $depvar0 $indvar0 [pw=earnwt ], rif(q(`i'))
	matrix uqr = nullmat(uqr)\r(table)',J(16,1,`i')
}

foreach j in 5 7 10 {
	forvalues i = 5(5)95 {
		local ii = `i'/100
		mi estimate, cmdok post:qrprocess     ivar`j' $indvar0 [pw=earnwt ], q(`ii')  
		matrix i`j'cqr = nullmat(i`j'cqr)\r(table)',J(12,1,`i')
		mi estimate, cmdok post:rifhdreg ivar`j' $indvar0 [pw=earnwt ], rif(q(`i'))
		matrix i`j'uqr = nullmat(i`j'uqr)\r(table)',J(16,1,`i')
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
	foreach i in 2.unionmme 2.sex 5.hgrade age {
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