# Contexto del Negocio

## Situación Inicial

El Gerente Comercial detectó una preocupación dentro del equipo de ventas:

> **“Estamos generando oportunidades, pero muchas no llegan a convertirse en ventas. Necesito entender dónde se está perdiendo el negocio, cuánto valor representa y qué partes del proceso comercial requieren atención.”**

La preocupación no era únicamente saber cuántas oportunidades terminaban en `Lost`.

El objetivo era entender **cómo se comportaba el pipeline**, identificar dónde aparecía la fricción y convertir esa información en decisiones concretas para mejorar la conversión comercial.

---

## Stakeholder

El principal stakeholder del análisis es el:

> **Gerente Comercial**

Sus responsabilidades incluyen:

- supervisar el pipeline de ventas;
- monitorear la conversión entre etapas;
- identificar cuellos de botella;
- reducir oportunidades perdidas;
- mejorar la eficiencia del equipo comercial;
- priorizar acciones de coaching;
- proteger el valor potencial del pipeline.

El análisis fue diseñado para ayudarlo a responder una pregunta sencilla:

> **¿Dónde deberíamos intervenir primero?**

---

## Problema de Negocio

La empresa genera oportunidades comerciales de forma constante, pero una proporción importante no termina convirtiéndose en ventas.

Esto genera varias preguntas:

- ¿Las oportunidades se están perdiendo demasiado temprano?
- ¿El proceso comercial tarda demasiado en determinadas etapas?
- ¿Las pérdidas se concentran cerca del cierre?
- ¿Estamos perdiendo muchas oportunidades pequeñas o pocas oportunidades de alto valor?
- ¿Todos los vendedores presentan un comportamiento similar?
- ¿Existen representantes con tasas de pérdida significativamente superiores al resto del equipo?

El problema no podía resolverse únicamente contando oportunidades `Won` y `Lost`.

Era necesario reconstruir el recorrido comercial completo.

---

## Pregunta Principal

La pregunta central del caso fue:

> **¿Dónde estamos perdiendo oportunidades dentro del pipeline comercial y qué impacto tienen esas pérdidas sobre el negocio?**

---

## Preguntas que Queríamos Responder

El análisis se estructuró alrededor de tres grandes áreas.

### 1. Salud del Pipeline

Queríamos entender:

- cuánto tarda una oportunidad en avanzar entre etapas;
- dónde se ralentiza el proceso;
- qué porcentaje avanza correctamente;
- qué porcentaje termina en `Lost`;
- en qué etapa comienza a deteriorarse la conversión.

---

### 2. Valor en Riesgo

No todas las oportunidades tienen el mismo valor.

Por eso también necesitábamos responder:

- ¿en qué etapa se pierde mayor cantidad de valor potencial?;
- ¿la etapa con mayor Loss Rate es también la que representa mayor impacto económico?;
- ¿cuál es el ticket promedio de las oportunidades perdidas?;
- ¿qué porcentaje del valor potencial perdido se concentra en cada etapa?

---

### 3. Performance Comercial

Finalmente, queríamos saber si las pérdidas estaban distribuidas de forma uniforme dentro del equipo.

Las preguntas principales fueron:

- ¿qué vendedores presentan mayor Loss Rate?;
- ¿en qué etapas aparecen esas diferencias?;
- ¿existen vendedores que aparecen repetidamente entre los peores resultados?;
- ¿el tamaño de los deals puede explicar parte de esas diferencias?

---

## Pipeline Comercial Oficial

El proceso comercial principal de la empresa sigue esta secuencia:

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

### Prospecting

En esta etapa se identifican posibles clientes y se abre una oportunidad comercial.

El objetivo es determinar si existe suficiente potencial para continuar investigando.

---

### Qualified

La oportunidad pasa por un primer filtro comercial.

Se valida que exista un nivel suficiente de encaje, necesidad y posibilidad de compra como para justificar una investigación más profunda.

---

### Discovery

El vendedor profundiza en la situación del cliente.

Se busca entender:

- problema;
- necesidad;
- contexto;
- urgencia;
- stakeholders;
- impacto;
- expectativas.

El objetivo es comprender suficientemente la oportunidad antes de preparar una propuesta.

---

### Proposal

Se presenta formalmente una solución comercial.

Puede incluir:

- alcance;
- precio;
- condiciones;
- tiempos;
- implementación;
- propuesta de valor.

---

### Negotiation

El cliente está evaluando seriamente la compra.

En esta etapa pueden negociarse:

- precio;
- descuentos;
- términos;
- alcance;
- condiciones contractuales;
- tiempos;
- aprobaciones internas.

---

### Won

La oportunidad se convierte en una venta.

---

### Lost

`Lost` no forma parte de la secuencia lineal principal.

Una oportunidad puede terminar como `Lost` desde distintas etapas del proceso.

Ejemplos:

```text
Prospecting → Lost
Qualified → Lost
Discovery → Lost
Proposal → Lost
Negotiation → Lost
```

Esto permite analizar en qué punto del pipeline se está abandonando el proceso comercial.

---

## Rutas Secundarias

El historial también contiene movimientos que no siguen exactamente el pipeline principal.

Entre ellos:

- `Needs Analysis`;
- saltos de etapas;
- retrocesos;
- reclasificaciones.

Estas rutas fueron conservadas en los datos porque pueden representar comportamiento real del CRM.

Sin embargo, para analizar la salud general del proceso se utilizó como referencia el pipeline oficial.

---

## Decisiones que Queríamos Apoyar

El análisis no fue diseñado únicamente para describir lo ocurrido.

La intención era ayudar al Gerente Comercial a decidir:

- qué etapa del pipeline requiere mayor atención;
- dónde se está perdiendo mayor valor potencial;
- si es necesario mejorar la calidad de Discovery;
- si Negotiation necesita un proceso más estructurado;
- qué vendedores requieren una revisión más profunda;
- dónde conviene enfocar coaching y seguimiento;
- qué KPIs deberían monitorearse regularmente.

---

## Resultado Esperado

Al finalizar el análisis, el Gerente Comercial debería poder pasar de una preocupación general como:

> **“Estamos perdiendo demasiadas oportunidades.”**

a preguntas mucho más concretas:

> **“¿Dónde está ocurriendo la pérdida?”**

> **“¿Cuánto valor está en riesgo?”**

> **“¿Qué parte del proceso debemos mejorar primero?”**

> **“¿Qué vendedores requieren una revisión adicional?”**

El objetivo final del proyecto es transformar datos del CRM en una visión clara de la salud del pipeline y en prioridades accionables para el negocio.
