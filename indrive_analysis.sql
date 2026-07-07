create database indrive;
use indrive;
select count(*) from bookings;
select * from bookings;

													-- BOOKING PERFORMANCE --
                                                    
-- 1. TOTAL BOOKINGS? 
select count(booking_id) as total_bookings from bookings;
-- 2. SUCCESSFUL BOOKINGS?
select count(booking_id) as successful_bookings from bookings where booking_status='Success';
-- 3. CANCELLED BOOKINGS
select count(booking_id) as canceled_bookings from bookings where booking_status in('Canceled by driver','Canceled by customer', 'Driver not found');
-- 4. INCOMPLETE RIDES 
SELECT 
    COUNT(CASE WHEN incomplete_rides = 'yes' THEN 1 END) AS yes_count,
    COUNT(CASE WHEN incomplete_rides IS NULL THEN 1 END) AS null_count
FROM bookings;
 
-- 5. RIDE COMPLETION RATE
select round(count(case when booking_status='Success' then 1 end)*100.0/count(*), 2) as ride_completion_rate from bookings;
-- 6. CANCELLATION RATE 
select round(
          count( 
                case when booking_status in ('Canceled by driver','Canceled by customer', 'Driver not found') then 1 end)
                *100.0/count(*), 2)
 as cancellation_rate from bookings;
-- 7. INCOMPLETE RIDE RATE 
select round(count(case when incomplete_rides is null then 1 end)*100.0/count(*), 2) as incomplete_ride_rate from bookings;
-- 8. AVERAGE BOOKING VALUE 
select avg(booking_value) as avg_booking_value from bookings;
-- 9. AVERAGE RIDE DISTANCE 
select avg(ride_distance) as avg_ride_distance from bookings;


-- CHANGEING THE DATE COLUMN NAME
ALTER TABLE bookings
RENAME COLUMN ï»¿Date TO booking_date;

-- 10. BOOKING TREND BY DAY
select date(booking_date) as day, count(booking_id) as total_bookings
from bookings group by date(booking_date) order by date(booking_date);
-- 11. BOOKING TREND BY HOUR 
select hour(time) as booking_hour, count(booking_id) as total_bookings 
from bookings group by hour(time) order by hour(time);
-- 12. BOOKING TREND BY VEHICLE TYPE 
select vehicle_type, count(booking_id) as total_bookings from bookings 
group by vehicle_type order by total_bookings desc; 

                                                 -- CUSTOMER ANALYTICS --

-- 1. TOP 10 CUSTOMERS BY BOOKINGS 
select customer_id, count(booking_id) as total_bookings from bookings 
group by customer_id 
order by total_bookings desc, customer_id asc limit 10;
-- 2. TOP CUSTOMERS BY BOOKING VALUE
select customer_id, sum(booking_value) as total_customer_booking_value
from bookings group by customer_id 
order by total_customer_booking_value desc limit 10;
-- 3. CUSTOMERS WITH HIGHEST CANCELLATIONS
select customer_id,
sum(case when booking_status in ('Canceled by driver','Canceled by customer', 'Driver not found') then 1 end) as highest_cancellations 
from bookings group by customer_id 
order by highest_cancellations desc;
-- 4. CUSTOMERS EXPERIENCING THE LONGEST WAITING TIME
select customer_id, max(c_tat) as longest_waiting_time from bookings where c_tat is not null
group by customer_id order by longest_waiting_time desc limit 10;
-- 5. CUSTOMERS GIVING LOWEST RATINGS 
select customer_id, min(customer_rating) as low_ratings_by_customers from bookings 
where customer_rating is not null and customer_rating<4 
group by customer_id order by low_ratings_by_customers asc limit 10;

-- 6. CUSTOMERS PREFERING THE DIGITAL PAYMENTS 
select customer_id, payment_method as digital_payments, count(booking_id) as total_bookings from bookings 
where payment_method in ('upi','credit card')
group by customer_id, payment_method
order by total_bookings desc;
-- 7. AVERAGE CUSTOMER SPENDING
SELECT 
    customer_id,
    COUNT(booking_id) AS total_bookings,
    SUM(booking_value) AS total_spent,
    ROUND(
        SUM(booking_value) / NULLIF(COUNT(booking_id), 0),
        2
    ) AS avg_booking_value
