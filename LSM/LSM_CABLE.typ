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

== 陆面过程的基本公式

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
- $macron(w' q')$：湍流湿度通量。

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

- $g$：重力常数。

将上式代入$xi$的计算公式，再加上潜热通量分数(Raupach et al., 1997)就得到了CABLE中使用的热稳定参数的公式：

$ xi = -z_"ref" k g (H_T + 0.07 lambda E_T) / (T_"ref" rho_a c_p u_*^3) $

式中，$H_T$和$lambda E_T$为总的地表显热和潜热通量。

通量和$xi$的计算在很大程度上取决于表面温度$T_"suf"$，同时$T_"suf"$也取决于$xi$，因此需要使用迭代方法进行计算。假设初始条件稳定，$xi = 0$，$T_c = T_"ref"$，$q_c = q_"ref"$。在计算阻力、通量和冠层温度后，从上式中获得新的$xi$。使用新的$xi$重新进行迭代，使用四次迭代获得稳定性参数、表面通量和冠层温度的最终值。

== 双大叶模型

CABLE采用双大叶模型，分别计算阳叶和阴叶的光合作用、冠层蒸腾和感热通量。
双大叶模型使用同一组方程来计算单片叶子的光合作用、冠层蒸腾和感热通量，但对所有阳叶和阴叶分别进行参数化。对于给定的叶子参数P，阳叶和阴叶对应的参数值计算如下：

$ P_"sunlit" = integral_0^Lambda p(lambda) f_"sun" (lambda) d lambda $

$ P_"shaded" = integral_0^Lambda p(lambda) (1 - f_"sun") (lambda) d lambda $

- $lambda$：累积叶面积指数LAI。

式中，$f_"sun"$为冠层内阳叶比例，其计算方式如下：

$ f_"sun" = exp(-k_b lambda) $

式中，$k_b$为黑叶树冠的直射辐射消光系数，其计算方式如下：

$ k_b (Theta) = G / cos(Theta) $

式中，$Theta$为太阳天顶角。G为叶片在垂直于太阳辐射入射方向的投影面积与实际叶片面积之比，可以近似计算为：

$ G = phi_1 + phi_2 cos(Theta) $

式中，$phi_1 = 0.5 - 0.633 chi$，$phi_2 = 0.977 (1 - 2 phi_1)$。其中$chi$是与叶角分布相关的经验系数，$chi = 0$表示球形叶角分布，$chi$越大，平均倾角越小。上述G的近似值适用于[-0.4,0.6]范围内的$chi$。

== 感热与潜热通量

在有冠层的地表系统中，总地表通量是从土壤（s）到冠层的通量与从冠层（c）到大气的通量之和：

$ H_T = H_s + H_c $

$ lambda E_T = lambda E_s + lambda E_c $

冠层能量平衡公式：

$ "Rn"_c = lambda E_c + H_c $

潜热通量采用Penman-Monteith公式：

$ lambda E_c = (s "Rn"_c + c_p rho_a D_a (G_h + G_r)) / (s + gamma (G_h + G_r) / G_w) $

式中，$s$为饱和水汽压与温度关系曲线的斜率，$gamma$为湿度计常数。

感热通量：

$ H_c = G_h c_p rho_a (T_f - T_a) $

式中，$G_w$、$G_h$和$G_r$分别为水、热和辐射的导度，$G_b$为边界层导度，$G_c$为CO2从细胞间隙到参考高度的总导度，它们的计算方式如下：

水导度：

$ 1/G_w = 1/G_a + 1/G_b + 1/G_"st" $

热导度：

$ 1/G_h = 1/G_a + 1/(n b_"bh" G_b) $

边界层导度：

$ G_b = G_"bu" + G_"bf" $

辐射导度：

$ G_r = 4 epsilon_f sigma_b T_a^3 \/ c_p $

总导度：

$ 1/G_c = 1/G_a + 1/(b_"bc" G_b) + 1/(b_"sc" G_"st") $

式中，$b_"bc" = 1.27$，$b_"sc"=1.57$，$b_"bh"=1.075$，对于双生叶来说$n=1$，对于下口叶来说$n=2$。有关边界层导度$G_b$的计算请参见Wang and Leuning(1998)。空气动力学导度$G_a$的计算方式如下：

$ G_a = u_* / r_"tc" $

式中，*$r_"tc"$为单个植被层的总阻力*。$G_r$为辐射导度，参见Wang and Leuning(1998)。

== 冠层蒸腾阻力

气孔导度采用Ball-Berry-Leuning模型：

$ G_"st" = G_0 / b_"sc" + (a f_w A_c) / (C_s (1 + D_s / D_"s0")) $

$G_0$是当叶片净光合作用为零时叶片对H2O的气孔导度。$D_s$为叶表面的水汽压差。$f_w$为描述土壤可以为植物提供的可用水量的经验系数，$a$和$D_"s0"$为经验常数（该方程适用于$a$、$D_"s0"$和$G_0$不同值的C3和C4植物）。

光合作用的气体扩散部分描述了从气孔到叶边界层扩散提供的的CO2：

$ A_c = b_"sc" G_"st" (C_s - C) = G_c (C_a - C) $

式中，$A_c$为净光合速率，$C_s$为叶表面的CO2浓度，$C$为叶片的胞间CO2浓度。

== 土壤蒸发阻力

土壤潜热和感热通量由整体传递关系得到：

$ H_s = rho c_p (T_s - T_"ref") \/ r_s $

$ lambda E_"sp" = lambda rho (q^*(T_s) - q_"ref") \/ r_s $

式中，$T_s$为土壤表面温度，*$r_s$为从土壤到冠层的空气动力学阻力*。$E_"sp"$为土壤潜在蒸散发。Penman-Monteith组合方程(Garratt,1992)为模型中的潜在蒸散发提供了另一种方案。在这种方案中，潜在蒸散发划分为能量和空气动力学对蒸发的贡献：

$$

== 土壤水运动

CABLE使用多层土壤模型,并采用Richards方程来求解土壤湿度，采用热传导方程来求解土壤温度。