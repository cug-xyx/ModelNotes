// #import "../typst/lib.typ": *
#import "@preview/modern-cug-report:0.1.0": *

#show: (doc) => template(doc, 
  size: 11.5pt,
  footer: "CUG水文气象学2024",
  header: "Noah-MP模型结构")
#counter(heading).update(0)
#set par(leading: 1.24em)
#codly(number-format: none)
#show figure.caption: set par(leading: 0.7em)

#let pkg-table-figure(it) = {
  show table.cell.where(y: 0): strong
  // See the strokes section for details on this!
  let frame(stroke) = (x, y) => (
    left: 0pt, right: 0pt,
    // left: if x > 0 { 0pt } else { stroke },
    // right: stroke,
    // top: if y < 2 { stroke } else { 0pt },
    // bottom: stroke,
    top: 0pt,
    bottom: 0pt,
  )
  set table(
    // fill: (rgb("EAF2F5"), none),
    stroke: frame(rgb("21222C")),
    align: (x, y) => ( if x > 0 { center } else { left } )
  )
  it
}

#let table-figure(caption, img, width: 80%) = {
  pkg-table-figure[#figure(
    caption: [#caption #v(-0.8em)],
    table(image(img, width: width))
  )] 
  v(-1em)
}


= Noah-MP陆面模式

== 子网格划分

Noah-MP引入“半瓦片”子网格方案来表征地表异质性。考虑间隙概率，首先假设植被均匀分布在网格内，使用改进的双流近似计来算计算整个网格的短波辐射传输。对于长波辐射、潜热、显热和地表热通量则分别计算两个网格：$F_"veg"$：植被覆盖面积分数、$1 - F_"veg"$：裸地面积分数。

#figure(
  image("../images/Noah-MP_semitile.png", width: 100%),
  caption: [Noah-MP的“半瓦片”子网格方案示意图]
) <fig_Noah-MP_semitile>

== 感热与潜热通量

根据子网格划分方案，感热与潜热通量的计算公式如下：

$ H = (1 - F_"veg") H_"g,b" + F_"veg" (H_v + H_"g,v") $

$ "LE" = (1 - F_"veg") "LE"_"g,b" + F_"veg" ("LE"_v + "LE"_"g,v") $

- 下标$"g,v"$代表植被覆盖的地表部分；
- 下标$"v"$代表植被覆盖的植被部分；
- 下标$"g,b"$代表裸地覆盖的地表部分；

*每个感热部分的元素：*

$ H_"g,b" = rho C_p (T_"g,b" - T_"air")/ r_"ah" $

$ H_"g,v" = rho C_p (T_"g,v" - T_"ac")/ r_"ah,g" $

$ H_"v" = 2 (L_e + S_e) rho C_p (T_"v" - T_"ac")/ r_"b" $

- $rho$：空气密度（kg m-3）；
- $C_p$：干空气比热容（=1005 J kg-1 K-1）；
- $T_"air"$：参考高度的空气温度（K）；
- $T_"ac"$：冠层空气温度（可以根据$H_"g,v" + H_v = rho C_p (T_"ac" - T_"air") / r_"ah"$得到）；
- $r_"ah"$：空气动力学阻力 (= 1/($C_H U_"air"$))，其中$U_"air"$是参考高度处的风速，$C_H$是表面热交换系数；
- $r_"ah,g"$：冠层下方的空气动力学阻力(Niu and Yang, 2004)；
- $L_e$：有效LAI（$L_e = "LAI" times F_"veg"$）；
- $S_e$：有效SAI（茎面积指数，Stem area index），（$S_e = "SAI" times F_"veg"$）；
- $r_b$：每单位LAI的叶片边界层阻力(Brutsaert, 1982)

*每个潜热部分的元素：*

$ "LE"_"g,b" = (rho C_p) / gamma (e_"sat"(T_"g,b") h_g - e_"air") / (r_"aw" + r_"soil") $

$ "LE"_"g,v" = (rho C_p) / gamma (e_"sat"(T_"g,v") h_g - e_"ac") / (r_"aw,g" + r_"soil") $

$ "LE"_"v" = (rho C_p) / gamma (C_"e"^"w" + C_"t"^"w") (e_"sat" (T_v) - e_"ac") $

== 冠层蒸腾阻力

Noah-MP设计了两种气孔导度方案：

（1）Ball-Berry型：

$ "Ball-Barry p74" $

