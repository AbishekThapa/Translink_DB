-- Shows information about each route including type and frequency
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

-- Identifies the busiest hours of service

SELECT 
    EXTRACT(HOUR FROM st.arrival_time) AS hour_of_day,
    COUNT(*) AS number_of_stops
FROM stop_times AS st
GROUP BY
    hour_of_day
order BY number_of_stops DESC;

-- Showing how many unique stops each route serves
SELECT
    r.route_short_name,
    COUNT(DISTINCT st.stop_id) AS unique_stops,
    COUNT(st.stop_id) AS total_stops,
    ROUND(COUNT(st.stop_id)::numeric / COUNT(DISTINCT t.trip_id), 2) AS average_stops_per_trips
FROM routes AS r 
JOIN trips AS t ON t.route_id = r.route_id
JOIN stop_times AS st ON st.trip_id = t.trip_id
GROUP BY
    r.route_short_name
ORDER BY unique_stops DESC;

-- Analyzing how often each route runs
SELECT
    r.route_long_name,
    r.route_short_name,
    COUNT(DISTINCT t.trip_id) AS total_trip,
    COUNT(DISTINCT t.service_id) AS total_service,
    ROUND(COUNT(DISTINCT t.trip_id)::numeric / COUNT(DISTINCT t.service_id), 2) AS average_trips_per_day
FROM routes AS r
JOIN trips AS t ON t.route_id = r.route_id
GROUP BY
        r.route_long_name,
    r.route_short_name
ORDER BY average_trips_per_day

-- Identifies the most frequently used stops
SELECT
    s.stop_name,
    COUNT(DISTINCT t.route_id) AS routes_serving_stop,
    COUNT(st.stop_id) AS times_stop_served
FROM stops AS s
JOIN stop_times AS st ON st.stop_id = s.stop_id
JOIN trips AS t ON t.trip_id = st.trip_id
GROUP BY s.stop_name
ORDER BY times_stop_served DESC;

-- Calculating average trip duration for each route
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
GROUP BY
    route_short_name,
    route_long_name
ORDER BY average_trips_duration DESC;

-- Showing which days have the most service
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

-- Showing the distribution of different transport types
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

-- Analyzing the average distance between stops for each route
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
GROUP BY
    route_short_name,
    route_long_name
HAVING COUNT(DISTINCT stop_id) > 1
ORDER BY total_stops DESC;

-- Showing how many routes serve each stop
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