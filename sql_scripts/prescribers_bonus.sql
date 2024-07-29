--How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT(DISTINCT npi) from prescriber
EXCEPT
SELECT COUNT(DISTINCT npi) from prescription

--2.a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT generic_name, sum(total_claim_count) AS most_prescribed 
FROM prescriber 
	       INNER JOIN prescription USING (NPI)
	       INNER JOIN drug USING(drug_name)
WHERE specialty_description= 'Family Practice'
GROUP BY  generic_name
ORDER BY most_prescribed DESC
LIMIT 5;

--2b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
SELECT generic_name, sum(total_claim_count) AS most_prescribed 
FROM prescriber 
	       INNER JOIN prescription USING (NPI)
	       INNER JOIN drug USING(drug_name)
WHERE specialty_description= 'Cardiology'
GROUP BY  generic_name
ORDER BY most_prescribed DESC
LIMIT 5;

select distinct(specialty_description)
FROM prescriber 
	       INNER JOIN prescription USING (NPI)
	       INNER JOIN drug USING(drug_name)
--2c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
SELECT drug_name, generic_name, sum(total_claim_count) AS most_prescribed 
FROM prescriber 
	       INNER JOIN prescription USING (NPI)
	       INNER JOIN drug USING(drug_name)
WHERE specialty_description= 'Cardiology' OR specialty_description= 'Family Practice'
GROUP BY  generic_name,drug_name
ORDER BY most_prescribed DESC
LIMIT 5;

--3.Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--3a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
    SELECT DISTINCT npi, SUM(total_claim_count), nppes_provider_city
	FROM prescriber
		INNER JOIN prescription USING (NPI)
	 WHERE nppes_provider_city = 'NASHVILLE'
	GROUP BY npi, nppes_provider_city
ORDER BY SUM(total_claim_count) DESC
LIMIT 5;

   --3b. Now, report the same for Memphis.
     SELECT DISTINCT npi, SUM(total_claim_count), nppes_provider_city
	FROM prescriber
		INNER JOIN prescription USING (NPI)
	 WHERE nppes_provider_city = 'MEMPHIS'
	GROUP BY npi, nppes_provider_city
ORDER BY SUM(total_claim_count) DESC
LIMIT 5;
    --3c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

SELECT DISTINCT npi, SUM(total_claim_count), nppes_provider_city
	FROM prescriber
		INNER JOIN prescription USING (NPI)
	 WHERE nppes_provider_city IN ('NASHVILLE', 'MEMPHIS', 'KNOXVILLE', 'CHATTANOOGA')
	GROUP BY npi, nppes_provider_city
ORDER BY SUM(total_claim_count) DESC
LIMIT 5;

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

SELECT county, SUM(overdose_deaths) as total_deaths
FROM fips_county as fc
INNER JOIN overdose_deaths as od ON fc.fipscounty::integer=od.fipscounty
WHERE overdose_deaths> (SELECT AVG(overdose_deaths) FROM overdose_deaths )
GROUP BY county	
ORDER BY total_deaths DESC 


--5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
--LARGEST POPULATION
SELECT cbsaname, SUM(population) AS combined_pop
FROM cbsa INNER JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER BY combined_pop DESC
LIMIT 1;

--SMALLEST POPULATION
SELECT cbsaname, SUM(population) AS combined_pop
FROM cbsa INNER JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER BY combined_pop 
LIMIT 1;

--5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT county,population
FROM fips_county
INNER JOIN population USING (fipscounty) 
WHERE  population IS NOT NULL AND fipscounty NOT IN 
(SELECT DISTINCT fipscounty
	FROM cbsa)
ORDER BY population DESC
LIMIT 1;


--5.a. Write a query that finds the total population of Tennessee.
    --b. Build off of the query that you wrote in part a to write a query that returns for each county that county's
--name, its population, and the percentage of the total population of Tennessee that is contained in that county.



WITH tn_total AS (
    SELECT SUM(population) AS tn_pop
    FROM fips_county
    INNER JOIN population USING (fipscounty)
    WHERE state = 'TN'
)
SELECT 
    fips_county.county, 
    population.population, 
    (population.population / tn_total.tn_pop) * 100 AS percentage_county_pop
FROM 
    fips_county
INNER JOIN 
    population USING (fipscounty)
CROSS JOIN 
    tn_total
WHERE 
    fips_county.state = 'TN';
