---Using Database
USE Medicare_Claims;

---1. Create clean beneficiary table
SELECT *
INTO Clean_Beneficiary
FROM Raw_Beneficiary_Summary;

---2. Create clean Inpatient Claims table
SELECT *
INTO Clean_Inpatient_Claims
FROM Raw_Inpatient_Claims;

---3. Create clean Outpatient Claims table
SELECT *
INTO Clean_Outpatient_Claims
FROM Raw_Outpatient_Claims;

---4. Verify Row counts
--4.1 Beneficiary
SELECT COUNT(*) AS Total_rows
FROM Clean_Beneficiary;

--4.2 Inpatient 
SELECT COUNT(*) AS Total_rows
FROm Clean_Inpatient_Claims;

--4.3 Outpatient
SELECT COUNT(*) AS Total_rows
FROm Clean_Outpatient_Claims;

---5. Check Primary Keys
--5.1 Beneficiary
SELECT
COUNT(*) TotalRows,
COUNT(DISTINCT DESYNPUF_ID) UniquePatients
FROM Clean_Beneficiary;

--5.2 Inpatient
SELECT
COUNT(*) TotalRows,
COUNT(DISTINCT CLM_ID) UniqueClaims
FROM Clean_Inpatient_Claims;

--5.3 Outpatient
SELECT
COUNT(*) TotalRows,
COUNT(DISTINCT CLM_ID) UniqueClaims
FROM Clean_Outpatient_Claims;

---6. Finding out either duplicates or nulls
--6.1 Inpatient
SELECT TOP 20
    CLM_ID,
    COUNT(*) AS ClaimCount
FROM Clean_Inpatient_Claims
GROUP BY CLM_ID
HAVING COUNT(*) > 1
ORDER BY ClaimCount DESC;

--6.2 Outpatient
SELECT TOP 20
    CLM_ID,
    COUNT(*) AS ClaimCount
FROM Clean_Outpatient_Claims
GROUP BY CLM_ID
HAVING COUNT(*) > 1
ORDER BY ClaimCount DESC;

---7. Check True duplicate row
--7.1 Inpatient claims
SELECT *
FROM
(
	SELECT *, 
	ROW_NUMBER() OVER
	(
      PARTITION BY
      CLM_ID,
      DESYNPUF_ID,
      CLM_PMT_AMT
      ORDER BY CLM_ID
     ) rn
    FROM Clean_Inpatient_Claims
)d
WHERE rn>1;

--7.2 Outpatient claims
SELECT *
FROM
(
	SELECT *, 
	ROW_NUMBER() OVER
	(
      PARTITION BY
      CLM_ID,
      DESYNPUF_ID,
      CLM_PMT_AMT
      ORDER BY CLM_ID
     ) rn
    FROM Clean_Outpatient_Claims
)d
WHERE rn>1;

/*There are duplicates in inpatient and outpatient claims
So, Creating Deduplicate Tables*/

--Inpatient Dedup
SELECT DISTINCT *
INTO Clean_Inpatient_dedup
FROM Clean_Inpatient_Claims;

--Outpatient Dedup
SELECT DISTINCT *
INTO Clean_Outpatient_dedup
FROM Clean_Outpatient_Claims;

---8. Check Nulls
--Beneficiary
SELECT
    SUM(CASE WHEN DESYNPUF_ID IS NULL THEN 1 ELSE 0 END) AS NullPatientID,
    SUM(CASE WHEN BENE_BIRTH_DT IS NULL THEN 1 ELSE 0 END) AS NullBirthDate,
    SUM(CASE WHEN BENE_SEX_IDENT_CD IS NULL THEN 1 ELSE 0 END) AS NullGender,
    SUM(CASE WHEN BENE_RACE_CD IS NULL THEN 1 ELSE 0 END) AS NullRace
FROM Clean_Beneficiary;

--Inpatient
SELECT
    SUM(CASE WHEN CLM_ID IS NULL THEN 1 ELSE 0 END) AS NullClaimID,
    SUM(CASE WHEN DESYNPUF_ID IS NULL THEN 1 ELSE 0 END) AS NullPatientID,
    SUM(CASE WHEN PRVDR_NUM IS NULL THEN 1 ELSE 0 END) AS NullProvider,
    SUM(CASE WHEN CLM_PMT_AMT IS NULL THEN 1 ELSE 0 END) AS NullPayment
FROM Clean_Inpatient_Dedup;

--Outpatient 
SELECT
    SUM(CASE WHEN CLM_ID IS NULL THEN 1 ELSE 0 END) AS NullClaimID,
    SUM(CASE WHEN DESYNPUF_ID IS NULL THEN 1 ELSE 0 END) AS NullPatientID,
    SUM(CASE WHEN PRVDR_NUM IS NULL THEN 1 ELSE 0 END) AS NullProvider,
    SUM(CASE WHEN CLM_PMT_AMT IS NULL THEN 1 ELSE 0 END) AS NullPayment
FROM Clean_Outpatient_Dedup;