（2）Jarvis型：

$ "(Jarvis, 1976) p78" $

*对于控制植被蒸腾的土壤水分限制因子$beta$，共设计了三种方案：*

（1）基于土壤湿度（$theta$）的Noah型因子：

$ beta = sum_(i=1)^(N_(root)) (Delta z_i) / z_(root) min(1.0, (theta_"liq,i" - theta_"wilt")/(theta_"ref" - theta_"wilt") ) $

- $theta_"wilt"$：土壤凋萎点的土壤水分；
- $theta_"ref"$：参考土壤水分（接近田间持水量）；
- $N_"root"$：含有根系的土壤层总数；
- $z_"root"$：根系深度；

（2）CLM型因子(Oleon et al., 2004)，它是BATS因子(Yang and Dickinson, 1996)的改进版本：

$ beta = sum_(i=1)^(N_(root)) (Delta z_i) / z_(root) min(1.0, (psi_"wilt" - psi_i)/(psi_"wilt" - psi_"sat") ) $

- $psi_i$：第i层的土壤基质势（$psi_i = psi_"sat" (theta_"liq,i" / theta_"sat")$）；
- $psi_"sat"$：饱和基质势；
- $psi_"wilt"$：凋萎基质势（=-150 m）与植被和土壤类型无关；

（3）SSiB型因子(Xue et al., 1991)：

$ beta = sum_(i=1)^(N_(root)) (Delta z_i) / z_(root) min(1.0, 1.0 - e^(-c_2 ln(psi_"wilt" / psi_i)) ) $

- $c_2$：斜率因子，取值范围从作物的4.36到阔叶灌木的6.37（详见Xue et al. (1991)的表2）；

#figure(
  image("../images/Noah-MP_beta.png", width: 100%),
  caption: [Noah-MP中控制气孔导度的不同土壤水分限制因子在不同土壤质地下随土壤水分的变化情况。]
) <fig_Noah-MP_beta>

== 土壤蒸发阻力

*对于控制土壤蒸发的限制因子$alpha$，共设计了四种方案：*

（1）(Sakaguchi and Zeng, 2009)：

$ alpha = Z_"soil,dry" / D_"vap,red" $

式中，干土厚度计算如下：

$ Z_"soil,dry" = -Z_"soil" (1) times (e^([1-min(1,(W_"liq,soil" (1))/(theta_"soil,max" (1)))] ^ (R_"S,exp")) - 1) / (2.71828-1) $

减少的蒸汽扩散率计算如下：

$ D_"veg,red" = 2.2 times 10^(-5) times theta_"soil,max" (1) times theta_"soil,max" (1) times (1 - (theta_"soil,wilt" (1))/ (theta_"soil,max" (1))) ^ (2 + 3 / B_"exp" (1)) $

- $theta_"soil,wilt"$：土壤凋萎点的土壤水分；
- $B_"exp"$：土壤B指数参数；

（2）Sallers (1992)：

$ alpha = f_"snow" times 1.0 + (1 - f_"snow") times e ^ (8.25 - 4.225 times B_"evap") $

式中，土壤蒸发因子（$B_"evap"$）计算如下：

$ B_"evap" = max(0, (theta_"liq,soil" (1))/ (theta_"sat" (1)) ) $

- $theta_"liq,soil"$：土壤液态含水量；
- $theta_"sat"$：饱和土壤含水量；

（3）adjusted Sallers 1992 for wet soil：

$ alpha = f_"snow" times 1.0 + (1 - f_"snow") times e ^ (8.25 - 6.0 times B_"evap") $

（4）Sakaguchi and Zeng, 2009 adjusted by $f_"snow"$ weighting：

非雪部分的计算方式与方案（1）相同：

$ alpha_0 = Z_"soil,dry" / D_"vap,red" $

利用积雪权重进一步计算：

$ alpha = 1 / (f_"snow" times 1 / alpha_"snow" + (1-f"snow") times 1 / (max(0.001,alpha_0))) $

式中，$alpha_"snow"$为雪面对地面升华的阻力。

== 土壤水运动

// 早期的TESSEL采用的是Campbell（1974）土水势函数，而最新的版本采用的是Van Genuchten（1980）。

// #beamer-block[土壤质地数据来源于：FAO (FAO, 2003)。]

// 上图可以看到，在土壤含水量低于$theta_"pwp"$之后，$"CH"$的扩散系数和水力传导系数是被高估的。