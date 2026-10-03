# Dashboard guide (Power BI / Tableau)

The file `data/processed/amazon_products_clean.csv` is ready to load into Power BI or Tableau. No extra cleaning is needed. Every row is one product (1,351 rows).

## Useful columns
| Column | Use |
|---|---|
| `main_category`, `sub_category` | filters / slicers, bar charts |
| `brand` | brand comparison |
| `discounted_price`, `actual_price`, `discount_pct` | price and discount analysis |
| `price_band`, `discount_band` | ready-made groups (they are text, so sort them manually in the order given below) |
| `rating`, `rating_count` | quality and popularity |
| `negative_per_review` | complaint signal |

Band order: Under 200, 200-500, 500-1000, 1000-2000, 2000-5000, 5000+ and 0-20%, 21-40%, 41-60%, 61-80%, 81%+.

## Suggested page layout (1 page is enough)
1. **KPI cards:** Total products, Average discount %, Average rating, Total ratings
2. **Bar chart:** average discount % by `sub_category`
3. **Bar chart:** average rating by `sub_category`
4. **Column chart:** average rating by `discount_band`
5. **Scatter plot:** `discount_pct` (x) vs `rating` (y), size = `rating_count`
6. **Table:** top brands (brands with 10+ products) with average rating
7. **Slicers:** `main_category`, `price_band`

## Power BI measures (DAX)
```
Total Products = COUNTROWS(amazon_products_clean)
Avg Discount % = AVERAGE(amazon_products_clean[discount_pct])
Avg Rating = AVERAGE(amazon_products_clean[rating])
Total Ratings = SUM(amazon_products_clean[rating_count])
Heavy Discount Products = CALCULATE(COUNTROWS(amazon_products_clean), amazon_products_clean[discount_pct] >= 60)
```

## Tableau
Connect to the CSV as a text file. Set `rating_count` and `rating` as measures and the band columns as dimensions. Calculated field for heavy discounts:
```
IF [discount_pct] >= 60 THEN "Heavy" ELSE "Normal" END
```

After building the dashboard, save a screenshot in the `images/` folder and add it to the README.
