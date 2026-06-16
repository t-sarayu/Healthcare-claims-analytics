# 🏥 Healthcare Claims Analytics — CMS DE-SynPUF

**SQL Server · Power BI · DAX · Healthcare KPIs**

> End-to-end claims analytics pipeline built on CMS Medicare synthetic data (DE-SynPUF), covering database setup, data profiling, cleaning, dimensional modelling, exploratory analysis, and a 6-page interactive Power BI dashboard — designed to mirror real-world payer/provider analytics workflows used at organisations like IQVIA, Parexel, and Optum.

---

## 📌 Business Problem

Healthcare payers and analytics teams process millions of inpatient and outpatient claims annually. Without structured analysis, it's impossible to:

- Identify which providers are driving cost outliers
- Monitor 30-day readmission rates (a key CMS quality metric)
- Track PMPM spend trends to flag population health risks
- Detect utilisation patterns across diagnosis categories

This project answers those questions using real-world CMS claims logic applied to synthetic Medicare data.

---

## 📊 Dashboard Pages

| Page | What It Answers |
|------|----------------|
| **Executive Summary** | Total spend ($864M), IP/OP claim volumes, PMPM ($7.02K), readmission rate (12.76%), monthly trends |
| **Population Analytics** | Cost per patient ($7.42K), spend by age group, gender split, top states by patient volume |
| **Provider Analytics** | Top providers by spend (23006G: $7.4M), claim count vs spend scatter, avg LOS by provider |
| **Diagnosis Analytics** | Spend by diagnosis code, avg claim cost heatmap, monthly diagnosis volume trend |
| **Financial Analytics** | IP spend ($639M) vs OP spend ($224M), monthly spend by year, top states by total spend |
| **Quality Analytics** | 9K readmitted admissions, monthly readmission trend, readmissions by age group and gender |

---

## 🗄️ Dataset

**Source:** [CMS DE-SynPUF (Medicare Claims Synthetic Public Use Files)](https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/SynPUFs)

Synthetic Medicare data — 100% safe for public portfolios, structured identically to real CMS claims data.

**Reporting Period:** January 2008 – December 2009

**Scale:**
- 116K patients, 123K distinct beneficiaries
- 67K inpatient claims · 791K outpatient claims
- $864M total healthcare spend

**Key Fields Used:**

| Field | Description |
|-------|-------------|
| `DESYNPUF_ID` | Beneficiary identifier |
| `CLM_ID` | Unique claim ID |
| `PRVDR_NUM` | Provider number |
| `CLM_PMT_AMT` | Claim payment amount |
| `CLM_ADMSN_DT` | Admission date |
| `CLM_THRU_DT` | Discharge / through date |
| `ICD9_DGNS_CD` | Diagnosis code |
| `SP_STATE_CODE` | Beneficiary state |
| `BENE_SEX_IDENT_CD` | Gender |
| `BENE_RACE_CD` | Race |

---

## 🛠️ Tools & Technologies

| Layer | Tool |
|-------|------|
| Data storage & querying | SQL Server (T-SQL) |
| Data cleaning & KPI logic | SQL (CTEs, window functions, DATEDIFF) |
| Dimensional modelling | Star schema (Fact + Dim tables) |
| Visualisation | Power BI Desktop |
| Measures & calculations | DAX |
| Data transformation | Power Query (M) |

---

## 📁 Repository Structure

