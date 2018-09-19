#!/bin/bash

spark-sql --master yarn --queue root.B --num-executors 400 --executor-cores 3 --executor-memory 10G -e "
	create table dfgx_tour_db.sz_travel_user_info_2018gq AS SELECT o.isdn, o.province, o.from_city, o.to_city, CASE WHEN o.first_traffic=1 THEN '飞机' WHEN o.first_traffic=2 THEN '火车' WHEN o.first_traffic=3 THEN '汽车' END AS traffic_type,o.first_day,o.last_day,o.stay_time,case WHEN n.age_type='' OR n.age_type is NULL THEN '未知' ELSE n.age_type END AS age_type,nvl(n.sex_type,'未知') AS sex_type FROM(SELECT m.isdn, m.province, m.from_city, m.to_city, m.first_traffic, m.first_day, m.last_day, m.stay_time FROM (SELECT l.isdn, l.province, l.from_city, l.to_city, l.type, first_value(l.traffic_type) over(partition by l.isdn, l.type ORDER BY l.t_time) AS first_traffic,split(first_time,' ')[0] AS first_day,split(last_time,' ')[0] AS last_day,l.stay_time FROM (SELECT k.isdn, k.t_time, k.province, k.from_city, k.to_city, k.type, k.traffic_type, k.first_time, k.last_time, datediff(case WHEN k.last_time < '2018-09-01 00:00:00' THEN '2018-09-01 00:00:00' ELSE k.last_time end,case WHEN k.first_time <'2018-09-01 00:00:00' THEN '2018-09-01 00:00:00' ELSE k.first_time end) AS stay_time FROM (SELECT j.isdn, j.t_time, j.lac, j.ci, j.province, j.from_city, j.to_city, j.type, j.traffic_type, first_value(j.t_time) OVER (partition by j.isdn,j.type ORDER BY j.t_time) AS first_time,last_value(j.t_time) over(partition by j.isdn,j.type ORDER BY j.t_time rows BETWEEN unbounded preceding AND unbounded following) AS last_time FROM (SELECT h.isdn, h.t_time, h.lac, h.ci, h.province, h.from_city, h.to_city, h.type, nvl (i.traffic_type, 0) AS traffic_type FROM (SELECT g.isdn, g.t_time, g.lac, g.ci, g.province, g.from_city, g.to_city, g.l_num, g.r_num, (g.l_num-g.r_num) AS type FROM (SELECT f.isdn, f.t_time, f.lac, f.ci, f.province, f.from_city, f.to_city, f.l_num, row_number() over(partition by f.isdn, f.to_city ORDER BY f.t_time,f.lac,f.ci) AS r_num FROM (SELECT e.isdn, e.t_time, e.lac, e.ci, e.province, e.from_city, e.to_city, row_number() over(partition by e.isdn ORDER BY e.t_time,e.lac,e.ci) AS l_num FROM (SELECT a.isdn, concat(concat_ws('-',a.year,lpad(a.month,2,0),lpad(a.day,2,0)),' ',regexp_replace (a.time,'-',':')) AS t_time,a.lac,a.ci,c.province,c.city AS from_city,d.city AS to_city FROM dfgx_tour_db.dfgx_brd_sdtp a JOIN dfgx_tour_db.to_sz_travel_people_2018gq b JOIN stq_location.stq_isdn_city_area_info c JOIN dfgx_tour_db.dfgx_lacci_info d ON a.isdn=b.isdn AND c.init_isdn=substr(a.isdn,1,7) AND d.lacci=concat(a.lac,a.ci) WHERE concat (a.deal_year,lpad(a.deal_month,2,0),lpad(a.deal_day,2,0))>='20180901' AND concat(a.deal_year,lpad(a.deal_month,2,0),lpad(a.deal_day,2,0))<='20180905' AND a.isdn <> '') e GROUP BY e.isdn,e.t_time,e.lac,e.ci,e.province,e.from_city,e.to_city) f WHERE f.to_city LIKE '%深圳%')g ORDER BY g.isdn,type) h LEFT JOIN dfgx_tour_db.dim_lac_ci_traffic_mapping i ON h.lac=conv(i.lac,10,16) AND h.ci=conv (i.ci,10,16)) j) k WHERE k.last_time >='2018-09-01 00:00:00') l WHERE l.traffic_type <> 0) m GROUP BY m.isdn,m.province,m.from_city,m.to_city,m.first_traffic,m.first_day,m.last_day,m.stay_time) o LEFT JOIN (SELECT SERIAL_NUMBER, sex, CASE WHEN age <=14 THEN '少年' WHEN age>=15 AND age<=24 THEN '青年' WHEN age>=25 AND age<=44 THEN '壮盛年' WHEN age>=45 AND age<=64 THEN '中年' WHEN age>=65 THEN '老年' END AS age_type,case WHEN sex LIKE '%M%' THEN '男' WHEN sex LIKE '%F%' THEN '女' ELSE '未知' END AS sex_type FROM dfgx_wo_db.dfgx_user_info) n ON o.isdn=n.SERIAL_NUMBER;
"