FROM bookings
GROUP BY customer_id
ORDER BY 
    total_spent DESC,
    total_bookings DESC,
    avg_booking_value DESC;
-- 8. CUSTOMER BOOKING FREQUENCY WITH ACTIVE DAYS
SELECT 
    customer_id,
    COUNT(booking_id) AS total_bookings,
    DATEDIFF(MAX(booking_date), MIN(booking_date)) AS active_days,
    CASE 
        -- If active days is 0, just return their total booking count for that day
        WHEN DATEDIFF(MAX(booking_date), MIN(booking_date)) = 0 THEN COUNT(booking_id)
        ELSE ROUND(COUNT(booking_id) / (DATEDIFF(MAX(booking_date), MIN(booking_date)) / 30.0), 2)
    END AS bookings_per_month
FROM 
    bookings
GROUP BY 
    customer_id order by bookings_per_month desc;
-- 9. CUSTOMERS WITH REPEAATED INCOMPLETE RIDES 
SELECT 
    customer_id,
    COUNT(*) AS repeated_incomplete_rides
FROM bookings
WHERE incomplete_rides = 'Yes'
   OR incomplete_rides IS NULL
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY repeated_incomplete_rides DESC;
-- 10.	High-value customers with poor service experience (Ft. Bookings)
select customer_id, count(booking_id) as total_bookings, round(avg(customer_rating),2) as avg_customer_rating
from bookings group by customer_id having count(booking_id)>1 and avg(customer_rating)=3 order by total_bookings desc;
-- 11. High-value customers with poor service experience (Ft. Booking value)
select customer_id, sum(booking_value) as total_spent, count(booking_id) as total_bookings,
round(avg(customer_rating),2) as avg_customer_rating from bookings group by customer_id having count(booking_id)>1 and 
avg(customer_rating)=3 
order by total_spent desc; 

                                 -- DRIVER & FLEET ANALLYTICS --

-- 1. AVERAGE DRIVER RATING 
select round(avg(driver_ratings),2) as avg_driver_rating from bookings;
-- 2. DRIVER CANCELLATION ANALYSIS
SELECT 
    Canceled_Rides_by_Driver AS Cancellation_Reason,
    COUNT(*) AS Total_Cancellations,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS Percentage_Of_Driver_Cancellations
FROM 
    bookings
WHERE 
    Canceled_Rides_by_Driver IS NOT NULL 
    AND Canceled_Rides_by_Driver <> 'null'
GROUP BY 
    Canceled_Rides_by_Driver
ORDER BY 
    Total_Cancellations DESC;
-- 3,4 & 5 VEHICLE WISE PERFORMANCE, VEHICLE WISE REVENUE, VEHICLE WISE COMPLETION RATE 
select vehicle_type, count(booking_id) as total_bookings, sum(booking_value) as total_value,
round(avg(booking_value),2) as avg_value,
count(case when canceled_rides_by_driver is not null and canceled_rides_by_driver <> 'null' then 1 end) as total_driver_cancellations,
round(count(case when canceled_rides_by_driver is not null and canceled_rides_by_driver <> 'null' then 1 end)*100.0/count(*),2) as driver_cancellation_rate
from bookings where vehicle_type is not null and vehicle_type<>'Null' 
group by vehicle_type order by total_value desc;
-- 6. VEHICLE WISE WAITING TIME
select vehicle_type, avg(v_tat) as avg_waiting_time, max(v_tat) as maximum_waiting_time, min(v_tat) as minimum_waiting_time
from bookings 
where vehicle_type is not null and vehicle_type <> 'Null' and v_tat is not null and v_tat <> 'Null'
group by vehicle_type order by avg_waiting_time desc;

set sql_safe_updates=0;
alter table bookings modify column v_tat int;
alter table bookings modify column c_tat int;
set sql_safe_updates=1;

