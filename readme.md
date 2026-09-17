#  Last-Mile Open Box Delivery (OBD) & Fraud Analytics Engine

An automated quality control and anomaly detection dashboard built with **Python**, **Pandas**, and **Streamlit**. Designed to streamline hub operations, identify last-mile fuel theft, and detect fraudulent claims in Open Box Delivery (OBD) workflows.

---

##  Overview & Business Context

In modern e-commerce logistics, **Open Box Delivery (OBD)** is critical for high-value product assurance (e.g., Mobiles, Laptops). Before accepting delivery, the customer verifies the physical contents of the package alongside the delivery executive. 

However, operational bottlenecks and fraud still occur:
1. **Fuel Theft / Distance Tampering:** Delivery agents over-reporting manual odometer readings compared to actual GPS tracks.
2. **High-Value Product Fraud:** Customers who refuse doorstep OBD checks but subsequently file "missing/damaged product" claims.

Manually auditing thousands of delivery logs in spreadsheets at the end of a shift is slow, error-prone, and unsustainable during peak sale events. This project automates the Quality Control (QC) process, processing thousands of delivery logs in seconds to flag high-risk deliveries and prioritize hub manager investigations.

---

##  Key Features

* **Automated Distance Tampering Detection:** Calculates percentage variance between tracked GPS routes and reported odometer readings to flag fuel allowance inflation (>15% variance threshold).
* **Multi-Condition High-Risk Fraud Engine:** Evaluates high-value items (> ₹15,000) where OBD was marked as `Refused` and a customer claim was subsequently filed (`Yes`).
* **Weighted Risk Scoring :** Assigns a cumulative `Total_Risk_Score` to prioritize severe financial risks over minor discrepancies for efficient resource allocation on the floor.
* **Dashboard:** Includes real-time KPI metrics, driver violation leaderboards, high-risk data tables, and interactive risk score filtering.
* **Flexible Ingestion Pipeline:** Accepts custom daily CSV uploads via the sidebar, with automatic fallback to a generated testing dataset if no file is uploaded.

---

