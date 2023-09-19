sum ylab
gen logylab = log(ylab)
keep if logylab!=.
rename s02a_02 sex
rename s02a_03 age
gen rel_other = 0
replace rel_other =1 if !inlist(s02a_05,1,2)
gen lang = 0
replace lang =1 if (s02a_08==6   |  s02a_08>30)   & s02a_08!=.
drop2 mstat
gen mstat = 1 if s02a_10==1
replace mstat = 2 if s02a_10==2 | s02a_10==3
replace mstat = 3 if mstat ==.
reg logylab i.area i.sex age i.rel_other i.lang i.mstat i.depto