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
--- Is this country's renewable share higher or lower than the global average?

SELECT country,
	electricity_demand AS total_twh,
	renewables_share_elec AS current_renewable_pct,
	RANK() OVER(ORDER BY electricity_demand DESC) AS total_consumption_rank,
	ROUND(
	(electricity_demand * 100.0)/SUM(electricity_demand) OVER (), 
	2
	) AS pct_global_share,
	ROUND(AVG(renewables_share_elec) OVER() , 2) AS global_avg_renewable_pct,
	ROUND(renewables_share_elec - AVG(renewables_share_elec) OVER (), 2) AS diff_from_avg
FROM energy_data
WHERE iso_code IS NOT NULL
	AND TRIM(iso_code) <> ''
	AND iso_code <> 'null'
	AND YEAR = 2023
	AND electricity_demand IS NOT NULL 
	AND renewables_share_elec IS NOT NULL
ORDER BY total_twh DESC;

