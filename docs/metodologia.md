# Metodología

Este proyecto fue desarrollado con un enfoque de Business Analytics orientado a responder una preocupación concreta del Gerente Comercial:

> **¿Dónde estamos perdiendo oportunidades dentro del pipeline comercial y qué impacto tienen esas pérdidas sobre el negocio?**

El objetivo no fue únicamente construir consultas SQL o visualizar métricas.

La intención fue convertir una preocupación de negocio en un análisis estructurado que permitiera:

- identificar dónde aparece la fricción;
- cuantificar su impacto;
- detectar patrones relevantes;
- y proponer acciones concretas.

---

## 1. Comprender el Problema

El punto de partida fue una preocupación general:

> **“Estamos generando oportunidades, pero muchas no llegan a convertirse en ventas.”**

Antes de analizar datos fue necesario transformar esa preocupación en preguntas concretas.

Las tres principales fueron:

1. ¿Dónde se ralentiza el pipeline?
2. ¿Dónde se pierde mayor valor potencial?
3. ¿Existen vendedores con tasas de pérdida significativamente superiores al resto del equipo?

Estas preguntas definieron la estructura completa del análisis.

---

## 2. Entender el Proceso Comercial

Antes de calcular cualquier KPI fue necesario conocer cómo funciona el pipeline oficial.

El flujo principal es:

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

Una oportunidad puede pasar a `Lost` desde diferentes etapas.

También existen rutas secundarias, saltos y retrocesos.

Estas transiciones se conservaron en los datos, pero se separaron del flujo lineal principal para no mezclar comportamientos distintos.

---

## 3. Validar la Calidad de los Datos

Antes de realizar cálculos se revisaron las tablas principales.

Se validaron:

- IDs;
- nombres de etapas;
- fechas;
- horas;
- relaciones entre tablas;
- consistencia de categorías;
- existencia de historial para cada oportunidad.

Durante esta revisión se identificaron varias inconsistencias.

Entre ellas:

- `Prospect` y `Prospecting` utilizados para representar la misma etapa;
- fecha y hora almacenadas por separado;
- oportunidades sin historial de etapas;
- rutas comerciales no lineales.

Estas inconsistencias fueron tratadas antes de construir los KPIs principales.

---

## 4. Reconstruir el Historial de Cada Oportunidad

La tabla `opportunity_stage_history` contiene los movimientos históricos de cada oportunidad.

Para reconstruir el recorrido se utilizaron:

```text
opportunity_id
```

y:

```text
stage_entered_at
```

Los registros se ordenaron cronológicamente dentro de cada oportunidad.

Esto permitió identificar:

- etapa actual;
- siguiente etapa;
- momento de entrada;
- tiempo transcurrido entre ambas.

De esta forma fue posible analizar el comportamiento real del pipeline y no únicamente el estado final.

---

## 5. Medir la Velocidad del Pipeline

Una vez reconstruidas las transiciones, se calculó cuánto tiempo tarda una oportunidad en avanzar de una etapa a la siguiente.

Se analizaron:

- promedio;
- mediana;
- mínimo;
- máximo.

Las transiciones principales mostraron:

| Transición | Tiempo promedio |
|---|---:|
| Prospecting → Qualified | 13.40 días |
| Qualified → Discovery | 13.73 días |
| Discovery → Proposal | 13.51 días |
| Proposal → Negotiation | 20.77 días |
| Negotiation → Won | 20.72 días |

Esto permitió detectar que el pipeline se vuelve significativamente más lento en las etapas finales.

---

## 6. Clasificar el Comportamiento de las Oportunidades

Cada transición desde una etapa del pipeline se clasificó en tres grupos.

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

La oportunidad sigue una ruta diferente.

Ejemplos:

```text
Proposal → Won
Discovery → Negotiation
Qualified → Prospecting
```

Esta clasificación permitió separar:

- avance normal;
- pérdida;
- comportamiento no lineal.

---

## 7. Medir Advance Rate y Loss Rate

A partir de la clasificación anterior se calcularon dos métricas principales.

### Advance Rate

Mide qué porcentaje de las oportunidades avanza correctamente.

### Loss Rate

Mide qué porcentaje termina directamente en `Lost`.

Los resultados mostraron que la tasa de pérdida aumenta progresivamente a medida que las oportunidades se acercan al cierre.

---

## 8. Medir el Impacto Económico

