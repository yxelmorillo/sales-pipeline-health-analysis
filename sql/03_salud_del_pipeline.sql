/* ============================================================
   CASO 2 — ANÁLISIS DE SALUD DEL PIPELINE COMERCIAL
   Archivo: 03_salud_del_pipeline.sql

   Objetivo:
   Medir la eficiencia operativa del pipeline comercial.

   Este archivo analiza:
   1. Volumen de salidas por etapa
   2. Advance Rate
   3. Loss Rate
   4. Other Transition Rate
   5. Tiempo promedio para avanzar
   6. Mediana de días por etapa
   7. Velocidad del pipeline lineal oficial
   ============================================================ */


/* ============================================================
   1. RECONSTRUIR TRANSICIONES
   ============================================================ */

WITH Stage_Flow AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,
        stage_entered_at AS current_stage_entered_at,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage,

        LEAD(stage_entered_at) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage_entered_at

    FROM opportunity_stage_history
),

Pipeline_Flow AS (

    SELECT
        opportunity_id,
        current_stage,
        next_stage,

        DATEDIFF(
            HOUR,
            current_stage_entered_at,
            next_stage_entered_at
        ) / 24.0 AS duration_days,

        CASE

            WHEN current_stage = 'Prospecting'
                 AND next_stage = 'Qualified'
                THEN 'Advanced'

            WHEN current_stage = 'Qualified'
                 AND next_stage = 'discovery'
                THEN 'Advanced'

            WHEN current_stage = 'discovery'
                 AND next_stage = 'proposal'
                THEN 'Advanced'

            WHEN current_stage = 'proposal'
                 AND next_stage = 'negotiation'
                THEN 'Advanced'

            WHEN current_stage = 'negotiation'
                 AND next_stage = 'Won'
                THEN 'Advanced'

            WHEN next_stage = 'Lost'
                THEN 'Lost'

            ELSE 'Other'

        END AS outcome,

        CASE current_stage
            WHEN 'Prospecting' THEN 1
            WHEN 'Qualified' THEN 2
            WHEN 'discovery' THEN 3
            WHEN 'proposal' THEN 4
            WHEN 'negotiation' THEN 5
        END AS pipeline_order

    FROM Stage_Flow

    WHERE current_stage IN (
        'Prospecting',
        'Qualified',
        'discovery',
        'proposal',
        'negotiation'
    )

      AND next_stage IS NOT NULL
      AND next_stage_entered_at IS NOT NULL
      AND next_stage_entered_at >= current_stage_entered_at
),

Pipeline_Stats AS (

    SELECT
        *,

        PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY duration_days
        ) OVER (
            PARTITION BY current_stage
        ) AS median_duration_days

    FROM Pipeline_Flow
)


/* ============================================================
   2. KPI PRINCIPAL DE SALUD DEL PIPELINE

   Devuelve una fila por etapa con:

   - total de salidas
   - oportunidades avanzadas
   - oportunidades perdidas
   - otras transiciones
   - Advance Rate
   - Loss Rate
   - Other Transition Rate
   - tiempo promedio para avanzar
   - mediana de duración
   ============================================================ */

