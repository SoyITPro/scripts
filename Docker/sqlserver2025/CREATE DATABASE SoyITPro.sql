CREATE DATABASE SoyITPro
ON PRIMARY 
(
    NAME = 'SoyITPro_Data',
    FILENAME = '/var/opt/mssql/data/SoyITPro.mdf',
    SIZE = 8MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 64MB
)
LOG ON
(
    NAME = 'SoyITPro_Log',
    FILENAME = '/var/opt/mssql/data/SoyITPro.ldf',
    SIZE = 8MB,
    MAXSIZE = 2GB,
    FILEGROWTH = 64MB
);

USE SoyITPro;
GO

--- 1. **employees Table: For REGEXP_LIKE Example**

-- Create employees table with some records
DROP TABLE IF EXISTS employees
CREATE TABLE employees (
    ID INT IDENTITY(101,1),
    [Name] VARCHAR(150),
    Email VARCHAR(320),
 Phone_Number NVARCHAR(20)
);
INSERT INTO employees ([Name], Email, Phone_Number) VALUES
    ('John Doe', 'john@contoso.com', '123-4567890'),
    ('Alice Smith', 'alice@fabrikam@com', '234-567-81'),
    ('Bob Johnson', 'bob.fabrikam.net','345-678-9012'),
    ('Eve Jones', 'eve@contoso.com', '456-789-0123'),
    ('Charlie Brown', 'charlie@contoso.co.in', '567-890-1234');
GO

-- 2. **customer_reviews Table: For REGEXP_COUNT Example**
DROP TABLE IF EXISTS customer_reviews
CREATE TABLE customer_reviews (
    review_id INT PRIMARY KEY,
    review_text VARCHAR(1000)
);
INSERT INTO customer_reviews (review_id, review_text) VALUES 
(1, 'This product is excellent! I really like the build quality and design.'),
(2, 'Good value for money, but the software could use improvements.'),
(3, 'Poor battery life, bad camera performance, and poor build quality.'),
(4, 'Excellent service from the support team, highly recommended!'),
(5, 'The product is good, but delivery was delayed. Overall, decent experience.');
GO
 
-- 3. **process_logs Table: For REGEXP_INSTR Example**
DROP TABLE IF EXISTS process_logs
CREATE TABLE process_logs (
    log_id INT PRIMARY KEY,
    log_entry VARCHAR(1000)
);
INSERT INTO process_logs (log_id, log_entry) VALUES 
(1, 'Start process... Step 1: Initialize. Step 2: Load data. Step 3: Complete.'),
(2, 'Begin... Step 1: Validate input. Step 2: Process data. Step 3: Success.'),
(3, 'Step 1: Check configuration. Step 2: Apply settings. Step 3: Restart.'),
(4, 'Step 1: Authenticate. Step 2: Transfer data. Step 3: Log complete.'),
(5, 'Step 1: Initiate system. Step 2: Check logs. Step 3: Shutdown.');
GO
 
-- 4. **transactions Table: For REGEXP_REPLACE Example**
DROP TABLE IF EXISTS transactions
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    credit_card_number VARCHAR(19)
);
INSERT INTO transactions (transaction_id, credit_card_number) VALUES 
(1, '1234-5678-9101-1121'),
(2, '4321-8765-1098-7654'),
(3, '5678-1234-9876-5432'),
(4, '9876-4321-6543-2109'),
(5, '1111-2222-3333-4444');
GO
 
-- 5. **server_logs Table: For REGEXP_SUBSTR and Data Cleanup Example**
DROP TABLE IF EXISTS server_logs
CREATE TABLE server_logs (
    log_id INT PRIMARY KEY,
    log_entry VARCHAR(2000)
);
INSERT INTO server_logs (log_id, log_entry) VALUES 
(1, '2023-08-15 ERROR: Connection timeout from 192.168.1.1 user admin@example.com'),
(2, '2023-08-16 INFO: User login successful from 10.0.0.1 user user1@company.com'),
(3, '2023-08-17 ERROR: Disk space low on 172.16.0.5 user support@domain.com'),
(4, '2023-08-18 WARNING: High memory usage on 192.168.2.2 user hr@office.com'),
(5, '2023-08-19 ERROR: CPU overload on 10.1.1.1 user root@system.com');
GO
 
-- 6. **personal_data Table: For REGEXP_REPLACE (Masking Sensitive Data) Example**
DROP TABLE IF EXISTS personal_data
CREATE TABLE personal_data (
    person_id INT PRIMARY KEY,
    sensitive_info VARCHAR(100)
);
INSERT INTO personal_data (person_id, sensitive_info) VALUES 
(1, 'John Doe - SSN: 123-45-6789'),
(2, 'Jane Smith - SSN: 987-65-4321'),
(3, 'Alice Johnson - Credit Card: 4321-5678-1234-8765'),
(4, 'Bob Brown - Credit Card: 1111-2222-3333-4444'),
(5, 'Eve White - SSN: 111-22-3333');
GO

/*These tables contain realistic sample data for testing the regular expression queries. 
You can modify or extend the records as needed for additional complexity. */

