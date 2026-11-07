
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
* `low_carbon_share_elec` (% of electricity from renewables + nuclear)
* `population` (used for electricity demand per person)
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
* Is its renewable share above or below the **world average**?

> **Why a weighted average?** A simple `AVG(renewables_share_elec)` counts every country equally, so Norway (136 TWh) counts as much as China (9,443 TWh). Many small, hydro-rich countries (Paraguay, Iceland, Bhutan, all ~100% renewable) pull that number up to **37.71%**.
> The **demand-weighted average**, `SUM(demand × renewable %) / SUM(demand)`, is the real renewable share of world electricity: **30.09%**. All gaps below use this number.

```sql
SELECT country,
       electricity_demand AS total_twh,
       renewables_share_elec AS current_renewable_pct,
       low_carbon_share_elec AS low_carbon_pct,
       RANK() OVER (ORDER BY electricity_demand DESC) AS total_consumption_rank,
       ROUND(electricity_demand * 100.0 / SUM(electricity_demand) OVER (), 2) AS pct_global_share,
       ROUND(SUM(electricity_demand * renewables_share_elec) OVER ()
             / SUM(electricity_demand) OVER (), 2) AS weighted_avg_renewable_pct,
       ROUND(renewables_share_elec
             - SUM(electricity_demand * renewables_share_elec) OVER ()
               / SUM(electricity_demand) OVER (), 2) AS diff_from_weighted_avg,
       ROUND(electricity_demand * (1 - renewables_share_elec / 100.0), 1) AS non_renewable_twh,
       ROUND(electricity_demand * 1000000.0 / population, 1) AS mwh_per_person
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

World average renewable share (demand-weighted): **30.1%**

| Rank | Country | Demand (TWh) | % Global Share | Renewable % | Gap vs World Avg | Low-carbon % | MWh per person |
|-----:|---------|-------------:|---------------:|------------:|-----------------:|-------------:|---------------:|
| 1 | China | 9,443 | 32.0% | 30.6% | +0.5 pp | 35.2% | 6.6 |
| 2 | United States | 4,273 | 14.5% | 22.7% | −7.4 pp | 40.9% | 12.4 |
| 3 | India | 1,917 | 6.5% | 19.3% | −10.8 pp | 21.8% | 1.3 |
| 4 | Russia | 1,162 | 3.9% | 17.8% | −12.3 pp | 36.2% | 8.0 |
| 5 | Japan | 1,007 | 3.4% | 22.1% | −8.0 pp | 29.8% | 8.1 |
| 6 | Brazil | 723 | 2.5% | 89.0% | +58.9 pp | 91.0% | 3.4 |
| 7 | South Korea | 617 | 2.1% | 9.6% | −20.5 pp | 38.8% | 11.9 |
| 8 | Canada | 614 | 2.1% | 65.4% | +35.3 pp | 79.2% | 15.6 |
| 9 | Germany | 513 | 1.7% | 54.4% | +24.3 pp | 55.8% | 6.1 |
| 10 | France | 466 | 1.6% | 26.6% | −3.5 pp | 92.1% | 7.0 |

*Low-carbon % = renewables + nuclear.*

---

### **Step 4: Assign a Mandate Tier**

Each of the **top 20 consumers** (≥ 270 TWh, together **81% of world demand**) gets a tier using a `CASE` statement. See [Tier Rules](#-tier-rules) below for the logic.

```sql
WITH base AS (
    SELECT country,
           electricity_demand,
           renewables_share_elec,
           low_carbon_share_elec,
           electricity_demand * (1 - renewables_share_elec / 100.0) AS non_renewable_twh,
           SUM(electricity_demand * renewables_share_elec) OVER ()
             / SUM(electricity_demand) OVER () AS weighted_avg
    FROM energy_data
    WHERE iso_code IS NOT NULL
      AND TRIM(iso_code) <> ''
      AND iso_code <> 'null'
      AND year = 2023
      AND electricity_demand IS NOT NULL
      AND renewables_share_elec IS NOT NULL
)
SELECT country,
       electricity_demand AS total_twh,
       renewables_share_elec AS current_renewable_pct,
       ROUND(non_renewable_twh, 1) AS non_renewable_twh,
       CASE
         WHEN electricity_demand < 270 THEN 'Other'
         WHEN low_carbon_share_elec >= 50 AND renewables_share_elec < 50 THEN 'Accelerate (nuclear-heavy)'
         WHEN renewables_share_elec < weighted_avg OR non_renewable_twh >= 1000 THEN 'Mandate'
         WHEN renewables_share_elec >= 50 THEN 'Benchmark'
         ELSE 'Accelerate'
       END AS mandate_tier
