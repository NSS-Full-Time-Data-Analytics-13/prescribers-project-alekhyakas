--1.a.  Which prescriber had the highest total number of claims (totaled over all drugs)? 
--Report the npi and the total number of claims.
SELECT npi, SUM(total_claim_count) AS total_number_of_claims 
FROM PRESCRIBER 
  LEFT JOIN PRESCRIPTION USING(NPI) 
GROUP BY npi
ORDER BY total_number_of_claims DESC NULLS LAST
LIMIT 1;

--1.b Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims

SELECT CONCAT(nppes_provider_first_name,' ', nppes_provider_last_org_name) AS prescriber_name, specialty_description, SUM(total_claim_count) AS total_number_of_claims 
FROM PRESCRIBER 
  LEFT JOIN PRESCRIPTION USING(NPI) 
GROUP BY prescriber_name, specialty_description
ORDER BY total_number_of_claims DESC NULLS LAST
LIMIT 1;

--2a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT  specialty_description, SUM(total_claim_count) AS total_number_of_claims 
FROM PRESCRIBER 
 LEFT JOIN PRESCRIPTION USING(NPI) 
GROUP BY specialty_description
ORDER BY total_number_of_claims DESC NULLS LAST
LIMIT 1;


--2b. Which specialty had the most total number of claims for opioids?

SELECT  specialty_description, SUM(total_claim_count) AS total_number_of_claims 
FROM prescriber 
  LEFT JOIN PRESCRIPTION USING(NPI) 
  INNER JOIN DRUG USING (drug_name)
WHERE opioid_drug_flag='Y'
GROUP BY specialty_description
ORDER BY total_number_of_claims DESC NULLS LAST
LIMIT 1;

-- 2c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT  DISTINCT specialty_description
FROM PRESCRIBER 
 LEFT JOIN PRESCRIPTION USING(NPI)
WHERE total_claim_count IS NULL OR total_claim_count=0;


--2d. For each specialty, report the percentage of total claims by that specialty which are for opioids. 
--Which specialties have a high percentage of opioids?
WITH total_claims1 AS (
    SELECT specialty_description, SUM(total_claim_count) AS specialty_total_claims_opiods
    FROM prescription 
    INNER JOIN prescriber USING(NPI)
    LEFT JOIN drug USING (drug_name)
    WHERE opioid_drug_flag='Y'
    GROUP BY specialty_description
),
total_claims2 AS (
    SELECT specialty_description, SUM(total_claim_count) AS specialty_total_claims
    FROM prescription 
    INNER JOIN prescriber USING(NPI)
    LEFT JOIN drug USING (drug_name)
    GROUP BY specialty_description
)

SELECT 
    total_claims1.specialty_description, 
    ROUND(total_claims1.specialty_total_claims_opiods * 100.0 / total_claims2.specialty_total_claims, 2) AS percentage_of_total_claims
FROM 
    total_claims1 
INNER JOIN 
    total_claims2 
USING (specialty_description)
ORDER BY 
    percentage_of_total_claims DESC;


--3a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name, total_drug_cost
FROM PRESCRIPTION INNER JOIN DRUG USING (drug_name)
ORDER BY total_drug_cost DESC
LIMIT 1;

--3b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT generic_name, ROUND(total_drug_cost/total_day_supply,2) AS total_cost_per_day
FROM PRESCRIPTION INNER JOIN DRUG USING (drug_name)
ORDER BY total_drug_cost DESC
LIMIT 1;


--4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 
SELECT drug_name,

	        CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
	        	 WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
	             ELSE 'neither' END AS drug_category
FROM drug;

--4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
--Hint: Format the total costs as MONEY for easier comparision.

SELECT drug_category,
    CAST(SUM(total_drug_cost) AS MONEY) AS total_cost
FROM (
    SELECT drug_name,
        CASE 
            WHEN opioid_drug_flag = 'Y' THEN 'opioid'
            WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
            ELSE 'neither' 
            END AS drug_category
    FROM drug 
) AS categorized_drugs INNER JOIN prescription USING (drug_name)
GROUP BY drug_category;


--5a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(DISTINCT cbsa) 
FROM cbsa
WHERE cbsaname ILIKE '%TN%';

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
(SELECT fipscounty
	FROM cbsa)
ORDER BY population DESC
LIMIT 1;


--6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, total_claim_count 
FROM prescription
WHERE total_claim_count>=3000
ORDER BY total_claim_count;

--6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name, total_claim_count, opioid_drug_flag
FROM prescription INNER JOIN drug USING (drug_name)
WHERE total_claim_count>=3000
ORDER BY total_claim_count;

--6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT nppes_provider_first_name, nppes_provider_last_org_name, drug_name, total_claim_count, opioid_drug_flag
FROM prescription 
 INNER JOIN drug USING (drug_name)
 INNER JOIN prescriber USING (npi)
WHERE total_claim_count>=3000
ORDER BY total_claim_count;

--The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.
--  7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y'

--  7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT pr.npi, pr.drug_name, COALESCE(pr.total_claim_count, 0) AS total_claim_count
FROM prescriber AS p
CROSS JOIN drug AS d
LEFT JOIN prescription AS pr ON pr.npi=p.npi AND pr.drug_name=d.drug_name
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y'
ORDER BY total_claim_count desc;
	
SELECT combo.npi, combo.drug_name, COALESCE(pr.total_claim_count, 0) AS total_claim_count
FROM (SELECT p.npi, d.drug_name
      FROM prescriber AS p
      CROSS JOIN drug AS d
      WHERE p.specialty_description = 'Pain Management'
        AND p.nppes_provider_city = 'NASHVILLE'
        AND d.opioid_drug_flag = 'Y') AS combo
LEFT JOIN prescription AS pr
ON combo.npi = pr.npi AND combo.drug_name = pr.drug_name
ORDER BY total_claim_count desc
--  7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.