// #import "../typst/lib.typ": *
#import "@preview/modern-cug-report:0.1.0": *

#show: (doc) => template(doc, 
  size: 11.5pt,
  footer: "CUG水文气象学2024",
  header: "CABLE模型结构")
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


= CABLE陆面模式

== CABLE版本更新过程

- 2006,CABLEv1（https://www.cmar.csiro.au/e-print/open/kowalczykea_2006a.pdf）
  - CABLEv1的流程如图#[@fig_CABLE_diagram]。
- 2011,CABLEv1.4b（https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2010JG001385）
- 2018,CABLE-POP（https://gmd.copernicus.org/articles/11/2995/2018/#abstract）
- 2019,CABLEv2.3.4（https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2019MS001845）
  - 相比于CABLEv1.4b，CABLEv2.3.4的主要更新如下：
    1. 新的*气孔导度方案*，其中明确参数化了不同植被功能类型PFT的植物水分利用方案；
    2. 地下水模型和亚网格尺度的径流参数化方案；
    3. 一种基于空隙尺度模型的*新土壤蒸发公式*。

#figure(
  image("../images/LSM_CABLE_diagram.png", width: 50%),
  caption: [CABLE的流程图。]
) <fig_CABLE_diagram>

== 子网格划分

CABLE认为每个网格内可能由植被、裸地、雪和冰等地表元素组合而成。

== 感热与潜热通量

CABLE的水、热与动量等垂直涡度通量取决于空气动力学阻力的流动的平均特性。感热通量和潜热通量的一般形式为：

$ H / (rho_a c_p) =  macron(w' T') = -u_* T_* =  (T_"sur" - T_"ref") / r_H  $

$ E / rho_a =  macron(w' q') = -u_* q_* =  (q_"sur" - q_"ref") / r_E  $

- $u$、$T$、$q$分别为湍流尺度下的风速温度和湿度；
- 下标ref表示参考高度；
- 下标sur表示表面；
- $rho_a$：空气密度；
- $c_p$：比热容；
- $r_H$：空气动力学热阻力；
- $r_E$：水汽从表面交换至参考高度的阻力，包括空气动力学阻力和冠层气孔导度阻力；
- $macron(w' T')$：湍流热通量；
- $macron(w' q')$：湍流湿度通量；

在有冠层的地表系统中，总地表通量是从土壤（s）到冠层的通量与从冠层（c）到大气的通量之和：

$ H_T = H_s + H_c $

$ lambda E_T = lambda E_s + lambda E_c $

地表通量计算的核心是空气动力学阻力的参数化，这取决于对大气变量T和q的参考高度以及冠层空气动力学的描述。使用Monin-Obukhov相似理论对组合冠层系统的地表通量进行参数化，最低模型层位于地表层，地表通量在垂直方向上恒定。对粗糙度长度（z0）和参考高度（z）之间的通量分布关系进行积分，得出以下关系：

$ u(z) = (u_*) / (k) [ln(z/z_0) - psi_M (z / L_"MO") + psi_M (z_0 / L_"MP")] $

因此，摩擦速度的表达式可以写为：

$ u_* = (k U_"ref") / (ln(z_"ref"/z_0) - psi_M (xi) + psi_M (xi z_0 / z_"ref")) $

- $U_"ref"$：参考高度的风速；
- $k$：von Karman常数（=0.4）；
- $psi_M$：是稳定和不稳定条件下动量通量剖面关系的Businger-Dyer函数；
- $L_"MO"$：Monin-Obukhov稳定高度；
- $xi$：无量纲高度。

为了计算摩擦速度，必须计算无量纲高度$xi$，它是一个热稳定参数：

$ xi = z_"ref" / L_"MO" $

根据Garratt(1992)，$L_"MO"$被定义为：

$ L_"MO" = -u_*^3 / (k (g/T) macron(w' T')) = -u_*^3 / (k g (H_T) / (T rho_a c_p)) $

- $g$：重力常数；

将上式代入$xi$的计算公式，再加上潜热通量分数(Raupach et al., 1997)就得到了CABLE中使用的热稳定参数的公式：

$ xi = -z_"ref" k g (H_T + 0.07 lambda E_T) / (T_"ref" rho_a c_p u_*^3) $

式中，$H_T$和$lambda E_T$为总的地表显热和潜热通量。

通量和$xi$的计算在很大程度上取决于表面温度$T_"suf"$，同时$T_"suf"$也取决于$xi$，因此需要使用迭代方法进行计算。假设初始条件稳定，$xi = 0$，$T_c = T_"ref"$，$q_c = q_"ref"$。在计算阻力、通量和冠层温度后，从上式中获得新的$xi$。使用新的$xi$重新进行迭代，使用四次迭代获得稳定性参数、表面通量和冠层温度的最终值。

== 冠层蒸腾阻力

CABLE采用Ball-Berry-Leuning气孔导度模型：

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
  image("../images/LSM_Noah-MP_beta.png", width: 100%),
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