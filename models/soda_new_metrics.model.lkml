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
  and ${dateviewed_date}< '{{ _user_attributes['soda_new_metrics_date_end'] }}'
  and ${bookmark_mins}>={% parameter paneldata.minutes_threshold %};;

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
  # foreign_key: paneldata.FK_Metadata
  sql_on: ${metadata.nfepisodeid}=${paneldata.episodeid} and ${metadata.nftitleid}=${paneldata.netflixid} ;;
}

join: reach_ndt {
  foreign_key: paneldata.diid
  # sql_on: ${paneldata.diid}=${reach_ndt.diid} and ${reach_ndt.bookmark_mins}>{% parameter paneldata.minutes_threshold %} ;;
  relationship: one_to_one
}

join: reach_sample_date {
  foreign_key: reach_ndt.selected_list
  relationship: many_to_one
}

  join: frequency_ndt {
    foreign_key: paneldata.diid
    # sql_on: ${paneldata.diid}=${reach_ndt.diid} and ${reach_ndt.bookmark_mins}>{% parameter paneldata.minutes_threshold %} ;;
    relationship: one_to_one
  }

join: weights_reach {
  sql_on: ${reach_ndt.rid}=${weights_reach.rid} and ${reach_ndt.profileid}=${weights_reach.profileid}
  and
    {% if paneldata.sample_date_overwrite._is_filtered %} ${weights_reach.dateofactivity}={% parameter paneldata.sample_date_overwrite%}
    {% else %}${reach_sample_date.sample_date}=${weights_reach.dateofactivity} {% endif %}
  and
  {% if paneldata.frequency_type._parameter_value == "'episodes'" %}
  ${frequency_ndt.frequency_episodes}>={% parameter paneldata.minimum_frequency %}
  {% else %} ${frequency_ndt.frequency_sessions}>={% parameter paneldata.minimum_frequency %} {% endif %};;
  relationship: many_to_one
}



}
