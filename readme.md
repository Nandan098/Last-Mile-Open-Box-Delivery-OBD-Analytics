# Last-Mile OBD & Delivery Fraud Analytics System

A rule-based analytics and risk-screening system for last-mile delivery operations. The project automates repetitive quality-control checks, identifies potentially anomalous delivery records, and prioritizes cases for investigation using SQL, Python/Pandas, Excel, MySQL, and Power BI.

> **Important:** This project is a **risk-screening and investigation-prioritization system**, not a system that proves fraud. A flagged record requires human review and supporting evidence before any final decision.

---

## 1. Project Overview

Last-mile delivery operations can generate a large volume of daily delivery records. Manually reviewing every record to identify unusual travel patterns or potentially risky customer claims is repetitive, time-consuming, and difficult to prioritize.

This project addresses that problem by building a simple, explainable rules engine that:

- processes delivery records in a structured way,
- identifies predefined anomaly patterns,
- assigns risk scores to flagged records,
- categorizes cases by investigation priority, and
- presents operational insights through a Power BI dashboard.

The project was designed as an **operations quality-control and risk-monitoring workflow**.

---

## 2. Business Problem

A delivery operations manager may need to review a large number of records at the end of the day to identify cases such as:

1. unusual differences between recorded/odometer distance and GPS distance, and
2. potentially risky combinations involving high-value orders, OBD refusal, and customer claims.

A manual row-by-row review creates three practical problems:

- **High review effort** – many records have to be checked manually.
- **Low prioritization** – critical cases can be buried among normal records.
- **Repetitive QC work** – the same checks have to be repeated every day.

The goal of this project is therefore to automate the initial screening stage and provide a prioritized investigation queue.

---

## 3. Objectives

- Automate repetitive delivery quality-control checks.
- Detect potentially anomalous delivery patterns using transparent business rules.
- Prioritize flagged cases using a simple weighted risk score.
- Reduce the amount of manual screening required from operations teams.
- Provide a dashboard for monitoring flagged and high-priority cases.
- Maintain a clear separation between **anomaly detection** and **final fraud confirmation**.

---

## 4. Data Used

The project works with delivery-level operational records containing fields such as:

| Field | Description |
|---|---|
| `Delivery_ID` | Unique delivery identifier |
| `Driver_ID` | Delivery-partner identifier |
| `Log_Timestamp` | Delivery/log timestamp |
| `Order_Value_INR` | Order value in INR |
| `OBD_Status` | Open Box Delivery status |
| `Customer_Claim_Filed` | Whether a customer claim was filed |
| `GPS_Distance_KM` | GPS-recorded distance |
| `Odometer_Distance_KM` | Odometer-recorded distance |

The project was designed around **1,000+ daily delivery records**.

---

## 5. Risk-Screening Logic

The screening engine uses two main business rules.

### Rule 1 — Distance Anomaly

The system compares odometer distance with GPS distance:

```text
Distance Variance % =
(Odometer Distance - GPS Distance)
/ GPS Distance × 100
```

A record is flagged when:

```text
Distance Variance % > 15%
```

This is treated as a **screening signal** for investigation. It does not by itself establish delivery-partner fraud.

### Rule 2 — High-Value Customer Claim Pattern

A record is flagged when all three conditions are satisfied:

```text
Order Value > ₹15,000
AND
OBD Status = "Refused"
AND
Customer Claim Filed = "Yes"
```

The ₹15,000 value is an **analytical threshold defined for this project**, not a company policy.

---

## 6. Risk Scoring

To prioritize investigations, the project assigns different weights to the two screening signals:

| Risk Signal | Weight |
|---|---:|
| Distance anomaly | 1 |
| High-value customer claim pattern | 2 |

The total risk score is calculated as:

```text
Total Risk Score =
Distance Anomaly Flag × 1
+
High-Value Claim Flag × 2
```

### Risk Categories

| Total Score | Category | Interpretation |
|---:|---|---|
| 0 | Low Risk | No defined risk rule triggered |
| 1 | Medium Risk | Distance anomaly detected |
| 2 | High Risk | High-value customer claim pattern detected |
| 3 | Critical Risk | Both screening rules triggered |

> Risk scores represent **investigation priority**, not the probability or certainty of fraud.

---

## 7. Technology Stack

- **MySQL** — staging, SQL transformation, rule engine, risk scoring
- **Python / Pandas** — data cleaning and analytical processing
- **Excel** — supporting analysis and data enrichment
- **Power BI** — operational dashboard and risk monitoring

---

## 8. SQL Implementation

The SQL workflow follows a staged design:

### Stage 1 — Staging Table

