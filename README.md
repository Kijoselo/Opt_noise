# Proyecto_RuidoPerfil — optimización de la silueta de un perfil para reducir el ruido de borde de fuga

Entorno modular de investigación computacional en MATLAB. Predice el ruido de borde de fuga de
un perfil (XFOIL → espectro de presión de pared TNO/Goody/Kamruzzaman/Amiet → teoría de
Amiet/Roger–Moreau → campo lejano → OASPL ponderado A) y optimiza la silueta (parametrización
CST) con restricciones aerodinámicas, geométricas y de adherencia de la capa límite.

El archivo principal es **`Main.mlx`**: un Live Script que inicializa el proyecto, fija los
parámetros, ejecuta cada módulo por secciones, muestra los resultados y los exporta.

## 1. Cómo abrir el proyecto

1. Abra MATLAB (probado con R2025b; requiere Optimization Toolbox y, para las optimizaciones,
   Global Optimization Toolbox).
2. Abra la carpeta `Proyecto_RuidoPerfil` (o simplemente abra `Main.mlx` desde el explorador
   de MATLAB). No hace falta cambiar el directorio de trabajo: el proyecto localiza su raíz a
   partir de `proyecto_init.m`.
3. Si MATLAB pregunta "Change Folder / Add to Path" al ejecutar, elija cualquiera de las dos.

Desde la línea de comandos equivale a:

```matlab
run('C:\...\Proyecto_RuidoPerfil\proyecto_init.m');   % o: cd a la carpeta y proyecto_init
rutas = proyecto_init();
cfg   = configuracion_general();
res   = predecir_ruido('NACA63221.txt', cfg);          % 1 llamada a XFOIL
```

## 2. Cómo ejecutar `Main.mlx`

El documento está dividido en secciones que se ejecutan con **Run Section** (Ctrl+Enter):

| Sección | Qué hace | Coste (llamadas a XFOIL) |
|---|---|---|
| 1. Inicialización | rutas, path, carpetas de resultados, `xfoil.exe` | — |
| 2. Parámetros generales | estructura `cfg` editable (caso de operación, modelo, perfiles, exportación) | — |
| 3.1 Predicción de un perfil | `predecir_ruido` + figura + tabla + capa límite | 1 |
| 3.2 Baseline vs optimizado | comparación de geometría, Φpp por lado, tercios de octava | 1 |
| 3.3 Tabla de capa límite | δ*, θ, H, Cf, Ue, pico de Φpp por lado | 0 |
| 3.4 Parametrización CST | ajuste de 14 coeficientes y error de reconstrucción | 0 |
| 3.5 Validación NACA 0012 | caso de referencia (Kucukosman 2018) | 2 |
| 3.6 Modelos de presión de pared | TNO / Goody / Kamruzzaman sobre la misma capa límite | 3 |
| 3.7 Diagnóstico perfil TNO | original vs cierre de Coles (ver `documentation/HALLAZGO_TNO.md`) | 2 |
| 3.8 Sensibilidad (interruptor) | barrido de las 14 variables de diseño | ~100 |
| 3.9 Optimización (interruptor) | `run_optimization` (pattern search) | presupuesto |
| 3.10 Estudios heredados | cómo lanzar los estudios y figuras del manuscrito | variable |
| 4. Resultados | registro de la sesión, tabla y gráfico comparativo | 0 |
| 5. Exportación | `.mat`, `.csv`, `parametros.txt` y PNG en `results/exports/<fecha>_sesion_main/` | 0 |
| 6. Pruebas | `ejecutar_pruebas` (interruptor) | 6 |

Siempre: ejecutar 1 y 2 primero; después cualquier módulo. Los módulos costosos tienen un
interruptor `ejecutar_* = false`; cámbielo a `true` para lanzarlos. Cada llamada a XFOIL tarda
5–10 s. Ejecutar el documento completo con los interruptores por defecto tarda ~3 min.

