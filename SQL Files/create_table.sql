-- Drop tables if they exist 
DROP TABLE IF EXISTS stop_times;
DROP TABLE IF EXISTS calendar_dates;
DROP TABLE IF EXISTS stops;
DROP TABLE IF EXISTS trips;
DROP TABLE IF EXISTS shapes;
DROP TABLE IF EXISTS calendar;
DROP TABLE IF EXISTS routes;

CREATE TABLE routes (
  route_id VARCHAR(15) PRIMARY KEY,
  route_short_name VARCHAR(20),
  route_long_name VARCHAR(100),
  route_desc VARCHAR(255),
  route_type INT,
  route_url VARCHAR(150),
  route_color VARCHAR(20),
  route_text_color VARCHAR(20)
);

CREATE TABLE calendar (
  service_id VARCHAR(40) PRIMARY KEY,
  monday SMALLINT,
  tuesday SMALLINT,
  wednesday SMALLINT,
  thursday SMALLINT,
  friday SMALLINT,
  saturday SMALLINT,
  sunday SMALLINT,
  start_date DATE,
  end_date DATE
);

CREATE TABLE trips (
  trip_id VARCHAR(50) PRIMARY KEY,
  service_id VARCHAR(40) NOT NULL,
  route_id VARCHAR(50) NOT NULL,
  trip_headsign VARCHAR(100),
  direction_id SMALLINT,
  block_id VARCHAR(50),
  shape_id VARCHAR(50),
  FOREIGN KEY (route_id) REFERENCES routes(route_id),
  FOREIGN KEY (service_id) REFERENCES calendar(service_id)
);

CREATE TABLE stops (
  stop_id VARCHAR(20) PRIMARY KEY,
  stop_code VARCHAR(20),
  stop_name VARCHAR(80),
  stop_desc VARCHAR(255),
  stop_lat DECIMAL(10,6),
  stop_lon DECIMAL(10,6),
  zone_id INT,
  stop_url VARCHAR(200),
  location_type SMALLINT,
  parent_station VARCHAR(50),
  platform_code VARCHAR(20),
  FOREIGN KEY (parent_station) REFERENCES stops(stop_id)
);

CREATE TABLE calendar_dates (
  service_id VARCHAR(40) NOT NULL,
  date DATE NOT NULL,
  exception_type SMALLINT,
  PRIMARY KEY (service_id, date),
  FOREIGN KEY (service_id) REFERENCES calendar(service_id)
);

CREATE TABLE stop_times (
  trip_id VARCHAR(50) NOT NULL,
  stop_id VARCHAR(50) NOT NULL,
  arrival_time TIME,
  departure_time TIME,
  stop_sequence INT NOT NULL,
  pickup_type SMALLINT,
  drop_off_type SMALLINT,
  PRIMARY KEY (trip_id, stop_sequence),
  FOREIGN KEY (trip_id) REFERENCES trips(trip_id),
  FOREIGN KEY (stop_id) REFERENCES stops(stop_id)
);  