---9. Validate Date Columns
--9.1 Beneficiary
SELECT 
	MIN(BENE_BIRTH_DT) AS EarlyDOB,
	MAX(BENE_BIRTH_DT) as LatestDOB	
FROM Clean_Beneficiary

--9.2 Inpatient
SELECT 
	MIN(CLM_ADMSN_DT) AS EarlyAdmission,
	MAX(CLM_ADMSN_DT) as LatestAdmission
FROM Clean_Inpatient_dedup

--9.3 Outpatient
SELECT 
	MIN(CLM_FROM_DT) AS EarlyAdmission,
	MAX(CLM_FROM_DT) as LatestAdmission
FROM Clean_Outpatient_dedup;

/*Found that data tyoe is different for date*/
---9.1.1
ALTER TABLE Clean_Outpatient_Dedup
ADD CLM_FROM_DATE DATE;
---9.1.2
UPDATE Clean_Outpatient_Dedup
SET CLM_FROM_DATE =
    CONVERT(DATE, CAST(CLM_FROM_DT AS VARCHAR(8)), 112);
---9.1.3
SELECT 
	MIN(CLM_FROM_DATE) AS EarlyAdmission,
	MAX(CLM_FROM_DATE) as LatestAdmission
FROM Clean_Outpatient_dedup;

---10. Create Age
ALTER TABLE Clean_Beneficiary
ADD Age INT;

UPDATE Clean_Beneficiary
SET Age = 
DATEDIFF(YEAR,BENE_BIRTH_DT,'2009-12-31');

/*DE-SynPUF data is based on 2008–2009 claims.
Using today's date would produce unrealistic ages.*/

---Validate age
SELECT
	MIN(Age) As min_age,
	MAX(Age) AS max_age,
	AVG(Age) AS avg_age
FROM Clean_Beneficiary;

---11. Create Age group
ALTER TABLE Clean_Beneficiary
ADD Age_Group VARCHAR(50);

UPDATE Clean_Beneficiary
SET Age_Group =
CASE
	WHEN Age<18 THEN 'Child'
	WHEN Age<40 THEN 'Young Adult'
	WHEN Age<65 THEN 'Adult'
	ELSE 'Senior'
END;

---Check
SELECT 
	Age_Group,
	COUNT(*) AS Patients
FROM Clean_Beneficiary
GROUP BY Age_Group;

---12. Create Length Of Stay(LOS)
ALTER TABLE Clean_Inpatient_dedup
ADD LOS INT;

UPDATE Clean_Inpatient_dedup
SET LOS =
DATEDIFF(
		DAY,
		CLM_ADMSN_DT,
		CLM_THRU_DT
);

--12.1 Validate
SELECT 
	MIN(LOS),
	MAX(LOS),
	AVG(LOS)
FROM Clean_Inpatient_dedup;

---12.2 Bad Records
SELECT *
FROM Clean_Inpatient_dedup
WHERE LOS<0;

---13. Payment Validation
--13.1 Inpatient
SELECT 
	MIN(CLM_PMT_AMT) AS Min_Payment,
	MAX(CLM_PMT_AMT) AS Max_Payment,
	AVG(CLM_PMT_AMT) AS Avg_Payment
FROM Clean_Inpatient_dedup;

--13.2 Outpatient
ALTER TABLE Clean_Outpatient_Dedup
ALTER COLUMN CLM_PMT_AMT DECIMAL(18,2);

SELECT 
	MIN(CLM_PMT_AMT) AS Min_Payment,
	MAX(CLM_PMT_AMT) AS Max_Payment,
	AVG(CLM_PMT_AMT) AS Avg_Payment
FROM Clean_Outpatient_dedup;

SELECT *
FROM Clean_Outpatient_dedup
WHERE CLM_PMT_AMT<0;

--Investigating negative payments
SELECT
    MIN(CAST(CLM_PMT_AMT AS DECIMAL(18,2))) AS MinNegative,
    MAX(CAST(CLM_PMT_AMT AS DECIMAL(18,2))) AS MaxNegative
FROM Clean_Outpatient_Dedup
WHERE CLM_PMT_AMT  < 0;

--Check impossible dates
SELECT COUNT(*)
FROM Clean_Outpatient_Dedup
WHERE CLM_FROM_DT > CLM_THRU_DT;

--Check null values
SELECT
    SUM(CASE WHEN CLM_PMT_AMT IS NULL THEN 1 ELSE 0 END) AS NullPayments
FROM Clean_Outpatient_Dedup;

---13. Relationship Validation
--13.1 Inpatient → Beneficiary
SELECT COUNT(*) AS Matiching_rows
FROM Clean_Inpatient_dedup i
INNER JOIN Clean_Beneficiary b
ON i.DESYNPUF_ID = b.DESYNPUF_ID

--13.2 Outpatient → Beneficiary
SELECT COUNT(*) AS Matiching_rows
FROM Clean_Outpatient_dedup o
INNER JOIN Clean_Beneficiary b
ON o.DESYNPUF_ID = b.DESYNPUF_ID