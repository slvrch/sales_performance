# E-Commerce Data Analytics: ETL Pipeline & Retail Sales Performance

## PostgreSQL ETL Pipeline

### ETL Overview

#### ETL

ETL (Extract, Transform, Load) is a data processing procedure designed to integrate data from various sources into a single centralized system, making it ready for use in analysis and reporting

#### Purpose

Building an ETL pipeline using PostgreSQL to process e-commerce transaction data transforming it from raw data into structured data ready for retail sales analysis

#### ETL Scope

- Extract transaction data from the source table
- Load the data into the staging layer
- Perform data cleansing and transformation
- Create dimension and fact tables in the data warehouse
- Create cubes and analytical data marts
- Automate the process using stored procedures 

#### ETL Architecture

The ETL pipeline transforms raw e-commerce transaction data into structured analytical data through staging, data warehouse, and data mart layers. The resulting data is used to support Retail Sales Performance Analysis

- Public: source/raw transaction data
- Staging: initial data preparation and cleaning
- Data Warehouse: structured dimension and fact tables
- Data Mart: analytical cube and aggregated KPI tables
- Retail Sales Analysis: uses the processed data for business analysis and dashboarding

#### Analytical Purpose

The data processed through the pipeline is used as analytical-ready data to support retail sales performance analysis, including analysis of transactions, products, stores, quantities and revenue

#### Key Implementation

- PostgreSQL
- Staging layer
- Star schema
- Data warehouse
- Data mart
- Range partitioning by date
- Stored procedure
- Batch refresh / SCD Type 1

## Retail Sales Performance Analysis

### Background Business

Retail Crystal, during the January-March 2025 period, experienced high transaction volumes and dynamic changes in customer behaviors. The key performance indicator (KPI) used is total revenue, with a benchmark of maintaining a minimum average monthly revenue of 18.7T. However, revenue showed a downward trend during the analysis period, so it is necessary to monitor sales performance regularly to understand sales trends, best-selling products, regional contributions, and customer transaction patterns.

Therefore, a retail sales performance dashboard has been created to assist with sales analysis, monitor key KPIs, and support decision-making based on transaction data.

### Business Problem

The company is experiencing a downward trend in revenue and does not yet have a structured sales monitoring system in place to understand the factors affecting its business performance

### Problem Statement

- What were the sales trends during the January-March 2025 period?
- Which products made the largest contribution to revenue?
- Which category had the highest sales volume?
- Which region was the main contributor to revenue?
- When are customers most active in making purchase?

### Data Understanding

#### Dataset Overview

- Total records: 2000
- Fact table: Sales Transactions
- Dimension: Product, Store, User
- Analysis Period: January-March 2025

#### Feature Categories
- Product Information: Product Name, Category, Quantity, Total Price
- Store & Location Information: Province, City, Store Name
- Transaction Information: Order ID, Transaction Status, Payment Method, Shipping Method
- Time Information: Transaction Date, Transaction Time, Day Name, Month

#### Data Quality Issue
- Missing value shipping method

### Analytics

<img width="626" height="396" alt="image" src="https://github.com/user-attachments/assets/13189a23-c9a8-4c8e-8829-0e647c934f1e" />

Insight:

- There was a 35% drop in revenue from January to March
- The number of transactions declined by only 17%
- February showed early signs of a decline in sales quality before demand fell in March

<img width="668" height="364" alt="image" src="https://github.com/user-attachments/assets/ebaa084e-6974-4f29-bcf0-7bea8e93dfc0" />

Insight:

- The Under Armour Gym Bag has become the product with the highest revenue contribution of 25.2 T
- Revenue is concentrated on a few key products, with an uneven contribution

<img width="687" height="350" alt="image" src="https://github.com/user-attachments/assets/0bd74b32-fc52-4314-a94c-21a723e96f93" />

Insight:

- Sports accounted for the highest proportion at 21.68%
- The distribution of quantities across categories is relatively even, with significant differences in their contributions

<img width="782" height="456" alt="image" src="https://github.com/user-attachments/assets/44244589-5632-4ad7-b150-a550e3339a73" />

Insight:

- Medan is the city with the highest revenue contribution, amounting to 10.2T
- Semarang and Makassar have shown almost identical revenue performance despite being from different regions

<img width="505" height="300" alt="image" src="https://github.com/user-attachments/assets/eb6f06ac-ca90-4b48-bedf-6c1f5ec2a32e" />

Insight:

- Wednesday and Friday are the days with the highest number of orders
- The highest trading activity occurs during the midnight and morning periods

### Conclusion

- Revenue experienced a downward trend during the January-March 2025 period
- The decline in revenue was steeper than the decline in the number of transactions, which indicates a fall in AOV
- Specific products, cities and transaction times are the key contributors to sales performance
- The dashboard helps identify opportunities for optimizing campaigns based on products, regions, and customer transaction patterns

### Recommendation

- Increase AOV through bundling and cross-selling
- Focus promotions on high-revenue products
- Optimize inventory for high-volume categories
- Focus campaigns on the Top 5 cities
- Run promotions during peak transaction times
- Combine products, regions and transaction times to create data-driven campaigns, such as promotions for sports products in Medan on Friday evenings


