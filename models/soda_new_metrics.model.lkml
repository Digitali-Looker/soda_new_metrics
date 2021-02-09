connection: "soda_new_metrics"


datagroup: soda_new_metrics_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: soda_new_metrics_default_datagroup


include: "/*/*"



#Test explore
explore: paneldata  {

join: weights {
  sql_on: ${paneldata.rid} = ${paneldata.rid} and ${paneldata.dateviewed_date} = ${weights.dateofactivity_date} ;;
  relationship: many_to_one
}

}