Puede escribir texto, ecuaciones y conclusiones debajo de cada bloque de resultados y guardar
el Live Script con los resultados visibles (Save). La fuente en texto plano del documento está
en `documentation/Main_fuente.m` (se convierte con
`matlab.internal.liveeditor.openAndSave('documentation/Main_fuente.m','Main.mlx')`).
`documentation/Main_ejecutado.pdf` es la exportación del documento ejecutado el 2026-10-19.

## 3. Organización de carpetas

```
Proyecto_RuidoPerfil/
├── Main.mlx                  cuaderno principal (Live Script)
├── proyecto_init.m           inicialización (path, rutas, carpetas)
├── README.md
├── config/
│   ├── configuracion_general.m   estructura cfg (fluido, caso, modelo, perfiles, exportación)
│   └── inputs_definition.m       parámetros originales del código de ruido
├── bin/                      xfoil.exe (y pplot/pxplot)
├── src/
│   ├── acoustics/            números de onda, integrales de radiación, campo lejano, 1/3 octava
│   ├── wall_pressure/        TNO (perfil de velocidad, fluctuaciones, espectro), Goody, Kamruzzaman, Amiet
│   ├── boundary_layer/       envoltorio de XFOIL, parámetros de capa límite
│   ├── geometry/             CST, Hicks–Henne, PARSEC, lectura/escritura de perfiles, espesor/curvatura
│   ├── evaluation/           evaluate_airfoil, predecir_ruido, evaluador memoizado, setup_problem
│   ├── optimization/         objetivos, restricciones, run_optimization, run_multiobjective
│   ├── studies/              estudios del manuscrito (robusto, sensibilidad, algoritmos, off-design, auditoría)
│   ├── postprocessing/       tablas, validación NACA 0012, polares 360°, registro y exportación
│   ├── visualization/        figuras de publicación, estilo (set_pub_defaults, pub_colors, savefig300)
│   └── utilities/            rutas, directorio de trabajo de XFOIL, búsqueda de archivos
├── data/
│   ├── airfoils/             coordenadas de los perfiles (NACA63221.txt, NACA63218.txt, ...)
│   ├── optimized/            óptimos publicados y baselines CST
│   ├── reference/Ref_fig_SPM datos de referencia (Kucukosman 2018)
│   ├── polars/               polares XFOIL de estudios anteriores
│   └── processed/            .mat/.csv de estudios anteriores (sensibilidad, semillas, Pareto)
├── results/
│   ├── figures/              figuras nuevas (previas/: las del trabajo anterior)
│   ├── tables/               tablas LaTeX
│   ├── simulations/          xfoil_work/ (temporales de XFOIL), cst_baselines/, <fecha>_opt_*/ (corridas),
│   │                         legacy_workspace/ (copia plana de datos para scripts heredados),
│   │                         estudios_previos/ (carpetas de resultados de estudios anteriores)
│   ├── exports/              exportaciones de sesión (<fecha>_<nombre>/), entregas_previas/
│   └── logs/                 informes de pruebas y logs de corridas anteriores
├── tests/                    test_dependencias, test_geometria, test_reproducibilidad, ejecutar_pruebas
├── documentation/            Main_fuente.m, INVENTARIO_FUNCIONES.md, MAPA_ARCHIVOS.md, CAMBIOS.md,
│                             INFORME_PRUEBAS.md, HALLAZGO_TNO.md, GUIA_CODIGO.md (guía anterior)
└── archive/                  legacy_utwente/ (scripts del zip no usados por la cadena), scripts_puntuales/,
                              study_cases/, backup_50pct/, paper_copia/, temporales/
```

## 4. Módulos (qué hace cada uno)

- **Cadena de ruido** (`src/acoustics`, `src/wall_pressure`, `src/boundary_layer`): código de
  UTwente (L. Botero Bolívar) sin cambios en la física. Entrada: `inputs` (= `cfg.caso`) y `fluid`
  (= `cfg.fluido`). `evaluate_airfoil(perfil, inputs, fluid)` devuelve `[OASPL_A, Cl, Cd, out]`;
  `predecir_ruido(perfil, cfg)` devuelve una estructura completa (espectros, niveles por lado,
  capa límite) lista para graficar/exportar.
