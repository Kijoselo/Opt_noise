# ⚠️ AVISO: los archivos AFnaca*_Coords.dat tienen los nombres INTERCAMBIADOS

Verificado numéricamente el 2026-07-10 (interpolación de superficies sobre malla común):

| Archivo | Espesor máx. real | Identidad real |
|---|---|---|
| `AFnaca633221_Coords.dat` | 0.180 c @ x/c 0.35 | Perfil del **18 %** (≈ `NACA63218.txt`, máx dif. 0.004 c por remuestreo a 50 pts) |
| `AFnaca633218_Coords.dat` | 0.210 c @ x/c 0.35 | Perfil del **21 %** (**idéntico punto a punto** a `NACA63221.txt`, dif. 0.00000) |

## Implicaciones

- Todos los artefactos con sufijo `AFnaca633221_Coords` (figuras, `optimized_*_hardcon.dat`,
  `pareto_*`, `study_cases/opt_*`) pertenecen en realidad al perfil del **18 %**, y los
  `AFnaca633218_Coords` al del **21 %**. NO usar estas etiquetas en el manuscrito.
- El caso del manuscrito usa los `.txt` oficiales (61 puntos, más densos), que están
  correctamente nombrados: `NACA63221.txt` = 21 %, `NACA63218.txt` = 18 %.
- Los archivos crudos AFnaca (50 pts + punto de referencia AeroDyn) NO convergen en XFOIL
  evaluados directamente; solo sus proyecciones CST son utilizables.

## Dato útil que dejó el ejercicio

`AFnaca633218_Coords.dat` ≡ `NACA63221.txt` (misma geometría) pero con 50 vs 61 puntos:

- baseline OASPL(A): 67.588 vs 67.10 dBA  → **0.49 dB de sensibilidad solo por muestreo**
- baseline Cl/Cd:    57.75  vs 54.17

Sirve como nota de robustez/limitación: la predicción de ruido es hipersensible a la
definición geométrica (diferencias de ajuste CST < 1e-3 c mueven ~0.5 dB el baseline).
