# E-Commerce Data Analytics: ETL Pipeline & Retail Sales Performance

## PostgreSQL ETL Pipeline

### ETL Overview

#### ETL

ETL (Extract, Transform, Load) is a data integration process used to extract data from source systems, transforms it into a consistent structure, and load it into a target system for analysis and reporting

#### Purpose

Building an ETL pipeline using PostgreSQL to transform raw e-commerce transaction data into structured, analytical-ready data for Retail Sales Performance Analysis 

#### ETL Scope

- Extract transaction data from the source table
- Load the data into the staging layer
- Perform data cleansing and transformation
- Create dimension and fact tables in the data warehouse
- Create a data mart cube and analytical data marts
- Automate the process using stored procedures 

#### ETL Architecture

The pipeline follows a layered architecture to transform raw e-commerce transaction data into analytical-ready data.

```mermaid
flowchart TD
    A[Public / Source<br/>ecommerce_transaction]
    B[Staging<br/>Data Preparation & Cleaning]
    C[Data Warehouse<br/>Dimension + Fact]
    D[Data Mart<br/>Cube + KPI Data Marts]
    E[Retail Sales Performance<br/>Analysis / Dashboard]

    A -->|Extract| B
    B -->|Transform & Load| C
    C -->|Integration| D
    D -->|Analytics| E
```

**Layers:**
- **Public**: source/raw transaction data
- **Staging**: initial data preparation and cleaning
- **Data Warehouse**: structured dimension and fact tables
- **Data Mart**: analytical cube and aggregated KPI tables
- **Retail Sales Analysis**: uses the processed data for business analysis and dashboarding

#### Analytical Purpose

The data processed through the pipeline is used as analytical-ready data to support retail sales performance analysis, including analysis of transactions, products, stores, quantities and revenue

#### Key Implementation

- PostgreSQL
- Staging layer
- Star schema
- Dimension & fact tables
- Data mart cube
- Range partitioning by transaction date
- Stored procedure for ETL automation
- Batch refresh strategy
- `TRUNCATE + INSERT` for staging and analytical data mart
- Duplicate prevention in fact loading

### Source Data

#### Source Table

```public.ecommerce_transaction``` is the raw transaction table that serves as the primary data source for the ETL pipeline.

#### Data Content
| Category    | Fields                                                          |
| ----------- | --------------------------------------------------------------- |
| Transaction | `id_transaksi`, `waktu_transaksi`, `transaksi_status`           |
| User        | `id_user`, `nama_user`, `gender_user`, `usia_user`, `kota_user` |
| Store       | `toko_id`, `toko_nama`, `toko_city`                             |
| Product     | `id_produk`, `produk_nama`, `produk_kategori`, `produk_harga`   |
| Sales       | `quantity`, `total_harga`                                       |
| Payment     | `payment_metode`                                                |
| Shipping    | `shipping_metode`                                               |

The source transaction table serves as the input to the ETL pipeline and is extracted into the staging layer for further processing.

### Staging & Data Transformation

The staging layer is used for initial data preparation and cleansing before the data is loaded into the data warehouse.

- Load extracted data into the staging table
- Add `last_update` as ETL metadata
- Handle missing values in `shipping_metode`
- Phone number fields were standardized by removing formatting characters while preserving the original numeric value
- Prepare the cleaned data for downstream processing

### Data Warehouse

The cleaned data from the staging layer is transformed into a structured data warehouse using a star schema. The data warehouse consists of dimension tables and a fact table.

#### Dimension Tables

- `datawarehouse.dim_ecommerce_product`
- `datawarehouse.dim_ecommerce_store`
- `datawarehouse.dim_ecommerce_user`

#### Fact Table

- `datawarehouse.fact_ecommerce_transaction`

Dimension tables store descriptive information about products, stores, and users, while the fact table stores e-commerce transaction records and measurable sales attributes such as quantity and transaction value.

```mermaid
flowchart LR
    P[dim_ecommerce_product] --> F[fact_ecommerce_transaction]
    S[dim_ecommerce_store] --> F
    U[dim_ecommerce_user] --> F
```

### Data Mart Cube

The data mart cube integrates transaction data from the fact table with descriptive attributes from the product, store, and user dimension tables. The resulting dataset provides an analytical-ready structure for downstream aggregation and reporting.

#### Cube View
A data mart view is created by joining the fact transaction table with product, store, and user dimensions to provide a denormalized analytical view.

- Fact: `fact_ecommerce_transaction`
- Product: `dim_ecommerce_product`
- Store: `dim_ecommerce_store`
- User: `dim_ecommerce_user`

The resulting view is stored as:

`datamart.vw_dm_cube_ecommerce_transaction`

#### Physical Cube Table

The integrated data is loaded into the physical data mart cube:

`datamart.dm_cube_ecommerce_transaction`

The cube contains transaction, user, product, store, quantity, revenue, payment, transaction status, and shipping information.

#### Data Deduplication

Duplicate transaction records are handled using `ROW_NUMBER()` partitioned by transaction ID, keeping the latest record based on `last_update`.

#### Refresh Strategy
 
The physical cube table uses a full-refresh approach by truncating existing data and reloading the latest integrated data from the cube view.

`TRUNCATE → INSERT`

This ensures that the cube contains the latest integrated data before downstream KPI data marts are refreshed.

### Partitioning

The cube table is partitioned by `transaksi_date` using range partitioning, with one partition for each day.

Daily partitions are created for the transaction date range from `2025-01-01` to `2025-03-28`.

This partitioning strategy helps optimize time-based analytical queries through partition pruning and simplifies the management of historical transaction data.

