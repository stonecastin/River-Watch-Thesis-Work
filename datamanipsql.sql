/*yayay let's get it going!

1st step being sort out combined tables into one root table, and then join with the others

let's keep track:

1997-2017:  qc_id, projectid, locationid, locationname, larosasiteid, visitdate, starttime, activitycategory, symbol, result, remarkcode, characteristicid, characteristicname, unitcode, rid

--want to:
-merge with 2021 data
-done with copy/paste in xlsx files

2018:   Sample Number, Order, Location, Date, QA, E. Coli.   (mpn/100ml),,Total Nitrogen  (mg/L),, Total Phosphorus (ug/L),, Dissolved Phosphorus (ug/L),, Total Suspended Solids (mg/L),, Turbidity (NTU),,, Mean TP for LF,, Geomean of Ecoli all,,, TP - DP, DP %, mnBF_Turb

--want to:
-merge with 2019 data
-done with copy/paste in xlsx files

2019: Sample Number, Location, Date, QA, Final E. Coli.(mpn/100ml), TN (mg-N/l), TP(ug P/L), TDP (ug P/L), TSS (mg/L), Turbidity (NTU)

--want to:
-merge with 2019 data
-done with copy/paste in xlsx files

2021:   Lab Project ID, Sample Type, Lab Sample ID, Parent Sample, Client Sample ID, Collected On, Year, Month, Day, Collected By, Analyte, Method, Result, UOM, Rem, Min, Max, Analyzed On, Analyzed By, Reporting Limit, Code, Size, Type, FIPS, Comments

--want to:
-merge with 1997-2017 dataset
-done with copy/paste in xlsx files*/

/* Actions taken on 1992-2017+2021 combined table:

--want to:
-extract observationns by 'characteristicid'
-join extracted tables into new table
-discard E. coli observations

--deleted suffix (ex. 523105-R-LCC0.3 to LCC0.3) inlocationid on all 2021 obervations, moved corrected locationid to larosasiteid where larosasiteid = NULL

IMPORT AS: slimtable*/

SELECT DISTINCT characteristicid
FROM slimtable;

/*characteristicid
NOx       Nitrate
Total Nitrogen
Ecoli
TNOX      Total Nitrate/Nitrite Nitrogen (mg/l)
RegAlk    Alkalinity
TN        Total Nitrogen (mg/l)
TurbNTU   Turbidity
TSS       Total Suspended Solids (mg/l)
Total Phosphorus
Chloride
DP        Dissolved Phosphorus (ug/l)
TP

Pairs:
-TN / Total Nitrogen
-TP / Total Phosphorus

unpaired:
-Chloride
-TurbNTU
-DP
-NOx
-TNOX
-RegAlk
-TSS

taking:
-TN/Total Nitrogen
-TP/Total Phosphorus
-DP
-TSS
-TurbNTU
*/

SELECT *
FROM slimtable
WHERE characteristicid = 'TN'
OR
characteristicid = 'Total Nitrogen';

/*1419 rows*/

SELECT larosasiteid AS location, visitdate AS date, result AS total_nitrogen, characteristicid, unitcode AS unit
FROM slimtable
WHERE characteristicid = 'TN'
OR
characteristicid = 'Total Nitrogen';

/*1419 rows*/

CREATE TABLE total_nitrogenisolated AS
SELECT larosasiteid AS location, visitdate AS date, result AS total_nitrogen, characteristicid, unitcode AS unit
FROM slimtable
WHERE characteristicid = 'TN'
OR
characteristicid = 'Total Nitrogen';

/*export tables in csv*/

SELECT larosasiteid AS location, visitdate AS date, result AS total_phosphorus, characteristicid, unitcode AS unit
FROM slimtable
WHERE characteristicid = 'TP'
OR
characteristicid = 'Total Phosphorus';

/*4155 rows*/

