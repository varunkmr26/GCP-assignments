#!/bin/bash
echo "Creating SQL instance"
gcloud sql instances create varun-pe-sql --tier=db-f1-micro --region=us-central1
echo "Creating Database"
gcloud sql databases create employee_mgmt --instance=varun-pe-sql
echo "Creating user"
gcloud sql users create application_user --instance=varun-pe-sql
echo "getting IP"
ip=`gcloud sql instances describe varun-pe-sql --format="value(ipAddresses.ipAddress)"`
gcloud sql connect varun-pe-sql --user=root<< EOF
USE employee_mgmt;
CREATE TABLE employee_details (name VARCHAR(10), role VARCHAR(10));
INSERT INTO employee_details VALUES ('Varun', 'PE');
INSERT INTO employee_details VALUES ('Sanchit', 'SD');
INSERT INTO employee_details VALUES ('Neeti', 'MLE');
INSERT INTO employee_details VALUES ('Nikki', 'MLE');
SELECT * FROM employee_details;
UPDATE employee_details SET role='PE' WHERE name=='Sanchit';
SELECT * FROM employee_details;
DELETE FROM employee_details WHERE name=='Sanchit';
SELECT * FROM employee_details;
GRANT SELECT, INSERT on employee_mgmt.employee_details to application_user;
SHOW GRANTS application_user;
REVOKE SELECT, INSERT on employee_mgmt.employee_details from application_user;
SHOW GRANTS application_user;
EOF
