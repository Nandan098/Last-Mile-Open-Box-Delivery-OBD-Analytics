-- 1. Initialize Database
CREATE DATABASE IF NOT EXISTS operations_fraud_db;
USE operations_fraud_db;

-- 2. Create the Staging Table for the Raw CSV
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

-- 3. Load the Generated Data 
-- (Replace 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/daily_logs.csv' with your secure_file_priv path)
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/daily_logs.csv'
INTO TABLE raw_delivery_logs_staging
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 4. Execute the Heavy SQL Fraud Analytics Logic
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
        
        -- Calculate static distance variance
        ROUND(((Odometer_Distance_KM - GPS_Distance_KM) / NULLIF(GPS_Distance_KM, 0)) * 100, 2) AS Distance_Variance_Pct,
        
        -- Apply Window Functions to track sequential driver behavior
        LAG(Log_Timestamp) OVER(PARTITION BY Driver_ID ORDER BY Log_Timestamp) AS Prev_Timestamp,
        LAG(GPS_Distance_KM) OVER(PARTITION BY Driver_ID ORDER BY Log_Timestamp) AS Prev_GPS_Distance
    FROM raw_delivery_logs_staging
),
Fraud_Detection_Engine AS (
    SELECT 
        *,
        -- Rule 1: Static Odometer Tampering (>15% variance)
        CASE WHEN Distance_Variance_Pct > 15.0 THEN 1 ELSE 0 END AS Flag_Distance_Tampering,
        
        -- Rule 2: Financial Leakage (High-Value Refused OBD)
        CASE WHEN Order_Value_INR > 15000 AND OBD_Status = 'Refused' AND Customer_Claim_Filed = 'Yes' THEN 1 ELSE 0 END AS Flag_High_Value_Leakage,
        
        -- Rule 3: Dynamic GPS Spoofing (e.g., Moving >10km in under 5 minutes)
        CASE WHEN Prev_Timestamp IS NOT NULL 
              AND TIMESTAMPDIFF(MINUTE, Prev_Timestamp, Log_Timestamp) <= 5 
              AND ABS(GPS_Distance_KM - Prev_GPS_Distance) > 10 
             THEN 1 ELSE 0 END AS Flag_GPS_Spoofing
    FROM Temporal_Tracking
),
Risk_Aggregation AS (
    SELECT 
        *,
        -- Calculate weighted risk score based on flags
        (Flag_Distance_Tampering + (Flag_High_Value_Leakage * 2) + (Flag_GPS_Spoofing * 3)) AS Total_Risk_Score
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
    Flag_GPS_Spoofing,
    Total_Risk_Score,
    -- Assign Human-Readable Categories for Power BI & Excel
    CASE 
        WHEN Total_Risk_Score >= 3 THEN 'Critical Risk (Spoofing/High Value)'
        WHEN Total_Risk_Score = 2 THEN 'High Risk (Financial Leakage)'
        WHEN Total_Risk_Score = 1 THEN 'Medium Risk (Distance Tampering)'
        ELSE 'Low Risk'
    END AS Risk_Category
FROM Risk_Aggregation;

-- 5. View the Final Processed Data
SELECT * FROM vw_master_obd_fraud_analysis ORDER BY Total_Risk_Score DESC;