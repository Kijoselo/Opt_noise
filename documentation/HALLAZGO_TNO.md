# Hallazgo: perfil de velocidad del modelo TNO y orden succión/presión

Fecha: 2026-10-16 (análisis), 2026-10-19 (incorporado al proyecto reorganizado).
Estado: **documentado, no corregido en los resultados publicados**. El código por defecto
sigue reproduciendo el manuscrito; la corrección existe solo como opción de diagnóstico.

## 1. Contexto

La profesora objetó que, a ángulo de ataque positivo, el lado de succión no puede dar menos
ruido que el de presión, mientras que el manuscrito afirma que el lado de presión domina
(65.9 frente a 60.9 dBA en el baseline NACA 63-221). Se verificó que:

- La asignación de lados en la lectura de XFOIL (`XFOIL_new_airfoil.m`: fila `index` =
  succión, `n_nodes-index+1` = presión) es correcta.
- El código en uso es idéntico al zip original de UTwente salvo el lanzador de XFOIL
  (tiempo límite) y los inputs del caso. Con el zip y los inputs del paper se obtienen
  exactamente las cifras del manuscrito.
- El resultado del zip depende de las condiciones: con transición natural succión gana por
  0.2–0.4 dB; con transición forzada en 0.05 (paper) presión gana, y la diferencia
  succión−presión *empeora* al aumentar el ángulo de ataque, al revés de la física.

## 2. Causa

`src/wall_pressure/mean_velocity_profile.m` (idéntico al zip) calcula el parámetro de
Clauser como

```matlab
dcpdx = dcpdxc*(1/inputs.chord);
beta  = delta_s/tau_w*dcpdx;
Pi_w  = 0.8*(beta+0.5)^(3/4);
```

Falta la presión dinámica (`0.5*rho*U^2`) para pasar de dCp/dx a dp/dx (el propio zip la
incluye en `Kamruzzaman.m`). Así `beta ≈ 0.01` y el parámetro de estela queda en
`Pi_w ≈ 0.48` (placa plana sin gradiente) en todos los casos. Consecuencia: el perfil
logarítmico escalado con `u_tau` solo llega a 30–40 m/s en el borde de la capa límite de
succión (Ue ≈ 72 m/s) cuando `Cf` es bajo, mientras que en presión (`Cf` ≈ 1.7e-3) sí llega a
≈70 m/s. `dU/dy` y las fluctuaciones de succión quedan subpredichas.

| Caso | U(δ)/Ue succión (código original) |
|---|---|
| NACA 0012, 0°, c = 0.4 m, U = 56 m/s | 0.76 |
| NACA 63-221 baseline, 4° | 0.41 |
| NACA 63-221 optimizado, 4° | 0.28 |

## 3. Comprobaciones independientes

- **BPM (Brooks–Pope–Marcolini 1989)** con los mismos δ* de XFOIL: succión 82 dBA, presión
  77 dBA (baseline 63-221); cruce a ≈1.5 kHz.
- **Medidas de Kucukosman et al. 2018** (NACA 0012, 4°): succión ≈84 dB, presión ≈79 dB en el
  pico. Los archivos `data/reference/Ref_fig_SPM/*_Goody.tsv` son las curvas del modelo de
  Goody de esa figura (presión > succión), no las medidas.
- **Cierre de Coles** (`cfg.caso.tno_perfil = 'coles'`: Π tal que U(δ) = Ue): reproduce el
  orden medido (succión +5 dB en el pico a 4°, NACA 0012) y en el barrido de 24 condiciones
  del 63-218 succión gana siempre, de +0.6 a +9.5 dB, creciendo con el ángulo de ataque.

## 4. Impacto sobre los resultados publicados

Con el cierre de Coles todos los óptimos salen más ruidosos que sus baselines:

| Caso | original: base → opt [dBA] | Coles: base → opt [dBA] |
|---|---|---|
| NACA 63-221 | 67.10 → 65.81 | 73.09 → 73.87 |
| NACA 63-218 (definitivo) | 67.82 → 65.64 | 72.19 → 73.72 |
| NACA 63-218 (robusto) | 67.82 → 65.93 | 72.19 → 73.94 |

El optimizador llevó `Cf` de succión al piso de la restricción (1.5e-4), lo que reduce `u_tau`
y, con el perfil defectuoso, el ruido predicho; físicamente una capa límite casi separada es más
ruidosa. El mecanismo descrito en el manuscrito (presión dominante, succión baja 4 dB) es un
artefacto de este defecto.

## 5. Otras observaciones sobre el código original

- `Kamruzzaman.m` línea 2: `u_t = 0.0318*56` fijo (valor del NACA 0012 a 56 m/s) y la llamada
  del lado de presión en `surface_pressure_spectrum.m` pasa `u_t_s`. Afecta a la comparación
  entre modelos del manuscrito y a la optimización robusta.
- Validación NACA 0012 (0°): incluso con el cierre de Coles, el pico de Φpp sale a ≈650 Hz
  frente a ≈2.5 kHz en las medidas; el nivel del pico (2πΦpp) queda en 78–83 dB frente a
  ≈81 dB medido. El `Φpp` del código es por rad/s (`plots.m` multiplica por 2π); las tablas
  del manuscrito etiquetadas "dB/Hz" están en esa convención.

## 6. Qué se cambió en el proyecto reorganizado

- `mean_velocity_profile.m` acepta `inputs.tno_perfil = 'original' | 'coles'`. El valor por
  defecto `'original'` es byte a byte la fórmula del zip; `test_reproducibilidad` lo verifica.
- `surface_pressure_spectrum.m` fija `inputs.Ue_lado` antes de cada llamada a TNO (solo lo usa
  el modo `'coles'`).
- `diagnostico_perfil_tno.m` y la sección 3.7 de `Main.mlx` muestran ambos modos.
- No se tocó `Kamruzzaman.m`.

## 7. Pendiente (requiere decisión con la profesora)

1. Acordar la corrección del perfil de velocidad (cierre de Coles u otro modelo apto para
   gradiente adverso) y validarla frente a las medidas del NACA 0012 (nivel y frecuencia del pico).
2. Corregir `u_tau` en Kamruzzaman.
3. Reoptimizar los dos casos con el modelo corregido y revisar la restricción de adherencia
   (el piso de `Cf` es justo la dirección que explotó el optimizador).
4. Reescribir la sección del mecanismo del manuscrito.