-- 7.  VEHICLE WISE RIDE DISTANCE 
select vehicle_type, avg(ride_distance) as avg_distance, max(ride_distance) as max_distance,
min(ride_distance) as min_distance
from bookings 
group by vehicle_type order by avg_distance desc;
-- 8. TOP 5 VEHICLES GENERATING THE HIGHEST REVENUE 
select vehicle_type, sum(booking_value) as total_revenue
from bookings group by vehicle_type order by total_revenue desc limit 5;
-- 9. TOP VEHICLES WITH HIGHEST CANCELLATIONS 
select vehicle_type, count(case when booking_status in ('Canceled by driver','Canceled by customer', 'Driver not found') then 1 end) as highest_cancellations
from bookings where booking_status is not null and booking_status <> 'Null'
group by vehicle_type 
order by highest_cancellations desc limit 5;
-- 10. VEHICLES WITH HIGHEST INCOMPLETE RIDES 
select vehicle_type, count(*) as highest_incomplete_rides 
from bookings where incomplete_rides ='yes' or incomplete_rides is null
group by vehicle_type order by highest_incomplete_rides desc;

                                      -- OPERATIONAL ANALYTICS --

-- 1. PEAK BOOKING HOURS
select hour(time) as peak_booking_hour, count(*) as total_bookings from bookings 
group by peak_booking_hour order by total_bookings desc;
-- 2. PEAK BOOKING WEEKDAYS
select dayname(booking_date) as peak_booking_weekdays, count(*) as total_bookings from bookings 
group by peak_booking_weekdays order by total_bookings desc;

set sql_safe_updates=0;
alter table bookings modify column booking_date datetime;
set sql_safe_updates=1;

-- 3. PICKUP HOTSPOT ANALYSIS
select pickup_location, count(booking_id) as total_bookings, round(sum(booking_value),2) as total_booking_value
from bookings where pickup_location is not null and pickup_location <> 'Null'
group by pickup_location order by total_bookings desc limit 10;
-- 4. DROP HOTSPOT ANALYSIS
select drop_location, count(booking_id) as total_bookings, round(sum(booking_value),2) as total_booking_value
from bookings where drop_location is not null and drop_location <> 'Null'
group by drop_location order by total_bookings desc limit 10;
-- 5. MOST POPULAR ROUTES
select pickup_location, drop_location, concat(pickup_location, ' -> ',drop_location) as popular_routes,
count(booking_id) as total_bookings, round(sum(booking_value),2) as total_booking_value
from bookings where pickup_location is not null and pickup_location <> 'null' and drop_location is not null and drop_location <>'Null'
group by pickup_location, drop_location order by total_bookings desc limit 10;
-- 6. LONGEST ROUTES
select pickup_location, drop_location, concat(pickup_location,' -> ',drop_location) as route_name,
count(booking_id) as total_bookings, round(avg(ride_distance),2) as avg_ride_distance
from bookings where 
pickup_location is not null and pickup_location <> 'Null' and drop_location is not null and drop_location <> 'Null'
and ride_distance is not null and ride_distance <> 'Null' and ride_distance>0
group by pickup_location, drop_location
order by avg_ride_distance desc limit 10;
-- 7. AVERAGE V_TAT -- 8. AVERAGE C_TAT
select vehicle_type, round(avg(v_tat),2) as avg_v_tat,
round(avg(c_tat),2) as avg_c_tat from bookings group by vehicle_type order by avg_v_tat desc;
-- 9. LOCATIONS WITH LONGEST WAITING TIMES 
select pickup_location, count(booking_id) as total_bookings, round(avg(v_tat),2) as avg_waiting_time from bookings
where pickup_location is not null and pickup_location <> 'Null' and v_tat is  not null and v_tat <> 'Null'
group by pickup_location order by avg_waiting_time desc limit 10;

-- 10. OPERATIONAL DELAYS BY VECHICLE TYPE
select vehicle_type, count(booking_id) as total_bookings, 
round(avg(v_tat),2) as driver_arrival_delay, 
round(avg(c_tat),2) as customer_arrival_delay from bookings 
where v_tat is not null and v_tat <> 'Null' and c_tat is not null and c_tat <> 'Null'
and vehicle_type is not null and vehicle_type <> 'Null'
group by vehicle_type
order by driver_arrival_delay desc;

                                          -- REVENUE ANALYTICS --