```
Healthcare_Claims_Project/
│
├── SQL/
│   ├── 01_Database_Setup.sql          # Create DB, schemas, raw table definitions
│   ├── 02_Data_Profiling.sql          # Row counts, null checks, value distributions
│   ├── 03_Data_Dictionary.md          # Field definitions and business context
│   ├── 04_Data_Cleaning.sql           # Type casting, deduplication, null handling
│   ├── 05_Dimensions.sql              # dim_beneficiary, dim_provider, dim_diagnosis, dim_date
│   ├── 06_Facts.sql                   # fact_claims — inpatient + outpatient unified
│   ├── 07_Exploratory_Analysis.sql    # Summary stats, spend trends, utilisation patterns
│   ├── 08_Provider_Analysis.sql       # Top providers by spend, claim count, avg LOS
│   ├── 09_Diagnosis_Analysis.sql      # Spend and volume by ICD-9 diagnosis code
│   ├── 10_Readmission_Analysis.sql    # 30-day readmission flag using LEAD window function
│   └── 11_Final_Views.sql             # Cleaned views consumed by Power BI
│
├── PowerBI/
│   ├── Healthcare_Claims_Analytics.pbix   # Full 6-page dashboard
│   └── Healthcare_Claims_Analytics.pdf    # Static export for quick preview
│
├── Screenshots/
│   ├── 01_Executive_Summary.png
│   ├── 02_Population_Analytics.png
│   ├── 03_Provider_Analytics.png
│   ├── 04_Diagnosis_Analytics.png
│   ├── 05_Financial_Analytics.png
│   └── 06_Quality_Analytics.png
│
└── README.md
```

---

## 🔧 SQL Logic — Key Snippets

### 01 · Database Setup
```sql
CREATE DATABASE HealthcareClaims;
GO
USE HealthcareClaims;

CREATE TABLE raw_inpatient_claims (
    DESYNPUF_ID       VARCHAR(50),
    CLM_ID            BIGINT,
    CLM_ADMSN_DT      VARCHAR(10),
    CLM_THRU_DT       VARCHAR(10),
    PRVDR_NUM         VARCHAR(20),
    CLM_PMT_AMT       FLOAT,
    ICD9_DGNS_CD_1    VARCHAR(10)
);
```

### 04 · Data Cleaning
```sql
-- Cast dates, remove nulls, deduplicate
SELECT DISTINCT
    DESYNPUF_ID,
    CLM_ID,
    PRVDR_NUM,
    TRY_CAST(CLM_ADMSN_DT AS DATE) AS CLM_ADMSN_DT,
    TRY_CAST(CLM_THRU_DT  AS DATE) AS CLM_THRU_DT,
    CLM_PMT_AMT
FROM raw_inpatient_claims
WHERE CLM_PMT_AMT IS NOT NULL
  AND TRY_CAST(CLM_ADMSN_DT AS DATE) IS NOT NULL;
```

### 06 · Facts — KPI Calculations (LOS, PMPM)
```sql
-- Length of Stay per claim
SELECT
    CLM_ID,
    DESYNPUF_ID,
    PRVDR_NUM,
    CLM_ADMSN_DT,
    CLM_THRU_DT,
    DATEDIFF(DAY, CLM_ADMSN_DT, CLM_THRU_DT) AS LOS_Days,
    CLM_PMT_AMT
FROM clean_inpatient_claims;

-- PMPM (Per Member Per Month)
SELECT
    FORMAT(CLM_ADMSN_DT, 'yyyy-MM')                              AS Claim_Month,
    SUM(CLM_PMT_AMT)                                             AS Total_Spend,
    COUNT(DISTINCT DESYNPUF_ID)                                  AS Distinct_Members,
    SUM(CLM_PMT_AMT) / NULLIF(COUNT(DISTINCT DESYNPUF_ID), 0)   AS PMPM
FROM fact_claims
GROUP BY FORMAT(CLM_ADMSN_DT, 'yyyy-MM')
ORDER BY Claim_Month;
```

