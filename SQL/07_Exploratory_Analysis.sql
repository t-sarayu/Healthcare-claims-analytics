---Use database
USE Medicare_Claims;

---Dataset Overview
--1 Total patients
SELECT COUNT(*) AS Total_patients
FROM Dim_Beneficiary;

--2 Total Inpatient Claims
SELECT COUNT(*) AS Total_IPclaims
FROM Fact_Inpatient_Claims;

--3 Total Outpatient Claims
SELECT COUNT(*) AS Total_OPclaims
FROM Fact_Outpatient_Claims;

---4. Total Healthcare spend
--4.1 Inpatient 
SELECT
	SUM(CLM_PMT_AMT) AS Total_IPspend
FROM Fact_Inpatient_Claims;

--4.2 Outpatient 
SELECT
	SUM(CLM_PMT_AMT) AS Total_IPspend
FROM Fact_Outpatient_Claims;

---5. Combined Spend
SELECT
(
SELECT
	SUM(CLM_PMT_AMT) AS Total_IPspend
FROM Fact_Inpatient_Claims
)
+
(
SELECT
	SUM(CLM_PMT_AMT) AS Total_IPspend
FROM Fact_Outpatient_Claims
)
AS Total_Healthcare_Spend;

---6. Avg Claim Cost
--6.1 Inpatient
SELECT
	AVG(CLM_PMT_AMT) AS Avg_IPcost
FROM Fact_Inpatient_Claims;

--6.2 Outpatient
SELECT
	AVG(CLM_PMT_AMT) AS Avg_OPcost
FROM Fact_Outpatient_Claims;

---7. Age group distribution
SELECT	
	Age_Group,
	COUNT(*) AS Patient_count
FROM Dim_Beneficiary
GROUP BY Age_Group
ORDER BY Patient_count DESC;

---8. Gender Distribution
SELECT	
	BENE_SEX_IDENT_CD,
	COUNT(*) AS Patient_count
FROM Dim_Beneficiary
GROUP BY BENE_SEX_IDENT_CD
ORDER BY Patient_count DESC;

UPDATE Dim_Beneficiary
SET BENE_SEX_IDENT_CD =
    CASE
        WHEN BENE_SEX_IDENT_CD = '1' THEN 'Male'
        WHEN BENE_SEX_IDENT_CD = '2' THEN 'Female'
    END;