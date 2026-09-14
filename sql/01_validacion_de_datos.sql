/* ============================================================
   CASO 2 — ANÁLISIS DE SALUD DEL PIPELINE COMERCIAL
   Archivo: 01_validacion_de_datos.sql

   Objetivo:
   Validar la calidad y consistencia de los datos antes de
   construir métricas sobre el pipeline comercial.

   Este archivo revisa:
   1. Volumen de oportunidades
   2. Valores de Stage
   3. Oportunidades sin historial
   4. Integridad entre tablas
   5. Consistencia temporal
   ============================================================ */


/* ============================================================
   1. VOLUMEN GENERAL DE OPORTUNIDADES
   ============================================================ */

SELECT
    COUNT(*) AS total_opportunities,
    COUNT(DISTINCT opportunity_id) AS unique_opportunities
FROM opportunities;


/* ============================================================
   2. DISTRIBUCIÓN DE ETAPAS EN EL HISTORIAL

   Permite detectar categorías inconsistentes o etiquetas
   duplicadas dentro del pipeline.
   ============================================================ */

SELECT
    Stage,
    COUNT(*) AS registros
FROM opportunity_stage_history
GROUP BY Stage
ORDER BY Stage;


/* ============================================================
   3. VALIDACIÓN DE ETAPAS ESPERADAS

   Pipeline oficial:
   Prospecting → Qualified → Discovery → Proposal
   → Negotiation → Won

   También pueden existir:
   Lost
   Needs Analysis
   ============================================================ */

SELECT
    Stage,
    COUNT(*) AS registros
FROM opportunity_stage_history
WHERE Stage NOT IN (
    'Prospecting',
    'Qualified',
    'discovery',
    'proposal',
    'negotiation',
    'Won',
    'Lost',
    'needs analysis'
)
GROUP BY Stage
ORDER BY Stage;


/* ============================================================
   4. OPORTUNIDADES SIN HISTORIAL DE ETAPAS

   Estas oportunidades no pueden utilizarse para reconstruir
   el recorrido del pipeline.
   ============================================================ */

SELECT
    COUNT(DISTINCT o.opportunity_id) AS opportunities_without_history
FROM opportunities o
LEFT JOIN opportunity_stage_history h
    ON o.opportunity_id = h.opportunity_id
WHERE h.opportunity_id IS NULL;


/* ============================================================
   5. OPORTUNIDADES CON HISTORIAL VÁLIDO

   Esta es la población utilizada para los análisis de
   transiciones y tiempos entre etapas.
   ============================================================ */

SELECT
    COUNT(DISTINCT o.opportunity_id) AS opportunities_with_history
FROM opportunities o
INNER JOIN opportunity_stage_history h
    ON o.opportunity_id = h.opportunity_id;


/* ============================================================
   6. VALIDACIÓN DE IDS PROBLEMÁTICOS

   Durante la revisión se identificaron IDs con prefijo OPP_DUP.
   Se valida su presencia y si poseen historial asociado.
   ============================================================ */

SELECT
    COUNT(*) AS total_opportunities,
    SUM(
        CASE
            WHEN opportunity_id LIKE 'OPP_DUP%' THEN 1
            ELSE 0
        END
    ) AS opp_dup_records,
    SUM(
        CASE
            WHEN opportunity_id NOT LIKE 'OPP_DUP%' THEN 1
            ELSE 0
        END
    ) AS normal_ids
FROM opportunities;


/* ============================================================
   7. OPP_DUP CON O SIN HISTORIAL
   ============================================================ */

SELECT
    COUNT(DISTINCT o.opportunity_id) AS opp_dup_total,

    COUNT(DISTINCT h.opportunity_id) AS opp_dup_with_history,

    COUNT(DISTINCT o.opportunity_id)
    - COUNT(DISTINCT h.opportunity_id) AS opp_dup_without_history

FROM opportunities o

LEFT JOIN opportunity_stage_history h
    ON o.opportunity_id = h.opportunity_id

WHERE o.opportunity_id LIKE 'OPP_DUP%';


/* ============================================================
   8. VALIDACIÓN DE DUPLICADOS EN HISTORY_ID

   history_id debería identificar de forma única cada evento
   del historial.
   ============================================================ */

SELECT
    history_id,
    COUNT(*) AS registros
FROM opportunity_stage_history
GROUP BY history_id
HAVING COUNT(*) > 1
ORDER BY registros DESC;


/* ============================================================
   9. VALIDACIÓN DE FECHAS NULAS

   stage_entered_at es indispensable para reconstruir el orden
   cronológico del pipeline.
   ============================================================ */

SELECT
    COUNT(*) AS null_stage_entered_at
FROM opportunity_stage_history
WHERE stage_entered_at IS NULL;


/* ============================================================
   10. VALIDACIÓN DE OPPORTUNITY_ID NULO
   ============================================================ */

SELECT
    COUNT(*) AS null_opportunity_ids
FROM opportunity_stage_history
WHERE opportunity_id IS NULL;


/* ============================================================
   11. VALIDACIÓN DE SALES_REP_ID NULO
   ============================================================ */

SELECT
    COUNT(*) AS opportunities_without_sales_rep
FROM opportunities
WHERE sales_rep_id IS NULL;


/* ============================================================
   12. VALIDACIÓN DE AMOUNT_USD

   Permite detectar oportunidades sin valor económico disponible.
   ============================================================ */

SELECT
    COUNT(*) AS opportunities_without_amount
FROM opportunities
WHERE Amount_usd IS NULL;


/* ============================================================
   13. VALIDACIÓN DE VALORES NO POSITIVOS

   Se revisan Amount_usd iguales o menores a cero antes de
   utilizarlos para calcular valor potencial perdido.
   ============================================================ */

SELECT
    COUNT(*) AS non_positive_amounts
FROM opportunities
WHERE Amount_usd <= 0;


/* ============================================================
   CONCLUSIONES DE CALIDAD DE DATOS

   - Se normalizó Prospect → Prospecting durante la limpieza.
   - Se combinaron fecha y hora en stage_entered_at.
   - Se identificaron oportunidades sin historial de etapas.
   - Las oportunidades sin trazabilidad fueron excluidas de
     los análisis que requieren reconstruir el pipeline.
   - Los datos originales no fueron modificados; las
     transformaciones se realizaron sobre la capa limpia.
   ============================================================ */
