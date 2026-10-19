# Informe: funcionamiento y manejo del código de optimización aeroacústica

**Proyecto:** `Opti_Param_ruidoio/work/Amiet-Theory-for-TE-Noise/`
**Caso actual:** NACA 63-221 oficial (`NACA63221.txt`), AoA 4°, U = 83.31 m/s, Re = 3.17×10⁶
**Requisitos:** MATLAB (con Global Optimization Toolbox) + `xfoil.exe` (incluido en la carpeta). Solo Windows.

---

## 1. Arquitectura general: dos capas

```
┌────────────────────────────────────────────────────────────┐
│  CAPA DE OPTIMIZACIÓN  (carpeta optim/ — código nuestro)    │
│  parametrización CST · restricciones · optimizadores ·      │
│  figuras · auditoría                                        │
└──────────────────────────┬─────────────────────────────────┘
                           │ llama a evaluate_airfoil(perfil)
┌──────────────────────────▼─────────────────────────────────┐
│  CÓDIGO DE RUIDO ORIGINAL (raíz — NO MODIFICADO)            │
│  XFOIL → TNO-Blake → Amiet + Roger-Moreau → OASPL(A)        │
└────────────────────────────────────────────────────────────┘
```

- **La física del ruido nunca se toca.** Está verificado (diff contra el ZIP
  original) que los ~45 archivos `.m` del modelo de ruido son idénticos al
  código original de la profesora. Todo lo nuestro vive en `optim/`.
- La capa de optimización trata al código de ruido como **caja negra**: le pasa
  un archivo de coordenadas y recibe OASPL(A), Cl, Cd, Cm y los espectros.

## 2. Cadena de predicción de ruido (por evaluación)

1. `inputs_definition.m` — define el caso (perfil, cuerda, U, AoA, transición,
   observador, fluido). **Es el único archivo de la raíz que se edita** para
   cambiar condiciones.
2. `XFOIL_new_airfoil.m` — ejecuta `xfoil.exe` (viscoso, transición forzada
   0.05) y extrae los parámetros de capa límite en x/c = 0.99 y los
   coeficientes Cl, Cd, Cm. Protegido con timeout de 20 s (mata XFOIL si un
   perfil degenerado lo cuelga).
3. `Boundary_layer_characteristics.m` + `surface_pressure_spectrum.m` (TNO-Blake)
   — espectro de presión de pared Φpp en ambas superficies.
4. `wavesnumbers.m`, `Radiation_integral*.m`, `spanwise_corlength.m` — teoría de
   Amiet con corrección de retrodispersión (Roger-Moreau) → espectro de campo
   lejano S_pp en el observador (0,0,1) m.
5. Ponderación A e integración 100 Hz–20 kHz → **OASPL(A)**, el objetivo.

Punto de entrada original: `Main_TE_noise_prediction.m` (script interactivo).
Para la optimización se usa el envoltorio funcional equivalente:

```matlab
[OASPL_A, Cl, Cd, out] = evaluate_airfoil('perfil.dat', inputs, fluid);
% out.f, out.S_pp (espectro), out.S_pp_s/S_pp_p (por superficie), out.Cm
```

## 3. Capa de optimización (`optim/`) — piezas clave

| Archivo | Función |
|---|---|
| `setup_problem.m` | Construye TODO el problema: ajusta CST orden 6 al perfil base (14 variables), define la caja ±50%, las restricciones y el contexto `ctx`. Evalúa el baseline. |
| `eval_airfoil_cached.m` | Evaluador central con caché (una llamada XFOIL compartida entre objetivo y restricción). Aplica los guardas: geometría válida (sin cruces, cap de espesor, frente≥cola) y **adherencia** (H ≤ 2.7, Cf ≥ 1.5e-4 en succión) — evita que el optimizador explote el modelo TNO fuera de su validez. |
| `obj_noise_pure.m` / `con_clcd.m` / `con_cl.m` | Objetivo OASPL(A) y restricciones no lineales (Cl/Cd ≥ base, Cl ≥ base). |
| `run_optimization.m` | **Caso principal**: pattern search con restricción dura Cl/Cd. `run_optimization(2000,'NACA63221.txt')`. |
| `run_multiobjective.m` | Frente de Pareto ruido vs Cl/Cd (gamultiobj). `run_multiobjective(40,30,'NACA63221.txt')`. |
| `compare_algorithms.m` | Benchmark GA/PSO/patternsearch/surrogateopt/SQP a presupuesto igual. |
| `sensitivity_analysis.m` | Barrido OAT de las 14 variables CST → tornado. |
| `compare_parameterizations.m` | CST vs PARSEC vs Hicks-Henne (error de reconstrucción). |
| Diagnósticos | `plot_mechanism` (geometría+Cp+Φpp), `boundary_layer_table` (tabla H/Cf/δ*), `regen_optimum_spectrum` (espectro 3 paneles), `plot_search_domain` (banda alcanzable del box CST), `silhouette_variation` (modos de forma). |
| `audit_optimization.m` | Auditoría: error de ajuste CST, actividad de límites del óptimo, re-evaluación de consistencia, restricciones activas. |
| `savefig300.m` / `collect_figures.m` | Exportación 600 dpi tamaño revista y copia a `paper/figures/`. |

