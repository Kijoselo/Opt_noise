# Paquete de revisión — base vs óptimo (NACA 63-218 y 63-221)

Paquete para **revisar todo el análisis comparando base contra óptimo**. El
óptimo de cada caso es el de **dominio expandido + objetivo robusto**
(minimiza el peor caso entre TNO, Goody y Kamruzzaman) — la versión final,
físicamente creíble y con geometría sensata.

Dos carpetas, una por perfil: **`NACA63218/`** y **`NACA63221/`**. Cada una
contiene, base y óptimo lado a lado:

| Archivo | Contenido |
|---|---|
| `coord_base_NACA****.dat` | Coordenadas x,y del **perfil base** (CST, 199 pts, Selig) |
| `coord_optimo_NACA****.dat` | Coordenadas x,y del **perfil óptimo** (199 pts, Selig) |
| `polar_base_NACA****.txt` | **Polar analizada** del base: α, Cl, Cd, Cdp, Cm (XFOIL) |
| `polar_optimo_NACA****.txt` | Polar analizada del óptimo: α, Cl, Cd, Cdp, Cm |
| `fig_polar_base_vs_optimo_NACA****.png` | Polares comparadas: Cl, Cd, Cl/Cd, Cm vs α (base negro, óptimo rojo) |
| `fig_OASPL_espectro_NACA****.png` | **Espectro OASPL** base vs óptimo: banda estrecha, 1/3-octava, ΔSPL por banda |
| `fig_historial_NACA****.png` | **Historial de optimización**: OASPL peor-caso vs evaluación + Cl/Cd vs evaluación |
| `fig_histograma_NACA****.png` | **Histograma** de diseños cercanos al óptimo (la "meseta") |
| `fig_geometria_NACA****.png` | Geometría del óptimo dentro de la banda alcanzable expandida |

## Condiciones (todas las evaluaciones)
AoA 4°, U 83.31 m/s, Re 3.17×10⁶, M 0.242, transición forzada x/c=0.05 (ambas
caras), observador a 1 m sobre el borde de fuga. Polares: XFOIL, N_crit 8.9.

## Resultados (peor caso TNO/Goody/Kamruzzaman)

| Caso | OASPL peor-caso | Cl/Cd | Espesor t/c | Qué hizo |
|---|---|---|---|---|
| NACA 63-218 | 67.82 → **65.78** dBA | 60.1 → **61.5** | 18.1% → **19.0%** | engrosó |
| NACA 63-221 | 67.10 → **65.79** dBA | 54.2 → **59.0** | 21.0% → **18.5%** | adelgazó |

Ambos convergen a la **misma sección** (~18.5–19%, alto camber adelantado) y
reducen el ruido **en los tres modelos** simultáneamente, mejorando además el
Cl/Cd. La reducción es físicamente creíble (no sobreajuste a un solo modelo).

## Notas
- El óptimo es el de **dominio expandido** (caja ±80%, cap de espesor liberado):
  se dejó que el perfil pudiera engrosar por encima del base, no solo adelgazar.
- Determinismo verificado: la optimización reproduce el mismo resultado al
  re-correr.
- El baseline en las figuras de geometría se dibuja del archivo oficial (nariz
  con pocos puntos); la geometría evaluada es la proyección CST suave (fidelidad
  vs XFOIL 4.2×10⁻⁴c, auditada).
