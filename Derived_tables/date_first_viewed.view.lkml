view: date_first_viewed {
  derived_table: {
explore_source: ds_metadata_only{
column: nftitleid {field:nftitleid}
column: nfepisodeid {field:nfepisodeid}
column: nfseasonnumber {field:nfseasonnumber}
column: nfepisodenumber {field:nfepisodenumber}
# column: account_country {} ## to be added when have more than 1 country
column: countryviewed {field:paneldata.countryviewed}
column: dateviewed {field:paneldata.dateviewed_date}
derived_column: min_date {
  sql: min(dateviewed) over (partition by
  nftitleid,
  {% if nfseasonnumber._is_selected or ds_metadata_ext.content_name_granularity._parameter_value == "'season'" %} nfseasonnumber {% esle %} 1 {% endif %},
  {% if nfepisodenumber._is_selected or ds_metadata_ext.content_name_granularity._parameter_value == "'episode'" %} nfepisodenumber {% esle %} 1 {% endif %},
  {% if paneldata.countryviewed._is_selected %} countryviewed {% esle %} 1 {% endif %}
  ) ;;
}

bind_filters: {
  from_field: ds_paneldata_ext.countryviewed
  to_field: countryviewed
}
}
  }
  dimension: nftitleid {
    hidden: yes
  }

  dimension: nfepisodeid {
    hidden: yes
  }

  dimension: min_date {
    view_label: "METADATA"
    label: "Date First Viewed"
    type: date
  }
  }
