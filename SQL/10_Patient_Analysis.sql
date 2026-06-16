---Use DB
USE Medicare_Claims;

---1. High Cost Patients
SELECT TOP 20
    DESYNPUF_ID,
    SUM(CLM_PMT_AMT) TotalSpend
FROM Fact_Inpatient_Claims
GROUP BY DESYNPUF_ID
ORDER BY TotalSpend DESC;

---2. Patients with more admissions
SELECT TOP 20
    DESYNPUF_ID,
    COUNT(*) AdmissionCount
FROM Fact_Inpatient_Claims
GROUP BY DESYNPUF_ID
ORDER BY AdmissionCount DESC;

