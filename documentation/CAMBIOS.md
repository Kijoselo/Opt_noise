# Resumen de cambios de la reorganización (2026-10-19)

Origen: `work/Amiet-Theory-for-TE-Noise/` (código de ruido de UTwente + carpeta `optim/` propia).
Copia de seguridad previa a cualquier cambio: `../backup_work_Amiet_2026-10-19.zip` (17.9 MB).
La carpeta original no se modificó ni se borró; todo se **copió** a `Proyecto_RuidoPerfil/`
(`MAPA_ARCHIVOS.md` relaciona cada archivo original con su nueva ubicación).

## 1. Estructura nueva

Ver `README.md` §3. Criterios: el código de ruido original queda separado por etapa física
(`acoustics`, `wall_pressure`, `boundary_layer`); lo propio por finalidad (`geometry`,
`evaluation`, `optimization`, `studies`, `postprocessing`, `visualization`, `utilities`);
datos en `data/`, resultados en `results/`, pruebas en `tests/`, documentación en
`documentation/`, y en `archive/` lo que no participa en la cadena (scripts del zip de teoría de
bandas, validaciones antiguas, scripts puntuales de una sola vez con rutas fijas, estudios de
casos, copia del manuscrito, temporales).

## 2. Archivos nuevos

| Archivo | Función |
|---|---|
| `Main.mlx` | Live Script principal (generado desde `documentation/Main_fuente.m`, ejecutado y guardado con resultados). |
| `proyecto_init.m` | Inicialización: path, rutas, carpetas de resultados, copia de `xfoil.exe`; opción `'workspace','legacy'` y `'xfoil_workdir'`. |
| `config/configuracion_general.m` | Estructura `cfg` central (fluido, caso, modelo, perfiles, exportación, rutas). |
| `src/utilities/proyecto_rutas.m` | Rutas absolutas del proyecto calculadas desde la ubicación del archivo. |
| `src/utilities/xfoil_workdir.m`, `xfoil_out.m` | Carpeta de trabajo de XFOIL y rutas de sus archivos temporales. |
| `src/utilities/buscar_perfil.m` | Resuelve nombres de perfiles a rutas (data/airfoils, data/optimized, ...). |
| `src/utilities/carpeta_ejecucion.m` | Carpeta con marca de tiempo para no sobrescribir resultados. |
| `src/utilities/copiar_figura.m` | Sustituye los `copyfile` relativos de figuras. |
| `src/utilities/actualizar_caso.m` | Recalcula M, Re y semicuerda tras editar `cfg`. |
| `src/evaluation/predecir_ruido.m` | Predicción completa (espectros, niveles por lado, capa límite) a partir de `evaluate_airfoil`. |
| `src/visualization/graficar_prediccion.m`, `graficar_comparacion.m` | Figuras de `Main.mlx`. |
| `src/postprocessing/tabla_resumen.m`, `tabla_capa_limite.m`, `registrar_resultado.m`, `exportar_ejecucion.m`, `comparar_modelos_wps.m`, `diagnostico_perfil_tno.m` | Tablas, registro de sesión, exportación, comparación de modelos, diagnóstico TNO. |
| `tests/test_dependencias.m`, `test_geometria.m`, `test_reproducibilidad.m`, `ejecutar_pruebas.m` | Pruebas e informe. |
| `documentation/*.md`, `Main_ejecutado.pdf` | README, inventario, mapa, cambios, informe de pruebas, hallazgo TNO. |

## 3. Archivos modificados (y por qué)

Ninguna de estas modificaciones cambia la física ni los resultados: `test_reproducibilidad`
compara con el código original ejecutado en la misma sesión (diferencia < 0.001 dB).

