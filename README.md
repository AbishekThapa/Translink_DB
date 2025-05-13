# 🚌 Public Transport Data Analysis (GTFS - Translink Queensland)

This project analyzes **public transport data from Queensland's Translink** using structured SQL queries based on the **GTFS (General Transit Feed Specification)** format. It uses PostgreSQL for querying the datasets and provides deep insights into route efficiency, service frequency, stop utilization, and trip performance.

## 📁 Files

- `create_table.sql` – Defines the database schema and structure
- `import_table.sql` – Scripts for importing GTFS data into the database
- `route_analysis.sql` – Contains all SQL queries used for data analysis across multiple GTFS tables

## 📦 Dataset

The data used in this project comes from the [Translink GTFS Feed](https://translink.com.au/about-translink/open-data), which provides real-time and scheduled transport data for Queensland, Australia. This includes:
- `routes.csv` – Route information and transport types
- `trips.csv` – Trip schedules and service patterns
- `stop_times.csv` – Arrival and departure times
- `stops.csv` – Stop locations and details
- `calendar.csv` – Service availability by day
- `calendar_dates.csv` – Service exceptions and holidays

These were imported into a PostgreSQL database for analysis.

## 📊 Key Analyses Performed

All SQL queries shown below are available in the [`route_analysis.sql`](SQL%20Files/route_analysis.sql) file. Each analysis provides unique insights into different aspects of the transit system:

### 🚍 1. Route Summary
[View Results Screenshot](Screenshots/1.png)

```sql
SELECT 
    r.route_id,
    r.route_short_name,
    r.route_long_name,
    CASE
        WHEN r.route_type = 0 THEN 'Tram'
        WHEN r.route_type = 1 THEN 'Subway'
        WHEN r.route_type = 2 THEN 'Rail'
        WHEN r.route_type = 3 THEN 'Bus'
        WHEN r.route_type = 4 THEN 'Ferry'
        ELSE 'Other'
    END AS transport_type,
    COUNT(DISTINCT t.trip_id) AS total_trip
FROM routes AS r 
LEFT JOIN trips AS t ON t.route_id = r.route_id
GROUP BY 
    r.route_id, 
    r.route_short_name, 
    r.route_long_name,
    r.route_type
ORDER BY total_trip DESC;
```

### 🕐 2. Busiest Hours of the Day
[View Results Screenshot](Screenshots/2.png)

```sql
SELECT 
    EXTRACT(HOUR FROM st.arrival_time) AS hour_of_day,
    COUNT(*) AS number_of_stops
FROM stop_times AS st
GROUP BY hour_of_day
ORDER BY number_of_stops DESC;
```

### 🛑 3. Unique Stops per Route
[View Results Screenshot](Screenshots/3.png)

```sql
SELECT
    r.route_short_name,
    COUNT(DISTINCT st.stop_id) AS unique_stops,
    COUNT(st.stop_id) AS total_stops,
    ROUND(COUNT(st.stop_id)::numeric / COUNT(DISTINCT t.trip_id), 2) AS average_stops_per_trips
FROM routes AS r 
JOIN trips AS t ON t.route_id = r.route_id
JOIN stop_times AS st ON st.trip_id = t.trip_id
GROUP BY r.route_short_name
ORDER BY unique_stops DESC;
```

### 🔁 4. Route Frequency Analysis
[View Results Screenshot](Screenshots/4.png)

```sql
SELECT
    r.route_long_name,
    r.route_short_name,
    COUNT(DISTINCT t.trip_id) AS total_trip,
    COUNT(DISTINCT t.service_id) AS total_service,
    ROUND(COUNT(DISTINCT t.trip_id)::numeric / COUNT(DISTINCT t.service_id), 2) AS average_trips_per_day
FROM routes AS r
JOIN trips AS t ON t.route_id = r.route_id
GROUP BY r.route_long_name, r.route_short_name
ORDER BY average_trips_per_day;
```

### 📍 5. Most Frequently Used Stops
[View Results Screenshot](Screenshots/5.png)

```sql
SELECT
    s.stop_name,
    COUNT(DISTINCT t.route_id) AS routes_serving_stop,
    COUNT(st.stop_id) AS times_stop_served
FROM stops AS s
JOIN stop_times AS st ON st.stop_id = s.stop_id
JOIN trips AS t ON t.trip_id = st.trip_id
GROUP BY s.stop_name
ORDER BY times_stop_served DESC;
```

### ⏱ 6. Average Trip Duration
[View Results Screenshot](Screenshots/6.png)

```sql
WITH trip_durations AS (
    SELECT
        r.route_short_name,
        r.route_long_name,
        t.trip_id,
        EXTRACT(EPOCH FROM(
            MAX(st.arrival_time) - MIN(st.arrival_time)
        )) / 60 AS trip_duration_minutes
    FROM routes AS r
    JOIN trips AS t ON t.route_id = r.route_id
    JOIN stop_times AS st ON st.trip_id = t.trip_id
    GROUP BY 
        r.route_short_name,
        r.route_long_name,
        t.trip_id
)
SELECT
    route_short_name,
    route_long_name,
    ROUND(AVG(trip_duration_minutes), 2) AS average_trips_duration,
    COUNT(DISTINCT trip_id) AS total_trips
FROM trip_durations
GROUP BY route_short_name, route_long_name
ORDER BY average_trips_duration DESC;
```

### 📅 7. Most Active Days of the Week
[View Results Screenshot](Screenshots/7.png)

```sql
SELECT
    c.service_id,
    COUNT(DISTINCT t.trip_id) AS trips_per_day,
    CASE
        WHEN c.monday = 1 THEN 'Monday'
        WHEN c.tuesday = 1 THEN 'Tuesday'
        WHEN c.wednesday = 1 THEN 'Wednesday'
        WHEN c.thursday = 1 THEN 'Thursday'
        WHEN c.friday = 1 THEN 'Friday'
        WHEN c.saturday = 1 THEN 'Saturday'
        WHEN c.sunday = 1 THEN 'Sunday'
    END as service_day
FROM calendar AS c
JOIN trips AS t ON t.service_id = c.service_id
GROUP BY c.service_id
ORDER BY trips_per_day DESC;
```

### 🚈 8. Transport Type Distribution
[View Results Screenshot](Screenshots/8.png)

```sql
SELECT
    CASE
        WHEN r.route_type = 0 THEN 'Tram'
        WHEN r.route_type = 1 THEN 'Subway'
        WHEN r.route_type = 2 THEN 'Rail'
        WHEN r.route_type = 3 THEN 'Bus'
        WHEN r.route_type = 4 THEN 'Ferry'
        ELSE 'Other'
    END as transport_type,  
    COUNT(DISTINCT r.route_id) AS number_of_routes,
    COUNT(DISTINCT t.trip_id) AS total_trips
FROM routes AS r
LEFT JOIN trips AS t ON t.route_id = r.route_id
GROUP BY route_type
ORDER BY total_trips DESC;
```

### 🧭 9. Average Time Between Stops
[View Results Screenshot](Screenshots/9.png)

```sql
WITH stop_times_with_next AS (
    SELECT
        r.route_short_name,
        r.route_long_name,
        st.arrival_time,
        st.stop_id,
        LEAD(st.arrival_time) OVER (
            PARTITION BY t.trip_id 
            ORDER BY st.stop_sequence
        ) AS next_stop_time
    FROM routes AS r
    JOIN trips AS t ON t.route_id = r.route_id
    JOIN stop_times AS st ON st.trip_id = t.trip_id
    GROUP BY 
        r.route_short_name,
        r.route_long_name,
        st.arrival_time,
        st.stop_id,
        st.stop_sequence,
        t.trip_id
)
SELECT
    route_short_name,
    route_long_name,
    COUNT(DISTINCT stop_id) AS total_stops,
    ROUND(AVG(EXTRACT(EPOCH FROM(next_stop_time - arrival_time))/ 60), 2) AS avg_minutes_between_stops
FROM stop_times_with_next
WHERE next_stop_time IS NOT NULL
GROUP BY route_short_name, route_long_name
HAVING COUNT(DISTINCT stop_id) > 1
ORDER BY total_stops DESC;
```

### 📌 10. Routes per Stop
[View Results Screenshot](Screenshots/10.png)

```sql
SELECT 
    s.stop_name,
    COUNT(DISTINCT r.route_id) as number_of_routes,
    STRING_AGG(DISTINCT r.route_short_name, ', ') as routes_serving_stop
FROM stops s
JOIN stop_times st ON s.stop_id = st.stop_id
JOIN trips t ON st.trip_id = t.trip_id
JOIN routes r ON t.route_id = r.route_id
GROUP BY s.stop_name
HAVING COUNT(DISTINCT r.route_id) > 1
ORDER BY number_of_routes DESC
LIMIT 10;
```

## 🛠 Technical Implementation

The analysis uses several SQL techniques:
- Common Table Expressions (CTEs)
- Window Functions (LEAD)
- Time calculations using EPOCH
- Aggregation functions
- Complex JOINs
- CASE statements for categorization

## 💡 Use Cases

This project can be extended to:
- Visualize busiest routes on a map
- Feed into a transport optimization model
- Compare weekday vs weekend service patterns
- Evaluate stop accessibility or redundancy
- Add geographic analysis
- Include passenger load data
- Analyze transfer patterns
- Calculate route efficiency metrics
- Add real-time performance analysis

## 🚀 Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/AbishekThapa/Translink_Data.git
   ```

2. Run the SQL scripts in PostgreSQL:
   - `create_table.sql` to create the database schema
   - `import_table.sql` to load data into the tables
   - `route_analysis.sql` to perform transit system analysis

3. Modify or extend the database as needed for your project

---

> 🚀 *"Turning raw transit data into actionable mobility insights."*



