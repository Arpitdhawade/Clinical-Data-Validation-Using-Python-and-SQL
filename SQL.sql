---Data cleaning of table brca301lb------------------------------------------------------------------------------------------------------------

WITH ranked AS(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY bl.usubjid , lbseq, lbdtc ORDER BY lbdtc)AS rn
FROM brca301_lb bl 
),
deduplicates AS 
(
	SELECT
		usubjid,
		lbseq ,
		initcap(trim(lbtestcd))AS lbtestcd,
		initcap(trim(lbtest)) AS lbtest,
		initcap(trim(lbcat)) AS lbcat,
		lbstresn,
		---40 null
		trim(lbstresu) AS lbstresu,
		---25 null
		lbnrlo,
		lbnrhi,
		initcap(trim(lbnrind)) AS lbnrind,
		---40 null
		visitnum,
		initcap(trim(lower(visit))) AS visit ,
		to_date(lbdtc, 'YYYY-MM-DD') AS lbdtc
	FROM
		ranked
	WHERE
		rn = 1
),
non_null AS
(
	SELECT
		*,
		(
			SELECT
				percentile_cont(0.5)WITHIN GROUP( ORDER BY lbstresn)AS  med_lbstresn
			FROM
				deduplicates
		) AS medlbstresn
	FROM
		deduplicates
),
null_handeling AS 
(
	SELECT
		* ,
		COALESCE(lbstresn, medlbstresn)AS lbstresnf,
		COALESCE(lbstresu, 'Not Known')AS lbstresuf,
		COALESCE(lbnrind, 'Normal')AS lbnrindf
	FROM
		non_null
),
outlier_stats AS (
	SELECT
		lbtestcd,
		percentile_cont(0.25) WITHIN GROUP (
		ORDER BY
			lbstresnf
		) AS q1,
		percentile_cont(0.75) WITHIN GROUP (
		ORDER BY
			lbstresnf
		) AS q3
	FROM
		null_handeling
	GROUP BY
		lbtestcd
),
iqr_calc AS (
	SELECT
		nh.*,
		os.q1,
		os.q3,
		(
			os.q3 - os.q1
		) AS iqr,
		(
			os.q1 - 1.5 * (
				os.q3 - os.q1
			)
		) AS lower_bound,
		(
			os.q3 + 1.5 * (
				os.q3 - os.q1
			)
		) AS upper_bound
	FROM
		null_handeling nh
	JOIN outlier_stats os
        ON
		nh.lbtestcd = os.lbtestcd
),
final_brca301lb AS
(
	SELECT
		*,
		CASE
			WHEN lbstresnf < lower_bound
				OR lbstresnf > upper_bound 
        THEN 'Outlier'
				ELSE 'Normal'
			END AS outlier_flag
		FROM
			iqr_calc
		WHERE
			lbstresnf BETWEEN lower_bound AND upper_bound
)
SELECT
	usubjid,
	lbseq,
	lbtestcd,
	lbtest,
	lbcat,
	lbstresnf,
	lbstresuf,
	lbnrlo,
	lbnrhi,
	lbnrindf,
	visitnum ,
	visit,
	lbdtc
FROM
	final_brca301lb;

--------- Data cleaning of table brca301ae------------------------------------------------------------------------------------------------------

WITH ranked AS 
(
	SELECT
		trim(ba.usubjid)AS usubjid,
		ba.aeseq ,
		initcap(trim(ba.aedecod)) AS aedecod,
		initcap(trim(ba.aebodsys)) AS aebodsys,
		initcap(trim(ba.aehlt)) AS aehlt,
		initcap(trim(ba.aesev)) AS aesev,
		initcap(trim(ba.aeser)) AS aeser,
		initcap(trim(ba.aerel))AS aerel,
		initcap(trim(ba.aeout))AS aeout,
		to_date(ba.aestdtc, 'YYYY-MM-DD') AS aestdtc,
		to_date(ba.aeendtc , 'YYYY-MM-DD') AS aeendtc,
		ba.aetoxgr,
		ROW_NUMBER() OVER(PARTITION BY ba.usubjid , aeseq, aestdtc ORDER BY ba.aestdtc) AS rn
	FROM
		brca301_ae ba
),
null_handeling AS 
(
	SELECT
		usubjid ,
		aeseq,
		aedecod,
		COALESCE(aebodsys, 'Not Known') AS aebodsys ,
		COALESCE(aehlt , 'Not Known') AS aehlt,
		COALESCE(aesev, 'Not Known') AS aesev,
		COALESCE(aeser, 'Not Known') AS aeser,
		aerel,
		COALESCE(aeout, 'Not Known')AS aeoutf,
		aestdtc,
		aeendtc,
		aetoxgr
	FROM
		ranked
	WHERE
		rn = 1
),
outlier_stat AS
(
	SELECT
		aedecod,
		PERCENTILE_CONT(0.25)WITHIN GROUP(ORDER BY aeseq)AS q1,
		percentile_cont(0.75) WITHIN GROUP (
		ORDER BY
			aeseq
		) AS q3
	FROM
		null_handeling
	GROUP BY
		aedecod
)
,
iqr_calc AS (
	SELECT
		nh.*,
		os.q1,
		os.q3,
		(
			os.q3 - os.q1
		) AS iqr,
		(
			os.q1 - 1.5 * (
				os.q3 - os.q1
			)
		) AS lower_bound,
		(
			os.q3 + 1.5 * (
				os.q3 - os.q1
			)
		) AS upper_bound
	FROM
		null_handeling nh
	JOIN outlier_stat os
        ON
		nh.aedecod = os.aedecod
),
final_brca301ae AS
(
	SELECT
		*,
	REPLACE(REPLACE(aerel, 'Yes', 'Related'), 'Y', 'Related') AS aerelf,
		
		CASE
			WHEN aeseq< lower_bound
				OR aeseq> upper_bound 
        THEN 'Outlier'
				ELSE 'Normal'
			END AS outlier_flag
		FROM
			iqr_calc
		WHERE
			aeseq BETWEEN lower_bound AND upper_bound
)SELECT
	usubjid ,
	aeseq,
	aedecod,
	 aebodsys ,
	aehlt,
	aesev,
	aeser,
	aerelf,
	aeoutf,
	aestdtc,
	aeendtc,
	aetoxgr
