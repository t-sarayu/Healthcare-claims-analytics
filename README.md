# 🏥 Healthcare Claims Analytics — CMS DE-SynPUF

**SQL Server · Power BI · DAX · Healthcare KPIs**

> End-to-end claims analytics pipeline built on CMS Medicare synthetic data (DE-SynPUF), covering data cleaning, KPI engineering, and a 6-page interactive Power BI dashboard — designed to mirror real-world payer/provider analytics workflows used at organisations like IQVIA, Parexel, and Optum.

---

## 📌 Business Problem

Healthcare payers and analytics teams process millions of inpatient and outpatient claims annually. Without structured analysis, it's impossible to:

- Identify which providers are driving cost outliers
- Monitor 30-day readmission rates (a key CMS quality metric)
- Track PMPM spend trends to flag population health risks
- Detect utilisation patterns that signal fraud or inefficiency

This project answers those questions using real-world CMS claims logic applied to synthetic Medicare data.

---

## 📊 Dashboard Pages

| Page | What It Answers |
|------|----------------|
| **Executive Summary** | Total spend ($864M), IP/OP claim volumes, PMPM ($7.02K), readmission rate (12.76%), monthly trends |
| **Population Analytics** | Cost per patient ($7.42K), spend by age group (Senior vs Adult vs Young Adult), gender split, top states |
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
- 67K inpatient claims, 791K outpatient claims
- $864M total healthcare spend

**Key Fields Used:**

| Field | Description |
|-------|-------------|
| `DESYNPUF_ID` | Beneficiary identifier |
| `CLM_ID` | Unique claim ID |
| `PRVDR_NUM` | Provider number |
| `CLM_PMT_AMT` | Claim payment amount |
| `CLM_ADMSN_DT` | Admission date |
| `CLM_THRU_DT` | Discharge/through date |
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
| Visualisation | Power BI Desktop |
| Measures & calculations | DAX |
| Data transformation | Power Query (M) |

---

## 🔧 SQL Work — Key Logic

### 1. Data Cleaning

```sql
-- Standardise claim dates and remove nulls
SELECT
    DESYNPUF_ID,
    CLM_ID,
    PRVDR_NUM,
    TRY_CAST(CLM_ADMSN_DT AS DATE)  AS CLM_ADMSN_DT,
    TRY_CAST(CLM_THRU_DT  AS DATE)  AS CLM_THRU_DT,
    CLM_PMT_AMT
FROM raw_inpatient_claims
WHERE CLM_PMT_AMT IS NOT NULL
  AND TRY_CAST(CLM_ADMSN_DT AS DATE) IS NOT NULL;
```

### 2. KPI Calculations — LOS, PMPM, Avg Claim Cost

```sql
-- Length of Stay (LOS) per claim
SELECT
    CLM_ID,
    DESYNPUF_ID,
    PRVDR_NUM,
    DATEDIFF(DAY, CLM_ADMSN_DT, CLM_THRU_DT) AS LOS_Days,
    CLM_PMT_AMT
FROM inpatient_claims;

-- PMPM (Per Member Per Month)
SELECT
    FORMAT(CLM_ADMSN_DT, 'yyyy-MM') AS Claim_Month,
    SUM(CLM_PMT_AMT)                AS Total_Spend,
    COUNT(DISTINCT DESYNPUF_ID)     AS Distinct_Members,
    SUM(CLM_PMT_AMT) / NULLIF(COUNT(DISTINCT DESYNPUF_ID), 0) AS PMPM
FROM all_claims
GROUP BY FORMAT(CLM_ADMSN_DT, 'yyyy-MM');
```

### 3. 30-Day Readmission Flag

```sql
-- Flag patients readmitted within 30 days of discharge
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
    FROM inpatient_claims
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

---

## 📐 Data Model

Star schema with one central fact table and supporting dimension tables:

```
fact_claims
    ├── dim_beneficiary   (patient demographics)
    ├── dim_provider      (provider details)
    ├── dim_diagnosis     (ICD-9 codes)
    └── dim_date          (calendar hierarchy)
```

---

## 📈 Key KPIs & DAX Measures

| KPI | Value | DAX Logic |
|-----|-------|-----------|
| Total Spend | $864M | `SUM(fact_claims[CLM_PMT_AMT])` |
| PMPM | $7.02K | `Total Spend / DISTINCTCOUNT(Members) / Months` |
| Avg LOS | 5.69 days | `AVERAGE(fact_claims[LOS_Days])` |
| Readmission Rate | 12.76% | `Readmitted / Total IP Admissions` |
| Avg Claim Cost | $1.01K | `DIVIDE(Total Spend, Claim Count)` |
| IP % | 74.01% | `IP Spend / Total Spend` |

---

## 💡 Key Insights

- **Seniors drive 85%+ of total spend** ($0.72bn of $0.86bn) — consistent with Medicare population dynamics
- **Provider 23006G** is the highest-cost provider at $7.4M total spend with only 1.1K claims — signalling high avg claim cost worth investigating
- **March readmission peak (17.66%)** vs December low (10.88%) — seasonal pattern that warrants clinical review
- **State 05 leads** in both patient volume (10.2K) and total spend ($69M)
- **IP claims represent 74% of spend** despite being a fraction of total claim volume — inpatient cost management is the highest-leverage opportunity

---

## 📁 Repository Structure

```
healthcare-claims-analytics/
│
├── SQL/
│   ├── 01_data_cleaning.sql
│   ├── 02_kpi_calculations.sql
│   └── 03_readmission_logic.sql
│
├── PowerBI/
│   └── Healthcare_Claims_Analytics.pbix
│
├── Screenshots/
│   ├── executive_summary.png
│   ├── population_analytics.png
│   ├── provider_analytics.png
│   ├── diagnosis_analytics.png
│   ├── financial_analytics.png
│   └── quality_analytics.png
│
└── README.md
```

---

## 🚀 How to Reproduce

1. Download DE-SynPUF Sample 1 from [CMS.gov](https://www.cms.gov/Research-Statistics-Data-and-Systems/Downloadable-Public-Use-Files/SynPUFs/DE_Syn_PUF)
2. Load CSVs into SQL Server and run scripts in `/SQL/` in order
3. Connect Power BI Desktop to your SQL Server instance
4. Open `Healthcare_Claims_Analytics.pbix` — refresh data source

---

## 👩‍💻 Author

**Sarayu Tirumalasetty**
B.Tech Biotechnology · NIT Andhra Pradesh · PL-300 Certified

- GitHub: [t-sarayu](https://github.com/t-sarayu)
- LinkedIn: [sarayu-tirumalasetty](https://www.linkedin.com/in/sarayu-tirumalasetty/)
- Portfolio: [sarayu-tirumalasetty.lovable.app](https://sarayu-tirumalasetty.lovable.app)

---

*Built with CMS DE-SynPUF synthetic data — no real patient data used.*