- **Geometría** (`src/geometry`): `cst_fit`/`cst_to_coords` (variables de diseño), `load_airfoil`,
  `write_airfoil_dat`, `thickness_camber`, comparación con PARSEC y Hicks–Henne.
- **Optimización** (`src/optimization`): `setup_problem` construye el problema (cotas, baseline,
  restricciones); `obj_*`, `con_*` son objetivos/restricciones; `run_optimization`,
  `run_multiobjective` las corridas. Cada corrida escribe en `results/simulations/<fecha>_...`.
- **Estudios** (`src/studies`): scripts que reproducen las tablas y figuras del manuscrito.
  Trabajan en `results/simulations/legacy_workspace/` (se cambia el directorio automáticamente).
- **Post-proceso y visualización**: tablas (`tabla_resumen`, `tabla_capa_limite`), registro de
  sesión (`registrar_resultado`), exportación (`exportar_ejecucion`), figuras
  (`graficar_prediccion`, `graficar_comparacion`, figuras de publicación).

Inventario completo con firmas y dependencias: `documentation/INVENTARIO_FUNCIONES.md`.

## 5. Dependencias externas

- MATLAB R2022b o posterior (probado en R2025b), Optimization Toolbox; Global Optimization
  Toolbox para `patternsearch`, `ga`, `particleswarm`, `gamultiobj`, `surrogateopt`.
- `bin/xfoil.exe` (XFOIL 6.99 para Windows). Se copia automáticamente a la carpeta de trabajo
  `results/simulations/xfoil_work/`. Para correr dos sesiones de MATLAB a la vez use
  `proyecto_init('xfoil_workdir', otra_carpeta)` en una de ellas.

## 6. Cómo agregar nuevas funciones

1. Cree la función en la subcarpeta de `src/` que corresponda (se añade al path
   automáticamente por `proyecto_init`).
2. Reciba los parámetros por argumento (normalmente `cfg` o `cfg.caso`/`cfg.fluido`) y devuelva
   resultados; no dependa de variables del workspace ni del directorio actual.
3. Para leer perfiles use `buscar_perfil(nombre)`; para archivos de XFOIL `xfoil_out(nombre)`;
   para rutas `proyecto_rutas()`; para guardar figuras `savefig300(fig, 'nombre')` (va a
   `results/figures/`) o `exportar_ejecucion`.
4. Documente entradas, salidas y unidades en la cabecera y añada una sección en `Main.mlx`
   (edite `documentation/Main_fuente.m` y reconvierta, o edite el `.mlx` directamente).
5. Añada una prueba en `tests/` si el resultado es verificable.

## 7. Dónde se guardan los resultados

- Figuras de las funciones de publicación: `results/figures/`.
- Corridas de optimización: `results/simulations/<fecha>_opt_<caso>/` (geometría `.dat`,
  `resultado_optimizacion.mat` con historial, figuras). El óptimo publicado de `data/optimized/`
  no se sobrescribe; para adoptar uno nuevo cópielo allí a mano.
- Exportaciones de sesión desde `Main.mlx`: `results/exports/<fecha>_sesion_main/`.
- Informes de pruebas: `results/logs/informe_pruebas_<fecha>.txt`.
- Temporales de XFOIL: `results/simulations/xfoil_work/` (se pueden borrar).

## 8. Cómo reproducir los análisis

- Niveles del manuscrito (baseline 67.10/67.11 dBA, óptimo 65.81 dBA del NACA 63-221;
  67.82 → 65.64 dBA del NACA 63-218): `ejecutar_pruebas` o la sección 6 de `Main.mlx`.
- Figura del mecanismo: `fig_mechanism_aero_v2('NACA63221.txt')`; tabla de capa límite:
  `boundary_layer_table('NACA63221.txt')`.
- Optimización completa del 63-221: `run_optimization(400, 'NACA63221.txt')` (≈1 h).
- Estudios del manuscrito: ver sección 3.10 de `Main.mlx` y `src/studies/`.

Contexto científico pendiente (defecto del perfil de velocidad TNO y su impacto en los
óptimos): `documentation/HALLAZGO_TNO.md`.
