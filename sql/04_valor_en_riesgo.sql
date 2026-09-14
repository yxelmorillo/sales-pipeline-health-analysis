/* ============================================================
   CASO 2 — ANÁLISIS DE SALUD DEL PIPELINE COMERCIAL
   Archivo: 04_valor_en_riesgo.sql

   Objetivo:
   Medir el impacto económico de las oportunidades perdidas
   dentro del pipeline comercial.

   Este archivo analiza:
   1. Oportunidades que pasan a Lost
   2. Valor potencial perdido por etapa
   3. Ticket promedio perdido
   4. Porcentaje del valor potencial perdido
   5. Diferencia entre tasa de pérdida e impacto económico
   ============================================================ */


/* ============================================================
   1. RECONSTRUIR TRANSICIONES HACIA LOST

   Se identifica desde qué etapa del pipeline una oportunidad
   pasa directamente a Lost.
   ============================================================ */

WITH Stage_Flow AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage

    FROM opportunity_stage_history
)

SELECT
    opportunity_id,
    current_stage,
    next_stage

FROM Stage_Flow

WHERE next_stage = 'Lost'

  AND current_stage IN (
      'Prospecting',
      'Qualified',
      'discovery',
      'proposal',
      'negotiation'
  )

ORDER BY
    current_stage,
    opportunity_id;


/* ============================================================
   2. UNIR LAS PÉRDIDAS CON EL VALOR ECONÓMICO

   Amount_usd representa el valor potencial de la oportunidad.

   Importante:
   No se interpreta como revenue real perdido.
   Representa valor potencial del pipeline que no llegó
   a convertirse en venta.
   ============================================================ */

WITH Stage_Flow AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage

    FROM opportunity_stage_history
),

Lost_Opportunities AS (

    SELECT
        sf.opportunity_id,
        sf.current_stage,
        o.Amount_usd

    FROM Stage_Flow sf

    INNER JOIN opportunities o
        ON sf.opportunity_id = o.opportunity_id

    WHERE sf.next_stage = 'Lost'

      AND sf.current_stage IN (
          'Prospecting',
          'Qualified',
          'discovery',
          'proposal',
          'negotiation'
      )
)

SELECT
    opportunity_id,
    current_stage,
    Amount_usd

FROM Lost_Opportunities

ORDER BY
    current_stage,
    Amount_usd DESC;


/* ============================================================
   3. VALOR POTENCIAL PERDIDO POR ETAPA

   Esta consulta constituye la base principal del Dashboard 2.
   ============================================================ */

WITH Stage_Flow AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage

    FROM opportunity_stage_history
),

Lost_Opportunities AS (

    SELECT
        sf.opportunity_id,
        sf.current_stage,
        o.Amount_usd,

        CASE sf.current_stage
            WHEN 'Prospecting' THEN 1
            WHEN 'Qualified' THEN 2
            WHEN 'discovery' THEN 3
            WHEN 'proposal' THEN 4
            WHEN 'negotiation' THEN 5
        END AS pipeline_order

    FROM Stage_Flow sf

    INNER JOIN opportunities o
        ON sf.opportunity_id = o.opportunity_id

    WHERE sf.next_stage = 'Lost'

      AND sf.current_stage IN (
          'Prospecting',
          'Qualified',
          'discovery',
          'proposal',
          'negotiation'
      )
),

Stage_Losses AS (

    SELECT
        pipeline_order,
        current_stage,

        COUNT(*) AS lost_opportunities,

        SUM(Amount_usd) AS potential_usd_lost,

        AVG(Amount_usd) AS avg_lost_deal_usd

    FROM Lost_Opportunities

    GROUP BY
        pipeline_order,
        current_stage
)

SELECT
    pipeline_order,
    current_stage,

    lost_opportunities,

    CAST(
        potential_usd_lost
        AS DECIMAL(18,2)
    ) AS potential_usd_lost,

    CAST(
        avg_lost_deal_usd
        AS DECIMAL(18,2)
    ) AS avg_lost_deal_usd,

    CAST(
        potential_usd_lost * 100.0
        / NULLIF(SUM(potential_usd_lost) OVER (), 0)
        AS DECIMAL(10,2)
    ) AS percentage_total_usd_lost

