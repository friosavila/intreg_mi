kdensity logp, gen(f) at(logp)
sum f
replace f=f/r(max)
replace f=f*4269
tabstat logp, by(price_g) stats(min max)
color_style winter, n(8)
 two histogram logp if price_g==1, w(.981) freq pstyle(p1) ///
				 ||  histogram logp if price_g==2, w(.405) freq pstyle(p2)  ///
				 ||  histogram logp if price_g==3, w(.286) freq pstyle(p3)  ///
				 ||  histogram logp if price_g==4, w(.223) freq pstyle(p4)  ///
				 ||  histogram logp if price_g==5, w(.182) freq pstyle(p5)  ///
				 ||  histogram logp if price_g==6, w(.287) freq pstyle(p6)  ///
				 ||  histogram logp if price_g==7, w(.222) freq pstyle(p7)  ///
				 ||  histogram logp if price_g==8, w(2.032) freq pstyle(p8)  ///
				 || (line f logp, sort color(black) ), ///
				 legend(order(1 "<200k"  2 "200K-300K" ///
							  3 "300K-400K"   4 "400K-500K" ///
							  5 "500K-600K"   6 "600K-800K" ///
							  7 "800K-1000K"  8 ">1000K" 9 "density")) ///
				 xlabel( `=log(100)' "100k" `=log(200)' "200k" `=log(300)' "300k" ///
				         `=log(400)' "400k" `=log(500)' "500k" `=log(600)' "600k"  `=log(800)' "800k" ///
						 `=log(1000)' "1000k" `=log(2000)' "2000k" , alt	 )	xtitle("") ///
						 title("Housing Prices in UK") xsize(8) ysize(5)
							  

display -4.317488+5.298317
display -5.298947 + 5.703783
display -5.705444 + 5.991465
       display -5.991964 + 6.214608
       display -6.214622 +  6.39693
       display -6.397929 + 6.684612
       display -6.685236 + 6.907755
       display -6.917706 + 8.948976
