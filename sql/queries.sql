-- Amazon India product analysis - SQL queries
-- Table: products (loaded from data/processed/amazon_products_clean.csv)
-- Run with: python src/run_sql.py
-- Each query starts with a "-- name:" line so the script can run them one by one.

-- name: q01_overview
-- Basic numbers for the whole dataset
SELECT COUNT(*)                          AS total_products,
       COUNT(DISTINCT brand)             AS brands,
       ROUND(AVG(discounted_price), 0)   AS avg_selling_price,
       ROUND(AVG(discount_pct), 1)       AS avg_discount_pct,
       ROUND(AVG(rating), 2)             AS avg_rating,
       SUM(rating_count)                 AS total_ratings
FROM products;

-- name: q02_category_summary
-- Products, discount and rating for each main category
SELECT main_category,
       COUNT(*)                        AS products,
       ROUND(AVG(discounted_price), 0) AS avg_price,
       ROUND(AVG(discount_pct), 1)     AS avg_discount,
       ROUND(AVG(rating), 2)           AS avg_rating,
       SUM(rating_count)               AS total_ratings
FROM products
GROUP BY main_category
ORDER BY products DESC;

-- name: q03_subcategory_discount_rating
-- Sub-categories with at least 15 products, most discounted first
SELECT sub_category,
       COUNT(*)                    AS products,
       ROUND(AVG(discount_pct), 1) AS avg_discount,
       ROUND(AVG(rating), 2)       AS avg_rating
FROM products
GROUP BY sub_category
HAVING COUNT(*) >= 15
ORDER BY avg_discount DESC;

-- name: q04_discount_band_vs_rating
-- Does rating drop as discount increases?
SELECT CASE
           WHEN discount_pct <= 20 THEN '1. 0-20%'
           WHEN discount_pct <= 40 THEN '2. 21-40%'
           WHEN discount_pct <= 60 THEN '3. 41-60%'
           WHEN discount_pct <= 80 THEN '4. 61-80%'
           ELSE '5. 81%+'
       END AS discount_band,
       COUNT(*)                AS products,
       ROUND(AVG(rating), 2)   AS avg_rating
FROM products
WHERE rating IS NOT NULL
GROUP BY discount_band
ORDER BY discount_band;

-- name: q05_price_band_summary
-- Same idea for price bands
SELECT CASE
           WHEN discounted_price < 200  THEN '1. Under 200'
           WHEN discounted_price < 500  THEN '2. 200-500'
           WHEN discounted_price < 1000 THEN '3. 500-1000'
           WHEN discounted_price < 2000 THEN '4. 1000-2000'
           WHEN discounted_price < 5000 THEN '5. 2000-5000'
           ELSE '6. 5000+'
       END AS price_band,
       COUNT(*)                    AS products,
       ROUND(AVG(discount_pct), 1) AS avg_discount,
       ROUND(AVG(rating), 2)       AS avg_rating
FROM products
GROUP BY price_band
ORDER BY price_band;

-- name: q06_top_brands
-- Brands with 10 or more products, best rated first
SELECT brand,
       COUNT(*)                    AS products,
       ROUND(AVG(discount_pct), 1) AS avg_discount,
       ROUND(AVG(rating), 2)       AS avg_rating,
       SUM(rating_count)           AS total_ratings
FROM products
GROUP BY brand
HAVING COUNT(*) >= 10
ORDER BY avg_rating DESC
LIMIT 15;

-- name: q07_top3_per_subcategory
-- Window function: 3 most rated products inside each sub-category
WITH ranked AS (
    SELECT sub_category,
           SUBSTR(product_name, 1, 50) AS product,
           rating,
           rating_count,
           ROW_NUMBER() OVER (PARTITION BY sub_category ORDER BY rating_count DESC) AS rn
    FROM products
    WHERE rating_count IS NOT NULL
)
SELECT sub_category, rn AS rank_in_category, product, rating, rating_count
FROM ranked
WHERE rn <= 3
ORDER BY sub_category, rn;

-- name: q08_weighted_rating_top10
-- IMDb style weighted rating: (v/(v+m))*R + (m/(v+m))*C
-- C = mean rating of all products, m = 16,051 (75th percentile of rating_count, from the notebook)
WITH stats AS (
    SELECT AVG(rating) AS c FROM products
)
SELECT SUBSTR(product_name, 1, 50) AS product,
       rating,
       rating_count,
       ROUND((rating_count * 1.0 / (rating_count + 16051)) * rating
             + (16051.0 / (rating_count + 16051)) * stats.c, 3) AS weighted_rating
FROM products, stats
WHERE rating IS NOT NULL AND rating_count IS NOT NULL
ORDER BY weighted_rating DESC
LIMIT 10;

-- name: q09_overpromised_products
-- Big discount, low rating, lots of ratings
SELECT SUBSTR(product_name, 1, 50) AS product,
       brand, sub_category, discount_pct, rating, rating_count
FROM products
WHERE discount_pct >= 70
  AND rating < 3.8
  AND rating_count >= 1000
ORDER BY rating_count DESC;

-- name: q10_discount_vs_subcategory_average
-- Products whose discount is 20+ points above their sub-category average
WITH sub_avg AS (
    SELECT sub_category, AVG(discount_pct) AS avg_disc
    FROM products
    GROUP BY sub_category
)
SELECT SUBSTR(p.product_name, 1, 45) AS product,
       p.sub_category,
       p.discount_pct,
       ROUND(s.avg_disc, 1)                AS sub_category_avg,
       ROUND(p.discount_pct - s.avg_disc, 1) AS above_average_by,
       p.rating
FROM products p
JOIN sub_avg s ON p.sub_category = s.sub_category
WHERE p.discount_pct - s.avg_disc >= 20
  AND p.rating_count >= 5000
ORDER BY above_average_by DESC
LIMIT 10;

-- name: q11_complaints_by_subcategory
-- Negative keywords per review (from the cleaning notebook), 15+ products only
SELECT sub_category,
       COUNT(*)                          AS products,
       ROUND(AVG(negative_per_review), 3) AS avg_negative_per_review,
       ROUND(AVG(rating), 2)              AS avg_rating
FROM products
GROUP BY sub_category
HAVING COUNT(*) >= 15
ORDER BY avg_negative_per_review DESC;
