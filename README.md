
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

|country                         |total_twh|current_renewable_pct|total_consumption_rank|pct_global_share|global_avg_renewable_pct|diff_from_avg|
|--------------------------------|---------|---------------------|----------------------|----------------|------------------------|-------------|
|China                           |9,443.07 |30.61                |1                     |32              |37.71                   |-7.1         |
|United States                   |4,272.81 |22.68                |2                     |14.48           |37.71                   |-15.03       |
|India                           |1,917.28 |19.32                |3                     |6.5             |37.71                   |-18.39       |
|Russia                          |1,162.44 |17.75                |4                     |3.94            |37.71                   |-19.96       |
|Japan                           |1,006.73 |22.14                |5                     |3.41            |37.71                   |-15.57       |
|Brazil                          |723.23   |88.99                |6                     |2.45            |37.71                   |51.28        |
|South Korea                     |617.49   |9.57                 |7                     |2.09            |37.71                   |-28.14       |
|Canada                          |613.72   |65.4                 |8                     |2.08            |37.71                   |27.69        |
|Germany                         |512.91   |54.41                |9                     |1.74            |37.71                   |16.7         |
|France                          |466.39   |26.62                |10                    |1.58            |37.71                   |-11.09       |
|Saudi Arabia                    |429.21   |1.1                  |11                    |1.45            |37.71                   |-36.61       |
|Iran                            |379.43   |6.47                 |12                    |1.29            |37.71                   |-31.24       |
|Mexico                          |354.59   |20.27                |13                    |1.2             |37.71                   |-17.44       |
|Indonesia                       |351.49   |18.6                 |14                    |1.19            |37.71                   |-19.11       |
|Turkey                          |323.81   |42.01                |15                    |1.1             |37.71                   |4.3          |
|United Kingdom                  |315.83   |46.38                |16                    |1.07            |37.71                   |8.67         |
|Italy                           |312.75   |44.54                |17                    |1.06            |37.71                   |6.83         |
|Taiwan                          |282.28   |8.9                  |18                    |0.96            |37.71                   |-28.81       |
|Vietnam                         |278.76   |42.94                |19                    |0.94            |37.71                   |5.23         |
|Australia                       |273.11   |34.81                |20                    |0.93            |37.71                   |-2.9         |
|Spain                           |265.88   |51.64                |21                    |0.9             |37.71                   |13.93        |
|South Africa                    |231.92   |12.68                |22                    |0.79            |37.71                   |-25.03       |
|Thailand                        |224.03   |15.62                |23                    |0.76            |37.71                   |-22.09       |
|Egypt                           |220.32   |11.7                 |24                    |0.75            |37.71                   |-26.01       |
|Malaysia                        |186.66   |19.16                |25                    |0.63            |37.71                   |-18.55       |
|Pakistan                        |179.59   |28.98                |26                    |0.61            |37.71                   |-8.73        |
|Poland                          |168.19   |27.24                |27                    |0.57            |37.71                   |-10.47       |
|United Arab Emirates            |167.42   |8.76                 |28                    |0.57            |37.71                   |-28.95       |
|Argentina                       |159.92   |34.77                |29                    |0.54            |37.71                   |-2.94        |
|Iraq                            |153.42   |1.17                 |30                    |0.52            |37.71                   |-36.54       |
|Sweden                          |137.4    |69.38                |31                    |0.47            |37.71                   |31.67        |
|Norway                          |135.79   |98.47                |32                    |0.46            |37.71                   |60.76        |
|Philippines                     |116.76   |21.94                |33                    |0.4             |37.71                   |-15.77       |
|Bangladesh                      |115.57   |1.62                 |34                    |0.39            |37.71                   |-36.09       |
|Kazakhstan                      |115.04   |12.73                |35                    |0.39            |37.71                   |-24.98       |
|Netherlands                     |114.48   |47.46                |36                    |0.39            |37.71                   |9.75         |
|Ukraine                         |104.52   |19.66                |37                    |0.35            |37.71                   |-18.05       |
|Algeria                         |94.02    |0.94                 |38                    |0.32            |37.71                   |-36.77       |
|Colombia                        |89.53    |65.97                |39                    |0.3             |37.71                   |28.26        |
|Chile                           |87.67    |64.4                 |40                    |0.3             |37.71                   |26.69        |
|Kuwait                          |85.57    |2.23                 |41                    |0.29            |37.71                   |-35.48       |
|Belgium                         |83.79    |33.45                |42                    |0.28            |37.71                   |-4.26        |
|Finland                         |82.86    |51.66                |43                    |0.28            |37.71                   |13.95        |
|Venezuela                       |82.34    |78.38                |44                    |0.28            |37.71                   |40.67        |
|Uzbekistan                      |79.18    |9.25                 |45                    |0.27            |37.71                   |-28.46       |
|Austria                         |71.21    |84.82                |46                    |0.24            |37.71                   |47.11        |
|Israel                          |67.48    |10.51                |47                    |0.23            |37.71                   |-27.2        |
|Czechia                         |66.63    |14.71                |48                    |0.23            |37.71                   |-23          |
|Peru                            |62.23    |53.06                |49                    |0.21            |37.71                   |15.35        |
|Switzerland                     |61.07    |62.35                |50                    |0.21            |37.71                   |24.64        |
|Singapore                       |57.4     |4.54                 |51                    |0.19            |37.71                   |-33.17       |
|Portugal                        |56.42    |74.5                 |52                    |0.19            |37.71                   |36.79        |
|Qatar                           |55.14    |0.25                 |53                    |0.19            |37.71                   |-37.46       |
|Romania                         |53.93    |49.8                 |54                    |0.18            |37.71                   |12.09        |
|Greece                          |53.74    |49.72                |55                    |0.18            |37.71                   |12.01        |
|Hong Kong                       |49.23    |0.96                 |56                    |0.17            |37.71                   |-36.75       |
|Hungary                         |46.62    |26.35                |57                    |0.16            |37.71                   |-11.36       |
|Oman                            |45.01    |4.04                 |58                    |0.15            |37.71                   |-33.67       |
|Morocco                         |44.31    |21.71                |59                    |0.15            |37.71                   |-16          |
|New Zealand                     |43.86    |87.64                |60                    |0.15            |37.71                   |49.93        |
|Belarus                         |43.03    |3.07                 |61                    |0.15            |37.71                   |-34.64       |
|Nigeria                         |40.11    |22.89                |62                    |0.14            |37.71                   |-14.82       |
|Denmark                         |37.14    |86.45                |63                    |0.13            |37.71                   |48.74        |
|Serbia                          |36.98    |34.69                |64                    |0.13            |37.71                   |-3.02        |
|Bulgaria                        |36.78    |25.13                |65                    |0.12            |37.71                   |-12.58       |
|Bahrain                         |36.18    |0.25                 |66                    |0.12            |37.71                   |-37.46       |
|Libya                           |35.91    |0.03                 |67                    |0.12            |37.71                   |-37.68       |
|Ireland                         |34.57    |44.82                |68                    |0.12            |37.71                   |7.11         |
|Ecuador                         |34.42    |76.78                |69                    |0.12            |37.71                   |39.07        |
|Slovakia                        |26.11    |22.72                |70                    |0.09            |37.71                   |-14.99       |
|Azerbaijan                      |26.06    |6.53                 |71                    |0.09            |37.71                   |-31.18       |
|Myanmar                         |25.49    |38.19                |72                    |0.09            |37.71                   |0.48         |
|Turkmenistan                    |24.79    |0.03                 |73                    |0.08            |37.71                   |-37.68       |
|Dominican Republic              |24.56    |17.26                |74                    |0.08            |37.71                   |-20.45       |
|Tunisia                         |23.79    |3.95                 |75                    |0.08            |37.71                   |-33.76       |
|Ghana                           |22.34    |38.53                |76                    |0.08            |37.71                   |0.82         |
|Iceland                         |20.12    |100                  |77                    |0.07            |37.71                   |62.29        |
|Paraguay                        |20.04    |100                  |78                    |0.07            |37.71                   |62.29        |
|Puerto Rico                     |19.9     |5.38                 |79                    |0.07            |37.71                   |-32.33       |
|Tajikistan                      |19.21    |92.59                |80                    |0.07            |37.71                   |54.88        |
|Cambodia                        |18.87    |44.52                |81                    |0.06            |37.71                   |6.81         |
|Croatia                         |18.81    |69.76                |82                    |0.06            |37.71                   |32.05        |
|Angola                          |17.94    |76.42                |83                    |0.06            |37.71                   |38.71        |
|Sudan                           |17.63    |70.15                |84                    |0.06            |37.71                   |32.44        |
|Democratic Republic of Congo    |17.31    |100                  |85                    |0.06            |37.71                   |62.29        |
|Kyrgyzstan                      |17.23    |85.65                |86                    |0.06            |37.71                   |47.94        |
|Bosnia and Herzegovina          |16.87    |39.18                |87                    |0.06            |37.71                   |1.47         |
|Zambia                          |16.64    |89                   |88                    |0.06            |37.71                   |51.29        |
|Ethiopia                        |16.5     |100                  |89                    |0.06            |37.71                   |62.29        |
|Mozambique                      |16.36    |83.69                |90                    |0.06            |37.71                   |45.98        |
|Cuba                            |15.29    |4.71                 |91                    |0.05            |37.71                   |-33          |
|Laos                            |15.26    |76.71                |92                    |0.05            |37.71                   |39           |
|Slovenia                        |14.04    |40.51                |93                    |0.05            |37.71                   |2.8          |
|Guatemala                       |13.93    |74.52                |94                    |0.05            |37.71                   |36.81        |
|Georgia                         |13.72    |76.04                |95                    |0.05            |37.71                   |38.33        |
|Kenya                           |13.07    |89.84                |96                    |0.04            |37.71                   |52.13        |
|Panama                          |12.7     |61.77                |97                    |0.04            |37.71                   |24.06        |
|Lithuania                       |12.14    |83.49                |98                    |0.04            |37.71                   |45.78        |
|Bhutan                          |11.99    |100                  |99                    |0.04            |37.71                   |62.29        |
|Bolivia                         |11.94    |35.01                |100                   |0.04            |37.71                   |-2.7         |
|Honduras                        |11.92    |61.57                |101                   |0.04            |37.71                   |23.86        |
|Tanzania                        |11.14    |25.5                 |102                   |0.04            |37.71                   |-12.21       |
|Costa Rica                      |10.99    |99.91                |103                   |0.04            |37.71                   |62.2         |
|Uruguay                         |10.96    |92                   |104                   |0.04            |37.71                   |54.29        |
|Cote d'Ivoire                   |10.38    |31.09                |105                   |0.04            |37.71                   |-6.62        |
|Zimbabwe                        |10.21    |67.51                |106                   |0.03            |37.71                   |29.8         |
|Mongolia                        |10.11    |9.61                 |107                   |0.03            |37.71                   |-28.1        |
|Trinidad and Tobago             |9.5      |0.11                 |108                   |0.03            |37.71                   |-37.6        |
|Estonia                         |9.15     |49.74                |109                   |0.03            |37.71                   |12.03        |
|Senegal                         |8.54     |21.74                |110                   |0.03            |37.71                   |-15.97       |
|Cameroon                        |8.39     |63.87                |111                   |0.03            |37.71                   |26.16        |
|Albania                         |8.09     |100                  |112                   |0.03            |37.71                   |62.29        |
|Armenia                         |7.54     |27.98                |113                   |0.03            |37.71                   |-9.73        |
|Afghanistan                     |7.19     |86.6                 |114                   |0.02            |37.71                   |48.89        |
|Latvia                          |7.17     |77.71                |115                   |0.02            |37.71                   |40           |
|El Salvador                     |7.11     |90.62                |116                   |0.02            |37.71                   |52.91        |
|North Macedonia                 |7.06     |32.27                |117                   |0.02            |37.71                   |-5.44        |
|Luxembourg                      |6.6      |89.29                |118                   |0.02            |37.71                   |51.58        |
|Moldova                         |6.22     |12.08                |119                   |0.02            |37.71                   |-25.63       |
|Brunei                          |5.59     |0                    |120                   |0.02            |37.71                   |-37.71       |
|Nicaragua                       |5.5      |64.53                |121                   |0.02            |37.71                   |26.82        |
|Cyprus                          |5.31     |20.15                |122                   |0.02            |37.71                   |-17.56       |
|Congo                           |5.17     |20.7                 |123                   |0.02            |37.71                   |-17.01       |
|Papua New Guinea                |4.73     |23.68                |124                   |0.02            |37.71                   |-14.03       |
|Namibia                         |4.64     |97.88                |125                   |0.02            |37.71                   |60.17        |
|Mali                            |4.58     |42.66                |126                   |0.02            |37.71                   |4.95         |
|Lebanon                         |4.52     |47.35                |127                   |0.02            |37.71                   |9.64         |
|Botswana                        |4.51     |0.39                 |128                   |0.02            |37.71                   |-37.32       |
|Guinea                          |4.05     |74.81                |129                   |0.01            |37.71                   |37.1         |
|Gabon                           |3.77     |47.96                |130                   |0.01            |37.71                   |10.25        |
|Montenegro                      |3.35     |61.14                |131                   |0.01            |37.71                   |23.43        |
|Burkina Faso                    |3.31     |17.34                |132                   |0.01            |37.71                   |-20.37       |
|Mauritius                       |3.27     |17.43                |133                   |0.01            |37.71                   |-20.28       |
|Yemen                           |3.07     |16.94                |134                   |0.01            |37.71                   |-20.77       |
|Malta                           |2.97     |13.62                |135                   |0.01            |37.71                   |-24.09       |
|Suriname                        |2.14     |42.99                |136                   |0.01            |37.71                   |5.28         |
|Togo                            |2.02     |20.65                |137                   |0.01            |37.71                   |-17.06       |
|Niger                           |2.01     |2.5                  |138                   |0.01            |37.71                   |-35.21       |
|Benin                           |1.84     |3                    |139                   |0.01            |37.71                   |-34.71       |
|Equatorial Guinea               |1.57     |31.21                |140                   |0.01            |37.71                   |-6.5         |
|Eswatini                        |1.49     |96.43                |141                   |0.01            |37.71                   |58.72        |
|Guyana                          |1.34     |6.72                 |142                   |0               |37.71                   |-30.99       |
|Fiji                            |1.15     |63.48                |143                   |0               |37.71                   |25.77        |
|Barbados                        |1.1      |8.18                 |144                   |0               |37.71                   |-29.53       |
|Rwanda                          |1.08     |56.6                 |145                   |0               |37.71                   |18.89        |
|Maldives                        |0.85     |7.06                 |146                   |0               |37.71                   |-30.65       |
|Belize                          |0.73     |88.89                |147                   |0               |37.71                   |51.18        |
|Djibouti                        |0.71     |35                   |148                   |0               |37.71                   |-2.71        |
|Cayman Islands                  |0.7      |2.86                 |149                   |0               |37.71                   |-34.85       |
|United States Virgin Islands    |0.67     |2.99                 |150                   |0               |37.71                   |-34.72       |
|Bermuda                         |0.64     |1.56                 |151                   |0               |37.71                   |-36.15       |
|Seychelles                      |0.63     |14.29                |152                   |0               |37.71                   |-23.42       |
|South Sudan                     |0.59     |6.78                 |153                   |0               |37.71                   |-30.93       |
|East Timor                      |0.51     |0                    |154                   |0               |37.71                   |-37.71       |
|Gambia                          |0.51     |0                    |154                   |0               |37.71                   |-37.71       |
|Burundi                         |0.49     |69.23                |156                   |0               |37.71                   |31.52        |
|Eritrea                         |0.44     |11.36                |157                   |0               |37.71                   |-26.35       |
|Somalia                         |0.42     |19.05                |158                   |0               |37.71                   |-18.66       |
|Liberia                         |0.39     |33.33                |159                   |0               |37.71                   |-4.38        |
|Antigua and Barbuda             |0.36     |5.56                 |160                   |0               |37.71                   |-32.15       |
|Turks and Caicos Islands        |0.26     |0                    |161                   |0               |37.71                   |-37.71       |
|Gibraltar                       |0.22     |0                    |162                   |0               |37.71                   |-37.71       |
|Sierra Leone                    |0.21     |95.24                |163                   |0               |37.71                   |57.53        |
|American Samoa                  |0.17     |0                    |164                   |0               |37.71                   |-37.71       |
|British Virgin Islands          |0.17     |0                    |164                   |0               |37.71                   |-37.71       |
|Samoa                           |0.15     |40                   |166                   |0               |37.71                   |2.29         |
|Dominica                        |0.15     |13.33                |166                   |0               |37.71                   |-24.38       |
|Saint Vincent and the Grenadines|0.15     |13.33                |166                   |0               |37.71                   |-24.38       |
|Comoros                         |0.14     |0                    |169                   |0               |37.71                   |-37.71       |
|Solomon Islands                 |0.11     |9.09                 |170                   |0               |37.71                   |-28.62       |
|Vanuatu                         |0.08     |25                   |171                   |0               |37.71                   |-12.71       |
|Tonga                           |0.07     |14.29                |172                   |0               |37.71                   |-23.42       |
|Nauru                           |0.04     |0                    |173                   |0               |37.71                   |-37.71       |

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