La cantidad de oportunidades perdidas no era suficiente para evaluar el impacto del problema.

Por esta razón se incorporó:

```text
Amount_usd
```

para calcular:

- valor potencial perdido;
- porcentaje del valor perdido;
- ticket promedio de las oportunidades perdidas.

Este análisis permitió separar dos conceptos:

> **Tasa de pérdida**

y

> **Impacto económico**

La etapa con mayor Loss Rate no necesariamente era la que concentraba mayor valor potencial perdido.

---

## 9. Analizar el Desempeño por Vendedor

Después de identificar las etapas críticas se evaluó si las pérdidas estaban distribuidas de forma uniforme dentro del equipo comercial.

Para evitar comparaciones injustas no se utilizó únicamente la cantidad de oportunidades perdidas.

Se calculó:

```text
Loss Rate por vendedor y por etapa
```

Esto permitió comparar representantes con distintos volúmenes de oportunidades.

También se aplicó un volumen mínimo para evitar conclusiones basadas en muestras demasiado pequeñas.

---

## 10. Construir Rankings por Etapa

Se analizaron los vendedores con mayor Loss Rate en:

- Discovery;
- Proposal;
- Negotiation.

El objetivo no fue identificar “malos vendedores”.

El ranking se utilizó para detectar casos que requerían una investigación adicional.

Se observaron representantes que aparecían repetidamente entre los mayores Loss Rates.

---

## 11. Analizar Deal Size

Antes de concluir que un vendedor tenía problemas de gestión se evaluó si el tamaño de las oportunidades podía explicar parte de las diferencias.

Se comparó:

```text
Average Lost Deal Size
```

contra:

```text
Average Advanced Deal Size
```

Esto permitió responder:

> **¿Los vendedores con mayor Loss Rate están gestionando oportunidades más grandes y potencialmente más difíciles de cerrar?**

Los resultados mostraron que en algunos casos el tamaño del deal puede explicar parte del riesgo, pero no explica por sí solo las diferencias observadas.

---

## 12. Construir los Dashboards

El análisis se dividió en tres dashboards.

### Dashboard 1 — Salud del Pipeline

Responde:

> **¿Dónde se ralentiza y pierde eficiencia el proceso comercial?**

Incluye:

- volumen por etapa;
- Advance Rate;
- Loss Rate;
- tiempo promedio entre etapas.

---

### Dashboard 2 — Valor en Riesgo

Responde:

> **¿Dónde se concentra el mayor impacto económico de las oportunidades perdidas?**

Incluye:

- valor potencial perdido;
- porcentaje del valor perdido;
- cantidad de oportunidades perdidas;
- ticket promedio perdido.

---

### Dashboard 3 — Performance Comercial

Responde:

> **¿Qué vendedores presentan mayores tasas de pérdida y qué factores pueden explicar esas diferencias?**

Incluye:

- Loss Rate por vendedor;
- ranking por etapa;
- volumen gestionado;
- Average Lost Deal Size;
- Average Advanced Deal Size;
- Deal Size Difference.

---

## 13. Convertir Hallazgos en Recomendaciones

El análisis permitió transformar los resultados en cuatro líneas principales de acción.

### Reforzar Discovery

Discovery concentra una parte importante del valor potencial perdido.

### Estandarizar Negotiation

Negotiation presenta la mayor tasa de pérdida y tiempos elevados.

### Implementar Coaching Dirigido

No todos los vendedores muestran el mismo comportamiento.

### Monitorear Pipeline Health

Se recomienda incorporar métricas operativas de forma recurrente.

---

# Flujo Analítico del Proyecto

El proyecto siguió esta secuencia:

```text
Problema de negocio
        ↓
Comprender el proceso
        ↓
Validar los datos
        ↓
Reconstruir el pipeline
        ↓
Medir velocidad
        ↓
Medir pérdidas
        ↓
Medir impacto económico
        ↓
Analizar vendedores
        ↓
Controlar Deal Size
        ↓
Construir dashboards
        ↓
Recomendaciones
```

---

# Enfoque General

La metodología priorizó siempre una pregunta:

> **¿Qué decisión de negocio queremos apoyar con este análisis?**

SQL, Google Sheets y Looker Studio fueron utilizados como herramientas para responder esa pregunta.

El objetivo final no fue producir más métricas, sino convertir los datos del CRM en información accionable para la gestión comercial.