-- 1. TOTAL REVENEUE BY BOOKING VALUE 
with revenue_segments as(
     select booking_id, booking_value,
     case when booking_value between 0 and 100 then 'Low Fare'
     when booking_value between 101 and 400 then 'Mid fare'
     when booking_value between 401 and 700 then 'High fare'
     else '700+ luxuery ride' end as revenue_bucket from bookings
     where booking_value is not null and booking_value <> 'Null'
)
select revenue_bucket, count(booking_id) as total_bookings, round(sum(booking_value),2) as total_revenue
from revenue_segments group by revenue_bucket order by total_revenue desc;

-- 2. REVENUE BY VEHICLE TYPE 
with vehicle_revenue as(
     select vehicle_type, booking_id, booking_value from bookings where 
     vehicle_type is not null and vehicle_type <> 'Null'
     and booking_value is not null and booking_value <> 'Null'
     and booking_value > 0
)
select vehicle_type, count(booking_id) as total_bookings, 
round(sum(booking_value),2) as revenue_by_vehicle from vehicle_revenue
group by vehicle_type order by revenue_by_vehicle desc;

-- 3. REVENUE BY PAYMENT METHOD 
with method_wise_revenue as (
     select vehicle_type, booking_id,booking_value, payment_method from bookings where payment_method is not null and payment_method <> 'Null' and
     booking_value is not null and booking_value <> 'Null' and booking_value > 0
)
select vehicle_type,payment_method, count(booking_id) as total_bookings, round(sum(booking_value),2) as revenue_by_payment_method
from method_wise_revenue group by vehicle_type, payment_method order by revenue_by_payment_method desc;

-- 4. REVENUE BY PICKUP LOCATION (Ft. Vehicle type)
with revenue_calculation as (
    select vehicle_type, booking_id, pickup_location, booking_value from bookings 
    where vehicle_type is not null and vehicle_type <> 'Null'
    and  pickup_location is not null and pickup_location <> 'Null' 
    and booking_value is not null and booking_value <> 'Null' 
    and booking_value > 0
)
select vehicle_type, count(booking_id) as total_bookings, pickup_location, round(sum(booking_value),2) as total_revenue
from revenue_calculation group by vehicle_type, pickup_location order by total_revenue desc limit 10;
-- 5. REVENUE BY DROP LOCATION
with revenue_drop as (
     select vehicle_type, booking_id, drop_location, booking_value from bookings 
     where vehicle_type is not null and vehicle_type <> 'Null'
     and drop_location is not null and drop_location <> ' Null'
     and booking_value is not null and booking_value <> 'Null'
     and booking_value > 0
)
select vehicle_type, count(booking_id) as total_bookings, drop_location, round(sum(booking_value),2) as total_revenue
from revenue_drop group by vehicle_type, drop_location order by total_revenue desc;
-- 6. REVENUE BY WEEKDAY 
with weekday_revenue as(
     select booking_date, dayname(booking_date) as weekday_name,
     dayofweek(booking_date) as weekday_index, booking_id, booking_value
     from bookings where booking_value is not null and booking_value <> 'Null'
     and booking_value > 0
)
select weekday_name, count(booking_id) as total_bookings, round(sum(booking_value),2) as total_revenue
from weekday_revenue group by weekday_name, weekday_index order by total_revenue desc;
-- 7. REVENUE BY BOOKING HOUR 
with revenue_hour as(
     select hour(time) as booking_hour, booking_id, booking_value from bookings 
     where booking_value is not null and booking_value <> 'Null'
     and booking_value > 0
)
select booking_hour, count(booking_id) as total_bookings, round(sum(booking_value),2) as total_revenue
from revenue_hour group by booking_hour order by total_revenue desc;
-- 8. REVENUE LOST FROM CUSTOMER CANCELLATIONS
with revenue_lost as (
     select  booking_id, canceled_rides_by_customer, booking_value from bookings 
     where canceled_rides_by_customer is not null and canceled_rides_by_customer <> 'Null'
     and booking_value is not null and booking_value <> 'Null' and booking_value > 0
)
select count(booking_id) as total_bookings, count(canceled_rides_by_customer) as customer_cancellations,
round(sum(booking_value),2) as total_revenue_lost from revenue_lost;
-- 9. REVENUE LOST FROM DRIVER CANCELLATIONS
with revenue_lost_from_driver as(
       select canceled_rides_by_driver, booking_value from bookings 
       where canceled_rides_by_driver is not null and canceled_rides_by_driver <> 'Null'
       and booking_value is not null and booking_value <> 'Null'
       and booking_value > 0
)
select count(canceled_rides_by_driver) as driver_cancellations, round(sum(booking_value),2) as total_revenue_lost 
from revenue_lost_from_driver;
-- 10. REVENUE LOST FROM INCOMPLETE RIDES
with revenue_lost_by_incomplete_rides as (
     select incomplete_rides, booking_value from bookings 
     where incomplete_rides !='No' and booking_value is not null and booking_value <> 'Null'
     and booking_value > 0
)
select count(incomplete_rides) as incomplete_rides_count, round(sum(booking_value),2) as total_revenue_lost_by_incomplete_rides
from revenue_lost_by_incomplete_rides;

                                    -- ADVANCED SQL QUESTIONS --
