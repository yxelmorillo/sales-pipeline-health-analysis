# Diccionario de Datos

Este documento resume las principales tablas y campos utilizados en el análisis del pipeline comercial.

El objetivo no es documentar toda la base de datos, sino únicamente los campos necesarios para entender cómo se construyeron las métricas y dashboards del proyecto.

---

## 1. Tabla `opportunities`

Contiene la información principal de cada oportunidad comercial.

| Campo | Descripción |
|---|---|
| `opportunity_id` | Identificador único de la oportunidad. |
| `lead_id` | Identificador del lead asociado. |
| `account_id` | Identificador de la cuenta o empresa asociada. |
| `sales_rep_id` | Identificador del vendedor responsable de la oportunidad. |
| `Amount_usd` | Valor potencial de la oportunidad expresado en USD. |
| `Current_Stage2` | Estado actual o final registrado de la oportunidad. |

### Uso en el análisis

Esta tabla se utiliza principalmente para:

- vincular oportunidades con vendedores;
- obtener el valor económico potencial;
- analizar Deal Size;
- calcular valor potencial perdido.

---

## 2. Tabla `opportunity_stage_history`

Contiene el historial de etapas de cada oportunidad.

Cada fila representa el momento en que una oportunidad entra en una determinada etapa.

| Campo | Descripción |
|---|---|
| `history_id` | Identificador único del registro histórico. |
| `opportunity_id` | Identificador de la oportunidad. |
| `Stage` | Etapa del pipeline registrada. |
| `stage_entered_at` | Fecha y hora en que la oportunidad entró en la etapa. |

### Uso en el análisis

Esta tabla es la base principal para reconstruir el pipeline.

Se utiliza para:

- ordenar cronológicamente las etapas;
- identificar la siguiente etapa;
- calcular tiempos de transición;
- identificar pérdidas;
- medir Advance Rate;
- medir Loss Rate;
- detectar rutas no lineales.

---

## 3. Tabla `Sales_rep`

Contiene información de los representantes comerciales.

| Campo | Descripción |
|---|---|
| `sales_rep_id` | Identificador único del vendedor. |
| `sales_rep_name` | Nombre del vendedor. |
| `Country` | País asociado al vendedor. |

### Uso en el análisis

Esta tabla se utiliza para:

- asignar cada oportunidad a un vendedor;
- calcular Loss Rate por representante;
- construir rankings por etapa;
- comparar Deal Size entre vendedores.

---

# Campos Analíticos Derivados

Durante el análisis se crearon métricas y campos derivados a partir de las tablas originales.

---

## `current_stage`

Representa la etapa actual de una oportunidad dentro de una transición.

Ejemplo:

```text
Proposal
```

---

## `next_stage`

Representa la siguiente etapa cronológica registrada para una oportunidad.

Se obtiene a partir del historial ordenado por:

```text
opportunity_id
+
stage_entered_at
```

Ejemplo:

```text
Proposal → Negotiation
```

---

## `duration_days`

Cantidad de días transcurridos entre la entrada a una etapa y la entrada a la siguiente.

Conceptualmente:

```text
duration_days =
next_stage_entered_at
-
current_stage_entered_at
```

Se utiliza para analizar la velocidad del pipeline.

---

## `outcome`

Clasificación utilizada para interpretar una transición.

Puede tomar tres valores:

```text
Advanced
Lost
Other
```

### Advanced

La oportunidad avanza hacia la siguiente etapa esperada.

### Lost

La siguiente etapa registrada es `Lost`.

### Other

La oportunidad sigue una ruta distinta al pipeline lineal principal.

---

## `advance_rate`

Porcentaje de oportunidades que avanzan hacia la siguiente etapa esperada.

Conceptualmente:

```text
Advance Rate =
Advanced Opportunities
/
Total Stage Exits
```

---

## `loss_rate`

Porcentaje de oportunidades que pasan directamente a `Lost`.

Conceptualmente:

```text
Loss Rate =
Lost Opportunities
/
Total Stage Exits
```

---

## `other_transition_rate`

Porcentaje de oportunidades que siguen una ruta diferente al avance esperado o a `Lost`.

Incluye:

- saltos de etapa;
- retrocesos;
- Needs Analysis;
- otras rutas no lineales.

---

## `potential_usd_lost`

Suma del valor potencial de las oportunidades que pasan a `Lost`.

Se calcula utilizando:

```text
Amount_usd
```

No representa revenue real perdido.

Representa:

> **valor potencial del pipeline que no llegó a convertirse en venta**

---

## `percentage_total_usd_lost`

Porcentaje del valor potencial perdido total que corresponde a una etapa específica.

Conceptualmente:

```text
Potential USD Lost in Stage
/
Total Potential USD Lost
```

---

## `avg_lost_deal_usd`

Valor promedio de las oportunidades que terminan en `Lost`.

---

## `avg_advanced_deal_usd`

Valor promedio de las oportunidades que avanzan correctamente a la siguiente etapa.

---

## `deal_size_difference_usd`

Diferencia entre el valor promedio de las oportunidades perdidas y las oportunidades avanzadas.

Conceptualmente:

```text
Deal Size Difference =
Average Lost Deal Size
-
Average Advanced Deal Size
```

Interpretación:

- positivo: los deals perdidos son más grandes;
- cercano a cero: el tamaño del deal parece similar;
- negativo: los deals avanzados son más grandes.

---

## `loss_rank`

Ranking de vendedores según Loss Rate dentro de una etapa específica.

Se utiliza para construir:

```text
Top 5 Sales Reps by Loss Rate
```

por etapa del pipeline.

---

# Relaciones Principales

Las principales relaciones utilizadas durante el análisis son:

```text
opportunities
      |
      | opportunity_id
      ↓
opportunity_stage_history
```

y:

```text
opportunities
      |
      | sales_rep_id
      ↓
Sales_rep
```

Esto permite combinar:

- comportamiento dentro del pipeline;
- valor económico;
- vendedor responsable.

---

# Consideraciones de Calidad

Durante la preparación de los datos se identificaron algunas inconsistencias relevantes.

### Etapas inconsistentes

Se encontraron valores como:

```text
Prospect
Prospecting
```

Ambos fueron normalizados como:

```text
Prospecting
```

---

### Fecha y hora separadas

La fecha y la hora de entrada a cada etapa se encontraban originalmente almacenadas por separado.

Se combinaron en:

```text
stage_entered_at
```

para facilitar el análisis temporal.

---

### Oportunidades sin historial

Se identificaron:

```text
120 oportunidades
```

presentes en `opportunities` sin registros correspondientes en `opportunity_stage_history`.

Estas oportunidades fueron excluidas de los análisis que requieren reconstruir el recorrido dentro del pipeline.

---

# Alcance del Diccionario

Este diccionario documenta únicamente los campos relevantes para el Caso 2.

No pretende representar toda la estructura de la base de datos.

El foco está en los elementos necesarios para comprender:

- salud del pipeline;
- valor en riesgo;
- desempeño comercial;
- Deal Size;
- métricas de conversión y pérdida.