FROM Stage_Losses

ORDER BY
    pipeline_order;


/* ============================================================
   4. RANKING DE ETAPAS POR IMPACTO ECONÓMICO

   Ordena las etapas desde mayor a menor valor potencial perdido.
   ============================================================ */

WITH Stage_Flow AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage

    FROM opportunity_stage_history
),

Lost_Opportunities AS (

    SELECT
        sf.opportunity_id,
        sf.current_stage,
        o.Amount_usd

    FROM Stage_Flow sf

    INNER JOIN opportunities o
        ON sf.opportunity_id = o.opportunity_id

    WHERE sf.next_stage = 'Lost'

      AND sf.current_stage IN (
          'Prospecting',
          'Qualified',
          'discovery',
          'proposal',
          'negotiation'
      )
)

SELECT
    current_stage,

    COUNT(*) AS lost_opportunities,

    CAST(
        SUM(Amount_usd)
        AS DECIMAL(18,2)
    ) AS potential_usd_lost,

    CAST(
        AVG(Amount_usd)
        AS DECIMAL(18,2)
    ) AS avg_lost_deal_usd,

    RANK() OVER (
        ORDER BY SUM(Amount_usd) DESC
    ) AS economic_loss_rank

FROM Lost_Opportunities

GROUP BY
    current_stage

ORDER BY
    economic_loss_rank;


/* ============================================================
   5. COMPARAR IMPACTO ECONÓMICO VS CANTIDAD DE PÉRDIDAS

   Permite detectar si una etapa pierde mucho valor por:
   - alta cantidad de oportunidades perdidas
   - alto ticket promedio
   - o una combinación de ambos factores
   ============================================================ */

WITH Stage_Flow AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage

    FROM opportunity_stage_history
),

Lost_Opportunities AS (

    SELECT
        sf.opportunity_id,
        sf.current_stage,
        o.Amount_usd

    FROM Stage_Flow sf

    INNER JOIN opportunities o
        ON sf.opportunity_id = o.opportunity_id

    WHERE sf.next_stage = 'Lost'

      AND sf.current_stage IN (
          'Prospecting',
          'Qualified',
          'discovery',
          'proposal',
          'negotiation'
      )
)

SELECT
    current_stage,

    COUNT(*) AS lost_opportunities,

    CAST(
        SUM(Amount_usd)
        AS DECIMAL(18,2)
    ) AS potential_usd_lost,

    CAST(
        AVG(Amount_usd)
        AS DECIMAL(18,2)
    ) AS avg_lost_deal_usd

FROM Lost_Opportunities

GROUP BY
    current_stage

ORDER BY
    potential_usd_lost DESC;


/* ============================================================
   6. RESULTADOS PRINCIPALES DEL ANÁLISIS

   Los resultados obtenidos fueron aproximadamente:

   Discovery:
   - ~886 oportunidades perdidas
   - ~$57.21M de valor potencial perdido
   - ~27.25% del valor potencial perdido total

   Proposal:
   - ~756 oportunidades perdidas
   - ~$46.98M de valor potencial perdido
   - ~22.38% del total

   Qualified:
   - ~704 oportunidades perdidas
   - ~$45.78M de valor potencial perdido
   - ~21.80% del total

   Negotiation:
   - ~543 oportunidades perdidas
   - ~$33.19M de valor potencial perdido
   - ~15.81% del total

   Prospecting:
   - ~421 oportunidades perdidas
   - ~$26.80M de valor potencial perdido
   - ~12.76% del total

   ============================================================ */


/* ============================================================
   7. INTERPRETACIÓN DE NEGOCIO

   El principal hallazgo es que:

   - Negotiation presenta el mayor Loss Rate.
   - Sin embargo, Discovery concentra el mayor valor potencial
     perdido en términos absolutos.

   Esto demuestra que:

   La etapa con mayor tasa de pérdida no necesariamente es la
   etapa con mayor impacto económico.

   Muchas oportunidades abandonan el pipeline antes de llegar
   a Negotiation, lo que provoca que una parte importante del
   valor potencial se pierda en etapas anteriores.

   Este resultado justifica priorizar acciones de mejora tanto
   en Discovery como en las etapas finales del pipeline.
   ============================================================ */
