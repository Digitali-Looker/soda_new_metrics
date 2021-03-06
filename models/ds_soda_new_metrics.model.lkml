
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
;;
# and ${metadata.nftitleid} is not null


# always_join: [metadata]
###### always join shouldn't include any weights table as dynamic targeting table relies on untouched set of viewing rows
## if any joins require other joins to happen use required joins param


join: metadata {
  from: ds_metadata_ext
  relationship: many_to_one
  sql_on: ${ds_paneldata.episodeid}=${metadata.nfepisodeid} and ${ds_paneldata.netflixid}=${metadata.nftitleid};;
  ##coalesce above will allow titles that don't have episode info in API yet to at least provide title link, can be excluded by adding sql_always_where in the model
  # foreign_key: ds_paneldata.FK_Metadata
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
  sql_on: ${ds_paneldata.rid}=${weights_reach.rid} and ${ds_paneldata.profileid}=${weights_reach.profileid}
  and ${ds_paneldata.sample_date_d_final}=${weights_reach.dateofactivity}
  and ${ds_paneldata.bookmark_mins}>= {% parameter ds_paneldata.minutes_threshold %};;
  sql_where: (${weights_reach.weight}>0 or ${ds_weights_streams_ext.weight}>0) ;;
  ### -- This sql where excludes cases where viewing registered was from a person that's both outside current sample for reach
  ##  and didn't have weight at the date of viewing (joined panel later than that date)
  ######  former join: concat_ws(', ',${ds_paneldata.rid},${ds_paneldata.profileid},${ds_paneldata.sample_date_d_final})=
  ######  concat_ws(', ',${weights_reach.rid},${weights_reach.profileid},${weights_reach.dateofactivity})
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

join: pop_size {
  relationship: many_to_one
  sql_on: ${pop_size.dateofactivity}=${ds_paneldata.sample_date_d_final} and ${pop_size.demoid}=${demoinfo.demoid};;
}

join: dynamic_targeting {
  relationship: many_to_one
  sql_on: ${ds_paneldata.rid}=${dynamic_targeting.rid} and ${ds_paneldata.profileid}=${dynamic_targeting.profileid} ;;
  type: inner
}


}







####### -- Notes for the prod version
#----1) There will be a few more fields to act as partitioning/joining fields, i.e. platformid, countrycode and country of panellist
#----2) Country of panellist and country code should be combined into 'native' vs 'non-native' viewing by viewing line.
#----This way there won't be confusion between spanish viewing from uk account or gb viewing from spanish for instance
#---And for date first viewed this will massively simplify things
