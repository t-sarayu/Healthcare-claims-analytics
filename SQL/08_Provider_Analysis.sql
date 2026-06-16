---Using database
USE Medicare_Claims;

---1. Top Providers By spend
SELECT TOP 20 
	PRVDR_NUM,
	SUM(CLM_PMT_AMT) AS  Total_Spend
FROM Fact_Inpatient_Claims
GROUP BY PRVDR_NUM
ORDER BY Total_Spend DESC;
		
---2. Top Providers By Volume
SELECT TOP 20 
	PRVDR_NUM,
	COUNT(*) AS  Claim_count
FROM Fact_Inpatient_Claims
GROUP BY PRVDR_NUM
ORDER BY Claim_count DESC;

---3. Avg cost per Providers
SELECT TOP 20 
	PRVDR_NUM,
	AVG(CLM_PMT_AMT) AS  Avg_claimcost
FROM Fact_Inpatient_Claims
GROUP BY PRVDR_NUM
ORDER BY Avg_claimcost DESC;
