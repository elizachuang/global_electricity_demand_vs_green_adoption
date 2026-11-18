--- Step 1 only filter individual country, not country group. 
--- Year=2023 because OWID 2024 data might be partial. 2023 is usually the latest full year.
SELECT * 
FROM energy_data
WHERE iso_code IS NOT NULL
	AND TRIM(iso_code) <> ''
	AND iso_code <> 'null'
	AND YEAR = 2023
	LIMIT 10;

--- Step 2 find out country has high electricity demand and current share of renewables.
SELECT country,
	electricity_demand AS total_twh,
	renewables_share_elec AS current_renewable_pct
FROM energy_data
WHERE iso_code IS NOT NULL
	AND TRIM(iso_code) <> ''
	AND iso_code <> 'null'
	AND YEAR = 2023
	AND electricity_demand IS NOT NULL 
	AND renewables_share_elec IS NOT NULL
ORDER BY total_twh DESC;

--- Step 3 Applying Window Functions to find out:
--- Where does this country sit in global consumption?
--- What % of global electricity does this one country use?
--- Is this country's renewable share higher or lower than the world average?
--- NOTE: the world average is WEIGHTED BY DEMAND = SUM(demand x renewable %) / SUM(demand).
---       A simple AVG() counts every country equally (Norway = China) and gives 37.71%.
---       The weighted average is 30.09%, the real renewable share of world electricity.
--- Also added:
---   low_carbon_pct    = renewables + nuclear (France is 92% low-carbon but only 27% renewable)
---   non_renewable_twh = electricity not from renewables (absolute size of the problem)
---   mwh_per_person    = demand per person (fairness: India 1.3 vs United States 12.4)

SELECT country,
	electricity_demand AS total_twh,
	renewables_share_elec AS current_renewable_pct,
	low_carbon_share_elec AS low_carbon_pct,
	RANK() OVER (ORDER BY electricity_demand DESC) AS total_consumption_rank,
	ROUND(
	(electricity_demand * 100.0) / SUM(electricity_demand) OVER (),
	2
	) AS pct_global_share,
	ROUND(
	SUM(electricity_demand * renewables_share_elec) OVER () / SUM(electricity_demand) OVER (),
	2
	) AS weighted_avg_renewable_pct,
	ROUND(
	renewables_share_elec
	- SUM(electricity_demand * renewables_share_elec) OVER () / SUM(electricity_demand) OVER (),
	2
	) AS diff_from_weighted_avg,
	ROUND(electricity_demand * (1 - renewables_share_elec / 100.0), 1) AS non_renewable_twh,
	ROUND(electricity_demand * 1000000.0 / population, 1) AS mwh_per_person
FROM energy_data
WHERE iso_code IS NOT NULL
	AND TRIM(iso_code) <> ''
	AND iso_code <> 'null'
	AND YEAR = 2023
	AND electricity_demand IS NOT NULL
	AND renewables_share_elec IS NOT NULL
ORDER BY total_twh DESC;

--- Step 4 Assign a mandate tier to the top 20 consumers (>= 270 TWh, 81% of world demand).
--- Rules are checked in this order:
---   1. demand < 270 TWh                                   -> Other (not a major consumer)
---   2. low-carbon >= 50% AND renewable < 50%              -> Accelerate (nuclear-heavy)
---   3. renewable < weighted avg OR non-renewable >= 1,000 TWh -> Mandate
---   4. renewable >= 50%                                   -> Benchmark
---   5. everything else                                    -> Accelerate
--- The 1,000 TWh test keeps China in Mandate: it is near the world average in %,
--- but it generates 6,553 TWh from non-renewable sources, about 2x the United States.

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
		AND YEAR = 2023
		AND electricity_demand IS NOT NULL
		AND renewables_share_elec IS NOT NULL
)
SELECT country,
	electricity_demand AS total_twh,
	renewables_share_elec AS current_renewable_pct,
	ROUND(renewables_share_elec - weighted_avg, 2) AS diff_from_weighted_avg,
	low_carbon_share_elec AS low_carbon_pct,
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
