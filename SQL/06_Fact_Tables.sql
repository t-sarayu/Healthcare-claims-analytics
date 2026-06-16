---Use Database
USE Medicare_Claims;

---1. Create Fact IP Claims
SELECT
    i.CLM_ID,
    i.DESYNPUF_ID,
    i.PRVDR_NUM,
    i.CLM_DRG_CD,
    i.CLM_ADMSN_DT,
    i.CLM_THRU_DT,
    i.CLM_PMT_AMT,
    i.LOS
INTO Fact_Inpatient_Claims
FROM Clean_Inpatient_Dedup i;

--1.1 Verify
SELECT *
FROM Fact_Inpatient_Claims;

---2. Create Fact OP claims 
SELECT
    o.CLM_ID,
    o.DESYNPUF_ID,
    o.PRVDR_NUM,
    o.CLM_FROM_DT,
    o.CLM_THRU_DT,
    o.CLM_PMT_AMT
INTO Fact_Outpatient_Claims
FROM Clean_Outpatient_dedup o;

--2.1 Verify
SELECT *
FROM Fact_Outpatient_Claims;

--2.2 Changing data type
SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Fact_Outpatient_Claims'
AND COLUMN_NAME IN ('CLM_FROM_DT','CLM_THRU_DT')

ALTER TABLE Fact_Outpatient_Claims
ALTER COLUMN CLM_FROM_DT DATE;

ALTER TABLE Fact_Outpatient_Claims
ALTER COLUMN CLM_THRU_DT DATE;

---3. Validate Queries
--3.1 Check Beneficiary Join
SELECT COUNT(*)
FROM Fact_Inpatient_Claims f
INNER JOIN Dim_Beneficiary b
ON f.DESYNPUF_ID = b.DESYNPUF_ID;

--3.2 Check Provider Join
SELECT COUNT(*)
FROM Fact_Inpatient_Claims f
INNER JOIN Dim_Provider p
ON f.PRVDR_NUM = p.PRVDR_NUM;

--3.3 Diagnosis Join
SELECT COUNT(*)
FROM Fact_Inpatient_Claims f
INNER JOIN Dim_Diagnosis d
ON f.CLM_DRG_CD = d.CLM_DRG_CD;

--3.4 Check Beneficiary Join
SELECT COUNT(*)
FROM Fact_Outpatient_Claims f
INNER JOIN Dim_Beneficiary b
ON f.DESYNPUF_ID = b.DESYNPUF_ID;

--3.5 Check Provider Join
SELECT COUNT(*)
FROM Fact_Outpatient_Claims f
INNER JOIN Dim_Provider p
ON f.PRVDR_NUM = p.PRVDR_NUM;

---4. Create Business Measures
--4.1 Total Healthcare spend
SELECT
SUM(CLM_PMT_AMT) AS IP_TotalSpend
FROM Fact_Inpatient_Claims;

SELECT
SUM(CLM_PMT_AMT) AS OP_TotalSpend
FROM Fact_Outpatient_Claims;

--4.2 Average Claim Cost
SELECT
AVG(CLM_PMT_AMT) AS IP_AvgClaimCost
FROM Fact_Inpatient_Claims;

SELECT
AVG(CLM_PMT_AMT) AS OP_AvgClaimCost
FROM Fact_Outpatient_Claims;

--4.3 Average Length of stay
SELECT
AVG(CAST(LOS AS FLOAT)) AS AvgLOS
FROM Fact_Inpatient_Claims;

