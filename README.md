# Google-Analytics-E-commerce-analysis

## Objective
To conduct a comprehensive analysis of the Google Merchandise Store's analytics data. The goal is to identify key drivers of revenue by analyzing traffic sources, user demographics, and on-site behavior, culminating in a set of data-driven recommendations to the marketing and product teams.

---

## SQL Analysis Deep Dive
A series of 15 SQL queries were executed in Google BigQuery to extract key business insights. Below are some of the most impactful queries and their results.

### Query #3: Top Revenue-Generating Traffic Sources
This query identifies which marketing channels are the most profitable.
```sql
SELECT
    trafficSource.source,
    SUM(totals.totalTransactionRevenue) / 1000000 AS total_revenue
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE
    totals.transactions IS NOT NULL
GROUP BY
    trafficSource.source
ORDER BY
    total_revenue DESC
LIMIT 10;

<img width="905" height="497" alt="3" src="https://github.com/user-attachments/assets/6ff5b111-c5b7-4b9a-aa5e-f0e948714db5" />


## Query #6: Top Revenue-Generating Countries
This query identifies the most profitable geographic markets.

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

<img width="856" height="466" alt="6" src="https://github.com/user-attachments/assets/17920741-4d04-4c6b-989c-d794fe6cd3e4" />

## Query #8: Conversion Rate by Device
This query identifies which device category is most effective at turning visitors into buyers.

SELECT
    device.deviceCategory,
    (SUM(totals.transactions) / COUNT(fullVisitorId)) * 100 AS conversion_rate_percentage
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*`
GROUP BY
    device.deviceCategory
ORDER BY
    conversion_rate_percentage DESC;

<img width="818" height="339" alt="8" src="https://github.com/user-attachments/assets/a0ccc57d-77e7-437e-a3b7-50426467bff1" />

Key Findings Summary
Revenue vs. Traffic: The highest-traffic sources are not always the most profitable.

Geographic Concentration: The United States is the primary market for both traffic and revenue.

Device Disparity: Desktop users are significantly more valuable, with a much higher conversion rate than mobile users.

Customer Behavior: Returning visitors are more valuable than new visitors, spending more on average.

Actionable Recommendations
Optimize for High-Value Channels: Shift marketing budget towards channels that deliver high-revenue customers, not just high traffic.

Prioritize the Desktop User Experience: Ensure the desktop website is flawlessly optimized for conversions and investigate the mobile checkout funnel to improve its low conversion rate.

Launch Customer Retention Campaigns: Implement marketing campaigns (e.g., email, loyalty discounts) to bring valuable returning customers back to the store.