FROM base
ORDER BY total_twh DESC;
```

### 📂 Full country-level results are available in:
- `data/result_cleaned_energy_data.xlsx`
- SQL queries in `sql/energy_demand.sql`
- Interactive exploration via [Tableau Dashboard](https://public.tableau.com/views/GlobalElectricityDemandvs_GreenAdoption/Dashboard)


---

## 🧠 Key Insights

### **1️⃣ Who Has the Most Power?**

* **China (32%)** and the **United States (14.5%)** together consume **~46.5% of global electricity**
* The **top 20** countries consume **81%**
* Electricity demand is **highly concentrated**, not evenly distributed

📌 *Insight:* Targeting a small group of “energy giants” could drive outsized global impact.

---

### **2️⃣ Who Is Falling Behind?**

* World average renewable share (weighted by demand): **30.1%**
  * The simple average across countries is 37.7%, but it is inflated by small hydro-rich countries, so it is not used here.
* Top-20 consumers furthest below the world average:

  * Saudi Arabia: **1.1%** (−29.0 pp)
  * Iran: **6.5%** (−23.6 pp)
  * Taiwan: **8.9%** (−21.2 pp)
  * South Korea: **9.6%** (−20.5 pp)
  * Russia: **17.8%** (−12.3 pp)
  * India: **19.3%** (−10.8 pp)
  * United States: **22.7%** (−7.4 pp)

* **China** is at the world average in percentage terms (30.6%), but it generates **6,553 TWh from non-renewable sources**, about **32% of the world total** and twice the United States.

📌 *Insight:* Two things matter: **how far below average** a country is (%), and **how much non-renewable electricity** it produces (TWh). China leads on the second.

---

### **3️⃣ Is Transition Realistic?**

* Some high-demand countries already perform well:

  * **Brazil:** 89%
  * **Canada:** 65%
  * **Germany:** 54%

📌 *Insight:* Large-scale renewable adoption is **technically achievable**, even for major consumers. Note that Brazil and Canada rely heavily on hydropower, which depends on geography that not every country has.

---

## 🛠️ Tools Used

* **SQL (PostgreSQL-style syntax)**

  * Filtering & data validation
  * Window functions (`RANK()`, `SUM() OVER()`)
  * Demand-weighted average, global share and performance gap calculations
  * `CASE` logic for mandate tiers

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

This analysis shows that **global electricity demand (and therefore climate impact) is not evenly distributed**. A small group of countries consumes a disproportionate share of global electricity, and most of them run below the world average on renewables.

### 📏 Tier Rules

Applied to the **top 20 consumers** (≥ 270 TWh), checked in this order:

1. **Accelerate (nuclear-heavy):** low-carbon share ≥ 50% but renewable share < 50%. These countries already have clean electricity through nuclear, so calling them laggards would be unfair.
2. **Mandate:** renewable share below the world average (30.1%), **or** ≥ 1,000 TWh of non-renewable electricity.
3. **Benchmark:** renewable share ≥ 50%.
4. **Accelerate:** everyone else (above average, but below 50%).

### 🔴 **Mandate (High Demand, Low Renewables or Very Large Fossil Output)**

11 countries, together **68.5% of world electricity demand** and **74% of non-renewable generation**:

* **China**: 32% of world demand. Near the world average in %, but the **largest non-renewable generator** (6,553 TWh)
* **United States**: 14.5% of world demand, **−7.4 pp** below average
* **India**: 6.5% of world demand, **−10.8 pp**
* **Russia**: **−12.3 pp**
* **Japan**: **−8.0 pp**
* **South Korea**: **−20.5 pp**, one of the lowest renewable shares in the top 20
* **Saudi Arabia**: **1.1%** renewable, the lowest in the top 20
* **Iran**: **−23.6 pp**
* **Mexico**: **−9.8 pp**
* **Indonesia**: **−11.5 pp**
* **Taiwan**: **−21.2 pp**

---

### 🟡 **Accelerate (Above Average, Not Yet Leading)**

* **France** *(nuclear-heavy: 92% low-carbon)*
* **United Kingdom** *(nuclear-heavy: 60% low-carbon)*
* **Turkey**
* **Italy**
* **Vietnam**
* **Australia**

---

### 🟢 **Benchmark (High Demand, High Renewable Share)**

These countries show that **high electricity demand and high renewable adoption can coexist**:

* **Brazil**: ~89% renewable
* **Canada**: ~65% renewable
* **Germany**: ~54% renewable

---

A **one-size-fits-all climate mandate is inefficient**.

Instead, this data supports a **tiered, responsibility-based policy framework**:

| Country Category | Recommended Decision |
| ---------------- | -------------------- |
| 🔴 Mandate | **Mandatory renewable targets** |
| 🟡 Accelerate | **Accelerated transition policies** |
| 🟢 Benchmark | **Benchmark & support roles** |

---

## ⚠️ Limitations

* **Nuclear is not counted as renewable.** France (92% low-carbon) and South Korea (39% low-carbon) look worse on renewables alone than on carbon. The tier rules adjust for countries where low-carbon ≥ 50%.
* **Per-person fairness.** India uses **1.3 MWh per person**, compared with **12.4** in the United States and **11.9** in South Korea. Placing them in the same tier does not mean they should carry the same burden.
* **Single year (2023).** This is a snapshot. It does not show how fast each country is changing, which matters for judging whether a mandate is needed.
* **Geography.** Hydropower drives the high shares in Brazil, Canada and Norway. Not every country has that option.
* **Thresholds are choices.** The 270 TWh cut-off (top 20), the 50% benchmark line and the 1,000 TWh test are judgement calls. Changing them moves countries near the edges between tiers.

---

## 👤 Contact
**Eliza C. Huang**  
Data Analyst with a background in UX and data-driven analysis. Interested in high-impact roles across **Public Policy, NGOs, Human Rights**, as well as industries such as **Technology, Supply Chain & Logistics, Healthcare, Sustainability, and FinTech**.
- 📊 Tableau Public: https://public.tableau.com/app/profile/eliza.c.huang/vizzes  
- 💼 LinkedIn: https://www.linkedin.com/in/chuyunh/  
- 📸 Instagram: DataDrawers — https://www.instagram.com/datadrawers/  



