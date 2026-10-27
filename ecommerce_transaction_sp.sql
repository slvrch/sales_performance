create or replace procedure datawarehouse.generate_ecommerce_transaction()
 language plpgsql
as $procedure$
begin
	-- Step 1: Load Data into Staging (stg)
	create table if not exists staging.stg_ecommerce_transaction as
	select *, current_timestamp as last_update 
    from public.ecommerce_transaction;
    truncate table staging.stg_ecommerce_transaction;
    insert into staging.stg_ecommerce_transaction
    select *, current_timestamp as last_update 
    from public.ecommerce_transaction;

    -- Resolving missing value in the shipping_metode column
    update staging.stg_ecommerce_transaction
    set shipping_metode = 'Not Available'
    where shipping_metode IS NULL
       or trim(shipping_metode) = '';

    -- Step 2: Load Data into Dim_Product
    create table if not exists datawarehouse.dim_ecommerce_product (
        id_produk INT primary key,
        produk_nama varchar(255),
        produk_kategori varchar(50),
        produk_harga float4,
        last_update timestamp default current_timestamp   
    );
    truncate table datawarehouse.dim_ecommerce_product;
    insert into datawarehouse.dim_ecommerce_product (id_produk, produk_nama, produk_kategori, produk_harga, last_update)
    select src.id_produk, src.produk_nama, src.produk_kategori, src.produk_harga, CURRENT_TIMESTAMP
    from staging.stg_ecommerce_transaction as src
    group by src.id_produk, src.produk_nama, src.produk_kategori, src.produk_harga;
    
    -- Step 3: Load Data into Dim_Store
    create table if not exists datawarehouse.dim_ecommerce_store (
        toko_id int primary key,
        toko_nama varchar(255),
        toko_phone varchar(50),
        toko_city varchar(50),
        last_update timestamp default current_timestamp
    );
    truncate table datawarehouse.dim_ecommerce_store;
    insert into datawarehouse.dim_ecommerce_store (toko_id, toko_nama, toko_phone, toko_city, last_update)
    select src.toko_id, src.toko_nama, src.toko_phone, src.toko_city, current_timestamp
    from staging.stg_ecommerce_transaction as src
    group by src.toko_id, src.toko_nama, src.toko_phone, src.toko_city;
   
    -- Step 4: Load Data into Dim_User
    create table if not exists datawarehouse.dim_ecommerce_user (
        id_user int primary key,
        nama_user varchar(255),
        email_user varchar(255),
        phone_user varchar(50),
        gender_user varchar(50),
        usia_user int,
        kota_user varchar(50),
        last_update timestamp default current_timestamp
    );
    truncate table datawarehouse.dim_ecommerce_user;
    insert into datawarehouse.dim_ecommerce_user (id_user, nama_user, email_user, phone_user, 
                                                   gender_user, usia_user, kota_user, last_update)
    select src.id_user, src.nama_user, src.email_user, src.phone_user, 
           src.gender_user, src.usia_user, src.kota_user, current_timestamp
    from staging.stg_ecommerce_transaction as src
    group by src.id_user, src.nama_user, src.email_user, src.phone_user, src.gender_user, src.usia_user, src.kota_user; 
   
   
    -- Step 5: Load Data into Fact_Sales
    create table if not exists datawarehouse.fact_ecommerce_transaction (
        id_sale int primary key,
        transaksi_date date,
        transaksi_time time,
        toko_id int,
        id_user int,
        id_produk int,
        quantity int,
        total_harga float,
        payment_metode varchar(50),
        transaksi_status varchar(50),
        shipping_metode varchar(50),
        last_update timestamp default current_timestamp
    );
    insert into datawarehouse.fact_ecommerce_transaction (id_sale, transaksi_date, transaksi_time, toko_id, id_user, 
                                                          id_produk, quantity, total_harga, payment_metode,
                                                          transaksi_status, shipping_metode, last_update)
    select
       src.id_transaksi as id_sale,
       src.waktu_transaksi::DATE as transaksi_date,
       src.waktu_transaksi::TIME as transaksi_time,
       src.toko_id,
       src.id_user,
       src.id_produk,
       src.quantity,
       src.total_harga,
       src.payment_metode,
       src.transaksi_status,
       src.shipping_metode,
       current_timestamp as last_update
    from staging.stg_ecommerce_transaction as src
    where not exists (
        select 1 from datawarehouse.fact_ecommerce_transaction as fact
        where fact.id_sale = src.id_transaksi
    );
   
   
    -- Step 6: Create Data Mart View (vw_dm_cube_ecommerce_transaction)
    create or replace view datamart.vw_dm_cube_ecommerce_transaction as
    select
       fs.id_sale,
       fs.transaksi_date,
       fs.transaksi_time,
       fs.toko_id,
       ds.toko_nama,
       ds.toko_city,
       fs.id_user,
       du.nama_user,
       du.kota_user,
       fs.id_produk,
       dp.produk_nama,
       dp.produk_kategori,
       dp.produk_harga,
       fs.quantity,
       fs.total_harga,
       fs.payment_metode,
       fs.transaksi_status,
       fs.shipping_metode,
       fs.last_update
    from
       datawarehouse.fact_ecommerce_transaction fs
    left join
       datawarehouse.dim_ecommerce_store ds on fs.toko_id = ds.toko_id
    left join
       datawarehouse.dim_ecommerce_user du on fs.id_user = du.id_user
    left join
       datawarehouse.dim_ecommerce_product dp on fs.id_produk = dp.id_produk;
   
     -- Step 7: Create Data Mart Cube Table
     create table if not exists datamart.dm_cube_ecommerce_transaction (
       id_sale int,
       transaksi_date date,
       transaksi_time time,
       toko_id int,
       toko_nama varchar(255),
       toko_city varchar(50),
       id_user int,
       nama_user varchar(255),
       kota_user varchar(50),
       id_produk int,
       produk_nama varchar(255),
       produk_kategori varchar(50),
       produk_harga float4,
       quantity int,
       total_harga float,
       payment_metode varchar(50),
       transaksi_status varchar(50),
       shipping_metode varchar(50),
       last_update timestamp default current_timestamp    
    ) partition by range (transaksi_date);
   

    -- Step 8: Create Daily Partitions (2025-01-01 to 2025-03-28)
    do $$
    declare d date := '2025-01-01';
    begin
   	   while d <= '2025-03-28' loop
   	  	  execute format(
   	  	      'create table if not exists datamart.dm_cube_ecommerce_transaction_%s
               partition of datamart.dm_cube_ecommerce_transaction
               for values from (%L) to (%L);',
               to_char(d, 'YYYYMMDD'), d, d + interval '1 day'
   	  	);
        d := d + interval '1 day';
   	   end loop; 
    end $$;
   
   
    -- Step 9: Refresh Data in Data Mart Cube Table
    truncate table datamart.dm_cube_ecommerce_transaction;
    insert into datamart.dm_cube_ecommerce_transaction (id_sale, transaksi_date, transaksi_time, toko_id,
                                                        toko_nama, toko_city, id_user, nama_user, kota_user,
                                                        id_produk, produk_nama, produk_kategori, produk_harga,
                                                        quantity, total_harga, payment_metode, transaksi_status,
                                                        shipping_metode, last_update)
    select
       id_sale,
       transaksi_date,
       transaksi_time,
       toko_id,
       toko_nama,
       toko_city,
       id_user,
       nama_user,
       kota_user,
       id_produk,
       produk_nama,
       produk_kategori,
       produk_harga,
       quantity,
       total_harga,
       payment_metode,
       transaksi_status,
       shipping_metode,
       last_update
    from (
       select *, row_number() over (partition by id_sale order by last_update desc) as flag_unique
       from datamart.vw_dm_cube_ecommerce_transaction
    ) as ranked_data
    where flag_unique = 1;
   
    -- Step 10: Refresh Data in Most Transactions by Date Data Mart
    -- Automation: Create Table
    create table if not exists datamart.dm_most_transaction_date as 
    select transaksi_date, count(*) as total_transaksi, current_timestamp as last_update
    from datamart.dm_cube_ecommerce_transaction
    group by transaksi_date
    order by total_transaksi desc;
   
    -- Automation: Truncate --> SCD Type 1
    truncate table datamart.dm_most_transaction_date;
   
    -- Automation: Inserting New Data
    insert into datamart.dm_most_transaction_date
    select transaksi_date, count(*) as total_transaksi, current_timestamp as last_update
    from datamart.dm_cube_ecommerce_transaction
    group by transaksi_date
    order by total_transaksi desc;
   
   
    -- Step 11: Total Transaction and Total User per hour
    -- Automation: Create Table
	create table if not exists datamart.dm_total_transaction_total_user_per_hour as
    select
        date_trunc('hour', transaksi_date + transaksi_time) as transaction_hour, -- transformasi waktu 
        count(id_sale) as total_transaction, -- jumlah transaksi terjadi di tiap jam
        count(distinct id_user) as total_user, -- jumlah user unik bertransaksi di jam tersebut
        current_timestamp as last_update
    from datamart.dm_cube_ecommerce_transaction
    group by date_trunc('hour', transaksi_date + transaksi_time)
    order by transaction_hour;

    -- Automation: Truncate --> SCD Type 1
    truncate table datamart.dm_total_transaction_total_user_per_hour;
    -- Automation: Inserting New Data
    insert into datamart.dm_total_transaction_total_user_per_hour
    select
        date_trunc('hour', transaksi_date + transaksi_time) as transaction_hour,
        count(id_sale) as total_transaction,
        count(distinct id_user) as total_user,
        current_timestamp as last_update
   from datamart.dm_cube_ecommerce_transaction
   group by date_trunc('hour', transaksi_date + transaksi_time);

   -- Step 12: Total Quantity by Product ID
   -- Automation: Create Table
   create table if not exists datamart.dm_total_quantity_by_id_product as
   select
       id_produk, 
       sum(quantity) as total_quantity,
       current_timestamp as last_update
   from datamart.dm_cube_ecommerce_transaction
   group by id_produk;
   -- Automation: Truncate --> SCD Type 1
   truncate table datamart.dm_total_quantity_by_id_product;
   -- Automation: Inserting New Data
   insert into datamart.dm_total_quantity_by_id_product
   select id_produk,
          sum(quantity) as total_quantity,
          current_timestamp as last_update
   from datamart.dm_cube_ecommerce_transaction
   group by id_produk;

   -- Step 13: Total Quantity by Store ID 
   -- Automation: Create Table
   create table if not exists datamart.dm_total_quantity_by_store_id as
   select
       toko_id,
       sum(quantity) as total_quantity,
       current_timestamp as last_update
   from datamart.dm_cube_ecommerce_transaction
   group by toko_id;
   -- Automation: Truncate --> SCD Type 1
   truncate table datamart.dm_total_quantity_by_store_id;
   -- Automation: Inserting New Data
   insert into datamart.dm_total_quantity_by_store_id
   select 
       toko_id,
       sum(quantity) as total_quantity,
       current_timestamp as last_update
   from datamart.dm_cube_ecommerce_transaction
   group by toko_id;

   -- Step 14: Total Revenue by Store ID, Store Name, Store City
   -- Automation: Create Table
   create table if not exists datamart.dm_total_revenue_by_store as
   select
       toko_id,
       toko_nama,
       toko_city,
       sum(total_harga) as total_revenue,
       current_timestamp as last_update
   from datamart.dm_cube_ecommerce_transaction
   group by toko_id, toko_nama, toko_city;
   -- Automation: Truncate --> SCD Type 1
   truncate table datamart.dm_total_revenue_by_store;
   -- Automation: Inserting New Data
   insert into datamart.dm_total_revenue_by_store
   select
       toko_id,
       toko_nama,
       toko_city,
       sum(total_harga) as total_revenue,
       current_timestamp as last_update
   from datamart.dm_cube_ecommerce_transaction
   group by toko_id, toko_nama, toko_city;
end;
$procedure$
;