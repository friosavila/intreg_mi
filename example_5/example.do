** required
/*
ssc install qrprocess, replace
ssc install rif, replace
ssc install palettes, replace
ssc install colrspace  , replace
ssc install grstyle, replace
ssc install color_style, replace
net install fra, from(https://friosavila.github.io/stpackages)
fra install lbsvmat, replace
ssc install frause
*/
** Load Data
use asec18.dta, clear
keep if gq==1
drop if offpov==99
** Drop Zero or Negative Income
drop if offtotval<=0

** Identify Families: Within same HH there could be multiple families
egen hhid = group(serial offtotval)

** Demographics
bysort hhid:gen fsize = _N
bysort hhid:egen child012       =sum(inrange(age,0,12))
bysort hhid:egen child1317      =sum(inrange(age,13,17))
bysort hhid:egen yadult1824     =sum(inrange(age,18,24))
bysort hhid:egen mwork2564      =sum(inrange(age,25,64)*(sex==1)*inlist(empstat,10,12))
bysort hhid:egen wwork2564      =sum(inrange(age,25,64)*(sex==2)*inlist(empstat,10,12))
bysort hhid:egen mnwork2564     =sum(inrange(age,25,64)*(sex==1)*!inlist(empstat,10,12))
bysort hhid:egen wnwork2564     =sum(inrange(age,25,64)*(sex==2)*!inlist(empstat,10,12))
bysort hhid:egen m65p           =sum(inrange(age,65,999)*(sex==1))
bysort hhid:egen w65p           =sum(inrange(age,65,999)*(sex==2))

bysort hhid:egen pphs =sum(educ>=71)
bysort hhid:egen ppba =sum(educ>=111)
bysort hhid:egen ppgrd =sum(educ>=123)


** Race
gen racex = 1 if race==100
replace racex = 2 if race==200
replace racex = 4 if racex==.
replace racex = 3 if hispan!=0


bysort hhid:egen sblack =sum((racex==2)/fsize)
bysort hhid:egen shispan =sum((racex==3)/fsize)
bysort hhid:egen sother =sum((racex==4)/fsize)

gen hrace=1 
replace hrace=2 if sblack==1
replace hrace=3 if shispan==1
replace hrace=4 if sother==1
replace hrace=5 if !inlist(sblack,0,1) | !inlist(shispan,0,1) | !inlist(sother,0,1)

label define hrace 1 "White HH"  2 "Black HH" 3 "Hispanic HH" 4 "Other HH" 5 "Mixed Race HH"
label values hrace hrace 

bysort hhid:egen nat_citizen = sum( (citizen==4)/fsize)
bysort hhid:egen not_citizen = sum( (citizen==5)/fsize)

bysort hhid:egen hdiff       = sum(diffany ==2)

** Creating Brackets for Income. Based on CPS Fam Income Brackets
gen grp = 1 
gen ll = .
gen uu = .
** May need to adjust Top income to avoid overshooting
local ll 0    5000 7500 10000 12500 15000 20000 25000 30000 35000 40000 50000 60000 75000 100000 150000 
local uu 5000 7500 10000 12500 15000 20000 25000 30000 35000 40000 50000 60000 75000 100000 150000  2234000

forvalues j = 1/16 {
    local wll:word `j' of `ll'
    local wuu:word `j' of `uu'
    replace grp = `j' if inrange(offtotval,`wll',`wuu')
    replace ll = `wll' if inrange(offtotval,`wll',`wuu')
    replace uu = `wuu' if inrange(offtotval,`wll',`wuu')
}

** Into logs
gen log_ll=log(ll)
gen log_uu=log(uu)

***
bysort hhid:egen educ_h = max(educ)
label values educ_h EDUC
replace educ_h = 71 if educ_h<71
** Keep only household data
bysort hhid:gen flag=_n
keep if flag==1


** Impute 

global vars child012  child1317 yadult1824 ///
            wwork2564 mwork2564 mnwork2564 wnwork2564 ///
            m65p w65p  ///
            pphs ppba ppgrd  ///
            i.hrace nat_citizen not_citizen hdiff ///
            10.ownershp i.region 2.metro 3.metro 4.metro
            
intreg log_ll log_uu $vars [pw=asecwth], het($vars) 

local ll 0    5000 7500 10000 12500 15000 20000 25000 30000 35000 40000 50000 60000 75000 100000 150000 
local uu 5000 7500 10000 12500 15000 20000 25000 30000 35000 40000 50000 60000 75000 100000 150000  2234000

forvalues j = 1/16 {
    local wll:word `j' of `ll'
    local wuu:word `j' of `uu'
    local wll = log(`wll')
    local wuu = log(`wuu')
     predict pr`j', pr(`wll',`wuu')
}

intreg_mi mhinc
gen mhhinc=.
tempfile temp
save `temp'

mi import wide , imputed(mhhinc=mhinc*)
** create a variable based on imputed ones (passive)
mi passive:gen ihhinc=exp(mhhinc)

gen povoff  = (offtotval<offcutoff)*100
mi passive:gen ipovoff =(ihhinc<offcutoff)*100
 

** Small Analysis

mean povoff [pw=asecwth*fsize], over(hrace)
matrix b=e(b)
matrix colname b = 1.hrace 2.hrace 3.hrace 4.hrace 5.hrace
matrix list b
adde repost b=b, rename
est sto m2a

mi estimate, post: mean ipovoff [pw=asecwth*fsize], over(hrace)
matrix b=e(b)
matrix colname b = 1.hrace 2.hrace 3.hrace 4.hrace 5.hrace
matrix list b
adde repost b=b, rename
est sto m2b


mean povoff [pw=asecwth*fsize], over(region)
matrix b=e(b)
matrix colname b = 11.region 12.region 21.region 22.region 31.region 32.region 33.region 41.region 42.region
matrix list b
adde repost b=b, rename
est sto m3a

mi estimate, post: mean ipovoff [pw=asecwth*fsize], over(region)
matrix b=e(b)
matrix colname b = 11.region 12.region 21.region 22.region 31.region 32.region 33.region 41.region 42.region
matrix list b
adde repost b=b, rename
est sto m3b

mean povoff [pw=asecwth*fsize], over(educ_h)
matrix b=e(b)
matrix colname b = 71.educ_h 73.educ_h 81.educ_h 91.educ_h 92.educ_h 111.educ_h 123.educ_h 124.educ_h 125.educ_h
matrix list b
adde repost b=b, rename
est sto m4a

mi estimate, post: mean ipovoff [pw=asecwth*fsize], over(educ_h)
matrix b=e(b)
matrix colname b = 71.educ_h 73.educ_h 81.educ_h 91.educ_h 92.educ_h 111.educ_h 123.educ_h 124.educ_h 125.educ_h
matrix list b
adde repost b=b, rename
est sto m4b

esttab m2a m2b using tbl1, se nostar mtitle("Fully Observed" "Imputed") nonum lab note("")

esttab m3a m3b using tbl2, se nostar mtitle("Fully Observed" "Imputed") nonum lab md note("")

esttab m4a m4b using tbl3, se nostar mtitle("Fully Observed" "Imputed") nonum lab md note("")