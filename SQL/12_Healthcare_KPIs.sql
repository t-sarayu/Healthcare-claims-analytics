---Use DB
USE Medicare_Claims;

---Healthcare KPI Views
CREATE VIEW vw_Provider_Spend AS
SELECT
    PRVDR_NUM,
    SUM(CLM_PMT_AMT) TotalSpend
FROM Fact_Inpatient_Claims
GROUP BY PRVDR_NUM;

CREATE VIEW vw_Readmissions AS
WITH Admissions AS
(
    SELECT
        DESYNPUF_ID,
        CLM_ID,
        CLM_ADMSN_DT,
        CLM_THRU_DT,

        LEAD(CLM_ADMSN_DT) OVER
        (
            PARTITION BY DESYNPUF_ID
            ORDER BY CLM_ADMSN_DT
        ) AS NextAdmissionDate

    FROM Fact_Inpatient_Claims
)

SELECT
    *,
    DATEDIFF
    (
        DAY,
        CLM_THRU_DT,
        NextAdmissionDate
    ) AS DaysToReadmit,

    CASE
        WHEN DATEDIFF
             (
                 DAY,
                 CLM_THRU_DT,
                 NextAdmissionDate
             ) <= 30
        THEN 1
        ELSE 0
    END AS Readmitted30Days

FROM Admissions;