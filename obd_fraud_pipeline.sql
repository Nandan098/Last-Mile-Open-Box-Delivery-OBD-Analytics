CREATE DATABASE IF NOT EXISTS operations_fraud_db;
USE operations_fraud_db;

CREATE TABLE IF NOT EXISTS raw_delivery_logs_staging (
    Delivery_ID VARCHAR(50),
    Driver_ID VARCHAR(50),
    Log_Timestamp DATETIME,
    Order_Value_INR DECIMAL(10,2),
    OBD_Status VARCHAR(20),
    Customer_Claim_Filed VARCHAR(5),
    GPS_Distance_KM DECIMAL(10,2),
    Odometer_Distance_KM DECIMAL(10,2)
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/daily_logs.csv'
INTO TABLE raw_delivery_logs_staging
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

CREATE OR REPLACE VIEW vw_master_obd_fraud_analysis AS
WITH Temporal_Tracking AS (
    SELECT 
        Delivery_ID,
        Driver_ID,
        Log_Timestamp,
        Order_Value_INR,
        OBD_Status,
        Customer_Claim_Filed,
        GPS_Distance_KM,
        Odometer_Distance_KM,
        ROUND(((Odometer_Distance_KM - GPS_Distance_KM) / NULLIF(GPS_Distance_KM, 0)) * 100, 2) AS Distance_Variance_Pct,
        LAG(Log_Timestamp) OVER(PARTITION BY Driver_ID ORDER BY Log_Timestamp) AS Prev_Timestamp,
        LAG(GPS_Distance_KM) OVER(PARTITION BY Driver_ID ORDER BY Log_Timestamp) AS Prev_GPS_Distance
    FROM raw_delivery_logs_staging
),
Fraud_Detection_Engine AS (
    SELECT 
        *,
        CASE WHEN Distance_Variance_Pct > 15.0 THEN 1 ELSE 0 END AS Flag_Distance_Tampering,
        
        CASE WHEN Order_Value_INR > 15000 AND OBD_Status = 'Refused' AND Customer_Claim_Filed = 'Yes' THEN 1 ELSE 0 END AS Flag_High_Value_Leakage,
),
Risk_Aggregation AS (
    SELECT 
        *,
        (Flag_Distance_Tampering + (Flag_High_Value_Leakage * 2)) AS Total_Risk_Score
    FROM Fraud_Detection_Engine
)
SELECT 
    Delivery_ID,
    Driver_ID,
    Log_Timestamp,
    Order_Value_INR,
    Distance_Variance_Pct,
    Flag_Distance_Tampering,
    Flag_High_Value_Leakage,
    Total_Risk_Score,
    CASE 
        WHEN Total_Risk_Score >= 3 THEN 'Critical Risk (Spoofing/High Value)'
        WHEN Total_Risk_Score = 2 THEN 'High Risk (Financial Leakage)'
        WHEN Total_Risk_Score = 1 THEN 'Medium Risk (Distance Tampering)'
        ELSE 'Low Risk'
    END AS Risk_Category
FROM Risk_Aggregation;

SELECT * FROM vw_master_obd_fraud_analysis ORDER BY Total_Risk_Score DESC;
