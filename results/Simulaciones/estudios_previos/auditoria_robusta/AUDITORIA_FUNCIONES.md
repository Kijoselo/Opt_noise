# Auditoría completa del proceso geométrico y de cálculo

Auditoría en **3 niveles de lógica**, más verificación de (i) si la geometría
está restringida y (ii) si XFOIL toma bien las geometrías. **Sin tocar la
física.** Combina análisis estático del código y verificación dinámica ejecutada
(Etapa 0 del batch `opt_robusto_63218`).

---

## NIVEL 1 — Geometría (parámetros → coordenadas)

| Función | Qué hace | Verdicto |
|---|---|---|
| `cst_eval` | y = C(x)·S(x) + x·yte, con C=x^0.5(1−x)^1.0 y S=Σ Aᵢ·Bernstein | ✅ Formulación CST (Kulfan) estándar y correcta |
| `cst_fit` | Ajuste por mínimos cuadrados; descarta x=0 y x=1 (la clase se anula ahí, no aportan info de forma) | ✅ Correcto y bien justificado |
| `cst_to_coords` | Muestreo coseno (concentra LE/TE), arma lazo Selig TE→sup→LE→inf→TE | ✅ Correcto |
| `write_airfoil_dat` | Escribe .dat sin encabezado, `%9.5f`, formato que XFOIL lee | ✅ Correcto |
| `load_airfoil` | Lee .dat, maneja punto de referencia espurio, parte en LE (mín x) | ✅ Robusto |

**Hallazgo importante (a favor):** la parametrización es **CST orden 6** → solo
7 coeficientes por superficie. Esto la hace **suave por construcción**: es
*imposible* que genere ondulaciones patológicas de alta frecuencia. La "rareza"
que se percibe NO son wiggles numéricos; es la distribución de espesor/camber.

**Verificación dinámica (round-trip base):** 199 puntos, x∈[0,1], **cierre de
borde de fuga = 0.00e+00 exacto**. La geometría se genera y cierra perfectamente.

---

## NIVEL 2 — Dominio y restricciones (¿está restringida la geometría?)

**SÍ, la geometría está restringida — de forma intencional y correcta:**

| Restricción | Valor (caso 63-218) | Efecto |
|---|---|---|
| Parametrización | CST orden 6, 14 variables | Solo formas CST-representables (suaves) |
| Caja por coeficiente | **±50%** (piso absoluto 0.05) | Cada coef. varía ±50% del base; coefs. casi-cero pueden cambiar de signo |
| Cap de espesor | T ≤ 0.1807 (+tol 1e-3) | No puede engrosar más que el base |
| **Piso de espesor** | **T ≥ 0.0904 (= 0.5·T₀)** | **Permite adelgazar hasta 9%** |
| Adherencia | H ≤ 2.7, Cf ≥ 1.5e-4 (succión, x/c=0.99) | Rechaza flujo separado (validez TNO) |
| Muestreo | 100 puntos/superficie (coseno) | Resolución de la geometría |

**Este es el punto clave de tu inquietud:** el dominio **PERMITE adelgazar hasta
el 9%** (piso = 0.5·T₀). *Por eso* el optimizador pudo producir la geometría
delgada del 13%. No es un error — es que el dominio lo permite. La palanca para
forzar geometrías gruesas convencionales es subir ese piso (`ctx.tmax_min`), como
probamos en el experimento A.

- `setup_problem` (líneas 59-90): define caja, cap, piso, guardas. ✅ Coherente.
- `eval_airfoil_cached` (compute_one): aplica las guardas geométricas (sin cruce,
  cap, piso, frente≥cola) y de adherencia ANTES de aceptar un diseño; inválidos →
  penalización 200 dBA. ✅ Correcto.
- `con_clcd`: Cl/Cd ≥ base (dura). ✅ Correcto.

---

## NIVEL 3 — Interfaz con la física (¿XFOIL toma bien la geometría?)

| Función | Qué hace | Verdicto |
|---|---|---|
| `XFOIL_new_airfoil` | Escribe script XFOIL: `load` .dat → `pane` (repanela) → `visc/mach/iter` → transición → `alfa` → DUMP | ✅ Estándar |
| `evaluate_airfoil` | Cadena: wavesnumbers → integrales de radiación → long. correlación → espectro de pared (XFOIL+modelo) → WPS integrado → campo lejano → OASPL(A) | ✅ Orden correcto, igual a Main |

**Verificación dinámica (lo más importante que pediste):**
- XFOIL **carga** el .dat y lo **repanela a 160 nodos** con `pane` (su malla
  interna estándar).
- **Desvío máximo entre la geometría escrita y la que XFOIL realmente usa:
  4.2×10⁻⁴ c** (sup 4.2e-4, inf 4.2e-4). Es **despreciable** (< 0.05% de la
  cuerda) → **XFOIL toma la geometría correctamente**, sin distorsión.
- Converge y da OASPL(A) = 67.818, Cl = 0.6448, Cd = 0.01073 — **idéntico** al
  baseline de referencia → la cadena es reproducible y consistente.

---

## VEREDICTO DE LA AUDITORÍA

1. **No hay bug de cálculo ni de fidelidad geométrica.** XFOIL toma la geometría
   con desvío 4.2e-4c (despreciable). El cierre de TE es exacto. La cadena
   reproduce el baseline dígito a dígito.
2. **No hay "inventos de datos".** Todo es determinístico y trazable.
3. **La geometría SÍ está restringida** (box ±50%, cap/piso de espesor,
   adherencia), correctamente. La restricción que permitió el perfil delgado es
   el **piso de espesor en 0.5·T₀ = 9%**; subirlo fuerza geometrías gruesas.
4. **La parametrización (CST orden 6) garantiza suavidad** — la geometría rara no
   proviene de ruido numérico, sino de que el optimizador exprime el modelo TNO
   (ver revisión de mínimo local / sobreajuste).

El problema real NO es geométrico ni de cálculo: es que se optimiza el **modelo**
TNO, no el ruido físico. Por eso la optimización robusta multi-modelo (en curso)
es el cierre correcto.

---

## RESULTADO DE LA OPTIMIZACION ROBUSTA (peor caso TNO/Goody/Kamruzzaman)

  geometria       TNO    Goody   Kamruzzaman   Amiet
  base (18%)     67.82   64.08     67.45       68.30
  delgado (13%)  65.76   61.86     67.27       68.62   <- baja SOLO en TNO/Goody
  robusto (15%)  65.93   62.29     65.74       68.72   <- baja en LOS 3 modelos

  REDUCCION (base - optimo):
    delgado(13%):  TNO +2.06 | Goody +2.22 | Kamr +0.18 | Amiet -0.33
    robusto(15%):  TNO +1.89 | Goody +1.79 | Kamr +1.71 | Amiet -0.42

  El optimo ROBUSTO reduce el ruido en LOS TRES modelos de gradiente de presion
  (~1.7-1.9 dB cada uno) simultaneamente -> reduccion FISICAMENTE CREIBLE, no
  sobreajuste a TNO. Geometria: 15% (convencional, pegada al base). Cl/Cd 60.2.
  (Nota: presupuesto 600, se detuvo por presupuesto no por malla 1e-4; podria
   bajar un poco mas con mas presupuesto. Amiet queda ~0.4 dB mas ruidoso pero
   no estaba en el objetivo y da ~68 plano para todo.)

  -> Cambiar el objetivo de "solo TNO" a "peor caso multi-modelo" resuelve las
     dos inquietudes: reduccion creible en varios modelos Y geometria sensata.
