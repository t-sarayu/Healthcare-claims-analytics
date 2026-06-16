---Use DB
USE Medicare_Claims;

---1. Find Next Admission
WITH Admission AS
(
	SELECT 
		DESYNPUF_ID,
		CLM_ADMSN_DT,
		LEAD(CLM_ADMSN_DT)
		OVER
		(
			PARTITION BY DESYNPUF_ID
			ORDER BY CLM_ADMSN_DT 
		) AS Next_Admission
	FROM Fact_Inpatient_Claims
)
SELECT *
FROM Admission;

---2. Calculate Readmission Days
WITH RAD AS
(
    SELECT
        DESYNPUF_ID,
        CLM_ADMSN_DT,
        LEAD(CLM_ADMSN_DT)
        OVER
        (
            PARTITION BY DESYNPUF_ID
            ORDER BY CLM_ADMSN_DT
        ) AS NextAdmission
    FROM Fact_Inpatient_Claims
)

SELECT
    *,
    DATEDIFF
    (
        DAY,
        CLM_ADMSN_DT,
        NextAdmission
    ) AS DaysToReadmit
FROM RAD;

---3. 30-Day Readmission Rate
WITH RR AS
(
    SELECT
        DESYNPUF_ID,
        CLM_ADMSN_DT,
        LEAD(CLM_ADMSN_DT)
        OVER
        (
            PARTITION BY DESYNPUF_ID
            ORDER BY CLM_ADMSN_DT
        ) AS NextAdmission
    FROM Fact_Inpatient_Claims
)

SELECT
100.0 *
SUM
(
    CASE
        WHEN DATEDIFF
             (
                 DAY,
                 CLM_ADMSN_DT,
                 NextAdmission
             ) <= 30
        THEN 1
        ELSE 0
    END
)
/ COUNT(*)
AS ReadmissionRate
FROM RR;

