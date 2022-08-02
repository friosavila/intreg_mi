set scheme white2
color_style s2
gen d1=.
gen d2=.
gen d3=.
gen d4=.
label var d1 "x1[bt-bs]"
label var d2 "x1[bt-bs]"
label var d3 "x2[bt-bs]"
label var d4 "x2[bt-bs]"

replace d1=tcq10_b_x1  -scq10_b_x1
replace d2=tcq10_b_x1_h-scq10_b_x1_h
replace d3=tcq10_b_x2  -scq10_b_x2
replace d4=tcq10_b_x2_h-scq10_b_x2_h

joy_plot d1 d3 d2 d4, ///
legend(order(1 "x1 Het Error" 2 "x2 Het Error" 3 "x1 Hom Error" 4 "x2 Hom Error" ) row(1)) ///
 yline(0) fcolor(%51) violin name(m1, replace) title("CQ 10") range(-.3 .3) ylabel(-.3(.1) .3, format(%2.1f)) ///
 graphregion(margin(tiny))    

replace d1=tcq50_b_x1  -scq50_b_x1
replace d2=tcq50_b_x1_h-scq50_b_x1_h
replace d3=tcq50_b_x2  -scq50_b_x2
replace d4=tcq50_b_x2_h-scq50_b_x2_h

joy_plot d1 d3 d2 d4, ///
legend(order(1 "x1 Het Error" 2 "x2 Het Error" 3 "x1 Hom Error" 4 "x2 Hom Error" ) row(1)) ///
 yline(0) fcolor(%51) violin name(m2, replace) title("CQ 50") range(-.3 .3) ylabel(-.3(.1) .3, format(%2.1f)) ///
 graphregion(margin(tiny))  
 

replace d1=tcq90_b_x1  -scq90_b_x1
replace d2=tcq90_b_x1_h-scq90_b_x1_h
replace d3=tcq90_b_x2  -scq90_b_x2
replace d4=tcq90_b_x2_h-scq90_b_x2_h

joy_plot d1 d3 d2 d4, ///
legend(order(1 "x1 Het Error" 2 "x2 Het Error" 3 "x1 Hom Error" 4 "x2 Hom Error" ) row(1)) ///
 fcolor(%51) violin name(m3, replace) title("CQ 90") range(-.3 .3) ylabel(-.3(.1) .3, format(%2.1f)) ///
 graphregion(margin(tiny))    yline(0)
 grc1leg m1 m2 m3, row(1) nocopies name(xtra, replace)
 graph combine xtra, xsize(10) ysize(6)
 graph export nfig5.png, width(1000)