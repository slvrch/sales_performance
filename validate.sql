select toko_phone


select distinct toko_phone
from staging.stg_ecommerce_transaction t 
order by toko_phone;

select distinct phone_user
from staging.stg_ecommerce_transaction t 
order by phone_user ;

call datawarehouse.generate_ecommerce_transaction();

select count(*)
from public.ecommerce_transaction;

select * from public.ecommerce_transaction et
limit 10;

select count(*)
from public.ecommerce_transaction et ;

select *
from public.ecommerce_transaction;

select count(*)
from staging.stg_ecommerce_transaction;

select count(*)
from staging.stg_ecommerce_transaction
where shipping_metode is null
   or trim(shipping_metode) = '';

select count(*)
from public.ecommerce_transaction
where shipping_metode is null
   or trim(shipping_metode) = '';

select id_sale, count(*)
from datamart.dm_cube_ecommerce_transaction
group by id_sale
having count(*) > 1;

select *
from datamart.dm_total_revenue_by_store;

select *
from staging.stg_ecommerce_transaction;

select *
from datawarehouse.dim_ecommerce_product
order by id_produk;

select *
from datawarehouse.dim_ecommerce_store
order by toko_id; 

select *
from datawarehouse.dim_ecommerce_user
order by id_user;

select *
from datawarehouse.fact_ecommerce_transaction
order by id_sale;

select shipping_metode
from ecommerce_transaction et;

select *
from datamart.dm_most_transaction_date;

select *
from datamart.dm_total_quantity_by_id_product;

select *
from datamart.dm_total_transaction_total_user_per_hour;

select *
from datamart.dm_total_quantity_by_store_id;

select *
from datamart.dm_cube_ecommerce_transaction_20250101;

select *
from datawarehouse.dim_ecommerce_user;

select *
from datamart.vw_dm_cube_ecommerce_transaction;

select *
from datamart.dm_cube_ecommerce_transaction;

select count(*)
from datamart.dm_total_revenue_by_store dtrbs;

select *
from datamart.dm_total_revenue_by_store dtrbs 
order by dtrbs.total_revenue desc;

-- Cek Partition
select tablename
from pg_tables
where schemaname = 'datamart'
   and tablename like 'dm_cube_ecommerce_transaction_%'
order by tablename;

select 
    parent.relname as parent_table,
    child.relname as partition_table
from pg_inherits
join pg_class parent on pg_catalog.pg_inherits.inhparent = parent.oid
join pg_class child on pg_inherits.inhrelid = child.oid
where parent.relname = 'dm_cube_ecommerce_transaction'
order by partition_table;

select 
   child.relname as partition_name,
   pg_get_expr(child.relpartbound, child.oid) as partition_range
from pg_inherits
join pg_class child
   on pg_inherits.inhrelid = child."oid" 
join pg_class parent
   on pg_inherits.inhparent = parent."oid" 
where parent.relname = 'dm_cube_ecommerce_transaction'
order by child.relname;

select 
    c.relname as partition_name,
    pg_get_expr(c.relpartbound, c.oid) as partition_range
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'datamart'
   and c.relname like 'dm_cube_ecommerce_transaction_%'
order by partition_name;

select count(*)
from datamart.dm_cube_ecommerce_transaction_20250101;

select count(*)
from datamart.dm_cube_ecommerce_transaction;