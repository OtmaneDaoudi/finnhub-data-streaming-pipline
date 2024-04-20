CREATE KEYSPACE IF NOT EXISTS market WITH replication = {'class' : 'SimpleStrategy', 'replication_factor' : 1};

USE market;

CREATE TABLE IF NOT EXISTS trades(
    offset INT,
    symbol VARCHAR,
    volume DOUBLE,
    price DOUBLE,
    event_time TIMESTAMP,

    PRIMARY KEY ((symbol), event_time, offset)
) WITH CLUSTERING ORDER BY (event_time DESC, offset DESC);

CREATE TABLE IF NOT EXISTS minute_trades(
    last_offset INT,
    avg_price DOUBLE,
    total INT,
    event_time TIMESTAMP,

    PRIMARY KEY ((last_offset), event_time)
) WITH CLUSTERING ORDER BY (event_time DESC);