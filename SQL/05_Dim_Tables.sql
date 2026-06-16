---Use Database
USE Medicare_Claims

---1. Create Dim Beneficiary
SELECT DISTINCT
    DESYNPUF_ID,
    BENE_BIRTH_DT,
    Age,
    Age_Group,
    BENE_SEX_IDENT_CD,
    BENE_RACE_CD,
    SP_STATE_CODE
INTO Dim_Beneficiary
FROM Clean_Beneficiary;

--1.1 Verify
SELECT * 
FROM Dim_Beneficiary

---2. Create Dim_provider
SELECT DISTINCT
	PRVDR_NUM
INTO Dim_Provider
FROM
(
	SELECT PRVDR_NUM
	FROM Clean_Inpatient_dedup

	UNION 

	SELECT PRVDR_NUM
	FROM Clean_Outpatient_dedup
)p;

--2.1 verify
SELECT *
FROM Dim_Provider

---3. Dim Diagnosis
SELECT DISTINCT
	CLM_DRG_CD
INTO Dim_Diagnosis
FROM Clean_Inpatient_dedup
WHERE CLM_DRG_CD IS NOT NULL;

--3.1 Verify
SELECT COUNT(*)
FROM Dim_Diagnosis

---4. Dim Date
CREATE TABLE Dim_Date
(
	FullDate DATE,
	YearNum INT,
	MonthNum INT,
	MonthName VARCHAR(20),
	QuaterNum INT
);

--4.1 Populate
WITH DateSeries AS
(
    SELECT CAST('2008-01-01' AS DATE) AS FullDate

    UNION ALL

    SELECT DATEADD(DAY,1,FullDate)
    FROM DateSeries
    WHERE FullDate < '2009-12-31'
)

INSERT INTO Dim_Date
SELECT
    FullDate,
    YEAR(FullDate),
    MONTH(FullDate),
    DATENAME(MONTH, FullDate),
    DATEPART(QUARTER, FullDate)
FROM DateSeries
OPTION (MAXRECURSION 1000);

--4.2 Verify
SELECT * 
FROM Dim_Date