Raw delivery logs are loaded into a MySQL staging table for structured processing.

### Stage 2 — Feature Creation

The query calculates derived fields such as `Distance_Variance_Pct`.

### Stage 3 — Flag Generation

`CASE WHEN` rules generate the two risk flags:

- `Flag_Distance_Tampering`
- `Flag_High_Value_Leakage`

### Stage 4 — Risk Aggregation

The flags are converted into a weighted `Total_Risk_Score`.

### Stage 5 — Risk Categorization

The score is converted into an easy-to-understand investigation category.

### Stage 6 — Operational Output

The resulting view can be queried and consumed by reporting/dashboard tools.

---

## 9. Example SQL Logic

```sql
CASE
    WHEN Distance_Variance_Pct > 15.0 THEN 1
    ELSE 0
END AS Flag_Distance_Tampering
```

```sql
CASE
    WHEN Order_Value_INR > 15000
         AND OBD_Status = 'Refused'
         AND Customer_Claim_Filed = 'Yes'
    THEN 1
    ELSE 0
END AS Flag_High_Value_Leakage
```

```sql
(
    Flag_Distance_Tampering
    + (Flag_High_Value_Leakage * 2)
) AS Total_Risk_Score
```

The production version should keep the business rules clearly separated from the dashboard layer so that thresholds and logic can be changed without redesigning the reporting process.

---

## 10. Dashboard

The Power BI layer is designed from an operations-manager perspective rather than as a purely analytical report.

Typical monitoring views include:

- Total deliveries
- Flagged deliveries
- High-priority cases
- Risk-category distribution
- Delivery-partner level patterns
- Delivery discrepancy patterns
- Cases requiring investigation

The purpose of the dashboard is to answer:

> **“Where should the operations team focus its investigation first?”**

---

## 11. End-to-End Workflow

```text
Raw Delivery Logs
        ↓
Data Cleaning / Preparation
        ↓
MySQL Staging Table
        ↓
Derived Features
        ↓
Rule-Based Risk Flags
        ↓
Weighted Risk Score
        ↓
Risk Category
        ↓
Power BI Monitoring
        ↓
Human Investigation
```

---

## 12. Why a Rule-Based Approach?

A rule-based approach was selected because the project focuses on **explainable operational screening**.

Each flag can be directly explained to an operations manager:

- what condition triggered the flag,
- why the record was prioritized, and
- what additional evidence should be reviewed.

This is useful in operational environments where a screening system should be transparent and easy to audit.

---

## 13. Limitations

This project has several important limitations:

1. **A flag is not proof of fraud.** Legitimate operational situations can produce similar patterns.
2. **Thresholds are project-defined.** The 15% distance-variance threshold and ₹15,000 order-value threshold would require historical validation before production deployment.
3. **No confirmed-fraud ground truth is assumed.** The system therefore supports screening and prioritization rather than supervised fraud classification.
4. **Human investigation remains necessary.** Final decisions should use additional delivery, route, customer, and operational evidence.
5. **Production deployment would require monitoring.** False positives, false negatives, data quality, threshold drift, and operational impact should be tracked over time.

---

## 14. How the Project Could Be Improved

A production-ready version could be extended with:

- historical confirmed-case labels,
- threshold tuning using precision/recall and false-positive analysis,
- additional route and delivery signals,
- stronger customer/partner behavior features,
- automated alerting and investigation queues,
- model-based anomaly detection alongside the rule engine,
- monitoring for data-quality issues and threshold drift.

Any production change should be validated against historical data and operational outcomes before full deployment.

---

## 15. Business Value

The project converts a repetitive manual screening activity into a structured workflow:

```text
Manual review of many records
            ↓
Automated rule-based screening
            ↓
Risk prioritization
            ↓
Focused investigation
```

The primary value is therefore **faster identification and prioritization of potentially risky cases**, rather than claiming that the system itself proves or eliminates fraud.

---

## 16. Amazon Leadership Principles Demonstrated

This project can be discussed using several Amazon Leadership Principles:

### Invent and Simplify

Automated repetitive manual QC checks and organized them into a repeatable workflow.

### Dive Deep

Moved beyond a high-level delivery count and examined record-level travel and claim patterns.

### Insist on the Highest Standards

Designed the output as a screening signal and retained human investigation instead of treating every automated flag as a final conclusion.

### Are Right, A Lot

Recognized that a single anomaly can have legitimate explanations and should be validated before a decision is made.

### Ownership

Identified a repetitive operational review problem and developed an end-to-end analytical workflow to address it.

### Customer Obsession

Focused on protecting delivery reliability, customer trust, and appropriate investigation of potentially risky transactions.

---