**Convención por-caso:** todos los artefactos llevan el nombre del perfil:
`cst_baseline_<caso>.dat`, `optimized_<caso>_hardcon.dat`, `fig_*_<caso>.png`.
Así se pueden estudiar varios perfiles sin que se mezclen resultados. Solo el
caso del manuscrito (NACA63221) refresca además las figuras genéricas del paper.

## 4. Cómo se maneja (recetas)

```matlab
cd('C:\...\work\Amiet-Theory-for-TE-Noise'); addpath('optim');

% (a) Evaluar el ruido de UN perfil (p. ej. para la pala):
[fluid, inputs] = inputs_definition();
[OASPL, Cl, Cd, out] = evaluate_airfoil('mi_perfil.dat', inputs, fluid);

% (b) Optimizar un perfil (caso completo del paper):
run_optimization(2000, 'NACA63221.txt');     % guarda optimized_<caso>_hardcon.dat

% (c) Diagnósticos y figuras del resultado:
plot_mechanism('NACA63221.txt'); boundary_layer_table('NACA63221.txt');
regen_optimum_spectrum('NACA63221.txt');

% (d) Auditar que todo es consistente:
audit_optimization({'NACA63221.txt'});
```

**Ejecución desatendida** (sin abrir MATLAB, ideal para corridas largas):
```
"C:\Program Files\MATLAB\R2025b\bin\matlab.exe" -batch ^
  "cd('C:\...\Amiet-Theory-for-TE-Noise'); addpath('optim'); run_optimization(2000,'NACA63221.txt')"
```

**Para cambiar el caso de operación** (otra velocidad, AoA, cuerda): editar
`inputs_definition.m` (sección "test case parameters") y re-correr. El framework
es agnóstico al perfil: cualquier `.dat`/`.txt` Selig sirve como base.

## 5. Cosas que NO deben tocarse / gotchas conocidos

- **No modificar** los `.m` de física: `TNO.m`, `surface_pressure_spectrum.m`,
  `wavesnumbers.m`, `Boundary_layer_characteristics.m`, `Radiation_integral*.m`,
  `XFOIL_new_airfoil.m` (salvo el wrapper de timeout ya incluido), etc.
- **Higiene XFOIL:** si una corrida falla a medias, puede quedar un
  `POLAR_OUTPUT` huérfano que desincroniza la siguiente llamada. El evaluador lo
  limpia solo; si se llama `evaluate_airfoil` a mano tras un fallo, borrar
  `POLAR_OUTPUT` antes.
- **Archivos AFnaca\*.dat: los nombres están intercambiados** (verificado:
  `AFnaca633221` es el 18% y `AFnaca633218` es el 21% ≡ `NACA63221.txt`). Ver
  `AFNACA_SWAP_NOTE.md`. Usar siempre los `.txt` oficiales.
- **Sensibilidad al muestreo:** la misma geometría con 50 vs 61 puntos cambia el
  baseline ~0.5 dB. Usar siempre el archivo de coordenadas más denso disponible.
- La reducción reportada es **condicional a la caja de diseño ±50%** (no es un
  piso físico: ±30% → 1.02 dBA, ±50% → 1.28, ±70% → 1.74 con geometrías cada vez
  más alejadas de la familia).

## 6. Resultados vigentes (corrida definitiva, presupuesto 2000, convergida)

| | OASPL(A) | Cl | Cd | Cl/Cd | Cm | tmax/c |
|---|---|---|---|---|---|---|
| Base (CST) | 67.10 dBA | 0.630 | 0.0116 | 54.2 | −0.038 | 0.210 |
| **Optimizado** | **65.82 dBA** | 0.713 | 0.0130 | 54.8 | −0.013 | 0.205 |

Reducción **1.28 dBA (~26% de energía A)** manteniendo el espesor (reforma de
curvatura, no adelgazamiento). Mecanismo: el lado de presión domina el nivel
absoluto, pero la succión aporta ~58% de la reducción de energía. El manuscrito
(`work/.../paper/manuscript.tex` + `refs.bib` + `figures/`) está completamente
actualizado a estos números; se compila en Overleaf.