| Archivo | Cambio |
|---|---|
| `src/boundary_layer/XFOIL_new_airfoil.m` | Ejecuta XFOIL dentro de `xfoil_workdir()` y copia el perfil con nombre corto (`airfoil_in.dat`); restaura el directorio al salir. Resuelve el perfil con `buscar_perfil`. Lectura de XFOIL sin cambios. |
| `src/evaluation/evaluate_airfoil.m` | `inputs.perfil = buscar_perfil(perfil)`. |
| `src/geometry/load_airfoil.m` | Resuelve el nombre con `buscar_perfil`. |
| `src/evaluation/setup_problem.m` | Sin `cd`; baseline CST y candidato en `results/simulations/cst_baselines/`, óptimo publicado en `data/optimized/`; `resolve_airfoil_file` sustituido por `buscar_perfil`; `ctx.rutas`. |
| `src/evaluation/eval_airfoil_cached.m` y todos los scripts que leen `XFOIL_Output`, `XFOIL_CP_Output`, `POLAR_OUTPUT` | Rutas vía `xfoil_out(...)`. |
| `src/visualization/savefig300.m` | Sin carpeta en el nombre guarda en `results/figures/`; devuelve la ruta. |
| `src/optimization/run_optimization.m`, `run_multiobjective.m` | Salidas en `results/simulations/<fecha>_opt_<caso>/` (geometría, `.mat` con historial, figuras); ya no sobrescriben el óptimo publicado ni copian a `paper/`. |
| `src/wall_pressure/mean_velocity_profile.m` | Opción `inputs.tno_perfil = 'original'` (defecto, fórmula del zip) / `'coles'` (diagnóstico, no validado). Cabecera documentada. |
| `src/wall_pressure/surface_pressure_spectrum.m` | Fija `inputs.Ue_lado` antes de cada llamada a TNO (solo lo usa el modo `'coles'`). |
| `config/inputs_definition.m` | `input.perfil = 'NACA63221.txt'` (antes `'naca63221.dat'`, archivo inexistente). |
| 38 scripts de `src/studies`, `src/visualization`, `src/postprocessing` | Preámbulo `here/parent/cd(parent)` → `rutas = proyecto_init('workspace','legacy')` (trabajan en `results/simulations/legacy_workspace/`). |
| `compare_parameterizations.m`, `collect_figures.m`, `polar_360*.m`, `env_63221.m`, `fig_param_variables.m`, `fig_seed_boxplot_regen.m`, `fig_sens_modes_merged.m`, `regen_figs_63218.m`, `crossmodel_rel.m`, `domain_and_history_63218.m`, `paquete_definitivo.m`, `paquete_figuras.m`, `report_63218.m`, `barrido_espesor.m`, `chequeo_relativo_63218.m`, `definitivo_robusto.m`, `historial_expandido.m`, `opt_expandido.m`, `opt_robusto_63218.m`, `revision_minimo_local.m` | Rutas absolutas `C:\...` sustituidas por rutas del proyecto (`results/simulations/estudios_previos/<carpeta>` para las carpetas de resultados de estudios anteriores, `results/exports/...` para entregas, `results/figures` para figuras). |
| `copyfile([fig '.png'], 'nombre.png')` en 6 scripts | → `copiar_figura(fig, 'nombre')`. |
| `tests/verify_module2.m` | Preámbulo adaptado (workspace heredado). |

## 4. Archivos no modificados

Todo `src/acoustics/`, `src/wall_pressure/` salvo los dos indicados, `Boundary_layer_characteristics.m`,
`Goody.m`, `Kamruzzaman.m` (se documenta su `u_tau` fijo en `HALLAZGO_TNO.md`, no se corrige),
`src/geometry/` salvo `load_airfoil` y `compare_parameterizations`, objetivos y restricciones.

## 5. Datos

- `data/airfoils/`, `data/optimized/`, `data/polars/`, `data/processed/`, `data/reference/`: copias
  de los archivos sueltos de la carpeta original, clasificados.
- `results/simulations/legacy_workspace/`: copia plana de esos mismos datos (sin código) para que
  los scripts de estudio heredados sigan leyendo y escribiendo por nombre relativo como antes.
- `results/simulations/estudios_previos/`: copias de las carpetas de resultados que estaban en
  `Opti_Param_ruidoio/` (definitivo_robusto, chequeo_relativo, dominio_expandido, ...).
- `results/exports/entregas_previas/`: copias de las carpetas de entrega (pala, perfiles optimizados).
- `results/figures/previas/`: los 66 PNG de la carpeta original; `results/logs/`: sus 20 `.log`.

## 6. Decisiones de diseño

- **Un único directorio de trabajo de XFOIL** (`results/simulations/xfoil_work/`): XFOIL escribe
  archivos por nombre fijo; centralizarlos evita temporales por todo el proyecto. Para sesiones en
  paralelo: `proyecto_init('xfoil_workdir', ...)`.