CREATE TABLE total_phosphorusisolated AS
SELECT larosasiteid AS location, visitdate AS date, result AS total_phosphorus, characteristicid, unitcode AS unit
FROM slimtable
WHERE characteristicid = 'TP'
OR
characteristicid = 'Total Phosphorus';

/*export table as csv*/

SELECT larosasiteid AS location, visitdate AS date, result AS dissolved_phosphorus, characteristicid, unitcode AS unit
FROM slimtable
WHERE characteristicid = 'DP';

/*700 rows*/

CREATE TABLE dissolved_phosphorusisolated AS
SELECT larosasiteid AS location, visitdate AS date, result AS dissolved_phosphorus, characteristicid, unitcode AS unit
FROM slimtable
WHERE characteristicid = 'DP';

/*export table as csv*/

SELECT larosasiteid AS location, visitdate AS date, result AS total_suspended_solids, characteristicid, unitcode AS unit
FROM slimtable
WHERE characteristicid = 'TSS';

/*690 rows*/

CREATE TABLE total_suspended_solidsisolated AS
SELECT larosasiteid AS location, visitdate AS date, result AS total_suspended_solids, characteristicid, unitcode AS unit
FROM slimtable
WHERE characteristicid = 'TSS';

/*export as csv*/

SELECT larosasiteid AS location, visitdate AS date, result AS turbidity, characteristicid, unitcode AS unit
FROM slimtable
WHERE characteristicid = 'TurbNTU';

/*1708 rows*/

CREATE TABLE turbidityisolated AS
SELECT larosasiteid AS location, visitdate AS date, result AS turbidity, characteristicid, unitcode AS unit
FROM slimtable
WHERE characteristicid = 'TurbNTU';

/*export as csv*/

CREATE TABlE expandedslimtable AS
SELECT *
FROM total_phosphorusisolated;

/*picking the longest table to join everything to..... and hoping it just works*/

CREATE TABLE expandedslimtablea AS
SELECT expandedslimtable.*, turbidityisolated.turbidity
FROM expandedslimtable FULL OUTER JOIN turbidityisolated
ON expandedslimtable.location = turbidityisolated.location AND expandedslimtable.date = turbidityisolated.date;

CREATE TABLE expandedslimtableb AS
SELECT expandedslimtablea.*, total_suspended_solidsisolated.total_suspended_solids
FROM expandedslimtablea FULL OUTER JOIN total_suspended_solidsisolated
ON expandedslimtablea.location = total_suspended_solidsisolated.location AND expandedslimtablea.date = total_suspended_solidsisolated.date;

CREATE TABLE expandedslimtablec AS
SELECT expandedslimtableb.*, dissolved_phosphorusisolated.dissolved_phosphorus
FROM expandedslimtableb FULL OUTER JOIN dissolved_phosphorusisolated
ON expandedslimtableb.location = dissolved_phosphorusisolated.location AND expandedslimtableb.date = dissolved_phosphorusisolated.date;

CREATE TABLE expandedslimtablefinal AS
SELECT expandedslimtablec.*, total_nitrogenisolated.total_nitrogen
FROM expandedslimtablec FULL OUTER JOIN total_nitrogenisolated
ON expandedslimtablec.location = total_nitrogenisolated.location AND expandedslimtablec.date = total_nitrogenisolated.date;

/*export as csv, 5248 rows*/

SELECT *
FROM expandedslimtablefinal
WHERE location = 'NULL';

/*0 rows, meaning that no data got left behind in other tables*/

SELECT DISTINCT "visitdate", "locationid"
FROM slimtable

/*4381 rows, meaning we may have picked up some data*/

/*did pick up some data, 2016 and 2017 have some duplicate instances (ex. multiple readings of TP, etc.) which caused there to be up to 32 instances of unique sets of variables with the same date and location marker. This occured in 25 instances. Removed later in R analysis.*/

/*next step is to join the 2018-2019 data with the expandedslimtablefinal data, probably will just use xlsx copy
