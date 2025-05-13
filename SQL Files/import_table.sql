-- 1. Routes
\copy routes FROM 'path.csv' WITH (FORMAT csv, HEADER true);

-- 2. Calendar
\copy calendar FROM 'path.csv' WITH (FORMAT csv, HEADER true);

-- 3. Trips 
\copy trips FROM 'path.csv' WITH (FORMAT csv, HEADER true);

-- 4. Stops 
\copy stops FROM 'path.csv' WITH (FORMAT csv, HEADER true);

-- 5. Calendar Dates 
\copy calendar_dates FROM 'path.csv' WITH (FORMAT csv, HEADER true);

-- 6. Stop Times 
\copy stop_times FROM 'path.csv' WITH (FORMAT csv, HEADER true);