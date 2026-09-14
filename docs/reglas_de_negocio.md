# Reglas de Negocio

Este documento define las reglas utilizadas para interpretar el pipeline comercial y calcular las métricas principales del análisis.

El objetivo es asegurar que cualquier persona que revise el proyecto entienda qué significa cada transición, cómo se clasifican las oportunidades y qué criterios se utilizaron para construir los dashboards.

---

## 1. Pipeline Comercial Oficial

El flujo principal del proceso comercial es:

```text
Prospecting
    ↓
Qualified
    ↓
Discovery
    ↓
Proposal
    ↓
Negotiation
    ↓
Won
```

Este flujo representa la secuencia esperada para una oportunidad que avanza normalmente hasta convertirse en una venta.

Una oportunidad también puede terminar como `Lost` desde distintas etapas del pipeline.

---

## 2. Definición de Avance Correcto

Una oportunidad se considera que **avanza correctamente** cuando pasa a la siguiente etapa esperada del pipeline oficial.

Las transiciones lineales válidas son:

| Etapa actual | Siguiente etapa esperada |
|---|---|
| Prospecting | Qualified |
| Qualified | Discovery |
| Discovery | Proposal |
| Proposal | Negotiation |
| Negotiation | Won |

Estas transiciones se clasifican como:

```text
Advanced
```

---

## 3. Definición de Lost

Una oportunidad se considera **perdida** cuando la siguiente etapa registrada en su historial es:

```text
Lost
```

Ejemplos:

```text
Prospecting → Lost
Qualified → Lost
Discovery → Lost
Proposal → Lost
Negotiation → Lost
```

Esto permite identificar en qué momento del proceso comercial se abandona una oportunidad.

---

## 4. Needs Analysis

La etapa:

```text
Needs Analysis
```

aparece en el historial comercial, pero no forma parte del pipeline lineal principal.

Se interpreta como una **ruta secundaria o condicional** que puede utilizarse cuando una oportunidad requiere una evaluación adicional antes de continuar.

Por esta razón:

- no se elimina del dataset;
- no se considera una etapa obligatoria;
- no se incluye como parte del pipeline lineal principal;
- puede analizarse de forma independiente si fuera necesario.

---

## 5. Transiciones No Lineales

Durante el análisis se identificaron movimientos que no siguen el orden oficial del pipeline.

Ejemplos:

```text
Discovery → Negotiation
Proposal → Won
Qualified → Prospecting
Discovery → Qualified
```

Estas transiciones pueden representar:

- saltos de etapa;
- retrocesos;
- reclasificaciones;
- rutas secundarias;
- inconsistencias en el uso del CRM.

No se modifican automáticamente.

Para los KPIs principales del pipeline se separan del flujo lineal y se clasifican como:

```text
Other
```

---

## 6. Clasificación de Transiciones

Cada salida desde una etapa del pipeline se clasifica en uno de tres grupos:

### Advanced

La oportunidad avanza hacia la siguiente etapa esperada.

Ejemplo:

```text
Proposal → Negotiation
```

### Lost

La oportunidad pasa directamente a `Lost`.

Ejemplo:

```text
Proposal → Lost
```

### Other

La oportunidad:

- salta una etapa;
- retrocede;
- pasa por `Needs Analysis`;
- o sigue una ruta diferente al pipeline oficial.

Ejemplo:

```text
Proposal → Won
```

---

## 7. Cálculo del Tiempo entre Etapas

El tiempo de transición se calcula utilizando la fecha y hora en que una oportunidad entra en una etapa y la fecha y hora en que entra en la siguiente.

Conceptualmente:

```text
Tiempo de transición =
Fecha/Hora de entrada a la siguiente etapa
-
Fecha/Hora de entrada a la etapa actual
```

Las métricas utilizadas son:

- promedio de días;
- mediana de días;
- mínimo;
- máximo.

La mediana se utiliza como control para verificar si algunos casos extremos están distorsionando el promedio.

---

## 8. Advance Rate

El `Advance Rate` mide qué porcentaje de las oportunidades que salen de una etapa avanzan hacia la siguiente etapa esperada.

Conceptualmente:

```text
Advance Rate =
Oportunidades que avanzan correctamente
/
Total de salidas desde la etapa
```

Ejemplo:

Si 100 oportunidades salen de `Proposal` y 60 pasan a `Negotiation`:

```text
Advance Rate = 60%
```

---

## 9. Loss Rate

El `Loss Rate` mide qué porcentaje de las oportunidades que salen de una etapa pasan directamente a `Lost`.

Conceptualmente:

```text
Loss Rate =
Oportunidades que pasan a Lost
/
Total de salidas desde la etapa
```

Ejemplo:

Si 100 oportunidades salen de `Negotiation` y 37 pasan a `Lost`:

```text
Loss Rate = 37%
```

---

## 10. Other Transition Rate

El `Other Transition Rate` mide qué porcentaje de las oportunidades siguen una ruta distinta al avance lineal esperado o a `Lost`.

Conceptualmente:

```text
Other Transition Rate =
Oportunidades clasificadas como Other
/
Total de salidas desde la etapa
```

Esta métrica permite detectar:

