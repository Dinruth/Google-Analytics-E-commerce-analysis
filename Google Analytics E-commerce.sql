
## Project: Google Analytics E-commerce Deep Dive
## Objective: To conduct a comprehensive analysis of the Google Merchandise Store's analytics data. The goal is to identify key drivers of revenue by analyzing traffic sources, user demographics, and on-site behavior, culminating in a set of data-driven recommendations to the marketing and product teams.

# Initial Data exploration

SELECT
  *
FROM
  `bigquery-public-data.google_analytics_sample.ga_sessions_20170801`
LIMIT 10;

## High-Level Business Metrics

#1: What is the total number of sessions, unique visitors, and transactions in this dataset?

# This query scans all the daily tables from August 2016 to August 2017.
# We use COUNT(DISTINCT ...) to get the number of unique visitors.

SELECT
    COUNT(fullVisitorId) AS total_sessions,
    COUNT(DISTINCT fullVisitorId) AS unique_visitors,
    SUM(totals.transactions) AS total_transactions
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`;

## Part 1: Traffic Source Analysis

#2: What are the top 10 traffic sources that bring the most visitors?

# This query counts the total sessions (visits) for each traffic source
# and shows the top 10. We use a WHERE clause to filter out '(direct)' traffic
# which represents users typing the URL directly.

SELECT
    trafficSource.source,
    COUNT(fullVisitorId) AS total_sessions
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE
    trafficSource.source != '(direct)'
GROUP BY
    trafficSource.source
ORDER BY
    total_sessions DESC
LIMIT 10;

#3: What are the top 10 traffic sources that generate the most revenue?

# This query is similar to the last one, but instead of counting sessions,
# we are SUM-ming the total transaction revenue for each source.
# The revenue is divided by 1,000,000 to convert it to a standard currency format (e.g., dollars).

SELECT
    trafficSource.source,
    SUM(totals.totalTransactionRevenue) / 1000000 AS total_revenue
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE
    totals.transactions IS NOT NULL -- We only care about sessions where a purchase was made
GROUP BY
    trafficSource.source
ORDER BY
    total_revenue DESC
LIMIT 10;

#4: What is the average revenue per transaction for the top traffic sources?

# This query calculates the average revenue per transaction.
# We do this by dividing the total revenue by the total number of transactions for each source.

SELECT
    trafficSource.source,
    SUM(totals.totalTransactionRevenue) / 1000000 AS total_revenue,
    SUM(totals.transactions) AS total_transactions,
    (SUM(totals.totalTransactionRevenue) / SUM(totals.transactions)) / 1000000 AS avg_revenue_per_transaction
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE
    totals.transactions IS NOT NULL
GROUP BY
    trafficSource.source
ORDER BY
    total_revenue DESC
LIMIT 10;

#5: Which countries have the most visitors?

# This query counts the total number of sessions from each country
# to identify the top 10 countries by visitor traffic.

SELECT
    geoNetwork.country,
    COUNT(fullVisitorId) AS total_sessions
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
GROUP BY
    geoNetwork.country
ORDER BY
    total_sessions DESC
LIMIT 10;


## Part 2: Audience Analysis

#6: Which countries generate the most revenue?

# This query calculates the total revenue from each country and shows the top 10.
# It filters for only sessions where a transaction occurred.

SELECT
    geoNetwork.country,
    SUM(totals.totalTransactionRevenue) / 1000000 AS total_revenue
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE
    totals.transactions IS NOT NULL
GROUP BY
    geoNetwork.country
ORDER BY
    total_revenue DESC
LIMIT 10;

## Part 3: User Behavior Analysis

#7: Which device categories (Desktop, Mobile, Tablet) generate the most revenue?

# This query introduces the device.deviceCategory field.
# We group by this category to sum the revenue from Desktop, Mobile, and Tablet users.

SELECT
    device.deviceCategory,
    SUM(totals.totalTransactionRevenue) / 1000000 AS total_revenue
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE
    totals.transactions IS NOT NULL
GROUP BY
    device.deviceCategory
ORDER BY
    total_revenue DESC;

#8: What is the conversion rate for each device category?

# This query calculates the conversion rate for each device category.
# The formula is (Total Transactions / Total Sessions) * 100.

SELECT
    device.deviceCategory,
    SUM(totals.transactions) AS total_transactions,
    COUNT(fullVisitorId) AS total_sessions,
    (SUM(totals.transactions) / COUNT(fullVisitorId)) * 100 AS conversion_rate_percentage
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
GROUP BY
    device.deviceCategory
ORDER BY
    conversion_rate_percentage DESC;

## Part 4: Product Analysis

#9: What are the top 10 most viewed products on the website?

# This query uses UNNEST() to open up the nested 'hits' and 'product' data.
# This allows us to access product-level information like the product name.

SELECT
    p.v2ProductName AS product_name,
    COUNT(*) AS page_views
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS p
WHERE
    p.v2ProductName IS NOT NULL
GROUP BY
    product_name
ORDER BY
    page_views DESC
LIMIT 10;

#10: What are the top 10 most purchased products on the website?

# This query is similar to the last one, but we add a crucial WHERE clause
# to filter for sessions where totals.transactions is 1 or more.

SELECT
    p.v2ProductName AS product_name,
    COUNT(p.v2ProductName) AS quantity_sold
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS p
WHERE
    totals.transactions >= 1
    AND p.v2ProductName IS NOT NULL
GROUP BY
    product_name
ORDER BY
    quantity_sold DESC
LIMIT 10;

#11: What are the top 10 products by total revenue?

# This query calculates the total revenue generated by each unique product.
# We UNNEST the product data and filter for sessions with transactions.

SELECT
    p.v2ProductName AS product_name,
    SUM(p.productRevenue) / 1000000 AS total_revenue
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS p
WHERE
    totals.transactions >= 1
GROUP BY
    product_name
ORDER BY
    total_revenue DESC
LIMIT 10;

## Part 5: User Funnel & Behavior Analysis

#12: How many users viewed the homepage vs. how many made a purchase?

# This query uses a CASE statement to count two types of users in one pass:
# 1. Users who viewed the homepage ('is_homepage_visitor').
# 2. Users who completed a transaction ('is_purchaser').

SELECT
    COUNT(DISTINCT CASE WHEN hits.page.pagePath = '/home' THEN fullVisitorId END) AS homepage_visitors,
    COUNT(DISTINCT CASE WHEN totals.transactions >= 1 THEN fullVisitorId END) AS purchasers
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS hits
WHERE
    hits.type = 'PAGE';

#13: Are new or returning visitors more valuable?

# This query uses a CASE statement to segment users and then calculates the average revenue per transaction for each segment.

SELECT
    CASE
        WHEN totals.newVisits = 1 THEN 'New Visitor'
        ELSE 'Returning Visitor'
    END AS visitor_type,
    AVG(totals.totalTransactionRevenue) / 1000000 AS avg_revenue_per_transaction
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE
    totals.transactions IS NOT NULL
GROUP BY
    visitor_type;

#14: What is the average number of pages a user views before making a purchase?

# This query calculates the average number of pageviews for sessions
# that resulted in a transaction.

SELECT
    AVG(totals.pageviews) AS avg_pageviews_for_purchasers
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE
    totals.transactions IS NOT NULL;

## Part 6: Customer Lifetime Value (LTV) Analysis

#15: Who are the top 10 individual customers by total spending?

# This query is similar to our traffic source revenue query, but instead of grouping
# by the source, we group by the unique 'fullVisitorId' to find the total
# spending for each individual customer.

SELECT
    fullVisitorId,
    SUM(totals.totalTransactionRevenue) / 1000000 AS total_revenue
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE
    totals.transactions IS NOT NULL
GROUP BY
    fullVisitorId
ORDER BY
    total_revenue DESC
LIMIT 10;