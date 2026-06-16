---Using DB
USE Medicare_Claims

---1. Most Common DRGs
SELECT TOP 20 
	CLM_DRG_CD,
	COUNT(*) AS Claim_count
FROM Fact_Inpatient_Claims
GROUP BY CLM_DRG_CD
ORDER BY Claim_count DESC;

---2. Highest cost DRGs
SELECT TOP 20 
	CLM_DRG_CD,
	SUM(CLM_PMT_AMT) AS Total_Cost
FROM Fact_Inpatient_Claims
GROUP BY CLM_DRG_CD
ORDER BY Total_Cost DESC;

---3. Avg cost by DRGs
SELECT TOP 20 
	CLM_DRG_CD,
	Avg(CLM_PMT_AMT) AS AvgCost
FROM Fact_Inpatient_Claims
GROUP BY CLM_DRG_CD
ORDER BY AvgCost DESC;

