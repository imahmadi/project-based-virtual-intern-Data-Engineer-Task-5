--=================================================================================
--==========   CREATE customer_data_history_new Table   ===========================
--==========------------- Consist All Table ------------===========================
--=================================================================================

CREAT TABLE customer_data_history_new AS (
SELECT t1.clientnum,
		t2.status,
		t1.customer_age,
		t1.gender,
		t1.dependent_count,
		t3.education_level AS education,
		t4.marital_status AS marital,
		t1.income_category,
		t5.card_category,
		t1.months_on_book,
		t1.total_relationship_count,
		t1.months_inactive_12_mon,
		t1.contacts_count_12_mon,
		t1.credit_limit,
		t1.total_revolving_bal,
		t1.avg_open_to_buy,
		t1.total_trans_amt,
		t1.total_trans_tt,
		t1.avg_utilization_ratio		
FROM customer_data_history AS t1 
LEFT JOIN status AS t2
	ON t1.idstatus = t2.id
LEFT JOIN education AS t3
	ON t1.educationid = t3.id
LEFT JOIN marital AS t4
	ON t1.maritalid = t4.id
LEFT JOIN category AS t5
	ON t1.card_categoryid = t5.id
);

--=================================================================================
--==========   CREATE churn_with_seg VIEW   =======================================
--==========--- Consist All Table and seg --=======================================
--=================================================================================

CREATE TABLE churn_data AS (
SELECT *,
		CASE
			WHEN customer_age <= 25 THEN 'below 26'
			WHEN customer_age <= 35 THEN '26-35'
			WHEN customer_age <= 45 THEN '36-45'
			WHEN customer_age <= 55 THEN '46-55'
			WHEN customer_age <= 65 THEN '56-65'
			WHEN customer_age > 65 THEN 'older than 65'
		END AS age_seg,
		ROUND((FLOOR(avg_utilization_ratio::decimal * 10)/10),1) AS utilization_seg,
		CEILING(months_on_book::decimal/12) AS years_on_book,
		FLOOR(credit_limit::decimal/1000)*1000 AS credit_limit_seg,
		FLOOR(total_revolving_bal::decimal/100)*100 AS revolving_bal_seg,
		FLOOR(avg_open_to_buy::decimal/1000)*1000 AS open_to_buy_seg,
		FLOOR(total_trans_amt::decimal/1000)*1000 AS total_trans_amt_seg,
		FLOOR(total_trans_tt::decimal/10)*10 AS total_trans_freq_seg
FROM customer_data_history_new
WHERE status = 'Attrited Customer'
);

--===============================
--=== CUSTOMER STATUS PERCENTAGE
--===============================

CREATE TABLE v_cust_percent AS
(
WITH t1 AS 
	(
	SELECT status, 
				COUNT(*) AS cust_count
	FROM customer_data_history_new
	GROUP BY status
	)

SELECT *, 
		ROUND(((cust_count/(SELECT SUM(cust_count) FROM t1)) * 100), 2) AS percentage
FROM t1
);


--============================
--=== UTILIZATION RATE
--============================

CREATE TABLE v_utilization_count AS
(
SELECT utilization_seg, COUNT(*) AS cust_count
FROM churn_data
GROUP BY utilization_seg
ORDER BY utilization_seg
);


--============================
--=== TOTAL TRANSACTION COUNT
--============================

CREATE TABLE v_total_trans_count AS
(
SELECT total_trans_amt_seg, COUNT(*) AS total_cust
FROM churn_data
GROUP BY total_trans_amt_seg
ORDER BY total_trans_amt_seg
);


--==============================
--=== INCOME CATEGORY BY GENDER
--==============================

CREATE TABLE v_income_cat_gender AS
(
SELECT gender, income_category, COUNT(*) AS cust_count
FROM churn_data
GROUP BY gender, income_category
ORDER BY gender, CASE
					WHEN income_category ='Unknown' THEN 1
					WHEN income_category ='Less than $40K' THEN 2
					WHEN income_category ='$40K - $60K' THEN 3
					WHEN income_category ='$60K - $80K' THEN 4
					WHEN income_category ='$80K - $120K' THEN 5
					WHEN income_category ='$120K +' THEN 6
				END
);


--============================
--=== CUSTOMER AGE RANGE
--============================

CREATE TABLE v_age_range AS
(
SELECT age_seg, COUNT(*) cust_count
FROM churn_data
GROUP BY age_seg
ORDER BY age_seg
);


--============================
--=== EDUCATION
--============================

CREATE TABLE v_education AS
(
SELECT education, COUNT(*) cust_count
FROM churn_data
GROUP BY education
ORDER BY cust_count DESC
);
