-- to get familiar with the table - select 100 rows
SELECT * FROM subscriptions LIMIT 100;

-- get number of segments in table
SELECT COUNT(DISTINCT segment) FROM subscriptions;

-- determine range of months, get earliest date, start of any churn, and last churn date
SELECT MIN(subscription_start) AS "start", MIN(subscription_end) AS "churn begin", MAX(subscription_end) AS "end" FROM subscriptions;

-- build month table and check output
WITH months AS (
  SELECT "2017-01-01" AS first_day, 
    "2017-01-31"  AS last_day
  UNION
  SELECT "2017-02-01" AS first_day, 
    "2017-02-28" AS last_day
  UNION 
  SELECT "2017-03-01" AS first_day, 
    "2017-03-31" AS last_day
)
SELECT * FROM months;

-- cross join with subscriptions and check output
WITH months AS (
  SELECT "2017-01-01" AS first_day, 
    "2017-01-31" AS last_day
  UNION
  SELECT "2017-02-01" AS first_day, 
    "2017-02-28" AS last_day
  UNION 
  SELECT "2017-03-01" AS first_day, 
    "2017-03-31" AS last_day
), 

cross_join AS (
  SELECT * FROM subscriptions
  CROSS JOIN
  months
)
SELECT * FROM cross_join LIMIT 20;

-- create status table from prior cross_join table, adding in an active column for each segment, check output
WITH months AS (
  SELECT "2017-01-01" AS first_day, 
    "2017-01-31" AS last_day
  UNION
  SELECT "2017-02-01" AS first_day, 
    "2017-02-28" AS last_day
  UNION 
  SELECT "2017-03-01" AS first_day, 
    "2017-03-31" AS last_day
), 

cross_join AS (
  SELECT * FROM subscriptions
  CROSS JOIN months
), 

status AS (
  SELECT id, first_day AS month, 
  CASE WHEN segment = 87
    AND (subscription_start < first_day
        AND 
         (subscription_end >= first_day
         OR subscription_end IS NULL))
  THEN 1 ELSE 0
  END AS is_active_87, 
  CASE WHEN segment = 30
    AND (subscription_start < first_day
        AND 
         (subscription_end >= first_day
         OR subscription_end IS NULL))
  THEN 1 ELSE 0
  END AS is_active_30
  FROM cross_join
)
SELECT * FROM status LIMIT 20;

-- add canceled columns to status table, check output
WITH months AS (
  SELECT "2017-01-01" AS first_day, 
    "2017-01-31" AS last_day
  UNION
  SELECT "2017-02-01" AS first_day, 
    "2017-02-28" AS last_day
  UNION 
  SELECT "2017-03-01" AS first_day, 
    "2017-03-31" AS last_day
), 

cross_join AS (
  SELECT * FROM subscriptions
  CROSS JOIN months
), 

status AS (
  SELECT id, first_day AS month, 
  CASE WHEN segment = 87
    AND (subscription_start < first_day
        and 
         (subscription_end >= first_day
         OR subscription_end IS NULL))
  THEN 1 ELSE 0
  END AS is_active_87, 
  CASE WHEN segment = 30
    AND (subscription_start < first_day
        and 
         (subscription_end >= first_day
         OR subscription_end IS NULL))
  THEN 1 ELSE 0
  END AS is_active_30, 
    CASE WHEN segment = 87
    AND subscription_end 
     BETWEEN first_day and last_day
  THEN 1 ELSE 0
  END AS is_canceled_87, 
  CASE WHEN segment = 30
    AND subscription_end 
     BETWEEN first_day and last_day
  THEN 1 ELSE 0
  END AS is_canceled_30

  FROM cross_join
)
SELECT * FROM status LIMIT 20;

-- create status_aggregate table from status showing numbers of active and canceled, by month, for each segment. Check output
WITH months AS (
  SELECT "2017-01-01" AS first_day, 
    "2017-01-31" AS last_day
  UNION
  SELECT "2017-02-01" AS first_day, 
    "2017-02-28" AS last_day
  UNION 
  SELECT "2017-03-01" AS first_day, 
    "2017-03-31" AS last_day
), 

cross_join AS (
  SELECT * FROM subscriptions
  CROSS JOIN months
), 

status AS (
  SELECT id, first_day AS month, 
  CASE WHEN segment = 87
    AND (subscription_start < first_day
        AND 
         (subscription_end >= first_day
         OR subscription_end IS NULL))
  THEN 1 ELSE 0
  END AS is_active_87, 
  CASE WHEN segment = 30
    AND (subscription_start < first_day
        AND 
         (subscription_end >= first_day
         OR subscription_end IS NULL))
  THEN 1 ELSE 0
  END AS is_active_30, 
    CASE WHEN segment = 87
    AND subscription_end 
     BETWEEN first_day and last_day
  THEN 1 ELSE 0
  END AS is_canceled_87, 
  CASE WHEN segment = 30
    AND subscription_end 
     BETWEEN first_day and last_day
  THEN 1 ELSE 0
  END AS is_canceled_30

  FROM cross_join
), 

status_aggregate AS (
  SELECT month, 
    sum(is_active_87) AS sum_active_87,
    sum(is_active_30) AS sum_active_30, 
    sum(is_canceled_87) AS sum_canceled_87,
    sum(is_canceled_30) AS sum_canceled_30
  FROM status
  GROUP BY month
)
SELECT * FROM status_aggregate;

-- calculate churn rates for both segments, by month. 
WITH months AS (
  SELECT "2017-01-01" AS first_day, 
    "2017-01-31" AS last_day
  UNION
  SELECT "2017-02-01" AS first_day, 
    "2017-02-28" AS last_day
  UNION 
  SELECT "2017-03-01" AS first_day, 
    "2017-03-31" AS last_day
), 

cross_join AS (
  SELECT * FROM subscriptions
  CROSS JOIN months
), 

status AS (
  SELECT id, first_day AS month, 
  CASE WHEN segment = 87
    AND (subscription_start < first_day
        AND 
         (subscription_end >= first_day
         OR subscription_end IS NULL))
  THEN 1 ELSE 0
  END AS is_active_87, 
  CASE WHEN segment = 30
    AND (subscription_start < first_day
        AND 
         (subscription_end >= first_day
         OR subscription_end IS NULL))
  THEN 1 ELSE 0
  END AS is_active_30, 
    CASE WHEN segment = 87
    AND subscription_end 
     BETWEEN first_day AND last_day
  THEN 1 ELSE 0
  END AS is_canceled_87, 
  CASE WHEN segment = 30
    AND subscription_end 
     BETWEEN first_day AND last_day
  THEN 1 ELSE 0
  END AS is_canceled_30

  FROM cross_join
), 

status_aggregate AS (
  SELECT month, 
    SUM(is_active_87) AS sum_active_87,
    SUM(is_active_30) AS sum_active_30, 
    SUM(is_canceled_87) AS sum_canceled_87,
    SUM(is_canceled_30) AS sum_canceled_30
  FROM status
  GROUP BY 1
)

SELECT month,
  1.0 * sum_canceled_87/sum_active_87 AS churn_87, 
  1.0 * sum_canceled_30/sum_active_30 AS churn_30
FROM status_aggregate;