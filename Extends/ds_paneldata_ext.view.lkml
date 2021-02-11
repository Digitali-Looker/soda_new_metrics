include: "/[!model]*/*"

view: ds_paneldata_ext {
  extends: [paneldata]
  view_label: "PANELDATA"

#####################################################################################################################################################
##    AMENDMENTS OF BASE VIEW DIMENSIONS



  dimension_group: dateviewed {
    can_filter: no
  }

##
#####################################################################################################################################################


#####################################################################################################################################################
##    FILTERS & params



 filter: date_viewed {
  type: date
   suggest_dimension: dateviewed_raw
   default_value: " < (TO_TIMESTAMP('2021-01-01'))"
   sql: {% condition date_viewed %}
${dateviewed_raw}
{% endcondition %} ;;
 }

parameter: reach_account_granularity {
  # default_value: "rid"
  allowed_value: {
    label: "Profile"
    value: "profile"
  }
  allowed_value: {
    label: "Account"
    value: "rid"
  }
}

##
#####################################################################################################################################################



#####################################################################################################################################################
## SAMPLE DATE AND REACH JOIN DIMENSIONS

  # measure: sample_date_m {
  #   type: date
  #   label: "sample date"
  #   description: "max_date within selection"
  #   sql:
  #   max(${dateviewed_date}) ;;
  # }

  dimension: sample_date_d {
    type: date
    label: "testing field"
    sql: {% if dateviewed_year._is_selected %}
      dateadd(day,-1,dateadd(year,1,(date_trunc(year,${dateviewed_raw}))))
      {% elsif dateviewed_quarter._is_selected %}
      dateadd(day,-1,dateadd(quarter,1,(date_trunc(quarter,${dateviewed_raw}))))
      {% elsif dateviewed_month._is_selected %}
      dateadd(day,-1,dateadd(month,1,(date_trunc(month,${dateviewed_raw}))))
      {% elsif dateviewed_week._is_selected %}
      dateadd(day,-1,dateadd(week,1,(date_trunc(week,${dateviewed_raw}))))
      {% elsif dateviewed_date._is_selected %}
      ${dateviewed_date}
      {% elsif dateviewed_time._is_selected %}
      ${dateviewed_date}
      {% else %}
      {% date_end date_viewed %}
      {% endif %};;
    hidden: yes
  }

## This is correction for when max date of a date part (week, quarter etc) is outside the filter, to not show 0 it will take either end of the filter
  dimension: sample_date_d_final {
    type: date
    label: "Sample Date Dimension"
    sql: case when {% condition date_viewed %} ${sample_date_d} {% endcondition %} then ${sample_date_d}
    when ${sample_date_d}<{% date_start date_viewed %} then {% date_start date_viewed %}
    when ${sample_date_d}>={% date_end date_viewed %} then dateadd(day,-1,{% date_end date_viewed %}) end;;
  }


dimension: weight_for_reach {
  type: number
  sql: ${weights_reach.weight} ;;
}



##
#####################################################################################################################################################


#####################################################################################################################################################
##    MEASURES

measure: Streams {
  value_format: "# ### ### ##0\" K\""
  type: sum
  sql: ${ds_weights_streams_ext.weight} ;;
}

measure: Reach_Account {
  value_format: "# ### ### ##0\" K\""
  type: sum_distinct
  # sql_distinct_key: concat_ws(', ',${ds_weights_reach_ext.rid},${ds_weights_reach_ext.dateofactivity_date}) ;;
  sql_distinct_key:
  concat_ws(', ',${weights_reach.rid},${weights_reach.dateofactivity});;
  sql: ${weight_for_reach} ;;
  # hidden: yes
}


  measure: Reach_Profile {
    value_format: "# ### ### ##0\" K\""
    type: sum_distinct
    # sql_distinct_key: concat_ws(', ',${ds_weights_reach_ext.rid},${ds_weights_reach_ext.dateofactivity_date}) ;;
    sql_distinct_key:
      concat_ws(', ',${weights_reach.rid},${weights_reach.profileid},${weights_reach.dateofactivity});;
    sql: ${weight_for_reach} ;;
    # hidden: yes
  }

measure: Reach {
  value_format: "# ### ### ##0\" K\""
  type: number
  sql: {% if reach_account_granularity._parameter_value == "'profile'" %} ${Reach_Profile} {% else %} ${Reach_Account} {% endif %} ;;
  # html: {{value}} {{reach_account_granularity._parameter_value}} ;; ##This is just to check if liquid picks up the param value, for some reason it needed both sets of quotes around the value, which is weird
}


}



  # dimension: FK_Weights_Reach_full {
  #   sql: concat_ws(', ', ${rid}, ${profileid},${sample_date_d_final}) ;;
  #   hidden: yes
  # }

  # dimension: FK_Weights_Reach_no_date {
  #   sql:concat_ws(', ', ${rid}, ${profileid});;
  #   hidden: yes
  # }
