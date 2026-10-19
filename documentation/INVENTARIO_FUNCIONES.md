# Inventario de funciones y dependencias

Generado automáticamente a partir de las cabeceras de los archivos (2026-10-19).
`Llama a` lista las funciones del propio proyecto que usa cada archivo (detección por nombre; no incluye toolboxes).
Toolboxes externos requeridos por los puntos de entrada: MATLAB, Optimization Toolbox, Global Optimization Toolbox
(ver `test_dependencias`). Dependencia externa binaria: `bin/xfoil.exe` (XFOIL 6.99, Windows).

## proyecto_init.m (raíz)

| Archivo | Firma | Descripción | Llama a |
|---|---|---|---|
| `proyecto_init.m` | `rutas = proyecto_init(varargin)` | PROYECTO_INIT  Inicializa el proyecto: rutas, path de MATLAB y carpetas de resultados. rutas = proyecto_init() | proyecto_rutas |

## config/

| Archivo | Firma | Descripción | Llama a |
|---|---|---|---|
| `configuracion_general.m` | `cfg = configuracion_general()` | CONFIGURACION_GENERAL  Parámetros centrales del proyecto en una sola estructura. cfg = configuracion_general(); | actualizar_caso, inputs_definition, proyecto_rutas |
| `inputs_definition.m` | `[fluid,input] = inputs_definition()` | UNTITLED2 Summary of this function goes here Detailed explanation goes here |  |

## tests/