-- 1. RANK TOP 10 PICKUP LOCATIONS BY REVENUE
with top_locations as(
     select pickup_location, booking_id, booking_value from bookings 
     where pickup_location is not null and pickup_location <> 'Null'
     and booking_value is not null and booking_value <> 'Null'
     and booking_value > 0
)
select pickup_location, count(booking_id) as total_bookings, round(sum(booking_value),2) as total_revenue, 
dense_rank() over(order by count(booking_id) desc) as location_rank
from top_locations group by pickup_location order by total_revenue desc limit 10;

-- 2. TOP 3 BUSIEST PICKUP LOCATIONS 
with busy_locations as(
     select booking_id, pickup_location from bookings where pickup_location is not null and pickup_location <> 'Null'
)
select pickup_location, count(booking_id) as total_bookings, dense_rank() over(order by count(booking_id)desc) as location_rank 
from busy_locations group by pickup_location order by total_bookings desc limit 3;

-- 3. TOP 5 CUSTOMERS BY BOOKING VALUE 
with top_customers as (
     select customer_id, booking_id, booking_value from bookings 
     where booking_value is not null and booking_value <> 'Null'
     and booking_value > 0
)
select customer_id, count(booking_id) as total_bookings, round(sum(booking_value),2) as total_revenue,
dense_rank() over(order by round(sum(booking_value),2) desc) as customer_rank from top_customers
group by customer_id order by total_revenue desc limit 5;

-- 4. COMPARE CURRENT DAY BOOKINGS WITH PREVIOUS DAY BOOKINGS 
        -- COMPARISION CURRENT DAY VS PREVIOUS DAY
with bookings_comparision as(
     select date(booking_date) as drive_date,
     count(booking_id) as total_bookings,
     round(sum(booking_value),2) as total_revenue from bookings 
     where booking_date is not null 
     group by date(booking_date)
)
select drive_date, total_bookings as current_day_bookings, 
lag(total_bookings,1) over(order by drive_date) as previous_day_bookings,
(total_bookings-lag(total_bookings,1) over(order by drive_date)) as booking_difference,
total_revenue as current_day_revenue,  lag(total_revenue,1) over(order by drive_date) as previous_day_revenue
from bookings_comparision order by drive_date desc;

-- 5. IDENTIFY VEHICLE TYPES WITH ABOVE AVG COMPLETION RATES
with above_avg_vehicle_types as (
     select vehicle_type, 
     count(case when incomplete_rides = 'No' then 1 end) as completion_ride,
     count(booking_id) as total_bookings,
     count(case when incomplete_rides = 'No' then 1 end)*100.0/count(booking_id) as completion_rate
     from bookings where vehicle_type is not null and vehicle_type <> 'Null'
     group by vehicle_type
)
select vehicle_type, round(completion_rate,2) as vehicle_completion_rate from above_avg_vehicle_types
where completion_rate > (
       select count(case when incomplete_rides = 'No' then 1 end)*100.0/count(booking_id) from bookings
)
order by completion_rate desc;

