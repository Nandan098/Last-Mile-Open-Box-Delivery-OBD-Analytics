import pandas as pd
import random
from datetime import datetime, timedelta

# Set seed for reproducibility
random.seed(42)

n_rows = 1000
drivers = [f"DRV-{str(i).zfill(3)}" for i in range(1, 51)]

# Initialize empty dictionary to hold driver queues
driver_data = {driver: [] for driver in drivers}
delivery_ids = [f"DEL-{10000 + i}" for i in range(1, n_rows + 1)]

# Distribute deliveries randomly among drivers
for i in range(n_rows):
    assigned_driver = random.choice(drivers)
    gps_dist = round(random.uniform(1.0, 20.0), 2)
    
    driver_data[assigned_driver].append({
        'Delivery_ID': delivery_ids[i],
        'Order_Value_INR': random.randint(500, 25000),
        'OBD_Status': random.choice(['Accepted', 'Refused', 'N/A']),
        'Customer_Claim_Filed': random.choice(['Yes', 'No']),
        'GPS_Distance_KM': gps_dist,
        'Odometer_Distance_KM': round(gps_dist * random.uniform(1.01, 1.05), 2) # Normal 1-5% variance
    })

# Assign sequential timestamps for each driver's queue
today_start = datetime.now().replace(hour=8, minute=0, second=0, microsecond=0)
all_records = []

for driver, deliveries in driver_data.items():
    current_time = today_start
    for delivery in deliveries:
        # Time passes between deliveries for this specific driver
        current_time += timedelta(minutes=random.randint(2, 15))
        delivery['Driver_ID'] = driver
        delivery['Timestamp'] = current_time
        all_records.append(delivery)

# Convert to DataFrame
df = pd.DataFrame(all_records)

# ---------------------------------------------------------
# ANOMALY INJECTION 
# ---------------------------------------------------------

# 1. Distance Tampering (5% = 50 rows)
# Increase odometer reading by 16% to 35%
tamper_indices = random.sample(range(n_rows), 50)
for idx in tamper_indices:
    df.loc[idx, 'Odometer_Distance_KM'] = round(df.loc[idx, 'GPS_Distance_KM'] * random.uniform(1.16, 1.35), 2)

# 2. Financial Leakage (3% = 30 rows)
# Ensure no overlap with distance tampering for cleaner SQL validation
available_indices = list(set(range(n_rows)) - set(tamper_indices))
leakage_indices = random.sample(available_indices, 30)
for idx in leakage_indices:
    df.loc[idx, 'Order_Value_INR'] = random.randint(15001, 25000)
    df.loc[idx, 'OBD_Status'] = 'Refused'
    df.loc[idx, 'Customer_Claim_Filed'] = 'Yes'

# 3. Window Function Test (LAG function anomaly)
# Find a driver with multiple deliveries and force an impossible speed scenario
target_driver = df['Driver_ID'].value_counts().index[0] 
driver_idx = df[df['Driver_ID'] == target_driver].sort_values('Timestamp').index.tolist()

if len(driver_idx) >= 3:
    i1, i2, i3 = driver_idx[0], driver_idx[1], driver_idx[2]
    base_time = df.loc[i1, 'Timestamp']
    
    # Delivery 2 occurs 60 seconds after Delivery 1, but is 18 km away
    df.loc[i2, 'Timestamp'] = base_time + timedelta(seconds=60)
    df.loc[i2, 'GPS_Distance_KM'] = 18.5 
    df.loc[i2, 'Odometer_Distance_KM'] = round(18.5 * random.uniform(1.01, 1.05), 2)
    
    # Delivery 3 occurs another 60 seconds later, another 16 km away
    df.loc[i3, 'Timestamp'] = base_time + timedelta(seconds=120)
    df.loc[i3, 'GPS_Distance_KM'] = 16.2
    df.loc[i3, 'Odometer_Distance_KM'] = round(16.2 * random.uniform(1.01, 1.05), 2)

# ---------------------------------------------------------
# FINAL FORMATTING & EXPORT
# ---------------------------------------------------------

# Sort globally by timestamp to represent a standard chronological log file
df = df.sort_values('Timestamp').reset_index(drop=True)

# Order the columns logically
columns_order = [
    'Delivery_ID', 'Driver_ID', 'Timestamp', 'Order_Value_INR', 
    'OBD_Status', 'Customer_Claim_Filed', 'GPS_Distance_KM', 'Odometer_Distance_KM'
]
df = df[columns_order]

# Export to CSV
file_name = 'daily_logs.csv'
df.to_csv(file_name, index=False)
print(f"Dataset successfully generated and saved as '{file_name}' with {len(df)} records.")