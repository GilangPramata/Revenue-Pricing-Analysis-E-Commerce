# Revenue & Pricing Analysis

An end-to-end analysis of what drives revenue for a UK online gift retailer, and how
**pricing and promotions** affect volume and margin. Built on the **UCI Online Retail**
dataset (Dec 2010 – Dec 2011, ~542k transactions).

## Key Results
| Metric | Value |
|---|---|
| Total Revenue | **£10.25M** |
| Estimated Profit | **£5.06M** |
| Estimated Margin | **49.4%** |
| Invoices | **19,773** |
| Avg Order Value | **£518** |
| Avg Selling Price | **£3.28** |
| Promo Line Share | **7.8%** |

**Core insight:** revenue is **volume-driven** (Revenue–Units correlation 0.89; Revenue–Price 0.08).
Promotions reliably lift volume but **compress margin** — demonstrated on a real SKU,
*RABBIT NIGHT LIGHT (23084)*, whose estimated margin falls ~15 points in heavily promoted months.

## Methodology Note
The raw dataset has **no cost, discount, or profit columns**. These are derived transparently:
- **Discount / Promotion** — each SKU's reference (list) price is its modal unit price; sales
  ≥5% below list are flagged as *promoted*, with an implied discount %.
- **Estimated margin** — assumes cost = **50% of list price** (clearly labelled estimate, not source data).

All other metrics (revenue, AOV, ASP, top SKUs, trends) are computed directly from the data.

## Contents
| File | Description |
|---|---|
| `data/online_retail_raw.csv` | Raw dataset (541,909 rows) |
| `data/online_retail_clean.csv` | Cleaned, feature-engineered dataset (522,568 rows) |
| `Revenue_Pricing_Analysis.ipynb` | Notebook: cleaning + EDA + correlation + promotion case study (pre-executed) |
| `queries.sql` | PostgreSQL queries: revenue, profit, discount, ASP, top SKU, promo impact |
| `Revenue_Pricing_Dashboard.html` | Interactive dashboard (open in a browser) |
| `Revenue_Pricing_Summary.xlsx` | Multi-sheet Excel summary |
| `Executive_Summary.pdf` | Project narrative + insights + recommendations |
| `requirements.txt` | Python dependencies |

## Data Cleaning Process
`541,909` raw → remove **5,268 duplicates** → **10,587 returns/cancellations** →
**1,176 invalid prices** → **2,310 non-product service codes** → **522,568 clean line items**.

## Tools
Python (pandas, numpy, matplotlib, seaborn) · SQL (PostgreSQL) · Excel · HTML / Chart.js

## How to Use
```bash
pip install -r requirements.txt
jupyter notebook Revenue_Pricing_Analysis.ipynb     # run the analysis
# Open Revenue_Pricing_Dashboard.html directly in a browser
```

> Note: the dashboard is delivered as interactive HTML (a substitute for the proprietary
> Power BI .pbix format). To reproduce in Power BI, run `queries.sql` against PostgreSQL or
> import `online_retail_clean.csv` into Power BI Desktop and rebuild the visuals using this
> dashboard as the reference.