### 10 · Readmission Analysis — 30-Day Flag
```sql
-- LEAD window function to find next admission date per patient
WITH ReadmitCTE AS (
    SELECT
        DESYNPUF_ID,
        CLM_ID,
        CLM_ADMSN_DT,
        CLM_THRU_DT,
        LEAD(CLM_ADMSN_DT) OVER (
            PARTITION BY DESYNPUF_ID
            ORDER BY CLM_ADMSN_DT
        ) AS NextAdmissionDate
    FROM fact_claims
    WHERE claim_type = 'Inpatient'
)
SELECT
    *,
    DATEDIFF(DAY, CLM_THRU_DT, NextAdmissionDate) AS DaysToReadmit,
    CASE
        WHEN DATEDIFF(DAY, CLM_THRU_DT, NextAdmissionDate) <= 30
        THEN 1 ELSE 0
    END AS Readmitted30Days
FROM ReadmitCTE;
```

### 11 · Final Views (consumed by Power BI)
```sql
-- Power BI connects directly to these views
CREATE VIEW vw_provider_summary AS
SELECT
    PRVDR_NUM,
    COUNT(CLM_ID)              AS Claim_Count,
    COUNT(DISTINCT DESYNPUF_ID) AS Distinct_Members,
    AVG(CLM_PMT_AMT)           AS Avg_Claim_Cost,
    SUM(CLM_PMT_AMT)           AS Total_Spend,
    AVG(LOS_Days)              AS Avg_LOS
FROM fact_claims
GROUP BY PRVDR_NUM;
```

---

## 📐 Data Model — Star Schema

```
                    dim_date
                       │
dim_beneficiary ── fact_claims ── dim_provider
                       │
                  dim_diagnosis
```

| Table | Description |
|-------|-------------|
| `fact_claims` | Central fact table — one row per claim, IP + OP unified |
| `dim_beneficiary` | Patient demographics (gender, race, state, age group) |
| `dim_provider` | Provider number and state |
| `dim_diagnosis` | ICD-9 diagnosis codes |
| `dim_date` | Calendar hierarchy — year, month, quarter |

---

## 📈 Key KPIs & DAX Measures

| KPI | Value | DAX |
|-----|-------|-----|
| Total Spend | $864M | `SUM(fact_claims[CLM_PMT_AMT])` |
| PMPM | $7.02K | `[Total Spend] / DISTINCTCOUNT([Member]) / [Months]` |
| Avg LOS | 5.69 days | `AVERAGE(fact_claims[LOS_Days])` |
| Readmission Rate | 12.76% | `DIVIDE([Readmitted Claims], [Total IP Claims])` |
| Avg Claim Cost | $1.01K | `DIVIDE([Total Spend], [Claim Count])` |
| IP % | 74.01% | `DIVIDE([IP Spend], [Total Spend])` |

---

## 💡 Key Insights

- **Seniors drive 85%+ of total spend** ($0.72bn of $0.86bn) — consistent with Medicare population dynamics
- **Provider 23006G** is the highest-cost provider at $7.4M with only 1.1K claims — high avg claim cost worth flagging for audit
- **March readmission peak (17.66%)** vs December low (10.88%) — seasonal pattern that warrants clinical review
- **State 05 leads** in both patient volume (10.2K) and total spend ($69M)
- **IP claims = 74% of spend** despite being a fraction of total claim count — inpatient cost management is the highest-leverage opportunity

---

## 🚀 How to Reproduce

1. Download DE-SynPUF Sample 1 from [CMS.gov](https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/SynPUFs/DE_Syn_PUF)
2. Run SQL scripts in `/SQL/` **in order** (01 → 11) in SQL Server Management Studio
3. Open Power BI Desktop → connect to your SQL Server instance → select the `vw_*` views
4. Open `Healthcare_Claims_Analytics.pbix` and refresh

---

## 👩‍💻 Author

**Sarayu Tirumalasetty**
B.Tech Biotechnology · NIT Andhra Pradesh · Microsoft PL-300 Certified

- GitHub: [t-sarayu](https://github.com/t-sarayu)
- LinkedIn: [sarayu-tirumalasetty](https://www.linkedin.com/in/sarayu-tirumalasetty/)

---

*Built with CMS DE-SynPUF synthetic data — no real patient data used.*
