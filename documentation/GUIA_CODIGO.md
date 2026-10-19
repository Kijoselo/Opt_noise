# Guía del código — Optimización de silueta para ruido de borde de salida

Esta guía explica cómo está organizado el código que se construyó **encima** del
código de ruido de Amiet/TNO/XFOIL (que NO se modificó), y cómo correr cada parte.

---

## 1. Filosofía de diseño

El código original de ruido (carpeta raíz: `Main_TE_noise_prediction.m`,
`wavesnumbers.m`, `surface_pressure_spectrum.m`, `TNO.m`, `farfield_noise.m`, …)
**se dejó intacto**. Todo lo nuevo está en la carpeta **`optim/`** y solo *llama*
a esas funciones, nunca las cambia.

La idea central: el código de ruido sabe convertir **un perfil → un OASPL**.
Para optimizar, hace falta lo contrario: generar muchos perfiles, evaluarlos y
buscar el mejor. Por eso el código nuevo añade cuatro capas:

```
geometría (CST)  →  evaluar ruido  →  optimizar  →  analizar/graficar
```

---

## 2. Flujo de datos (el "pipeline" de optimización)

```
 variables de diseño (14 coef. CST)
        │  cst_to_coords.m
        ▼
 coordenadas del perfil  ──► write_airfoil_dat.m ──► perfil.dat
        │
        ▼  evaluate_airfoil.m  (llama al código de ruido SIN tocarlo)
   XFOIL → capa límite → TNO → Amiet → OASPL(A), Cl, Cd, Cm
        │  eval_airfoil_cached.m  (memoiza + registra cada evaluación)
        ▼
 función objetivo (obj_noise / obj_multi)
        │
        ▼  optimizador (patternsearch / ga / pso / surrogateopt / fmincon)
 mejor perfil  ──► figuras y tablas
```

---

## 3. Las cuatro capas de `optim/`

### Capa 1 — Geometría / parametrización
Convierten números (variables de diseño) en una silueta de perfil.

| Archivo | Qué hace |
|---|---|
| `load_airfoil.m` | Lee un `.dat` Selig y separa extradós/intradós |
| `cst_fit.m` | Ajusta coeficientes CST (Kulfan) a un perfil |
| `cst_eval.m` | Evalúa una superficie CST en x dado |
| `cst_to_coords.m` | Coef. CST → contorno completo del perfil (cosine spacing) |
| `parsec_fit/coeffs/eval.m` | Parametrización PARSEC (para la comparación) |
| `naca0012.m`, `hh_bumps.m`, `hh_fit.m`, `hh_eval.m` | Hicks–Henne (bumps sobre NACA0012) |
| `write_airfoil_dat.m` | Escribe el `.dat` que lee XFOIL |
| `thickness_camber.m` | Espesor t/c y línea de camber de un `.dat` |

### Capa 2 — Función objetivo (el puente al código de ruido)
Toman un perfil y devuelven su ruido + aerodinámica.

| Archivo | Qué hace |
|---|---|
| `evaluate_airfoil.m` | **Refactor de `Main_TE_noise_prediction.m` como función**: corre todo el pipeline de ruido y devuelve `OASPL(A), Cl, Cd, Cm, Φpp, S_pp`. *Verificado: reproduce el OASPL del Main original.* |
| `eval_airfoil_cached.m` | Envoltura memoizada: evalúa cada perfil único una sola vez (evita repetir XFOIL) y **registra** todas las evaluaciones (alimenta las figuras de exploración) |
| `setup_problem.m` | Define el problema: perfil base, variables de diseño `dv0`, cotas (`±50%`), restricciones, contexto `ctx` |
| `obj_noise.m` | Objetivo single-objetivo con penalización de Cl/Cd |
| `obj_noise_pure.m` + `con_clcd.m` | Objetivo OASPL + restricción dura de Cl/Cd (para patternsearch) |
| `obj_multi.m` | Objetivo multiobjetivo `[OASPL, −Cl/Cd]` para gamultiobj |

### Capa 3 — Optimizadores (los "estudios")
Cada uno es un script ejecutable que produce un resultado del paper.

| Archivo | Produce |
|---|---|
| `run_optimization.m` | **Caso 1**: óptimo single-objetivo (patternsearch, restricción dura) |
| `run_multiobjective.m` | **Caso 2**: frente de Pareto (gamultiobj) + 3 diseños representativos |
| `compare_algorithms.m` | Benchmark de 5 algoritmos (GA/PSO/PS/SBO/SQP) con igual presupuesto |
| `compare_algorithms_seeds.m` | Estudio de reproducibilidad (varias semillas) |

### Capa 4 — Análisis, validación y figuras

| Archivo | Produce |
|---|---|
| `compare_parameterizations.m` | Comparación CST/PARSEC/Hicks–Henne (Fig. 3, Tabla 1) |
| `sensitivity_analysis.m` | Tornado de sensibilidad OAT (Fig. 4) |
| `silhouette_variation.m` | Modos de forma CST (Fig. 6 + apéndice) |
| `plot_mechanism.m` | Mecanismo: silueta, t/c, camber, Cp, Φpp (Figs. 5 y 7) |
| `plot_spectrum_compare.m` / `regen_optimum_spectrum.m` | Espectro SPL baseline vs optimizado (Fig. 9) |
| `boundary_layer_table.m` | Parámetros de capa límite en x/c=0.99 (Tabla de capa límite) |
| `validate_naca0012.m` | Validación del modelo de presión de pared vs RANS (Fig. 1) |
| `set_pub_defaults.m` | Estilo de figuras tipo revista (fuente, ejes) |
| `savefig300.m` | Exporta PNG a 600 dpi, ancho de columna, sin título |
| `collect_figures.m` | Copia las figuras finales a `paper/figures/` |
| `make_all_figures.m` | Orquestador: corre todos los estudios de un tirón |
| `verify_module2.m` | Verifica que `evaluate_airfoil` reproduce el Main original |

---

## 4. Cómo correr (orden típico)

Desde MATLAB, con la carpeta `optim/` en el path:

```matlab
addpath('.../Amiet-Theory-for-TE-Noise/optim')

validate_naca0012        % validación (Fig 1)
compare_parameterizations% Fig 3, Tabla 1
run_optimization(400)    % óptimo principal -> optimized_hardcon.dat
plot_mechanism           % Figs 5, 7 + desglose por superficie
sensitivity_analysis     % Fig 4
silhouette_variation     % Fig 6
compare_algorithms(150)  % Tabla 4 + Fig 10
run_multiobjective       % Tabla 5 + Fig 11 (Pareto)
boundary_layer_table     % tabla de capa límite
regen_optimum_spectrum   % Fig 9 (espectro, 3 paneles)
collect_figures          % junta todo en paper/figures/
```

Parámetro clave: el rango de búsqueda está en `setup_problem.m`
(`bw_rel = 0.5` = ±50%). Bajarlo a `0.3` da el resultado conservador (±30%).

---

## 5. El artículo (`paper/`)

- `manuscript.tex` — manuscrito (clase elsarticle).
- `refs.bib` — bibliografía.
- `figures/` — las figuras finales (600 dpi).
- Compilar: `pdflatex → bibtex → pdflatex ×2`, o subir la carpeta a Overleaf.
