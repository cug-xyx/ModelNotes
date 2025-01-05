// #import "../typst/lib.typ": *
#import "@preview/modern-cug-report:0.1.0": *

#show: (doc) => template(doc, 
  size: 11.5pt,
  footer: "Author: Yuxuan Xie",
  header: "CMRSET模型结构")
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


= CMRSET蒸散发模型

CMRSET（CSIRO MODIS ReScaled EvapoTranspiration）蒸散发模型利用MODIS数据将潜在蒸散发（PET）重新约束至实际蒸散发（ET）。

- P
- ET0
- EVI
- GVMI

== 计算方式

CMRSET模型涉及参考作物蒸散发（$"ET"_0$）系数$k_c$和类似于作物蒸发拦截系数的 kEi：

$ "ET"_"a" = k_c times "ET"_0 + k_"Ei" $

式中，$P$为降水。

$k_"Ei"$是使用归一化的增强植被指数EVI计算得到的：

$ "EVI"_r = ("EVI" - "EVI"_"min") / ("EVI"_"max" - "EVI"_"min") $

式中，$"EVI"_"min" = 0$，$"EVI"_"max" = 0.9$。$"EVI"_r$通过校准系数$k_"Eimax" = 0.229$进行缩放，如下所示：

$ k_"Ei" = k_"Eimax" times "EVI"_r $

$ "RMI" = max(0, "GVMI" - (K_"RMI" times "EVI" + C_"RMI")) $

式中，$K_"RMI" = 0.755$，$C_"RMI" = -0.076$。

$ k_c = k_"cmax" times (1 - exp(-a times "EVI"_r^alpha - b times "RMI"^beta)) $

式中，$k_"cmax" = 0.69$，$a = 14.12$，$alpha = 2.482$，$b = 7.991$，$beta = 0.89$。

== References:

1. On the interchangeability of Landsat and MODIS data in the CMRSET actual evapotranspiration model - Comment on “Monitoring irrigation using Landsat observations and climate data over regional scales in the Murray-Darling Basin” by David Bretreger, In-Young Yeo, Greg Hancock and Garry Willgoose. Journal of Hydrology. (https://doi.org/10.1016/j.jhydrol.2021.127044)