-- 6. •	customers whose average booking value is above the average of all customers using the same vehicle type. 
with avg_booking_value as (
     select customer_id, vehicle_type, avg(booking_value) as customer_avg_booking
     from bookings  where booking_value is not null and booking_value <> 'Null'
     and booking_value > 0
     group by customer_id, vehicle_type
),
vehicle_benchmark as(
    select customer_id, vehicle_type,customer_avg_booking, avg(customer_avg_booking) over(partition by vehicle_type) as overall_vehicle_avg
    from avg_booking_value 
)
select customer_id, vehicle_type, round(customer_avg_booking,2) as avg_booking_individual from vehicle_benchmark
where customer_avg_booking > overall_vehicle_avg  order by customer_avg_booking desc limit 10;

-- 7. Find pickup locations whose cancellation rate is above the overall cancellation rate. 
with location_based as(
     select pickup_location, count(booking_id) as total_bookings, sum(case when 
	 canceled_rides_by_driver is not null or canceled_rides_by_customer is not null then 1 else 0 end) as cancelled_bookings,
     avg(booking_value) as avg_booking_value from bookings group by pickup_location
)
select pickup_location, round(cancelled_bookings*100.0/total_bookings,2) as cancellation_rate from location_based where
round(cancelled_bookings*100.0/total_bookings,2)> (
      select count(case when canceled_rides_by_driver is not null or canceled_rides_by_customer is not null then 1 end)/count(*) from bookings
);
-- 8. find routes with highest avg booking value 
select 
    pickup_location, 
    drop_location,
    concat(pickup_location, ' -> ', drop_location) as route_path,
    count(booking_id) as total_bookings,
    round(avg(booking_value), 2) as avg_booking_value
from bookings
where pickup_location is not null and pickup_location <> 'Null'
  and drop_location is not null and drop_location <> 'Null'
  and booking_value is not null and booking_value <> 'Null' and booking_value > 0
group by pickup_location, drop_location
order by avg_booking_value desc
limit 10;
-- 9. find routes with highest operational delays
select 
    pickup_location, 
    drop_location,
    concat(pickup_location, ' -> ', drop_location) as route_path,
    count(booking_id) as total_rides,
    round(avg(v_tat), 2) as avg_driver_delay,
    round(avg(c_tat), 2) as avg_customer_delay,
    round(avg(v_tat + c_tat), 2) as avg_total_operational_delay
from bookings
where pickup_location is not null and pickup_location <> 'Null'
  and drop_location is not null and drop_location <> 'Null'
  and (v_tat is not null or c_tat is not null)
group by pickup_location, drop_location
order by avg_total_operational_delay desc
limit 10;
-- 10. Identify peak booking hours for each vehicle type. 
with hourly_booking_metrics as (
    select 
        vehicle_type,
        hour(time) as booking_hour,
        count(booking_id) as total_bookings,
        row_number() over(partition by vehicle_type order by count(booking_id) desc) as rank_order
    from bookings
    where vehicle_type is not null and vehicle_type <> 'Null'
      and time is not null and time <> 'Null'
    group by vehicle_type, hour(time)
)
select 
    vehicle_type,
    booking_hour as peak_hour,
    total_bookings as bookings_at_peak_hour
from hourly_booking_metrics
where rank_order = 1
order by total_bookings desc;
-- 11. Compare weekday vs. weekend performance. 
with day_performance_metrics as (
    select 
        booking_id,
        booking_value,
        booking_status,
        dayofweek(time) as day_num,
        case when dayofweek(time) in (1, 7) then 'Weekend' else 'Weekday' end as day_type
    from bookings
    where time is not null and time <> 'Null'
)
select 
    day_type,
    count(booking_id) as total_bookings,
    round(avg(case when booking_value is not null and booking_value <> 'Null' then booking_value else 0 end), 2) as avg_booking_value,
    round(sum(case when booking_value is not null and booking_value <> 'Null' then booking_value else 0 end), 2) as total_revenue,
    round(
        sum(case when booking_status = 'Success' then 1 else 0 end) * 100.0 
        / count(booking_id), 2
    ) as completion_rate_pct,
    round(
        sum(case when booking_status in( 'canceled by driver', 'canceled by customer','driver not found') then 1 else 0 end) * 100.0 
        / count(booking_id), 2
    ) as cancellation_rate_pct