/* Let's see the use cases for `REGEXP_LIKE`, `REGEXP_COUNT`, `REGEXP_INSTR`, `REGEXP_REPLACE`, and `REGEXP_SUBSTR` in SQL. 
These examples are designed to handle real-world scenarios with multiple conditions, nested regex functions, or advanced string manipulations.*/
 
/* 1. **REGEXP_LIKE to filter based on Complex Pattern**
 
Scenario #1: find all the employees whose email addresses are valid and end with .com 
*/
SELECT [Name], Email
FROM Employees
WHERE REGEXP_LIKE(Email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.com$');
GO

/* 
Scenario #2: Recreate employees table with CHECK constraints for 'Email' and 'Phone_Number' columns
*/
DROP TABLE IF EXISTS Employees
CREATE TABLE Employees (
    ID INT IDENTITY(101,1),
    [Name] VARCHAR(150),
    Email VARCHAR(320)
 CHECK (REGEXP_LIKE(Email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
 Phone_Number NVARCHAR(20)
 CHECK (REGEXP_LIKE (Phone_Number, '^(\d{3})-(\d{3})-(\d{4})$'))
);
INSERT INTO employees ([Name], Email, Phone_Number) VALUES
    ('John Doe', 'john@contoso.com', '123-456-7890'),
    ('Alice Smith', 'alice@fabrikam.com', '234-567-8100'),
    ('Bob Johnson', 'bob@fabrikam.net','345-678-9012'),
    ('Eve Jones', 'eve@contoso.com', '456-789-0123'),
    ('Charlie Brown', 'charlie@contoso.co.in', '567-890-1234');
GO

-- CHECK Constraints - Ensure that the data fulfills the specified criteria.
-- FAILURE - Try inserting a row with INVALID values:

INSERT INTO Employees ([Name], Email, Phone_Number) VALUES
    ('Demo Data', 'demo@contoso.com', '123-456-7890');
GO
SELECT * FROM Employees;

---
 
/* 2. **`REGEXP_COUNT` to Analyze Word Frequency in Text**
 
Scenario: Counting Specific Words in Large Text Data
Suppose you have a `customer_reviews` table, and you want to count the number of occurrences of specific words like "excellent", "good", "bad", or "poor" 
to evaluate customer sentiment. */

SELECT review_id, 
       REGEXP_COUNT(review_text, '\b(excellent|good|bad|poor)\b', 1, 'i') AS sentiment_word_count, review_text
FROM customer_reviews;
GO
 
---
 
/* 3. **`REGEXP_INSTR to Detect Multiple Patterns in Sequence**
 
Scenario: Identify the Position of Multiple Patterns in Sequence
Imagine you have log data where each entry contains a sequence of steps, and you need to find the position of a specific pattern like "Step 1", "Step 2", 
and "Step 3", ensuring they occur in sequence. */

SELECT log_id, 
       REGEXP_INSTR(log_entry, 'Step\s1.*Step\s2.*Step\s3', 1, 1, 0, 'i') AS steps_position
FROM process_logs
WHERE REGEXP_LIKE(log_entry, 'Step\s1.*Step\s2.*Step\s3', 'i');
GO

---
 
/* 4. **`REGEXP_REPLACE` for replacing string based on the pattern match**
 
Scenario: Redacting Sensitive Information with Variable Lengths
You need to redact sensitive data from a table that contains personal information like Social Security Numbers (SSNs) and credit card numbers. 
The challenge is that the data might be in different formats (e.g., `###-##-####` for SSNs and `####-####-####-####` for credit cards). */
 
SELECT sensitive_info,
       REGEXP_REPLACE(sensitive_info, '(\d{3}-\d{2}-\d{4}|\d{4}-\d{4}-\d{4}-\d{4})', '***-**-****') AS redacted_info
FROM personal_data;
GO
 

---

/* 5. **REGEXP_SUBSTR to Extract Nested Information**

Scenario: Extract Specific Parts of a Complex String Format */

SELECT [Name], Email, REGEXP_SUBSTR(email, '@(.+)$', 1, 1,'c',1) AS Domain
FROM employees;
GO
---

/* 6. **Combining Multiple REGEXP Functions for Data Transformation**

Scenario: Log Cleanup and Transformation
You have raw server logs that contain noisy data. Your goal is to:
1. Extract the date.
2. Count how many times the word "ERROR" appears.
3. Replace any email addresses with `[REDACTED]`.
*/
SELECT log_entry,
       REGEXP_SUBSTR(log_entry, '\d{4}-\d{2}-\d{2}', 1, 1) AS log_date,
       REGEXP_COUNT(log_entry, 'ERROR', 1, 'i') AS error_count,
       REGEXP_REPLACE(log_entry, '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}', '[REDACTED]') AS cleaned_log
FROM server_logs;
GO

---
--*TVFs*
/* 7. **REGEXP_MATCHES - Find all the match in the string and return in tablular format***/
SELECT * FROM REGEXP_MATCHES ('Learning #AzureSQL #AzureSQLDB', '#([A-Za-z0-9_]+)');

/* 8. **REGEXP_SPLIT_TO_TABLE -  Split string based on regexp pattern**/
SELECT * FROM REGEXP_SPLIT_TO_TABLE ('192.168.0.1|80|200|Success|192.168.0.2|443|404|Not Found', '\|')