| Archivo | Firma | Descripción | Llama a |
|---|---|---|---|
| `ejecutar_pruebas.m` | `informe = ejecutar_pruebas()` | EJECUTAR_PRUEBAS  Corre todas las pruebas del proyecto y escribe un informe en results/logs/informe_pruebas_<fecha>.txt. | proyecto_init, test_dependencias, test_geometria, test_reproducibilidad |
| `test_dependencias.m` | `R = test_dependencias(verbose)` | TEST_DEPENDENCIAS  Comprueba la integridad del código reorganizado (sin XFOIL): 1. todos los .m de src/, config/, tests/ y la raíz pasan checkcode sin errores | proyecto_init |
| `test_geometria.m` | `R = test_geometria(verbose)` | TEST_GEOMETRIA  Pruebas rápidas (sin XFOIL) del módulo de geometría: - lectura de perfiles (load_airfoil, buscar_perfil) | buscar_perfil, cst_fit, cst_to_coords, load_airfoil, proyecto_init, thickness_camber, write_airfoil_dat |
| `test_reproducibilidad.m` | `R = test_reproducibilidad(verbose)` | TEST_REPRODUCIBILIDAD  Comprueba que la cadena de ruido reorganizada reproduce los niveles de referencia del código original (valores obtenidos con el código | configuracion_general, predecir_ruido, proyecto_init |
| `verify_module2.m` | `(script)` | VERIFY_MODULE2 Confirms that: | cst_fit, cst_to_coords, evaluate_airfoil, inputs_definition, load_airfoil, proyecto_init, write_airfoil_dat |

## src/acoustics/

| Archivo | Firma | Descripción | Llama a |
|---|---|---|---|
| `E.m` | `[E] = E(x)` |  |  |
| `erfz.m` | `[y,N,algo] = erfz(x,N,algo)` | error function for a real or complex array Note: The Fresnel integrals C(x) and S(x) can be computed for real x as |  |
| `farfield_noise.m` | `[S_pp_s,S_pp_p] = farfield_noise(inputs,fluid,omega,S0,I,Pi0_s,Pi0_p)` | far-field noise calculated in the position x,y,z from the input. |  |
| `Fresnel_int.m` | `E = Fresnel_int(x)` | Fresnel integral (Abramowitz & Stegun) | erfz |
| `Fresnel_int_conj.m` | `E_s = Fresnel_int_conj(x)` | Complex Conjugate of the Fresnel integral | Fresnel_int |
| `Integrated_WPS.m` | `[Pi0_s,Pi0_p] = Integrated_WPS(l_y,Phi_pp_s,Phi_pp_p)` | This function calculates the streamwise wavenumber integrated spectrum of the wall pressure fluctuations |  |
| `NarrowToNthOctave.m` | `[sortedData,Fc,Flow,Fhigh] = NarrowToNthOctave(arrayOfNBCenterFreqs,arrayOfdBToConvert,n)` | Program to convert narrowband data to 1/n octaveband data. Just send it an array of band center frequencies, the dB values to sort, and the nth |  |
| `Radiation_integral.m` | `[I] = Radiation_integral(f1,f2)` |  |  |
| `Radiation_integral1.m` | `[f1] = Radiation_integral1(B,C)` | This is the transfer function that account for the propagation of TE noise. This transfer function is idental to that for Amiet. | Fresnel_int_conj |
| `Raditation_integral2.m` | `[f2] = Raditation_integral2(B,K_bar,k_min_bar,mu_bar,S0,K_1_bar,alpha,inputs)` | This function calculates the radiation integral that accounts for the back-scattering effect from the LE. | Fresnel_int, Fresnel_int_conj |
| `spanwise_corlength.m` | `[l_y] = spanwise_corlength(U_c,omega,K_2_bar,inputs)` | This function calculates the spanwise correlation length for a  turbulent boundary layer |  |
| `TE_noise_Prediction.m` | `[omega, S_pp,Phi_pp_s, Cl,Cd, Cdp, Cm, Cf] = TE_noise_Prediction(inputs,fluid)` | Define waves number | Integrated_WPS, Radiation_integral, Radiation_integral1, Raditation_integral2, farfield_noise, spanwise_corlength, surface_pressure_spectrum, wavesnumbers |
| `wavesnumbers.m` | `[f,omega,B,C,K_bar,k_min_bar,mu_bar,S0,K_1_bar,alpha,U_c,K_2_bar] = wavesnumbers(inputs,fluid)` | UNTITLED4 Summary of this function goes here Detailed explanation goes here |  |

## src/boundary_layer/

| Archivo | Firma | Descripción | Llama a |
|---|---|---|---|
| `Boundary_layer_characteristics.m` | `[delta,tau_w,u_t,Rt] = Boundary_layer_characteristics(delta_s,theta,c_f,Ue,inputs,fluid)` | this function calculates the boundary layer characteristics based on the outputs of xfoil |  |
| `XFOIL_new_airfoil.m` | `[DSTRS,DSTRP,THETAS,THETAP,CFS,CFP,x_c,Cp,Ue_s,Ue_p, dcpdx_s, dcpdx_p, Cl, Cd, Cdp, Cm,cf] = XFOIL_new_airfoil(NACADIG,ALPSTAR,Re,Mach,xtr_s,xtr_p,C,pos,Name_file)` | This function calculates the displacement thickness using XFOIL. The turbulence intensity is set at 0.07 | E, buscar_perfil, xfoil_workdir |

## src/evaluation/

| Archivo | Firma | Descripción | Llama a |
|---|---|---|---|
| `eval_airfoil_cached.m` | `out = eval_airfoil_cached(dv, ctx)` | EVAL_AIRFOIL_CACHED  Memoised, logged airfoil evaluation. Runs the geometry + XFOIL + Amiet pipeline once per unique design vector and | cst_to_coords, evaluate_airfoil, write_airfoil_dat, xfoil_out |
| `evaluate_airfoil.m` | `[OASPL_A, Cl, Cd, out] = evaluate_airfoil(perfil, inputs, fluid)` | EVALUATE_AIRFOIL  Run the trailing-edge-noise pipeline for one airfoil and return the A-weighted overall sound pressure level (the design objective). | Integrated_WPS, Radiation_integral, Radiation_integral1, Raditation_integral2, buscar_perfil, farfield_noise, spanwise_corlength, surface_pressure_spectrum, wavesnumbers |
| `predecir_ruido.m` | `res = predecir_ruido(perfil, cfg, etiqueta)` | PREDECIR_RUIDO  Predicción completa de ruido de borde de fuga de un perfil. Envuelve evaluate_airfoil (XFOIL -> capa límite -> espectro de presión de pared | buscar_perfil, evaluate_airfoil, xfoil_out |
| `setup_problem.m` | `P = setup_problem(varargin)` | SETUP_PROBLEM  Common problem definition shared by every optimisation script (single-objective, multi-objective, algorithm comparison). | buscar_perfil, cst_fit, cst_to_coords, eval_airfoil_cached, inputs_definition, load_airfoil, proyecto_init, write_airfoil_dat |

## src/geometry/

| Archivo | Firma | Descripción | Llama a |
|---|---|---|---|
| `compare_parameterizations.m` | `compare_parameterizations(base_file)` | COMPARE_PARAMETERIZATIONS Module 1: justify the choice of airfoil parameterization. | buscar_perfil, cst_eval, cst_fit, hh_eval, hh_fit, load_airfoil, parsec_eval, parsec_fit, proyecto_init, pub_colors, savefig300, set_pub_defaults |
| `cst_eval.m` | `y = cst_eval(x, A, yte, N1, N2)` | CST_EVAL  Evaluate a CST (Kulfan) surface. y = C(x) * S(x) + x*yte |  |
| `cst_fit.m` | `p = cst_fit(af, order)` | CST_FIT  Least-squares fit of CST coefficients to an airfoil. order : Bernstein order per surface (order+1 coefficients each). |  |
| `cst_to_coords.m` | `[x, y, xu, yu, xl, yl] = cst_to_coords(Au, Al, yte_u, yte_l, npts, N1, N2)` | CST_TO_COORDS  Build a full airfoil coordinate loop from CST coefficients. Au, Al         : upper/lower shape coefficients | cst_eval |
| `hh_bumps.m` | `B = hh_bumps(x, xk, width)` | HH_BUMPS  Hicks-Henne bump basis matrix. b_k(x) = sin( pi * x^(log(0.5)/log(xk)) )^width |  |
| `hh_eval.m` | `y = hh_eval(x, a, xk, width, lower)` | HH_EVAL  Evaluate a Hicks-Henne surface = NACA0012 baseline + bumps. lower : true for the lower surface (negative baseline). | hh_bumps, naca0012 |
| `hh_fit.m` | `p = hh_fit(af, xk)` | HH_FIT  Fit Hicks-Henne bumps over a NACA0012 baseline to reproduce af. Hicks-Henne is a *perturbation* scheme, so it needs a baseline. We use a | hh_bumps, naca0012 |
| `load_airfoil.m` | `af = load_airfoil(filename)` | LOAD_AIRFOIL  Read a Selig/XFOIL .dat coordinate file and split surfaces. af.x, af.y    : full coordinate loop (TE -> upper -> LE -> lower -> TE) | buscar_perfil |
| `naca0012.m` | `yt = naca0012(x, t)` | NACA0012  Half-thickness of a NACA 00xx airfoil (default t=0.12). Returns the (positive) thickness y_t at stations x in [0,1]. |  |
| `parsec_coeffs.m` | `a = parsec_coeffs(a1, Xm, Zm, Zxx, Zte, te_slope)` | PARSEC_COEFFS  Solve the 6 PARSEC polynomial coefficients for one surface. a1       : leading-edge coefficient  (= +/- sqrt(2*rLE)) |  |
| `parsec_eval.m` | `y = parsec_eval(x, a)` | PARSEC_EVAL  Evaluate a PARSEC surface polynomial. y(x) = sum_{n=1..6} a(n) * x^(n-1/2) |  |
| `parsec_fit.m` | `p = parsec_fit(af)` | PARSEC_FIT  Extract PARSEC features from an airfoil and build coefficients. PARSEC parameters are geometric features, so we measure them directly from | parsec_coeffs |
| `thickness_camber.m` | `[xc, tc, camber] = thickness_camber(datfile, n)` | THICKNESS_CAMBER  Thickness and camber distributions of an airfoil .dat file. xc     : cosine-spaced chord stations [0,1] | load_airfoil |
| `write_airfoil_dat.m` | `write_airfoil_dat(filename, x, y)` | WRITE_AIRFOIL_DAT  Write coordinates to an XFOIL/Selig .dat file. Matches the header-less, two-column format of the proven-working |  |

## src/optimization/

| Archivo | Firma | Descripción | Llama a |
|---|---|---|---|
| `con_cl.m` | `[c, ceq] = con_cl(dv, ctx)` | CON_CL  Nonlinear constraint: keep the lift coefficient at or above the baseline value (constant-lift optimisation). | eval_airfoil_cached |
| `con_clcd.m` | `[c, ceq] = con_clcd(dv, ctx)` | CON_CLCD  Nonlinear constraint: keep Cl/Cd at or above the baseline. c <= 0 is feasible.  c = clcd_min - clcd. | eval_airfoil_cached |
| `obj_multi.m` | `F = obj_multi(dv, ctx)` | OBJ_MULTI  Multi-objective vector for gamultiobj. F(1) = OASPL(A)        (minimise noise) | eval_airfoil_cached |
| `obj_noise.m` | `J = obj_noise(dv, ctx)` | OBJ_NOISE  Single-objective noise objective with a Cl/Cd penalty. Penalty method (uniform across all algorithms, including those without | eval_airfoil_cached |
| `obj_noise_lin.m` | `J = obj_noise_lin(dv, ctx)` | OBJ_NOISE_LIN  Un-weighted OASPL (no A-filter) only, for use together with a nonlinear constraint (e.g. con_clcd). Same penalty handling as | eval_airfoil_cached |
| `obj_noise_pure.m` | `J = obj_noise_pure(dv, ctx)` | OBJ_NOISE_PURE  OASPL(A) only (no Cl/Cd penalty), for use together with con_clcd as a true nonlinear constraint in constrained solvers. | eval_airfoil_cached |
| `obj_noise_robusto.m` | `[J, detalle] = obj_noise_robusto(dv, ctx)` | OBJ_NOISE_ROBUSTO  Objetivo ROBUSTO multi-modelo: minimiza el PEOR caso del OASPL(A) sobre los modelos de presion de pared que YA tiene el codigo | cst_to_coords, eval_airfoil_cached, evaluate_airfoil, write_airfoil_dat, xfoil_out |
| `obj_noise_robusto_rel.m` | `[J, detalle] = obj_noise_robusto_rel(dv, ctx)` | OBJ_NOISE_ROBUSTO_REL  Objetivo ROBUSTO RELATIVO: minimiza el PEOR CAMBIO respecto al baseline de CADA modelo, quitando los offsets absolutos entre | cst_to_coords, eval_airfoil_cached, evaluate_airfoil, write_airfoil_dat, xfoil_out |
| `run_multiobjective.m` | `[oaspl, clcd] = run_multiobjective(popsize, gens, basefile)` | RUN_MULTIOBJECTIVE  (Case 2: Pareto front noise vs efficiency) Trade-off between A-weighted OASPL and Cl/Cd using gamultiobj. | carpeta_ejecucion, cst_to_coords, evaluate_airfoil, obj_multi, pub_colors, savefig300, set_pub_defaults, setup_problem, thickness_camber, write_airfoil_dat |
| `run_optimization.m` | `dv_opt = run_optimization(varargin)` | RUN_OPTIMIZATION  (Case 1: hard Cl/Cd constraint) Minimise A-weighted OASPL over the CST silhouette subject to a HARD | carpeta_ejecucion, con_clcd, cst_to_coords, eval_airfoil_cached, obj_noise_pure, plot_spectrum_compare, savefig300, set_pub_defaults, setup_problem, write_airfoil_dat |
| `run_optimization_lin.m` | `dv_opt = run_optimization_lin(varargin)` | RUN_OPTIMIZATION_LIN  (variant: un-weighted OASPL objective) Same problem as run_optimization (hard Cl/Cd constraint, geometry and | con_clcd, cst_to_coords, eval_airfoil_cached, obj_noise_lin, plot_spectrum_compare, savefig300, set_pub_defaults, setup_problem, write_airfoil_dat |

## src/postprocessing/

| Archivo | Firma | Descripción | Llama a |
|---|---|---|---|
| `boundary_layer_table.m` | `boundary_layer_table(basefile)` | BOUNDARY_LAYER_TABLE  Boundary-layer parameters at the wall-pressure sampling location (x/c = inputs.Mic, i.e. 0.99) for the baseline and optimized airfoils, | XFOIL_new_airfoil, evaluate_airfoil, proyecto_init, setup_problem |
| `comparar_modelos_wps.m` | `[T, resultados] = comparar_modelos_wps(perfil, cfg, modelos)` | COMPARAR_MODELOS_WPS  Evalúa un perfil con varios modelos de espectro de presión de pared (misma geometría, misma capa límite de XFOIL). | predecir_ruido, tabla_resumen |
| `diagnostico_perfil_tno.m` | `[T, resultados, fig] = diagnostico_perfil_tno(perfil, cfg)` | DIAGNOSTICO_PERFIL_TNO  Compara, para un perfil, el espectro de presión de pared TNO con el perfil de velocidad original del código (cfg.caso.tno_perfil | graficar_comparacion, predecir_ruido, tabla_resumen |
| `exportar_ejecucion.m` | `carpeta = exportar_ejecucion(resultados, cfg, nombre, figuras)` | EXPORTAR_EJECUCION  Guarda una o varias predicciones con sus parámetros, tablas, espectros y figuras en una carpeta nueva con marca de tiempo dentro | carpeta_ejecucion, tabla_capa_limite, tabla_resumen |
| `polar_360.m` | `polar_360(basefile, optfile, outdir)` | POLAR_360  Full +-180 deg Cl/Cd polars for the baseline and optimized airfoils, for whole-blade (BEM/AeroDyn-style) simulation. | E, inputs_definition, proyecto_init, savefig300, xfoil_out |
| `polar_360_simple.m` | `polar_360_simple(basefile, optfile, outdir)` | POLAR_360_SIMPLE  Simplified 360-deg polar without ASEQ (avoids XFOIL batch hang) Evaluates at specific alpha points manually, then applies Viterna | evaluate_airfoil, inputs_definition, proyecto_init, savefig300 |
| `regen_optimum_spectrum.m` | `regen_optimum_spectrum(basefile)` | REGEN_OPTIMUM_SPECTRUM  Rebuild the case-specific hard-constraint spectrum from the saved airfoils, WITHOUT re-running the 400-evaluation optimization. Uses onl | NarrowToNthOctave, copiar_figura, evaluate_airfoil, proyecto_init, pub_colors, savefig300, set_pub_defaults, setup_problem |
| `registrar_resultado.m` | `registro = registrar_resultado(registro, res, etiqueta)` | REGISTRAR_RESULTADO  Añade una predicción al registro de resultados de la sesión (para comparar ejecuciones en Main.mlx). | tabla_resumen |
| `tabla_capa_limite.m` | `T = tabla_capa_limite(resultados)` | TABLA_CAPA_LIMITE  Parámetros de capa límite en x/c = Mic (ambos lados) de varias predicciones (salidas de predecir_ruido). Equivale a la tabla de |  |
| `tabla_resumen.m` | `T = tabla_resumen(resultados)` | TABLA_RESUMEN  Tabla con los niveles globales y coeficientes de varias predicciones (salidas de predecir_ruido), una fila por perfil. |  |
| `validate_naca0012.m` | `validate_naca0012()` | VALIDATE_NACA0012  Validate the present noise framework against the standard NACA0012 benchmark used by Kou et al. (2023) and Kucukosman et al. (2018). | NarrowToNthOctave, evaluate_airfoil, inputs_definition, naca0012, proyecto_init, savefig300, set_pub_defaults, surface_pressure_spectrum, write_airfoil_dat |

## src/studies/

| Archivo | Firma | Descripción | Llama a |
|---|---|---|---|
| `audit_optimization.m` | `audit_optimization(files)` | AUDIT_OPTIMIZATION  Numerical audit of the optimisation chain (read-only on the manuscript; only prints). Answers three questions per case: | cst_eval, cst_fit, cst_to_coords, evaluate_airfoil, load_airfoil, proyecto_init, setup_problem, xfoil_out |
| `barrido_espesor.m` | `barrido_espesor` | BARRIDO_ESPESOR  Verificacion NO OPTIMIZADA de la relacion espesor -> ruido. Dos pruebas independientes, misma cadena de ruido sin modificar, mismas | evaluate_airfoil, inputs_definition, naca0012, proyecto_init, savefig300, thickness_camber, write_airfoil_dat, xfoil_out |
| `chequeo_relativo_63218.m` | `chequeo_relativo_63218` | CHEQUEO_RELATIVO_63218  Punto C3 del revisor: reoptimiza el NACA 63-218 con el objetivo ROBUSTO RELATIVO  min max_m [L_m(a)-L_m(a0)]  (quita offsets entre | con_clcd, cst_to_coords, eval_airfoil_cached, evaluate_airfoil, inputs_definition, obj_noise_robusto, obj_noise_robusto_rel, proyecto_init, setup_problem, write_airfoil_dat, xfoil_out |
| `compare_airfoils_opt.m` | `compare_airfoils_opt(budget)` | COMPARE_AIRFOILS_OPT  Diagnostic only (does NOT touch the manuscript). Optimises the official NACA 63-221 and NACA 63-218 coordinate files at the | con_clcd, cst_to_coords, eval_airfoil_cached, evaluate_airfoil, obj_noise_pure, proyecto_init, setup_problem, write_airfoil_dat, xfoil_out |
| `compare_algorithms.m` | `results = compare_algorithms(varargin)` | COMPARE_ALGORITHMS Benchmark several optimisation algorithms on the SAME problem: | cst_to_coords, eval_airfoil_cached, obj_noise, savefig300, set_pub_defaults, setup_problem |
| `compare_algorithms_seeds.m` | `S = compare_algorithms_seeds(nseed, budget, basefile)` | COMPARE_ALGORITHMS_SEEDS  Repeatability study for the stochastic optimizers. Runs GA, PSO and surrogate optimization with NSEED independent random seeds | eval_airfoil_cached, obj_noise, set_pub_defaults, setup_problem |
| `crossmodel_rel.m` | `crossmodel_rel` |  | evaluate_airfoil, inputs_definition, proyecto_init, xfoil_out |
| `definitive_run.m` | `definitive_run` | DEFINITIVE_RUN  Paper-grade final runs for the two official coordinate files: budget-2000 single-objective optimisation (hard Cl/Cd), full diagnostic | audit_optimization, boundary_layer_table, plot_mechanism, plot_search_domain, proyecto_init, regen_optimum_spectrum, run_optimization, silhouette_variation |
| `definitivo_robusto.m` | `definitivo_robusto` | DEFINITIVO_ROBUSTO  Corrida DEFINITIVA: optimizacion robusta (peor caso TNO/Goody/Kamruzzaman) a presupuesto 2000 (malla convergida 1e-4), dominio | con_clcd, cst_to_coords, eval_airfoil_cached, evaluate_airfoil, inputs_definition, obj_noise_robusto, proyecto_init, setup_problem, write_airfoil_dat, xfoil_out |
| `domain_and_history_63218.m` | `domain_and_history_63218` | DOMAIN_AND_HISTORY_63218 (1) Search-domain figure (CST +-50% reachable band) with the smooth | con_clcd, eval_airfoil_cached, obj_noise_pure, plot_search_domain, proyecto_init, savefig300, set_pub_defaults, setup_problem |
| `env_63221.m` | `env_63221` | ENV_63221  Off-design del NACA 63-221 (caso principal, optimo mono-modelo) en el MISMO rango AOA que el 63-218 (comentario 6 del comite): alpha -8..+6 deg, | evaluate_airfoil, inputs_definition, proyecto_init, pub_colors, savefig300, set_pub_defaults, setup_problem, xfoil_out |
| `find_best_aoa.m` | `aoa_best = find_best_aoa()` | FIND_BEST_AOA  Sweep the angle of attack for the NACA 63-221 baseline at the new operating conditions (U=83.31 m/s, c=0.57 m) and report the angle of | XFOIL_new_airfoil, inputs_definition, proyecto_init |
| `historial_expandido.m` | `historial_expandido` | HISTORIAL_EXPANDIDO  Re-corre las optimizaciones de dominio expandido (deterministicas) registrando el HISTORIAL por evaluacion: OASPL peor-caso | con_clcd, eval_airfoil_cached, obj_noise_robusto, proyecto_init, savefig300, setup_problem |
| `opt_expandido.m` | `opt_expandido(basefile, cap_factor, bw)` | OPT_EXPANDIDO  Optimizacion con DOMINIO EXPANDIDO: permite que el perfil ENGROSE por encima del base (cap subido) y da mas rango a los coeficientes | con_clcd, cst_eval, cst_to_coords, eval_airfoil_cached, load_airfoil, obj_noise_robusto, proyecto_init, savefig300, setup_problem, write_airfoil_dat |
| `opt_robusto_63218.m` | `opt_robusto_63218` | OPT_ROBUSTO_63218  (Etapa 0) Auditoria DINAMICA de como XFOIL toma la geometria + como se restringe la geometria.  (Etapa 1) Optimizacion ROBUSTA | con_clcd, cst_to_coords, eval_airfoil_cached, evaluate_airfoil, inputs_definition, obj_noise_robusto, proyecto_init, setup_problem, write_airfoil_dat, xfoil_out |
| `paper_studies.m` | `paper_studies` | PAPER_STUDIES  Re-runs every manuscript study that depends on the base airfoil, now with the OFFICIAL NACA63221.txt coordinates, so all paper | compare_algorithms, compare_parameterizations, con_clcd, eval_airfoil_cached, obj_noise_pure, proyecto_init, run_multiobjective, sensitivity_analysis, setup_problem |
| `paper_studies2.m` | `paper_studies2` | PAPER_STUDIES2  Resume of paper_studies: the stages that had not finished when the previous batch was interrupted (multiobjective, saturation runs, | con_clcd, eval_airfoil_cached, obj_noise_pure, proyecto_init, run_multiobjective, setup_problem |
| `review_studies.m` | `review_studies` | REVIEW_STUDIES  Three studies requested by the review (critical issue #3): B1: WPS-model sensitivity (TNO vs Goody vs Kamruzzaman) for baseline and | evaluate_airfoil, inputs_definition, proyecto_init, savefig300, xfoil_out |
| `revision_minimo_local.m` | `revision_minimo_local` | REVISION_MINIMO_LOCAL  Verifica si el optimo delgado del NACA 63-218 es un minimo local, SIN tocar la fisica (Amiet/TNO). Solo cambia parametros de la | con_clcd, cst_to_coords, eval_airfoil_cached, evaluate_airfoil, inputs_definition, load_airfoil, obj_noise, obj_noise_pure, proyecto_init, setup_problem, write_airfoil_dat, xfoil_out |
| `sanity_rel.m` | `sanity_rel` |  | inputs_definition, obj_noise_robusto, obj_noise_robusto_rel, proyecto_init, setup_problem |
| `sensitivity_analysis.m` | `sensitivity_analysis(nlev, basefile)` | SENSITIVITY_ANALYSIS One-at-a-time (OAT) sensitivity of the OASPL(A) and Cl/Cd to each CST design | cst_to_coords, eval_airfoil_cached, savefig300, set_pub_defaults, setup_problem |
| `smooth_study_63218.m` | `smooth_study_63218` | SMOOTH_STUDY_63218  Two-part study on the NACA63218 optima: Stage 1 (fast): post-hoc smoothing of the existing optima's CST | con_clcd, cst_to_coords, eval_airfoil_cached, obj_noise_lin, obj_noise_pure, proyecto_init, setup_problem, write_airfoil_dat |
| `study_cases.m` | `S = study_cases(budget, airfoils)` | STUDY_CASES  Exploration (NOT yet part of the paper). Optimises the two official airfoils (NACA 63-221 and NACA 63-218) under THREE single-objective | NarrowToNthOctave, con_cl, con_clcd, cst_to_coords, eval_airfoil_cached, obj_noise_pure, proyecto_init, savefig300, set_pub_defaults, setup_problem, write_airfoil_dat |

## src/utilities/

| Archivo | Firma | Descripción | Llama a |
|---|---|---|---|
| `actualizar_caso.m` | `cfg = actualizar_caso(cfg)` | ACTUALIZAR_CASO  Recalcula las magnitudes derivadas del caso de operación después de editar cfg.caso (cuerda, U, ...) o cfg.fluido: |  |
| `buscar_perfil.m` | `ruta = buscar_perfil(nombre, silencioso)` | BUSCAR_PERFIL  Resuelve el nombre de un archivo de coordenadas a una ruta absoluta. ruta = buscar_perfil('NACA63221.txt') | proyecto_rutas |
| `carpeta_ejecucion.m` | `[carpeta, etiqueta] = carpeta_ejecucion(nombre, base)` | CARPETA_EJECUCION  Crea una carpeta nueva con marca de tiempo para guardar los resultados de una ejecución sin sobrescribir ejecuciones anteriores. | proyecto_rutas |
| `copiar_figura.m` | `destino = copiar_figura(origen, destino_nombre)` | COPIAR_FIGURA  Copia una figura PNG ya guardada en results/figures con otro nombre (sustituye a los copyfile relativos del código original). | proyecto_rutas |
| `proyecto_rutas.m` | `rutas = proyecto_rutas()` | PROYECTO_RUTAS  Estructura con todas las rutas del proyecto (absolutas). Se calcula a partir de la ubicación de este archivo (src/utilities), de modo |  |
| `xfoil_out.m` | `p = xfoil_out(nombre)` | XFOIL_OUT  Ruta completa de un archivo de salida/temporal de XFOIL dentro de la carpeta de trabajo de XFOIL (ver xfoil_workdir). Nombres habituales: | xfoil_workdir |
| `xfoil_workdir.m` | `wd = xfoil_workdir()` | XFOIL_WORKDIR  Carpeta de trabajo de XFOIL (donde está xfoil.exe y donde quedan xfoil_ifile.txt, XFOIL_Output, XFOIL_CP_Output, POLAR_OUTPUT, ...). | proyecto_rutas |

## src/visualization/

| Archivo | Firma | Descripción | Llama a |
|---|---|---|---|
| `collect_figures.m` | `collect_figures()` | COLLECT_FIGURES  Copy the 8 final manuscript figures into paper/figures/. | proyecto_init |
| `fig_cfh_regen.m` | `fig_cfh_regen` | FIG_CFH_REGEN  Re-plot de Fig 5 (Cf y H chordwise, base vs opt del 63-221) con la paleta estandar (succion=azul, presion=naranja; base=solido, opt=discontinuo). | evaluate_airfoil, inputs_definition, proyecto_init, pub_colors, savefig300, set_pub_defaults, xfoil_out |
| `fig_mechanism_aero_v2.m` | `fig_mechanism_aero_v2(basefile)` | FIG_MECHANISM_AERO_V2  Revised aerodynamic/acoustic mechanism figure. Same baseline-vs-optimized comparison as plot_mechanism, but the two | evaluate_airfoil, proyecto_init, pub_colors, savefig300, set_pub_defaults, setup_problem, xfoil_out |
| `fig_param_variables.m` | `fig_param_variables` | FIG_PARAM_VARIABLES  Figura didactica (comentario 3 del comite): muestra COMO y DONDE actuan las variables de diseno de cada parametrizacion sobre el perfil, | hh_fit, load_airfoil, proyecto_init, pub_colors, savefig300, set_pub_defaults |
| `fig_seed_boxplot_regen.m` | `fig_seed_boxplot_regen` | FIG_SEED_BOXPLOT_REGEN  Re-plot del boxplot de 10 semillas (Fig 10) desde datos cacheados (seed_bench_63221.mat). Paleta estandar + leyenda LIMPIA (sin el | proyecto_init, pub_colors, savefig300, set_pub_defaults |
| `fig_sens_modes_merged.m` | `fig_sens_modes_merged` | FIG_SENS_MODES_MERGED  Fusion de la Fig 4 (tornado de sensibilidad) y la Fig A.16 (los 14 modos CST) en una sola figura. Solo-plot desde datos | cst_to_coords, proyecto_init, pub_colors, savefig300, set_pub_defaults |
| `fig_wps_delta_regen.m` | `fig_wps_delta_regen` | FIG_WPS_DELTA_REGEN  Recrea Fig 14: cambio del espectro de presion de pared en x/c=0.99 producido por la optimizacion del 63-221 (DeltaPhi_pp = opt - base) | evaluate_airfoil, inputs_definition, proyecto_init, pub_colors, savefig300, set_pub_defaults, xfoil_out |
| `graficar_comparacion.m` | `fig = graficar_comparacion(resultados, opciones)` | GRAFICAR_COMPARACION  Compara varias predicciones (salidas de predecir_ruido): (a) siluetas de los perfiles | NarrowToNthOctave, load_airfoil, pub_colors |
| `graficar_prediccion.m` | `fig = graficar_prediccion(res, opciones)` | GRAFICAR_PREDICCION  Figura resumen de una predicción (salida de predecir_ruido): (a) espectro de presión de pared en x/c = Mic, succión y presión | NarrowToNthOctave |
| `make_all_figures.m` | `(script)` | MAKE_ALL_FIGURES One-shot driver that produces every final figure for the article. | compare_algorithms, compare_parameterizations, run_multiobjective, run_optimization, sensitivity_analysis, silhouette_variation |
| `paquete_definitivo.m` | `paquete_definitivo` | PAQUETE_DEFINITIVO  Ensambla el paquete final con la geometria DEFINITIVA (robusta, malla convergida). Por caso: coordenadas, polares +-180 (XFOIL+ | NarrowToNthOctave, evaluate_airfoil, inputs_definition, proyecto_init, savefig300, xfoil_out |
| `paquete_figuras.m` | `paquete_figuras` | PAQUETE_FIGURAS  Genera, para 63218 y 63221, la comparacion base vs optimo: polares (tabla + figura 4 paneles), espectro OASPL (3 paneles) e histograma | NarrowToNthOctave, evaluate_airfoil, inputs_definition, proyecto_init, savefig300, xfoil_out |
| `plot_mechanism.m` | `plot_mechanism(basefile)` | PLOT_MECHANISM  Physical mechanism behind the noise reduction: compares the baseline (CST) and optimized airfoils in geometry and aerodynamics/acoustics. | copiar_figura, evaluate_airfoil, load_airfoil, proyecto_init, pub_colors, savefig300, set_pub_defaults, setup_problem, thickness_camber, xfoil_out |
| `plot_search_domain.m` | `plot_search_domain(basefile, optfile)` | PLOT_SEARCH_DOMAIN  Visualise the CST design box (search domain) of the optimiser for a given base airfoil. Because each surface is linear in its CST | copiar_figura, cst_eval, cst_to_coords, load_airfoil, proyecto_init, savefig300, setup_problem |
| `plot_spectrum_compare.m` | `plot_spectrum_compare(P, dv_opt, prefix)` | PLOT_SPECTRUM_COMPARE  OASPL spectrum (SPL vs frequency) baseline vs optimized. Plots narrowband SPL and 1/3-octave bands for both airfoils on one figure. | NarrowToNthOctave, eval_airfoil_cached, savefig300 |
| `plots.m` | `[] = plots(f,I,Phi_pp_s,Phi_pp_p,S_pp,S_pp_s,S_pp_p)` | UNTITLED12 Summary of this function goes here Detailed explanation goes here |  |
| `pub_colors.m` | `c = pub_colors()` | PUB_COLORS  Paleta estandar del paper (tonalidad unica en todas las figuras). Convencion acordada: BASELINE = naranja, OPTIMIZADO = azul (igual que la |  |
| `regen_figs_63218.m` | `regen_figs_63218()` | REGEN_FIGS_63218  Regenerate the two NACA 63-218 paper figures for the ROBUST optimum (plot-only, no XFOIL): geometry (base vs robust vs single-model | proyecto_init, pub_colors, savefig300, set_pub_defaults |
| `report_63218.m` | `report_63218` | REPORT_63218  Comprehensive visualization: geometry + aero + optimization history | load_airfoil, proyecto_init, savefig300 |
| `savefig300.m` | `out = savefig300(figh, fname, widthcm)` | SAVEFIG300  Export a figure at journal quality (600-dpi PNG, sized to a column width). Single-panel figures default to a single column (9 cm); | proyecto_rutas |
| `set_pub_defaults.m` | `set_pub_defaults()` | SET_PUB_DEFAULTS  Journal-quality default graphics settings (Elsevier-style). Call once at the start of any figure-producing routine. Sets serif fonts, |  |
| `silhouette_variation.m` | `silhouette_variation(basefile)` | SILHOUETTE_VARIATION Visualise how the airfoil silhouette varies with the CST design variables. | copiar_figura, cst_to_coords, pub_colors, savefig300, set_pub_defaults, setup_problem |

## src/wall_pressure/

| Archivo | Firma | Descripción | Llama a |
|---|---|---|---|
| `Amiet_Sqq.m` | `[S_qq] = Amiet_Sqq(input, fluid, omega, delta_s)` |  |  |
| `Goody.m` | `[a,b,c,d,e,f,g,h,i,R,phi_s,omega_s] = Goody(omega,tau_w,delta,Ue,u_t,fluid,inputs)` | UNTITLED10 Summary of this function goes here Detailed explanation goes here |  |
| `Integral_Length_scale.m` | `[gamma_y_vv, gamma_x_uu] = Integral_Length_scale(delta, y)` |  |  |
| `Kamruzzaman.m` | `[a,b,c,d,e,f,g,h,i,R,phi_s,omega_s] = Kamruzzaman(inputs,fluid,c_f, theta, dcpdcx,delta_s,Ue, omega, u_t)` |  |  |
| `mean_velocity_profile.m` | `[U,dUdy] = mean_velocity_profile(y,delta,u_t,fluid,inputs, dcpdxc,tau_w,delta_s)` | MEAN_VELOCITY_PROFILE  Perfil medio de velocidad U(y) de la capa limite para el modelo TNO: ley de la pared (lineal / logaritmica) + ley de la estela de Coles. |  |
| `phi_pp_Amiet.m` | `[Phi_pp] = phi_pp_Amiet(omega,inputs,fluid)` | This function calculates the surface pressure spectrum with the simplest model that is the model presented in the paper of Amiet. |  |
| `phi_pp_oneside.m` | `[Phi_pp] = phi_pp_oneside(a,b,c,d,e,f,g,h,i,R,phi_s,omega_s)` |  |  |
| `Point_spectrum.m` | `[Pi_w] = Point_spectrum(U,dUdy, u_y,gamma_y_vv,phi_vv,gamma_p_z,Uc,omega,y,inputs,kx, fluid)` |  |  |
| `spanwise_correlation_length.m` | `[gamma_p_z] = spanwise_correlation_length(omega, Uc)` |  |  |
| `surface_pressure_spectrum.m` | `[Phi_pp_s,Phi_pp_p,Cl,Cd, Cdp, Cm, Cf] = surface_pressure_spectrum(omega,inputs,fluid,model)` | UNTITLED8 Summary of this function goes here Detailed explanation goes here | Amiet_Sqq, Boundary_layer_characteristics, Goody, Kamruzzaman, TNO, XFOIL_new_airfoil, phi_pp_oneside |
| `TNO.m` | `[phi_pp] = TNO(delta,u_t,fluid,inputs, dcpdxc,tau_w,delta_s,omega)` |  | Integral_Length_scale, Point_spectrum, mean_velocity_profile, spanwise_correlation_length, velocity_fluctuations, velocity_spectrum |
| `Turbulence_spectrum.m` | `[phi_ww] = Turbulence_spectrum(Kx,Ky,inputs)` |  |  |
| `velocity_fluctuations.m` | `[u_x,u_y] = velocity_fluctuations(U, inputs)` |  |  |
| `velocity_spectrum.m` | `[phi_uu,phi_vv,Uc,kx] = velocity_spectrum(gamma_x_uu, omega, inputs)` |  |  |

## archive/legacy_utwente/ (no en el path)

| Archivo | Firma | Descripción | Llama a |
|---|---|---|---|
| `Corrige_Perfil.m` | `Corrige_Perfil` |  | — |
| `inputs_definition_StripTheory.m` | `[Strip,fluid,input] = inputs_definition_StripTheory()` |  | — |
| `Main_change_Airfoil.m` | `(script)` | This is the main script to calculate the trailing edge noise at different directivity angles based on the theory of Roger-Moreu 2005. | — |
| `Main_change_AoA.m` | `(script)` | This is the main script to calculate the trailing edge noise at different directivity angles based on the theory of Roger-Moreu 2005. | — |
| `Main_change_TransitionPoint.m` | `(script)` | This is the main script to calculate the trailing edge noise at different directivity angles based on the theory of Roger-Moreu 2005. | — |
| `Main_change_U.m` | `(script)` | This is the main script to calculate the trailing edge noise at different directivity angles based on the theory of Roger-Moreu 2005. | — |
| `Main_Directivity.m` | `(script)` | This is the main script to calculate the trailing edge noise at different directivity angles based on the theory of Roger-Moreu 2005. | — |
| `Main_Inverse_Strip_theory_2D.m` | `(script)` | This is the main script to calculate the trailing edge noise of an airfoil using inverse strip theory of a 2D airofil. | — |
| `Main_Strip_theory_2D.m` | `(script)` | This is the main script to calculate the trailing edge noise of an airfoil using strip theory of a 2D airofil. | — |
| `Main_TE_noise_prediction.m` | `(script)` | This is the main script to calculate the trailing edge noise based on the theory of Roger-Moreu 2005. | — |
| `plots_striptheory.m` | `plots_striptheory(f,S_pp_total,strip)` |  | — |
| `Validation_phi_pp.m` | `(script)` | CODE TO VALIDATE PHI_PP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Get the data | — |
| `Validation_with_Erfan.m` | `(script)` | CODE TO VALIDATE PHI_PP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Get the data | — |
| `Validation_with_Erfan_imag.m` | `(script)` | CODE TO VALIDATE PHI_PP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Get the data | — |
| `XFOIL.m` | `[DSTRS,DSTRP,THETAS,THETAP,CFS,CFP,x_c,Cp,Ue_s,Ue_p, dcpdx_s, dcpdx_p, Cl, Cd, Cdp, Cm,cf] = XFOIL(NACADIG,ALPSTAR,Re,Mach,xtr_s,xtr_p,C,pos)` | This function calculates the displacement thickness using XFOIL. The turbulence intensity is set at 0.07 | — |

## archive/scripts_puntuales/ (no en el path)

| Archivo | Firma | Descripción | Llama a |
|---|---|---|---|
| `cierre_revision.m` | `(script)` | siluetas | — |
| `cierre_robusto.m` | `(script)` | cross-model completo de los candidatos clave silueta | — |
| `correct_history.m` | `(script)` | Actual data from opt_NACA63218_full.log | — |
| `crossmodel_def.m` | `(script)` |  | — |
| `env_63218.m` | `(script)` | figura | — |
| `espectros_fix.m` | `(script)` |  | — |
| `gen_polar_63218.m` | `(script)` | Read XFOIL polars (skip header, read from line 13 onwards) Apply Viterna 360 extension | — |
| `geom_diff.m` | `(script)` |  | — |
| `geom_smooth.m` | `(script)` |  | — |
| `hist_lin.m` | `(script)` | valores reales de opt_lin_NACA63218.log (patternsearch, budget 2000) | — |
| `opt_history.m` | `(script)` | Parse log manually Next lines have data | — |
| `overlay_exp.m` | `(script)` | metricas | — |
| `paper_fig_63218.m` | `(script)` |  | — |
| `polar_naca63218.m` | `(script)` |  | — |
| `run_polar_interactive.m` | `(script)` |  | — |
| `seed_bench.m` | `(script)` |  | — |
| `seed_fig.m` | `p = prctile2(x,q)` | box | — |
| `simple_report.m` | `(script)` | Geometry Polars | — |
| `test_xfoil_18.m` | `(script)` | Test eval on baseline | — |
| `verify_polar_suave.m` | `(script)` | VERIFY_POLAR_SUAVE  Post-process XFOIL CLI sweeps of the smooth optima: coherence checks + Viterna 360 tables + comparison figures. | — |
| `verify_pso.m` | `s = ternary(c,a,b), if c, s=a; else, s=b; end, end` | reproduce seed 4 particleswarm exactly as compare_algorithms_seeds does write geometry for inspection | — |
| `wps_delta_fig.m` | `(script)` |  | — |
| `zoom_le.m` | `(script)` | cuantificar: cuantos puntos oficiales hay en x<0.03 vs CST error CST vs oficial (fidelidad) | — |
