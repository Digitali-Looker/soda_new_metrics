view: reach_sample_date {
  derived_table: {
sql:
SELECT SELECTED_LIST,max(potentialsampledate) sample_date FROM
(
select DISTINCT
a.selected_list,to_date(a.dateviewed) potentialsampledate
from ${reach_ndt.SQL_TABLE_NAME} a
inner join (select selected_list, min(percentile) middlepercentile from ${reach_ndt.SQL_TABLE_NAME} WHERE percentile>=50 AND weight>0 group by 1) b
ON a.selected_list = b.selected_list AND a.percentile = b.middlepercentile
)
GROUP BY 1
;;
    }
dimension: selected_list {hidden:yes
  primary_key:yes}
dimension: sample_date {hidden:no}
  }
