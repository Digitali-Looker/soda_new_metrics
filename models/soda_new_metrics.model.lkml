connection: "soda_new_metrics"


datagroup: soda_new_metrics_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: soda_new_metrics_default_datagroup


include: "/[!model]*/*"



#Test explore
explore: paneldata  {
  from:  paneldata_ext

  sql_always_where: ${rid} in (select distinct rid from core.weights)
  and ${dateviewed_date}>= '{{ _user_attributes['soda_new_metrics_date_start'] }}'
  and ${dateviewed_date}< '{{ _user_attributes['soda_new_metrics_date_end'] }}';;

join: weights {
  sql_on: ${paneldata.rid} = ${weights.rid} and ${paneldata.dateviewed_date} = ${weights.dateofactivity_date} ;;
  relationship: many_to_one
}

join: demoinfo {
  relationship: many_to_one
sql_on: ${paneldata.rid}=${demoinfo.rid} ;;
}

join: metadata {
  relationship: many_to_one
  foreign_key: paneldata.FK_Metadata
}

join: reach_ndt {
  foreign_key: paneldata.diid
  relationship: one_to_one
}

join: reach_sample_date {
  foreign_key: reach_ndt.selected_list
  relationship: many_to_one
}

join: weights_reach {
  sql_on: ${reach_ndt.rid}=${weights_reach.rid} and ${reach_ndt.profileid}=${weights_reach.profileid} and ${reach_sample_date.sample_date}=${weights_reach.dateofactivity} ;;
  relationship: many_to_one
}

}
