
# Global Electricity Demand vs. Green Adoption
<img width="auto" height="auto" alt="A horizontal banner with a warm mustard-yellow background. On the left side, the text reads Global Electricity in a large, white serif font, with a smaller subtitle below it that says Demand vs. Green Adoption in a clean sans-serif font. The right side features a decorative pattern of several realistic incandescent light bulbs floating at various angles, creating a theme of energy and illumination." src="https://github.com/user-attachments/assets/399d74e7-f3f6-41f6-8917-fa94c4cd396c" />

## 📌 Research Question

**Should the world’s biggest electricity users be required to adopt renewable energy?**

Rather than treating climate responsibility as evenly distributed across all countries, this project evaluates whether **the world’s largest electricity consumers should bear greater accountability** for accelerating the renewable energy transition.

---

## 📊 Data Sources

* **Our World in Data – Energy Dataset**

  * GitHub Repository: [https://github.com/owid/energy-data](https://github.com/owid/energy-data)
  * Website: [https://ourworldindata.org/energy](https://ourworldindata.org/energy)

**Data Year Selection**

* **2023** was used intentionally, as **2024 data may be partial or incomplete**.
* This ensures consistency and comparability across all countries.

---

## 🗂️ Datasets Used

From the OWID Energy dataset:

* `electricity_demand` (Total electricity consumption in TWh)
* `renewables_share_elec` (% of electricity generated from renewables)
* `iso_code`, `country`, `year`

**Filtering Rules Applied**

* Excluded country groups and aggregates
* Included only valid ISO country codes
* Removed null or incomplete records

---

## 🔎 Analysis Overview

### **Step 1: Filter Valid Individual Countries (2023)**

```sql
SELECT * 
FROM energy_data
WHERE iso_code IS NOT NULL
  AND TRIM(iso_code) <> ''
  AND iso_code <> 'null'
  AND year = 2023;
```

Purpose:

* Ensure analysis includes **only individual countries**, not regions or income groups.


---

### **Step 2: Identify High Electricity Demand & Renewable Share**

```sql
SELECT country,
       electricity_demand AS total_twh,
       renewables_share_elec AS current_renewable_pct
FROM energy_data
WHERE iso_code IS NOT NULL
  AND TRIM(iso_code) <> ''
  AND iso_code <> 'null'
  AND year = 2023
  AND electricity_demand IS NOT NULL
  AND renewables_share_elec IS NOT NULL
ORDER BY total_twh DESC;
```

Purpose:

* Rank countries by electricity demand
* Observe renewable adoption among the largest consumers

|country      |total_twh|current_renewable_pct|
|-------------|---------|---------------------|
|China        |9,443.07 |30.61                |
|United States|4,272.81 |22.68                |
|India        |1,917.28 |19.32                |
|Russia       |1,162.44 |17.75                |
|Japan        |1,006.73 |22.14                |
|Brazil       |723.23   |88.99                |
|South Korea  |617.49   |9.57                 |
|Canada       |613.72   |65.4                 |
|Germany      |512.91   |54.41                |
|France       |466.39   |26.62                |


---

### **Step 3: Global Context Using Window Functions**

Key questions answered:

* Where does each country rank globally?
* What percentage of global electricity does it consume?
* Is its renewable share above or below the global average?

```sql
SELECT country,
       electricity_demand AS total_twh,
       renewables_share_elec AS current_renewable_pct,
       RANK() OVER(ORDER BY electricity_demand DESC) AS total_consumption_rank,
       ROUND((electricity_demand * 100.0) / SUM(electricity_demand) OVER (), 2) AS pct_global_share,
       ROUND(AVG(renewables_share_elec) OVER (), 2) AS global_avg_renewable_pct,
       ROUND(renewables_share_elec - AVG(renewables_share_elec) OVER (), 2) AS diff_from_avg
FROM energy_data
WHERE iso_code IS NOT NULL
  AND TRIM(iso_code) <> ''
  AND iso_code <> 'null'
  AND year = 2023
  AND electricity_demand IS NOT NULL
  AND renewables_share_elec IS NOT NULL
ORDER BY total_twh DESC;
```
### Top Electricity Consumers vs Renewable Share (2023)

| Rank | Country | Electricity Demand (TWh) | % Global Share | Renewable % | Gap vs Global Avg |
|-----:|---------|--------------------------|---------------|-------------|-------------------|
| 1 | China | 9,443 | 32.0% | 30.6% | -7.1 pp |
| 2 | United States | 4,273 | 14.5% | 22.7% | -15.0 pp |
| 3 | India | 1,917 | 6.5% | 19.3% | -18.4 pp |
| 4 | Russia | 1,162 | 3.9% | 17.8% | -20.0 pp |
| 5 | Japan | 1,007 | 3.4% | 22.1% | -15.6 pp |
| 6 | Brazil | 723 | 2.5% | 89.0% | +51.3 pp |
| 7 | Canada | 614 | 2.1% | 65.4% | +27.7 pp |
| 8 | Germany | 513 | 1.7% | 54.4% | +16.7 pp |
| 9 | South Korea | 617 | 2.1% | 9.6% | -28.1 pp |
|10 | France | 466 | 1.6% | 26.6% | -11.1 pp |

### 📂 Full country-level results are available in:
- `data/result_cleaned_energy_data.xlsx`
- SQL queries in `sql/energy_demand.sql`
- Interactive exploration via [Tableau Dashboard](https://public.tableau.com/views/GlobalElectricityDemandvs_GreenAdoption/Dashboard)


---

## 🧠 Key Insights

### **1️⃣ Who Has the Most Power?**

* **China (32%)** and the **United States (14.5%)** together consume **~46.5% of global electricity**
* Electricity demand is **highly concentrated**, not evenly distributed

📌 *Insight:* Targeting a small group of “energy giants” could drive outsized global impact.

---

### **2️⃣ Who Is Falling Behind?**

* Global average renewable share: **37.7%**
* Several top consumers operate **far below average**:

  * South Korea: **9.6%**
  * Russia: **17.8%**
  * India: **19.3%**
  * United States: **22.7%**

📌 *Insight:* High demand + low renewable adoption identifies **priority mandate candidates**.

---

### **3️⃣ Is Transition Realistic?**

* Some high-demand countries already perform well:

  * **Brazil:** 89%
  * **Canada:** 65%
  * **Germany:** 54%

📌 *Insight:* Large-scale renewable adoption is **technically and economically achievable**, even for major consumers.

---

## 🛠️ Tools Used

* **SQL (PostgreSQL-style syntax)**

  * Filtering & data validation
  * Window functions (`RANK()`, `AVG() OVER()`, `SUM() OVER()`)
  * Global share and performance gap calculations

* **Tableau**

  * Scatter plot: Demand vs. Renewable %
  * Mandate Priority Matrix
  * Country-level choropleth map
  * KPI cards for global totals

📊 **Interactive Dashboard**
👉 [https://public.tableau.com/views/GlobalElectricityDemandvs_GreenAdoption/Dashboard](https://public.tableau.com/views/GlobalElectricityDemandvs_GreenAdoption/Dashboard)

<a href="https://public.tableau.com/views/GlobalElectricityDemandvs_GreenAdoption/Dashboard"><img width="auto" height="auto" alt="Data dashboard showing total global demand at 29,512 TWh. A priority matrix identifies China and the U.S. as high-demand outliers with below-average renewable shares, while Brazil and Canada lead in green adoption performance." src="https://github.com/user-attachments/assets/d7df3d9e-2952-4214-adcf-45443908f863" /></a>

---

## Conclusion

This analysis shows that **global electricity demand (and therefore climate impact) is not evenly distributed**. A small group of countries consumes a disproportionate share of global electricity while lagging behind in renewable adoption.

### 🔴 **High-Priority Mandate Candidates (High Demand, Low Renewable Share)**

These countries combine **massive electricity consumption** with **below-average renewable adoption**, making them the strongest candidates for binding renewable mandates:

* **China**: 32% of global demand, renewable share **below global average**
* **United States**: 14.5% of global demand, renewable share **−15 pp below average**
* **India**: Rapidly growing demand, renewable share **−18 pp below average**
* **Russia**: High consumption, fossil-fuel dominant mix
* **South Korea**: Top 10 consumer with **one of the lowest renewable shares**


---

### 🟡 **Conditional Mandate / Accelerated Transition Group**

Countries with moderate demand and near-average renewable performance:

* **Japan**
* **France**
* **Mexico**
* **Indonesia**
* **Australia**


---

### 🟢 **Proof-of-Feasibility Leaders (High Demand, High Renewable Share)**

These countries demonstrate that **high electricity demand and high renewable adoption can coexist**:

* **Brazil**:~89% renewable
* **Canada**:~65% renewable
* **Germany**:~54% renewable

---

A **one-size-fits-all climate mandate is inefficient**.

Instead, this data supports a **tiered, responsibility-based policy framework**:

| Country Category             | Recommended Decision                |
| ---------------------------- | ----------------------------------- |
| High Demand + Low Renewables | **Mandatory renewable targets**     |
| Medium Demand / Near Avg     | **Accelerated transition policies** |
| High Renewables Leaders      | **Benchmark & support roles**       |

---


## 👤 Contact
- Eliza C. Huang | Data Analyst with a background in UX and data-driven analysis. Interested in roles within public policy, NGOs, human rights, and social impact organizations.
- Portfolio / Data Visualizations: Instagram – DataDrawers [https://www.instagram.com/datadrawers/]
- LinkedIn: [https://www.linkedin.com/in/chuyunh/]



