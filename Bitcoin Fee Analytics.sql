SELECT * FROM bitcoin_data LIMIT 20;

-- Executive KPI Cards
-- 1. Total Transactions
SELECT COUNT(*) AS total_transaction, ROUND(SUM(output_btc::NUMERIC),4) AS total_volume_btc,
ROUND(SUM(fee_btc::NUMERIC), 4) AS total_fee_paid_btc, ROUND(AVG(fee_rate::NUMERIC), 6) AS avg_fee_rate
FROM bitcoin_data
WHERE is_coinbase = FALSE;

-- 2. Total Network Fees (BTC)
SELECT ROUND(SUM(fee_btc::NUMERIC), 6) AS total_fees_btc
FROM bitcoin_data;

-- 3. Average Fee Rate
SELECT ROUND(AVG(fee_rate::NUMERIC),4) AS avg_fee_rate
FROM bitcoin_data;
-- q2
SELECT DATE(block_timestamp) AS tx_date, ROUND(AVG(fee_rate::NUMERIC),4) AS avg_fee_rate
FROM bitcoin_data
GROUP BY tx_date
ORDER BY tx_date;

-- 4. High Fee Transaction %
SELECT ROUND(SUM(high_fee_flag::NUMERIC) / COUNT(*) * 100 ,2) AS "High Fee Transaction %"
FROM bitcoin_data
WHERE is_coinbase = FALSE;

-- 5. Large Transaction %
SELECT ROUND(SUM(large_tx_flag) / COUNT(*) * 100, 2) AS "Large Transaction %"
FROM bitcoin_data
WHERE is_coinbase = FALSE;

-- Time-Based Visuals
-- 6. Transactions by Hour
SELECT hour, COUNT(*) AS total_transactions, ROUND(AVG(size), 2) AS avg_tx_size, 
ROUND(AVG(fee_rate::NUMERIC),2) AS avg_fee_rate,
SUM(high_fee_flag) AS high_fee_count
FROM bitcoin_data
WHERE is_coinbase = FALSE
GROUP BY hour; 

-- 7. Daily Transaction Trend
SELECT DATE_TRUNC('day', block_timestamp) AS daily_trend, COUNT(*) AS total_transactions
FROM bitcoin_data
WHERE is_coinbase = FALSE
GROUP BY daily_trend
ORDER BY daily_trend;

-- Fee Analysis
-- 8. Fee Distribution Buckets
SELECT CASE WHEN fee_btc IS NULL THEN 'Unknown'
WHEN fee_btc < 0.0001 THEN 'Very Low' WHEN fee_btc < 0.001 THEN 'Low' WHEN fee_btc < 0.01 THEN 'Medium'
ELSE 'High' END AS fee_category, COUNT(*) AS transaction_count
FROM bitcoin_data
GROUP BY fee_category
ORDER BY transaction_count DESC;

-- 9. Top 10 Highest Fee Transactions
SELECT transaction_id, block_timestamp, fee_btc, fee_rate, size
FROM bitcoin_data
ORDER BY fee_btc DESC
LIMIT 10;

-- Network Efficiency Metrics
-- 10. Avg Fee Rate by Size Category
SELECT CASE WHEN size < 250 THEN 'Small (<250 bytes)' 
WHEN size BETWEEN 250 AND 500 THEN 'Medium (250-500 bytes)'
WHEN size BETWEEN 501 AND 1000 THEN 'Large (501-1000 bytes)'
ELSE 'Very Large (>1000)' END AS size_category,
ROUND(AVG(fee_rate::NUMERIC),4) AS avg_fee_rate,
ROUND(AVG(fee_btc::NUMERIC),6) AS avg_fee_btc,
ROUND(SUM(fee_btc::NUMERIC),4) AS total_fee_btc
FROM bitcoin_data
WHERE is_coinbase = FALSE
GROUP BY size_category
ORDER BY avg_fee_rate DESC;

-- 11. Coinbase vs Normal Transactions
SELECT CASE 
WHEN is_coinbase = TRUE THEN 'Coinbase (Mining Reward)'
ELSE 'Regular Transaction' END AS transaction_type, 
is_coinbase, COUNT(*) AS total_transactions, ROUND(AVG(fee_btc::NUMERIC),6) AS avg_fee_btc,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(),2) transaction_percentage
FROM bitcoin_data
GROUP BY is_coinbase
ORDER BY total_transactions DESC;

-- Risk Monitoring Section
-- 12. High Fee Transactions by Hour
SELECT DATE_TRUNC('hour', block_timestamp) AS txn_hour, COUNT(*) AS total_transactions,
SUM(high_fee_flag::NUMERIC) AS high_fee_transactions,
ROUND(SUM(high_fee_flag) / NULLIF(COUNT(*),0) * 100, 2) AS high_fee_percentage,
ROUND(AVG(fee_rate::NUMERIC),4) AS avg_fee_rate,
ROUND(SUM(fee_btc::NUMERIC),6) AS total_fee_btc
FROM bitcoin_data
WHERE is_coinbase = FALSE AND block_timestamp IS NOT NULL
GROUP BY txn_hour
ORDER BY high_fee_percentage DESC
LIMIT 10;

-- 13. Large Transactions Over Time
SELECT DATE(block_timestamp) AS tx_date, COUNT(*) AS total_transactions,
SUM(large_tx_flag) AS total_large_transactions,
ROUND(SUM(large_tx_flag) / NULLIF(COUNT(*), 0) * 100.0, 2) AS large_transaction_percent,
ROUND(SUM(fee_btc::NUMERIC),6) AS total_fee_btc,
ROUND(AVG(fee_rate::NUMERIC),4) AS avg_fee_rate
FROM bitcoin_data
WHERE is_coinbase = FALSE AND block_timestamp IS NOT NULL
GROUP BY DATE(block_timestamp)
ORDER BY large_transaction_percent DESC
LIMIT 10;
