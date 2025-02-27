-- CREATE TABLE for Patients_Records
CREATE TABLE Patients_Records (
    Name TEXT,
    Age INT,
    Gender TEXT,
    Blood_Type TEXT,
    Medical_Condition TEXT,
    Date_of_Admission DATE,
    Doctor TEXT,
    Hospital TEXT,
    Insurance_Provider TEXT,
    Billing_Amount FLOAT,
    Room_Number INT,
    Admission_Type TEXT,
    Discharge_Date DATE,
    Medication TEXT,
    Test_Results TEXT
);

-- Copying data from CSV to the table
COPY Patients_Records 
FROM 'C:\Users\PREODATOR HELIOS 300\Desktop\project_sql/healthcare_dataset.csv' 
DELIMITER ',' 
CSV HEADER;

-- Verifying the data
SELECT *
FROM Patients_Records;


-- 1. Copying all the data from the original table to patients_copy table
CREATE TABLE patients_copy AS
SELECT * 
FROM Patients_Records;

-- Verifying the data
SELECT *
FROM patients_copy;


-- Data Cleaning

-- 2. Converting the 'name' column to lowercase
UPDATE patients_copy
SET name = LOWER(name);

-- Verifying the change
SELECT name
FROM patients_copy;

-- 3. Capitalizing the first letter of each name
UPDATE patients_copy
SET name = INITCAP(name);

-- Verifying the change
SELECT name
FROM patients_copy;

-- 4. Finding duplicate entries within the data
SELECT name, date_of_admission, blood_type, medical_condition, doctor, hospital,
    ROW_NUMBER() OVER(PARTITION BY name, date_of_admission, blood_type, medical_condition, doctor, hospital) AS rn
FROM patients_copy;

-- 5. Removing duplicate entries
WITH duplicates_cte AS (
    SELECT ctid
    FROM (
        SELECT ctid, ROW_NUMBER() OVER(PARTITION BY name, date_of_admission, blood_type, medical_condition, doctor, hospital) AS rn
        FROM patients_copy
    ) ct
    WHERE rn > 1
)
DELETE FROM patients_copy
WHERE ctid IN (SELECT ctid FROM duplicates_cte);

-- Verifying the result
SELECT *
FROM (
    SELECT name, date_of_admission, blood_type, medical_condition, doctor, hospital,
        ROW_NUMBER() OVER(PARTITION BY name, date_of_admission, blood_type, medical_condition, doctor, hospital) AS rn
    FROM patients_copy
) sub
WHERE rn > 1;


-- 6. Checking for NULL values in the columns
SELECT 
    COUNT(*) AS total_rows,
    COUNT(name) AS non_null_name,
    COUNT(date_of_admission) AS non_null_date_of_admission,
    COUNT(blood_type) AS non_null_blood_type,
    COUNT(medical_condition) AS non_null_medical_condition,
    COUNT(doctor) AS non_null_doctor,
    COUNT(hospital) AS non_null_hospital
FROM patients_copy;


-- 7. Checking for outliers in age column
WITH outlier_cte AS (
    SELECT AVG(age) AS mean_age, STDDEV(age) AS std_age
    FROM patients_copy
)
SELECT *
FROM patients_copy, outlier_cte
WHERE ABS((age - mean_age) / std_age) > 3;

-- No outliers in the age column


-- 8. Checking for outliers in billing_amount column
WITH billing_outlier AS (
    SELECT AVG(billing_amount) AS avg_bill_amt, STDDEV(billing_amount) AS std_bill_amt
    FROM patients_copy
)
SELECT * 
FROM patients_copy, billing_outlier
WHERE ABS((billing_amount - avg_bill_amt) / (std_bill_amt)) > 3;

-- No outliers in billing amount


-- EDA (Exploratory Data Analysis)

-- 1. Count of patients by gender
SELECT gender, COUNT(gender) AS total_number
FROM patients_copy
GROUP BY gender
ORDER BY total_number DESC;

-- Insight: More female patients than male patients.


-- 2. Count of patients by blood type
SELECT blood_type, COUNT(blood_type) AS total_number
FROM patients_copy
GROUP BY blood_type
ORDER BY total_number DESC;

-- Insight: 'AB+' blood type is most common, and 'O-' is the least common blood type.


-- 3. Count of patients based on age groups
WITH age_range_cte AS (
    SELECT age,
           CASE
               WHEN age <= 18 THEN 'Teenager'
               WHEN age BETWEEN 19 AND 55 THEN 'Adult'
               WHEN age >= 56 THEN 'Old'
           END AS age_category
    FROM patients_copy
)
SELECT age_category, COUNT(age_category) AS total_number
FROM age_range_cte
GROUP BY age_category
ORDER BY total_number DESC;

-- Insight: Majority of patients fall into the 'Adult' category.


-- 4. Looking for most common medical conditions
SELECT medical_condition, COUNT(medical_condition) AS total_cases
FROM patients_copy
GROUP BY medical_condition
ORDER BY total_cases DESC;

-- Insight: Arthritis is the most common condition, while asthma has the least cases.


-- Admission and Discharge Trends

-- 1. Average stay
WITH avg_stay_period AS (
    SELECT (discharge_date - date_of_admission) AS stay_period
    FROM patients_copy
)
SELECT AVG(stay_period)
FROM avg_stay_period;

-- Insight: The average stay is 15.5 days for patients with various conditions.


-- 2. Stay per medical condition
SELECT medical_condition, AVG(DATE(discharge_date) - DATE(date_of_admission)) AS stay_period
FROM patients_copy
GROUP BY medical_condition
ORDER BY stay_period DESC;

-- Insight: Asthma patients have the longest stay, while diabetic patients spend fewer days in hospital.


-- 3. Readmission rates
WITH readmission_rates AS (
    SELECT name, COUNT(name)
    FROM patients_copy
    GROUP BY name
    HAVING COUNT(name) > 1
)
SELECT (COUNT(name) * 100) / (SELECT COUNT(DISTINCT name) FROM patients_copy) AS readmission_percent
FROM readmission_rates;

-- Insight: The readmission rate is 14%.


-- Billing Analysis

-- 1. Average billing amount per admission type
SELECT admission_type, AVG(billing_amount) AS average_billing_amount
FROM patients_copy
GROUP BY admission_type
ORDER BY average_billing_amount DESC;

-- Insight: Elective admissions have the highest billing amounts, while urgent admissions have the lowest.


-- 2. Insurance provider distribution
SELECT insurance_provider, COUNT(*) AS total_patients_insured
FROM patients_copy
GROUP BY insurance_provider
ORDER BY total_patients_insured DESC;

-- Insight: Cigna has the highest number of patients, while 'Aetna' covers the least number.


-- 3. Hospital distribution
SELECT hospital, COUNT(*) AS total_patients_handled
FROM patients_copy
GROUP BY hospital
ORDER BY total_patients_handled DESC;

-- Insight: 'LLC Smith' has handled the most patients (40 patients).