- saltos;
- retrocesos;
- rutas secundarias;
- comportamientos no estándar del pipeline.

---

## 11. Valor Potencial Perdido

El impacto económico de una oportunidad perdida se calcula utilizando:

```text
Amount_usd
```

de la tabla `opportunities`.

Este valor se interpreta como:

> **valor potencial del pipeline perdido**

y no como ingresos reales que la empresa ya hubiera generado.

Por esa razón, el análisis utiliza expresiones como:

- Valor Potencial Perdido
- Pipeline Value Lost
- Potential USD Lost

y evita describirlo como revenue efectivamente perdido.

---

## 12. Porcentaje del Valor Potencial Perdido

Para entender qué etapa concentra mayor impacto económico se calcula:

```text
Porcentaje del Valor Potencial Perdido =
Valor potencial perdido en la etapa
/
Valor potencial perdido total
```

Esta métrica permite diferenciar entre:

- la etapa con mayor tasa de pérdida;
- y la etapa con mayor impacto económico absoluto.

Ambas pueden ser diferentes.

---

## 13. Deal Size

Para evaluar si el tamaño de las oportunidades puede explicar parte del desempeño de un vendedor se comparan:

```text
Average Lost Deal Size
```

vs.

```text
Average Advanced Deal Size
```

La diferencia se calcula como:

```text
Deal Size Difference =
Average Lost Deal Size
-
Average Advanced Deal Size
```

Interpretación:

### Diferencia positiva

Las oportunidades perdidas tienen mayor valor promedio que las oportunidades que avanzan.

### Diferencia cercana a cero

El tamaño del deal no parece explicar una diferencia relevante.

### Diferencia negativa

Las oportunidades que avanzan tienen mayor valor promedio que las oportunidades perdidas.

El Deal Size se utiliza como un factor explicativo potencial, no como una causa definitiva.

---

## 14. Evaluación de Sales Representatives

Los vendedores no se comparan únicamente por cantidad de oportunidades perdidas.

La métrica principal utilizada es:

```text
Loss Rate por vendedor y por etapa
```

Esto evita penalizar automáticamente a vendedores que gestionan un mayor volumen de oportunidades.

Para evitar conclusiones basadas en muestras demasiado pequeñas, los rankings principales consideran únicamente vendedores con un volumen mínimo de oportunidades en la etapa analizada.

---

## 15. Top 5 por Etapa

Para identificar vendedores que requieren mayor atención se construyen rankings separados para:

- Discovery
- Proposal
- Negotiation

En cada etapa se seleccionan los vendedores con mayor:

```text
Loss Rate
```

El objetivo no es concluir automáticamente que un vendedor tiene bajo desempeño.

El ranking se utiliza para identificar casos que requieren una revisión adicional de:

- seguimiento;
- negociación;
- manejo de objeciones;
- pricing;
- características de los deals asignados.

---

## 16. Oportunidades sin Historial

Se identificaron:

```text
120 oportunidades
```

presentes en la tabla:

```text
opportunities
```

sin registros correspondientes en:

```text
opportunity_stage_history
```

Debido a que no es posible reconstruir su recorrido dentro del pipeline, estas oportunidades se excluyen de los análisis que requieren:

- transiciones;
- tiempo entre etapas;
- Advance Rate;
- Loss Rate;
- reconstrucción del pipeline.

Las oportunidades con historial válido constituyen la base del análisis principal.

---

## 17. Normalización de Etapas

Durante la preparación de los datos se identificaron etiquetas inconsistentes.

Ejemplo:

```text
Prospect
Prospecting
```

Ambas representaban la misma etapa.

La categoría fue normalizada como:

```text
Prospecting
```

para evitar dividir artificialmente una misma fase en dos categorías distintas.

---

## 18. Fecha y Hora de Entrada a una Etapa

La fecha y la hora se encontraban almacenadas originalmente en columnas separadas.

Para facilitar el análisis se combinaron en una sola variable:

```text
stage_entered_at
```

Esta variable representa el momento exacto en que una oportunidad entra en una etapa del pipeline.

Se utiliza para:

- ordenar cronológicamente el historial;
- identificar la siguiente etapa;
- calcular el tiempo entre transiciones.

---

## 19. Reconstrucción del Historial

El recorrido de cada oportunidad se reconstruye utilizando:

```text
opportunity_id
```

y:

```text
stage_entered_at
```

Los registros se ordenan cronológicamente dentro de cada oportunidad para identificar:

- etapa actual;
- siguiente etapa;
- momento de entrada;
- duración entre ambas.

Esto permite analizar el comportamiento real del pipeline y no únicamente el estado final.

---

## 20. Principio de Interpretación

Las métricas del proyecto se utilizan para identificar:

- fricción;
- riesgo;
- patrones;
- desviaciones;
- oportunidades de mejora.

No se utilizan para atribuir causalidad automática.

Por ejemplo:

Un vendedor con mayor Loss Rate no se considera automáticamente un mal vendedor.

Primero se revisan factores como:

- volumen de oportunidades;
- Deal Size;
- etapa del pipeline;
- características de los clientes;
- contexto comercial.

El objetivo del análisis es orientar la investigación y apoyar decisiones de negocio con evidencia.