from day_performance_metrics
group by day_type;
-- 12. Identify locations with consistently high V_TAT and C_TAT. 
with global_tat_benchmark as (
    select 
        avg(v_tat) as global_avg_v_tat,
        avg(c_tat) as global_avg_c_tat
    from bookings
    where v_tat is not null and c_tat is not null
)
select 
    pickup_location,
    count(booking_id) as total_rides_managed,
    round(avg(v_tat), 2) as avg_driver_delay_vtat,
    round(avg(c_tat), 2) as avg_customer_delay_ctat,
    round(avg(v_tat + c_tat), 2) as total_combined_delay
from bookings, global_tat_benchmark
where pickup_location is not null and pickup_location <> 'Null'
group by pickup_location
having count(booking_id) >= 50 
   and avg(v_tat) > max(global_avg_v_tat)
   and avg(c_tat) > max(global_avg_c_tat)
order by total_combined_delay desc;
-- 13. Compare operational efficiency across vehicle categories.
 select 
    vehicle_type,
    count(booking_id) as total_bookings,
    round(
        sum(case when booking_status = 'Success' or (canceled_rides_by_driver is null and canceled_rides_by_customer is null and incomplete_rides = 'No') then 1 else 0 end) * 100.0 
        / count(booking_id), 2
    ) as completion_rate_pct,
    round(
        sum(case when canceled_rides_by_driver is not null or canceled_rides_by_customer is not null or booking_status like '%Cancel%' then 1 else 0 end) * 100.0 
        / count(booking_id), 2
    ) as cancellation_rate_pct,
    round(
        sum(case when (booking_status like '%Incomplete%' or incomplete_rides = 'Yes') and (canceled_rides_by_driver is null and canceled_rides_by_customer is null) then 1 else 0 end) * 100.0 
        / count(booking_id), 2
    ) as incomplete_rate_pct,
    round(avg(case when v_tat > 0 then v_tat else null end), 2) as avg_driver_tat_delay
from bookings
where vehicle_type is not null and vehicle_type <> 'Null'
group by vehicle_type
order by total_bookings desc;

-- CHECK

select sum(booking_value) as total_revenue,
       round(avg(booking_value),2) as avg_revenue,
       count(case when booking_status="Success" then 1 end) as successful_bookings
       from bookings where booking_status="Success";

SELECT 
    COUNT(CASE WHEN Booking_Status IN ('Cancelled by Customer', 'Cancelled by Driver', 'Driver Not Found') THEN 1 END) AS Cancelled_Bookings,
    COUNT(Booking_ID) AS Total_Bookings,
    ROUND(
        (COUNT(CASE WHEN Booking_Status IN ('Cancelled by Customer', 'Cancelled by Driver', 'Driver Not Found') THEN 1 END) * 100.0) 
        / COUNT(Booking_ID), 
        2
    ) AS Cancellation_Rate_Percentage
FROM bookings;

SELECT 
    Vehicle_Type, 
    COUNT(Booking_ID) AS Total_Bookings,
    COUNT(DISTINCT Booking_ID) AS Distinct_Bookings
FROM 
    bookings
GROUP BY 
    Vehicle_Type
ORDER BY 
    Total_Bookings DESC;
    
select avg(customer_rating) as avg_customer_rating from bookings;

SELECT
    HOUR(time) AS booking_hour,
    COUNT(Booking_ID) AS total_bookings
FROM bookings
GROUP BY HOUR(time)
ORDER BY total_bookings DESC
LIMIT 1;

-- revenue lost 
select sum(booking_value) as revenue_lost 
from bookings where booking_status in ('canceled by customer', 'canceled by driver');
-- NET REVENUE 
SELECT
    SUM(CASE
            WHEN booking_status = 'Success'
            THEN booking_value
            ELSE 0
        END) AS total_revenue,

    SUM(CASE
            WHEN booking_status IN ('Canceled by Customer', 'Canceled by Driver')
            THEN booking_value
            ELSE 0
        END) AS revenue_lost,

    SUM(CASE
            WHEN booking_status = 'Success'
            THEN booking_value
            ELSE 0
        END)
    -
    SUM(CASE
            WHEN booking_status IN ('Canceled by Customer', 'Canceled by Driver')
            THEN booking_value
            ELSE 0
        END) AS net_revenue

FROM BOOKINGS;
