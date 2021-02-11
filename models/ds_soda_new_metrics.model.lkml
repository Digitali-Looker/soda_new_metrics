
connection: "soda_new_metrics"

include: "/[!model]*/*"

datagroup: ds_soda_new_metrics_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: ds_soda_new_metrics_default_datagroup


explore:  ds_paneldata {
 from: ds_paneldata_ext
 label: "Test Explore for New Metrics DS version"


join: metadata {
  relationship: many_to_one
  #sql_on: coalesce(${ds_paneldata.episodeid},${ds_paneldata.netflixid})=coalesce(${metadata.nfepisodeid},${metadata.nftitleid});;
  ##coalesce above will allow titles that don't have episode info in API yet to at least provide title link, can be excluded by adding sql_always_where in the model
  foreign_key: ds_paneldata.FK_Metadata
}

join: ds_weights_streams_ext {
  relationship: many_to_one
 # sql_on: ${ds_paneldata.rid}=${ds_weights_streams_ext.rid} and ${ds_paneldata.dateviewed_date}=${ds_weights_streams_ext.dateofactivity_date} ;;
  foreign_key: ds_paneldata.FK_Weights_Streams
}



    join: weights_reach {
    relationship: many_to_one
    sql_on:
    concat_ws(', ',${ds_paneldata.rid},${ds_paneldata.profileid},${ds_paneldata.sample_date_d_final})=
    concat_ws(', ',${weights_reach.rid},${weights_reach.profileid},${weights_reach.dateofactivity}) ;;
  }

join: demoinfo {
  relationship: many_to_one
  foreign_key: ds_paneldata.rid
}

}




  # join: ds_weights_reach_ext {
  #   relationship: many_to_one
  #   # sql_on: ${ds_paneldata.rid}=${ds_weights_streams_ext.rid} and ${ds_paneldata.dateviewed_date}=${ds_weights_streams_ext.dateofactivity_date} ;;
  #   foreign_key: ds_paneldata.FK_Weights_Reach
  # }

  # join: weights_reach {
  #   relationship: many_to_one
  #   sql_on: {% if ds_paneldata.sample_date_d_final._in_query %}
  #   concat_ws(', ',${ds_paneldata.rid},${ds_paneldata.profileid},${ds_paneldata.sample_date_d_final})=
  #   concat_ws(', ',${weights_reach.rid},${weights_reach.profileid},${weights_reach.dateofactivity})
  #   {% else %}
  #   concat_ws(', ',${ds_paneldata.rid},${ds_paneldata.profileid},'1')=
  #   concat_ws(', ',${weights_reach.rid},${weights_reach.profileid},'1')
  #   {% endif %};;
  # }