FROM
	final_brca301ae

------------- Data cleaning of table brca301dv----------------------------------------------------------------------------------------------------

WITH deduplicates AS 
(
	SELECT
		*,
		ROW_NUMBER() OVER(PARTITION BY bd.usubjid , dvstdtc ORDER BY dvstdtc) AS rn
	FROM
		brca301_dv bd
),
formated AS 
(
	SELECT
		trim(usubjid)AS usubjid ,
		dvseq ,
		initcap(trim(dvterm)) AS dvterm ,
		initcap(trim(dvcat)) AS dvcat,
		initcap(trim(dvscat)) AS dvscat,
		to_date(dvstdtc, 'YYYY-MM-DD') AS dvstdtc
	FROM
		deduplicates
),
final_brca301dv AS 
(
	SELECT
		usubjid ,
		dvseq,
		dvterm,
		dvscat,
		COALESCE(dvstdtc , '1990-09-09'::DATE) AS dvstdtc,
		REPLACE(REPLACE(dvcat, 'Min', 'Minimum'), 'Maj', 'Major') AS dvcatf
	FROM
		formated
)
SELECT
	usubjid ,
	dvseq,
	dvterm,
	REPLACE(REPLACE(dvcatf, 'Minimumor', 'Minimum'), 'Majoror', 'Major') AS dvcat,
	dvscat,
	dvstdtc,
	CASE
		WHEN dvstdtc = '1990-09-09' THEN 'Replaced'
		ELSE 'Original'
	END AS date_status
FROM
	final_brca301dv 

------------- Data cleaning of table brca301dm-----------------------------------------------------------------------------------------------------

WITH deduplicates AS 
(
	SELECT
		trim(usubjid) AS usubjid,
		siteid,
		initcap(trim(lower(arm))) AS arm,
		age,
		COALESCE(initcap(trim(race)), 'Unknown') AS race,
		initcap(trim(ethnic))AS ethnic ,
		initcap(trim(country)) AS country,
		to_date(rfstdtc, 'YYYY-MM-DD') AS rfstdtc,
		initcap(trim(lower(dsdecod))) AS dsdecod,
		initcap(trim(lower(dsscat))) AS dsscat,
		ROW_NUMBER() OVER(PARTITION BY bd.usubjid , bd.rfstdtc ORDER BY bd.rfstdtc ) AS rn
	FROM
		brca301_dm bd
),
null_handeling 
AS 
(
	SELECT
		usubjid,
		siteid,
		REPLACE(REPLACE(arm, 'Pbo', 'Placebo'), 'Lumi 100mg', 'Lumicanib 100mg') arm,
		age,
		race,
		ethnic ,
		country,
		COALESCE(rfstdtc, '1990-09-09'::DATE) AS rfstdtc,
		dsscat
	FROM
		deduplicates 
	WHERE
		rn = 1
),
outlier_stat AS
	(
	SELECT
		ethnic,
		percentile_cont(0.25)WITHIN GROUP (
		ORDER BY
			age
		) AS q1,
		percentile_cont(0.75)WITHIN GROUP (
		ORDER BY
			age
		) AS q3
	FROM
		null_handeling nh
	GROUP BY
		ethnic
),
iqr_calc AS (
	SELECT
		nh.*,
		os.q1,
		os.q3,
		(
			os.q3 - os.q1
		) AS iqr,
		(
			os.q1 - 1.5 * (
				os.q3 - os.q1
			)
		) AS lower_bound,
		(
			os.q3 + 1.5 * (
				os.q3 - os.q1
			)
		) AS upper_bound
	FROM
		null_handeling nh
	JOIN outlier_stat os
        ON
		nh.ethnic = os.ethnic
),
final_brca301dm AS 
(
	SELECT
		*,
		CASE
			WHEN age< lower_bound
				OR age> upper_bound 
        THEN 'Outlier'
				ELSE 'Normal'
			END AS outlier_flag
		FROM
			iqr_calc
		WHERE
			age BETWEEN lower_bound AND upper_bound
)
SELECT
	usubjid,
	siteid,
	arm,
	age,
	race,
	ethnic ,
	country,
	rfstdtc,
	dsscat
FROM
	final_brca301dm


	