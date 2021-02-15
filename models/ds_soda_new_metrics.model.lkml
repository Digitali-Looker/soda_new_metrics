
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
sql_always_where: ${rid} in (select distinct rid from core.weights)
and ${dateviewed_date}>= '{{ _user_attributes['soda_new_metrics_date_start'] }}'
and ${dateviewed_date}< '{{ _user_attributes['soda_new_metrics_date_end'] }}'
and ${metadata.nftitleid} is not null -- to exclude cases where the panellist watched smth within period, but they neither had a weight for that period, nor included in sample for reach
;;

always_join: [metadata, ds_weights_streams_ext]

join: metadata {
  from: ds_metadata_ext
  relationship: many_to_one
  #sql_on: coalesce(${ds_paneldata.episodeid},${ds_paneldata.netflixid})=coalesce(${metadata.nfepisodeid},${metadata.nftitleid});;
  ##coalesce above will allow titles that don't have episode info in API yet to at least provide title link, can be excluded by adding sql_always_where in the model
  foreign_key: ds_paneldata.FK_Metadata
}

######------------- Weights are joined twice - from the full table directly to provide streams (take actual weight on the day of viewing, new panellist
##---enter the panel with 0 for weights on older dates so that historical stream values don't change

join: ds_weights_streams_ext {
  relationship: many_to_one
 # sql_on: ${ds_paneldata.rid}=${ds_weights_streams_ext.rid} and ${ds_paneldata.dateviewed_date}=${ds_weights_streams_ext.dateofactivity_date} ;;
  foreign_key: ds_paneldata.FK_Weights_Streams
  sql_where: {% if weights_reach.*._in_query %} 1=1 {% else %} ${ds_weights_streams_ext.weight}>0 {% endif %};;
  ##### -- This sql where condition allows to control whether to show 0 stream entries or not - they should only appear when anything Reach related is selected as well
  ### -- so if any field from reach weights is present, don't apply this condition, if none - limit to only rows that have some streams
}

##-----second time the weight are joined from the derived table that adds a profileid in
##--(if profileid is added at the DB level, this can simply be another extension from the base table)
##--this join happens on a fixed sample date (or set of sample dates for a date breakdown)
##--the weights drawn from this join are used for calculating Reach related metrics

  join: weights_reach {
  relationship: many_to_one
  sql_on:
  concat_ws(', ',${ds_paneldata.rid},${ds_paneldata.profileid},${ds_paneldata.sample_date_d_final})=
  concat_ws(', ',${weights_reach.rid},${weights_reach.profileid},${weights_reach.dateofactivity}) ;;
  sql_where: (${weights_reach.weight}>0 or ${ds_weights_streams_ext.weight}>0) ;;
  ### -- This sql where excludes cases where viewing registered was from a person that's both outside current sample for reach
  ##  and didn't have weight at the date of viewing (joined panel later than that date)
}

###########

join: demoinfo {
  relationship: many_to_one
  foreign_key: ds_paneldata.rid
}

join: date_first_viewed {
  sql_on: coalesce(${ds_paneldata.episodeid},${ds_paneldata.netflixid})=coalesce(${date_first_viewed.nfepisodeid},${date_first_viewed.nftitleid})
  {% if ds_paneldata.countryviewed._is_selected %} and ${ds_paneldata.countryviewed}=${date_first_viewed.countryviewed} {% endif %} ;;
  relationship: many_to_one
}

}
