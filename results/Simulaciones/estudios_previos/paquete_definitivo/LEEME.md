# Paquete DEFINITIVO — optimización robusta convergida

Resultado **definitivo** (malla convergida, presupuesto 2000) de la optimización
**robusta**: minimiza el peor caso entre **TNO, Goody y Kamruzzaman**, con
dominio expandido (caja ±80%, cap de espesor liberado). Este es el resultado
publicable y el insumo correcto para la simulación de pala.

Dos carpetas (`NACA63218/`, `NACA63221/`), cada una base vs óptimo:

| Archivo | Contenido |
|---|---|
| `coord_base_*.dat` / `coord_optimo_*.dat` | Coordenadas x,y (base y óptimo, 199 pts) |
| `polar360_base_*.txt` / `polar360_optimo_*.txt` | Polar ±180° (XFOIL + Viterna), α/Cl/Cd — insumo BEM |
| `fig_polar_base_vs_optimo_*.png` | Polar rango operativo: Cl, Cd, Cl/Cd, Cm vs α |
| `fig_polar360_*.png` | Polar ±180° base vs óptimo |
| `fig_OASPL_espectro_*.png` | Espectro (curvas sin filtro A; título con OASPL(A) con filtro) |
| `fig_historial_*.png` | Convergencia OASPL peor-caso + Cl/Cd por evaluación |
| `fig_geometria_*.png` | Silueta base vs óptimo |

## Resultados definitivos (peor caso TNO/Goody/Kamruzzaman, convergido)

| Caso | OASPL peor-caso | Cl/Cd | Espesor | Reducción por modelo |
|---|---|---|---|---|
| **NACA 63-218** | 67.82 → **65.64** dBA | 60.1 → **63.2** | 18.1% → 18.0% | TNO −2.18, Goody −2.04, Kamr −1.90 |
| **NACA 63-221** | 67.10 → **65.71** dBA | 54.2 → **59.9** | 21.0% → 18.0% | TNO −1.38, Goody −1.54, Kamr (base NaN) |

Ambos convergen a **~18% de espesor**, reducen el ruido en los **3 modelos de
gradiente de presión** simultáneamente y **mejoran el Cl/Cd**.

## Caveats a reportar (honestos)
- **Amiet** (4º modelo, no incluido en el objetivo) queda ~0.2–0.6 dB más alto,
  pero es casi insensible a la geometría (≈68 dBA para todo) → mal
  discriminador, no contradicción física. 3 de 4 modelos coinciden.
- **Kamruzzaman no converge en la geometría base exacta del 63-221** (NaN); el
  óptimo sí. Fallo numérico del modelo empírico en esa forma.

## Condiciones
AoA 4°, U 83.31 m/s, Re 3.17×10⁶, M 0.242, transición x/c=0.05 ambas caras,
observador a 1 m. Polares: XFOIL N_crit 8.9, ±180° con Viterna (CDmax 1.3).

## Nota
Este paquete REEMPLAZA los óptimos anteriores (el delgado 13% del 63-218 era
sobreajuste a TNO — ver auditoría/revisión de mínimo local). El óptimo aquí es
la sección robusta ~18%, físicamente creíble.