- **Las funciones núcleo no cambian de directorio**; los scripts de estudio heredados sí
  (documentado en su preámbulo), porque reproducirlos sin `cd` exigiría reescribir decenas de
  lecturas/escrituras relativas, con riesgo de alterar resultados ya publicados.
- **Nada se sobrescribe**: corridas y exportaciones en carpetas con marca de tiempo.
- **Resultados científicos intactos**: la corrección del perfil TNO queda como opción explícita
  y marcada como no validada.

## 7. Operaciones no validadas / pendientes

Ver `INFORME_PRUEBAS.md` §3.

## 8. Correcciones tras la validación de los scripts de optimización y estudio (2026-10-19, tarde)

Se ejecutaron con presupuestos pequeños `run_optimization`, `run_multiobjective`,
`sensitivity_analysis`, `compare_algorithms`, `review_studies`, `polar_360_simple`,
`fig_wps_delta_regen` y `fig_cfh_regen` (detalle y resultados en `INFORME_PRUEBAS.md` §1).
Ninguna de estas correcciones toca la física; solo rutas, un error de sintaxis y una prueba.

| Archivo | Cambio |
|---|---|
| `src/postprocessing/polar_360_simple.m` | El `end` del `if nargin < 3` había quedado dentro del comentario `% (reorganizacion)`, y MATLAB no podía ejecutar el archivo. Se saca el `end` del comentario. |
| `src/studies/sensitivity_analysis.m` | `sensitivity_data.mat` se guardaba en el directorio actual (la función no cambia de directorio). Ahora se guarda en `results/simulations/legacy_workspace/` vía `proyecto_rutas()`, que es donde lo lee `fig_sens_modes_merged` y lo que documenta `Main.mlx` §3.8. |
| `src/studies/review_studies.m`, `src/visualization/fig_cfh_regen.m`, `src/visualization/fig_wps_delta_regen.m` | Escribían las figuras en `paper/figures` relativo al workspace heredado (`results/simulations/legacy_workspace/paper/figures/`). Ahora usan `rutas.figuras` (`results/figures/`), como el resto de scripts de figuras. Las figuras de la corrida de validación se movieron a `results/figures/` y se eliminó la carpeta `legacy_workspace/paper/`. |
| `tests/test_dependencias.m` | `checkcode` clasifica el `end` que falta o sobra como aviso `ENDCT*`, no como error de sintaxis, por lo que la prueba no detectó el fallo de `polar_360_simple`. Ahora los `ENDCT*` cuentan como errores graves. |

Notas de la validación:

- Los scripts de optimización y de estudio comparten `results/simulations/xfoil_work/` y, los
  que usan `setup_problem`, el archivo candidato `results/simulations/cst_baselines/cand_airfoil_<caso>.dat`.
  Mientras se validaba, un MATLAB interactivo con `Main.mlx` abierto ejecutó el documento y
  usó el mismo `xfoil_work/`; la primera corrida de `run_multiobjective` falló por eso
  (`POLAR_OUTPUT` borrado por la otra sesión entre la ejecución de XFOIL y su lectura) y
  corrió bien al repetirla en solitario. Para correr en paralelo use
  `proyecto_init('xfoil_workdir', carpeta)` en cada sesión y no lance dos optimizaciones
  del mismo caso a la vez.
- `sensitivity_analysis(3)` sobrescribió `legacy_workspace/sensitivity_data.mat` (7 niveles,
  dato del manuscrito). Se restauró desde `data/processed/sensitivity_data.mat` (md5 idéntico
  al de `work/`) y el resultado de la prueba quedó como
  `legacy_workspace/sensitivity_data_prueba_3niveles_20261019.mat`. Antes de una corrida
  real de sensibilidad conviene copiar el `.mat` vigente a `data/processed/`.
- `compare_algorithms` no acepta `('budget', N)`: su firma es `compare_algorithms(N)` o
  `compare_algorithms(N, perfil)`.
- `polar_360_simple` evalúa las 36 "alphas" al mismo ángulo de ataque de `inputs_definition`
  (lo advierte su propio comentario): es el comportamiento heredado, no se cambió.