### KPI Data Marts

The KPI data marts are created from the data mart cube to provide aggregated dataset for specific analytical requirements. Each data mart combines relevant business metrics with analytical dimensions to support transaction, product, store, and revenue analysis.

| Step | Data Mart                         | Metric                                      | Dimension | Analytical Purpose                   |
| ---- | --------------------------------- | ------------------------------------------- | --------- | ------------------------------------ |
| 10   | Most Transactions by Date         | `COUNT(*)`                                  | Date      | Analyze transaction volume over time |
| 11   | Total Transaction & User per Hour | `COUNT(id_sale)`, `COUNT(DISTINCT id_user)` | Hour      | Identify peak customer activity      |
| 12   | Total Quantity by Product         | `SUM(quantity)`                             | Product   | Analyze product sales volume         |
| 13   | Total Quantity by Store           | `SUM(quantity)`                             | Store     | Compare store sales volume           |
| 14   | Total Revenue by Store            | `SUM(total_harga)`                          | Store     | Compare store revenue performance    |


The KPI data marts provide pre-aggregated analytical dataset, while the data mart cube remains the primary detailed analytical source for broader business analysis and reporting.

### Stored Procedure & Automation

**Purpose:** The ETL workflow is automated using a PostgreSQL stored procedure to execute the data loading, transformation, data mart refresh, and partitioning processes as a single workflow.

#### Stored Procedure

CREATE OR REPLACE PROCEDURE datawarehouse.generate_ecommerce_transaction()
LANGUAGE plpgsql
AS $procedure$
BEGIN

    -- Step 1–14: ETL process

END;
$procedure$;

The `generate_ecommerce_transaction()` stored procedure encapsulates the ETL workflow into a single executable procedure. It is implemented using PostgreSQL PL/pSQL.

#### ETL Automation Workflow

                    CALL PROCEDURE
                         │
                         ▼
        generate_ecommerce_transaction()
                         │
        ┌────────────────┼────────────────┐
        ▼                ▼                ▼
    STAGING         DATA WAREHOUSE     DATA MART
        │                │                │
    Step 1            Step 2–5          Step 6–14
        │                │                │
    Cleansing       Dimension + Fact   Cube + KPI
        │                │                │
        └────────────────┴────────────────┘
                         │
                         ▼
                  Analytical Data
                         │
                         ▼
                     Power BI


| Stage      | Process                | Output                          |
| ---------- | ---------------------- | ------------------------------- |
| Step 1     | Load & cleanse staging | `stg_ecommerce_transaction`     |
| Step 2–4   | Load dimensions        | Product, Store, User            |
| Step 5     | Load fact              | `fact_ecommerce_transaction`    |
| Step 6–9   | Build & refresh cube   | `dm_cube_ecommerce_transaction` |
| Step 8     | Create partitions      | Daily transaction partitions    |
| Step 10–14 | Refresh KPI data marts | Analytical summaries            |

#### Refresh Strategy

The staging and analytical data marts use a batch full-refresh approach. Existing data is truncated and reloaded from the latest source or upstream analytical layer.

     Latest Source Data
            ↓
         TRUNCATE
            ↓
          INSERT
            ↓
       Refreshed Table

#### Partition Automation

Daily partitions are created as part of the ETL workflow before the cube before is loaded.

#### Execution

`CALL datawarehouse.generate_ecommerce_transaction();`

The complete ETL workflow can be executed through a single `CALL` statement instead of manually running each ETL step.

#### Automation Outcome

- Consistency: ETL steps are executed using a standardized workflow.
- Efficiency: Multiple SQL operations can be executed through a single procedure call
- Maintainability: ETL logic is centralized in one stored procedure
- Reusability: The procedure can be executed again when the source data needs to be refreshed

### ETL Validation

Data quality checks were performed after executing the ETL stored procedure to verify data completeness, transformation results uniqueness, and partition creation.

#### Record Count

| Layer | Row Count |
|---|---:|
| Source | 2,000 |
| Staging | 2,000 |

**Result:** PASS - The staging layer contains the same number of records as the source table.

#### Missing Value

| Layer | Missing `shipping_metode` |
|---|---:|
| Source | 1,324 |
| Staging | 0 |

**Result:** PASS - Empty values in `shipping_metode` were replaced with `Not Available` during staging transformation.

#### Duplicate Transaction

**Result:** PASS - No duplicate `id_sale` values were found in the data mart cube.

#### Partition Validation

The data mart cube was configured with daily range partitions from `2025-01-01` to `2025-03-28`.

| Validation | Expected | Actual |
|---|---:|---:|
| Daily partitions | 87 | 87 |

**Result:** PASS - ALL expected daily partitions were created.

#### Data Mart Output

The KPI data marts were checked to ensure that ETL process produced the expected analytical outputs.

**Result:** PASS - KPI data marts were successfully populated.

## Retail Sales Performance Analysis

### Background Business

Retail Crystal, during the January-March 2025 period, experienced high transaction volumes and dynamic changes in customer behaviors. The key performance indicator (KPI) used is total revenue, with a benchmark of maintaining a minimum average monthly revenue of 18.7T. However, revenue showed a downward trend during the analysis period, so it is necessary to monitor sales performance regularly to understand sales trends, best-selling products, regional contributions, and customer transaction patterns.

Therefore, a retail sales performance dashboard has been created to assist with sales analysis, monitor key KPIs, and support decision-making based on transaction data.

### Business Problem

The company is experiencing a downward trend in revenue and does not yet have a structured sales monitoring system in place to understand the factors affecting its business performance

### Questions Business

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