SELECT
    pipeline_order,
    current_stage,

    COUNT(*) AS total_stage_exits,

    SUM(
        CASE
            WHEN outcome = 'Advanced' THEN 1
            ELSE 0
        END
    ) AS advanced_opportunities,

    SUM(
        CASE
            WHEN outcome = 'Lost' THEN 1
            ELSE 0
        END
    ) AS lost_opportunities,

    SUM(
        CASE
            WHEN outcome = 'Other' THEN 1
            ELSE 0
        END
    ) AS other_transitions,

    CAST(
        SUM(
            CASE
                WHEN outcome = 'Advanced' THEN 1
                ELSE 0
            END
        ) * 100.0
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS advance_rate,

    CAST(
        SUM(
            CASE
                WHEN outcome = 'Lost' THEN 1
                ELSE 0
            END
        ) * 100.0
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS loss_rate,

    CAST(
        SUM(
            CASE
                WHEN outcome = 'Other' THEN 1
                ELSE 0
            END
        ) * 100.0
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS other_transition_rate,

    CAST(
        AVG(
            CASE
                WHEN outcome = 'Advanced'
                THEN duration_days
            END
        )
        AS DECIMAL(10,2)
    ) AS avg_days_to_advance,

    CAST(
        MAX(
            CASE
                WHEN outcome = 'Advanced'
                THEN median_duration_days
            END
        )
        AS DECIMAL(10,2)
    ) AS median_days

FROM Pipeline_Stats

GROUP BY
    pipeline_order,
    current_stage

ORDER BY
    pipeline_order;


/* ============================================================
   3. VELOCIDAD DEL PIPELINE LINEAL OFICIAL

   Esta consulta analiza exclusivamente las transiciones
   esperadas del proceso comercial.

   Pipeline:
   Prospecting → Qualified → Discovery
   → Proposal → Negotiation → Won
   ============================================================ */

WITH Stage_Transitions AS (

    SELECT
        opportunity_id,
        Stage AS current_stage,
        stage_entered_at AS current_stage_entered_at,

        LEAD(Stage) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage,

        LEAD(stage_entered_at) OVER (
            PARTITION BY opportunity_id
            ORDER BY stage_entered_at
        ) AS next_stage_entered_at

    FROM opportunity_stage_history
),

Linear_Pipeline AS (

    SELECT
        opportunity_id,
        current_stage,
        next_stage,

        DATEDIFF(
            HOUR,
            current_stage_entered_at,
            next_stage_entered_at
        ) / 24.0 AS duration_days,

        CASE
            WHEN current_stage = 'Prospecting'
                 AND next_stage = 'Qualified' THEN 1

            WHEN current_stage = 'Qualified'
                 AND next_stage = 'discovery' THEN 2

            WHEN current_stage = 'discovery'
                 AND next_stage = 'proposal' THEN 3

            WHEN current_stage = 'proposal'
                 AND next_stage = 'negotiation' THEN 4

            WHEN current_stage = 'negotiation'
                 AND next_stage = 'Won' THEN 5
        END AS pipeline_order

    FROM Stage_Transitions

    WHERE
        (
            current_stage = 'Prospecting'
            AND next_stage = 'Qualified'
        )

        OR (
            current_stage = 'Qualified'
            AND next_stage = 'discovery'
        )

        OR (
            current_stage = 'discovery'
            AND next_stage = 'proposal'
        )

        OR (
            current_stage = 'proposal'
            AND next_stage = 'negotiation'
        )

        OR (
            current_stage = 'negotiation'
            AND next_stage = 'Won'
        )
),

Pipeline_Median AS (

    SELECT
        *,

        PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY duration_days
        ) OVER (
            PARTITION BY current_stage, next_stage
        ) AS median_days

    FROM Linear_Pipeline
)

SELECT
    pipeline_order,

    current_stage + ' → ' + next_stage
        AS stage_transition,

    COUNT(*) AS opportunity_transitions,

    CAST(
        AVG(duration_days)
        AS DECIMAL(10,2)
    ) AS average_days,

    CAST(
        MAX(median_days)
        AS DECIMAL(10,2)
    ) AS median_days,

    CAST(
        MIN(duration_days)
        AS DECIMAL(10,2)
    ) AS minimum_days,

    CAST(
        MAX(duration_days)
        AS DECIMAL(10,2)
    ) AS maximum_days

FROM Pipeline_Median

GROUP BY
    pipeline_order,
    current_stage,
    next_stage

ORDER BY
    pipeline_order;


/* ============================================================
   4. DISTRIBUCIÓN DE OUTCOMES POR ETAPA

   Útil para revisar visualmente la composición de cada etapa.
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

Classified AS (

    SELECT
        opportunity_id,
        current_stage,
        next_stage,

        CASE

            WHEN current_stage = 'Prospecting'
                 AND next_stage = 'Qualified'
                THEN 'Advanced'

            WHEN current_stage = 'Qualified'
                 AND next_stage = 'discovery'
                THEN 'Advanced'

            WHEN current_stage = 'discovery'
                 AND next_stage = 'proposal'
                THEN 'Advanced'

            WHEN current_stage = 'proposal'
                 AND next_stage = 'negotiation'
                THEN 'Advanced'

            WHEN current_stage = 'negotiation'
                 AND next_stage = 'Won'
                THEN 'Advanced'

            WHEN next_stage = 'Lost'
                THEN 'Lost'

            ELSE 'Other'

        END AS outcome

    FROM Stage_Flow

    WHERE current_stage IN (
        'Prospecting',
        'Qualified',
        'discovery',
        'proposal',
        'negotiation'
    )

      AND next_stage IS NOT NULL
)

SELECT
    current_stage,
    outcome,
    COUNT(*) AS opportunities

FROM Classified

GROUP BY
    current_stage,
    outcome

ORDER BY
    CASE current_stage
        WHEN 'Prospecting' THEN 1
        WHEN 'Qualified' THEN 2
        WHEN 'discovery' THEN 3
        WHEN 'proposal' THEN 4
        WHEN 'negotiation' THEN 5
    END,
    outcome;


/* ============================================================
   5. RESULTADOS PRINCIPALES

   Los resultados del análisis mostraron:

   - Prospecting → Qualified:
     ~13.40 días promedio

   - Qualified → Discovery:
     ~13.73 días promedio

   - Discovery → Proposal:
     ~13.51 días promedio

   - Proposal → Negotiation:
     ~20.77 días promedio

   - Negotiation → Won:
     ~20.72 días promedio

   También se observó un aumento progresivo del Loss Rate
   a medida que las oportunidades avanzan hacia el cierre.

   Negotiation presentó el mayor Loss Rate del pipeline,
   aproximadamente 37%.

   Estos resultados indican que las etapas finales combinan:

   - mayor tiempo de avance
   - menor eficiencia de conversión
   - mayor riesgo de pérdida
   ============================================================ */
