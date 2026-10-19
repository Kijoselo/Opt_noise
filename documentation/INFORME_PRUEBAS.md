# Informe de pruebas de la reorganización (2026-10-19)

Entorno: Windows 11, MATLAB R2025b, XFOIL 6.99 (`bin/xfoil.exe`).
Informes automáticos: `results/logs/informe_pruebas_20261019_120038.txt` (todas las pruebas OK) y
`results/logs/informe_pruebas_20261019_124226.txt` (repetición tras las correcciones de la tarde;
todas OK, 31 s).

## 1. Validado

| Prueba | Cómo | Resultado |
|---|---|---|
| Sintaxis de los 129 archivos `.m` del proyecto | `test_dependencias` (`checkcode`) | OK, sin errores de análisis |
| Sin rutas absolutas ni `cd(parent)` en `src/` y `tests/` | `test_dependencias` (búsqueda de `C:\` y `cd(parent)` fuera de comentarios) | OK |
| Dependencias de 16 puntos de entrada dentro del proyecto | `matlab.codetools.requiredFilesAndProducts` | OK; toolboxes: MATLAB, Optimization, Global Optimization |
| Binario y datos clave presentes | `test_dependencias` | OK |
| Geometría: ajuste CST(6) de NACA 63-221 / 63-218, escritura/lectura `.dat`, espesor, `buscar_perfil` | `test_geometria` | OK (rms 2.2e-4 c y 5.3e-4 c; tmax/c 0.210) |
| **Reproducibilidad de la cadena de ruido** (6 perfiles: baselines oficiales y CST, óptimos de 63-221 y 63-218, niveles total y por lado) | `test_reproducibilidad`; valores de referencia obtenidos ejecutando el código original `work/Amiet-Theory-for-TE-Noise` en la misma sesión | OK, diferencias < 0.001 dB (67.107 / 67.097 / 65.815 / 67.754 / 67.818 / 65.636 dBA) |
| `Main.mlx` completo (secciones 1–6 con los interruptores por defecto: 9 llamadas a XFOIL, validación NACA 0012, 3 modelos WPS, diagnóstico TNO, registro, exportación) | `matlab.internal.liveeditor.executeAndSave` en modo batch | OK, sin errores; resultados embebidos en `Main.mlx`; exportación en `results/exports/20261019_121753_sesion_main/`; PDF en `documentation/Main_ejecutado.pdf` |
| `Main.mlx` es un Live Script auténtico | generado con `matlab.internal.liveeditor.openAndSave`; contenedor OPC con `matlab/document.xml` (título, encabezados, listas, ecuaciones LaTeX, bloques de código) y `matlab/output.xml` | OK |
| Scripts heredados de figuras/tablas en la nueva estructura: `silhouette_variation`, `compare_parameterizations`, `boundary_layer_table`, `plot_mechanism`, `fig_mechanism_aero_v2`, `regen_optimum_spectrum`, `fig_wps_delta_regen`, `fig_sens_modes_merged`, `fig_seed_boxplot_regen`, `fig_param_variables`, `verify_module2` | ejecución en batch, figuras en `results/figures/` | OK (11/11 corren sin error) |
| Salidas en las carpetas previstas | inspección tras la ejecución | figuras en `results/figures/`, temporales de XFOIL solo en `results/simulations/xfoil_work/`, exportaciones con marca de tiempo en `results/exports/` |
| **`run_optimization(15, 'NACA63221.txt')`** (2026-10-19 tarde) | batch; md5 de `data/optimized/optimized_NACA63221_hardcon.dat` antes/después | OK, 23 s, 8 XFOIL. `results/simulations/20261019_123401_opt_NACA63221/` con `optimized_NACA63221_hardcon.dat`, `resultado_optimizacion.mat`, `fig_silhouette_hardcon_*.png`, `fig_spectrum_hardcon_*.png`. 67.097 → 66.998 dBA (presupuesto de prueba). El óptimo publicado no cambió (md5 `91d8ee93…`). |
| **`run_multiobjective(6, 2, 'NACA63221.txt')`** | batch | OK, 24 s. `results/simulations/20261019_123723_pareto_NACA63221/` con `pareto_front_*.csv`, `pareto_designs_*.tex`, `resultado_pareto.mat`, `fig_pareto_front_*.png`, `fig_pareto_silhouettes_*.png`. (Una primera corrida falló por interferencia de un MATLAB interactivo que ejecutaba `Main.mlx` sobre el mismo `xfoil_work/`; ver `CAMBIOS.md` §8.) |
| **`sensitivity_analysis(3, 'NACA63221.txt')`** | batch | OK, 38 s, 19 XFOIL. `fig_sensitivity_tornado/curves/silhouettes.png` en `results/figures/`; `.mat` en `results/simulations/legacy_workspace/` (tras corregir la ruta de guardado). Los datos de 7 niveles del manuscrito se restauraron; la prueba quedó como `sensitivity_data_prueba_3niveles_20261019.mat`. |
| **`compare_algorithms(10)`** | batch (no admite `('budget',N)`) | OK, 157 s, 79 XFOIL; los 5 algoritmos (GA, PSO, PS, SBO, SQP) corren y producen `fig_algo_convergence/exploration/silhouettes.png` en `results/figures/`. Un fallo de convergencia de XFOIL en PSO se trató como diseño penalizado (comportamiento previsto). |
| **`review_studies`** | batch | OK, 85 s, 56 XFOIL. B1 reproduce la tabla TNO/Goody/Kamruzzaman (63-221: 67.097/65.815; 63-218: 67.818/65.762 dBA); B3 y B4 generan `fig_cfh_*.png` y `fig_offdesign_*.png`, ahora en `results/figures/`. |
| **`polar_360_simple('cst_baseline_NACA63218.dat','opt_NACA63218_definitivo.dat')`** | batch | OK tras corregir un `end` perdido en un comentario (antes no se podía ejecutar). 92 s, 72 XFOIL. `results/simulations/polares_360_NACA63218/` con `polar360_base.txt`, `polar360_optimizado.txt`, `fig_polar360.png`. |
| `fig_wps_delta_regen`, `fig_cfh_regen` | batch, tras redirigir sus figuras a `results/figures/` | OK, 19 s. |
| Dos sesiones de MATLAB en paralelo con `proyecto_init('xfoil_workdir', ...)` distinto | las corridas anteriores se ejecutaron en 2–3 sesiones simultáneas (`xfoil_work`, `xfoil_work_B`, `xfoil_work_C`) | OK siempre que no compartan carpeta de XFOIL ni el candidato de `setup_problem` del mismo caso. |

## 2. Validado parcialmente

- **Ejecución por secciones de `Main.mlx`**: la ejecución completa en batch demuestra que
  cada sección funciona tras la inicialización; la ejecución interactiva sección a sección en el
  Live Editor no se pudo probar sin interfaz gráfica. El diseño (variables `cfg`, `registro`,
  `figuras_sesion` creadas en las secciones 1–2 y reutilizadas) está pensado para ello.
- `verify_module2` corre, pero su comprobación interna (CST round-trip de `perfil2.dat`) da
  Δ = 0.55 dBA frente al umbral orientativo de 0.3 dBA que el propio script sugiere; es el
  comportamiento conocido del perfil `perfil2.dat` (sensibilidad al muestreo), no un efecto de la
  reorganización.

## 3. No validado / pendiente

| Elemento | Estado |
|---|---|
| Corridas de optimización y estudio con presupuesto completo | `run_optimization`, `run_multiobjective`, `sensitivity_analysis`, `compare_algorithms` y `review_studies` solo se han ejecutado con presupuestos pequeños (§1); con el presupuesto del manuscrito (horas) no. |
| `compare_algorithms_seeds`, `definitivo_robusto`, `opt_robusto_63218`, `opt_expandido`, `historial_expandido`, `chequeo_relativo_63218`, `revision_minimo_local`, `smooth_study_63218`, `study_cases`, `definitive_run`, `paper_studies*`, `audit_optimization`, `barrido_espesor`, `env_63221`, `find_best_aoa`, `compare_airfoils_opt`, `crossmodel_rel`, `sanity_rel`, `domain_and_history_63218` | No ejecutadas (coste de minutos a horas). Preámbulo y rutas adaptados; sintaxis y dependencias comprobadas (ahora también los `end` desbalanceados, ver `CAMBIOS.md` §8). Se recomienda probar cada una con presupuesto pequeño antes de una corrida larga. |
| `polar_360`, `paquete_figuras`, `paquete_definitivo`, `report_63218`, `regen_figs_63218`, `collect_figures`, `make_all_figures` | No ejecutados. Rutas adaptadas (salidas en `results/simulations/polares_360_*`, `results/exports/...`, `results/figures`). |
| Scripts de `archive/scripts_puntuales/` y `archive/legacy_utwente/` | Fuera del path; conservados tal cual, con rutas de la estructura antigua. No se usan en la cadena. |
| Modo `cfg.caso.tno_perfil = 'coles'` | Opción de diagnóstico; no validada frente a medidas (ver `HALLAZGO_TNO.md`). |
| `Kamruzzaman.m` con `u_tau` fijo | Defecto del código original documentado, no corregido. |
| Dos sesiones de MATLAB en paralelo sobre el **mismo caso** de `setup_problem` | Comparten `results/simulations/cst_baselines/cand_airfoil_<caso>.dat`; no probado y no recomendado. Con carpetas de XFOIL distintas y casos o scripts distintos sí funciona (§1). |

## 4. Cómo repetir las pruebas

```matlab
run('proyecto_init.m'); informe = ejecutar_pruebas();        % ~1.5 min
```
o la sección 6 de `Main.mlx` con `ejecutar_pruebas_proyecto = true`.
