---Database Used
USE Medicare_Claims;

---Beneficiary Data

--1. Total Rows
SELECT COUNT(*) AS Total_rows
FROM Raw_Beneficiary_Summary;

--2. Distinct id's
SELECT COUNT(Distinct DESYNPUF_ID) AS Unique_Patients
FROM Raw_Beneficiary_Summary;

/* Total_rows = Unique_patients
No duplicate DESYNPUF_ID values Found  */

--3. Null Analysis
SELECT
    SUM(CASE WHEN DESYNPUF_ID IS NULL THEN 1 ELSE 0 END) AS NullPatientID,
    SUM(CASE WHEN BENE_BIRTH_DT IS NULL THEN 1 ELSE 0 END) AS NullDOB,
    SUM(CASE WHEN BENE_SEX_IDENT_CD IS NULL THEN 1 ELSE 0 END) AS NullGender,
    SUM(CASE WHEN BENE_RACE_CD IS NULL THEN 1 ELSE 0 END) AS NullRace
FROM Raw_Beneficiary_Summary;

---4. Gender Distribution
SELECT BENE_SEX_IDENT_CD,
	COUNT(*) AS Patient_count
FROM Raw_Beneficiary_Summary
GROUP BY BENE_SEX_IDENT_CD;

---Inpatient Claims Data

--1. Toatl Claims
SELECT COUNT(*) AS Total_ip_claims
FROM Raw_Inpatient_Claims;

--2. Unique IP Claims
SELECT COUNT(DISTINCT CLM_ID) AS Unique_claims
FROM Raw_Inpatient_Claims;

--3. Unique Patients
SELECT COUNT(DISTINCT DESYNPUF_ID) AS Unique_Patients
FROM Raw_Inpatient_Claims;

--4. Unique Providers
SELECT COUNT(DISTINCT PRVDR_NUM) AS Unique_Providers
FROM Raw_Inpatient_Claims;

--5. Payment null check
SELECT COUNT(*) AS Null_Payments
FROM Raw_Inpatient_Claims
WHERE CLM_PMT_AMT IS NULL;

--6. Payment Statistics
SELECT
	MIN(CLM_PMT_AMT) AS MinPayment, 
	MAX(CLM_PMT_AMT) AS MaxPayment,
	ROUND(AVG(CLM_PMT_AMT),2) AS AvgPayment
FROM Raw_Inpatient_Claims;

--7. Admission Date Range
SELECT
	MIN(CLM_ADMSN_DT) AS Earliest_Admission,
	MAX(CLM_ADMSN_DT) AS Latest_Admission
FROM Raw_Inpatient_Claims;

--8. Top Providers By Claim Count
SELECT 
	PRVDR_NUM,
	COUNT(*) AS Claim_Count
FROM Raw_Inpatient_Claims
GROUP BY PRVDR_NUM
ORDER BY Claim_Count DESC;

---Outpatient Claims Data

--1. Total Claims
SELECT COUNT(*) AS Total_Claims
FROM Raw_Outpatient_Claims;

--2. Unique OP Claims
SELECT COUNT(DISTINCT CLM_PMT_AMT) AS Unique_claims
FROM Raw_Outpatient_Claims;

--3. Unique Patients
SELECT COUNT(DISTINCT DESYNPUF_ID) AS Unique_patients
FROM Raw_Outpatient_Claims;

--4. Unique Providers
SELECT COUNT(DISTINCT PRVDR_NUM) AS Unique_providers
FROM Raw_Outpatient_Claims;

--5. Payment Statistics
SELECT
    MIN(CAST(CLM_PMT_AMT AS DECIMAL(18,2))) AS MinPayment,
    MAX(CAST(CLM_PMT_AMT AS DECIMAL(18,2))) AS MaxPayment
FROM Raw_Outpatient_Claims;

--6. Service Date Range
SELECT
    MIN(CLM_FROM_DT) AS EarliestService,
    MAX(CLM_FROM_DT) AS LatestService
FROM Raw_Outpatient_Claims;

---(IV) RELATIONSHIP PROFILING

--1.How many Inpatient Claims match a beneficiary
SELECT
	COUNT(*) AS matching_rows
FROM Raw_Inpatient_Claims i
INNER JOIN Raw_Beneficiary_Summary b
ON i.DESYNPUF_ID = b.DESYNPUF_ID;

--2. How many Outpatient Claims match a beneficiary
SELECT
	COUNT(*) AS matching_rows
FROM Raw_Outpatient_Claims o
INNER JOIN Raw_Beneficiary_Summary b
ON o.DESYNPUF_ID = b.DESYNPUF_ID;

--3. Patient with Inpatient Claim
SELECT
	COUNT(DISTINCT DESYNPUF_ID) AS IP_claims
FROM Raw_Inpatient_Claims;

--4. Patient with Outpatient Claim
SELECT
	COUNT(DISTINCT DESYNPUF_ID) AS OP_claims
FROM Raw_Outpatient_Claims;




