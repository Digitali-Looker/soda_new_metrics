include: "/[!model]*/*"

#####################################################################################################################################################
##This view is the extension of the base paneldata view.
##Most calculations are to be written here to avoid invoking simmetric aggregate where possible (will still have to kick in for reach because of the nature of that measure)

view: ds_paneldata_ext {
  extends: [paneldata]
  view_label: "PANELDATA"

#####################################################################################################################################################
##    AMENDMENTS OF BASE VIEW DIMENSIONS


#----------Disable filtering of dateviewed field that comes in varius date groups - this is to be replaced with a separate date filter, so
#---that all filtering happens on a single field that's then referenced acrossed the model, this solves the issue we had in Netflix_int
#---where putting date_week or any other extension that date_date breaks some calculations cause only date_date is mentioned in derived tables and calcs
  dimension_group: dateviewed {
    can_filter: no
  }

##
#####################################################################################################################################################


#####################################################################################################################################################
##    FILTERS & params


###------Simple filter for date - limit to day level, sql consition means that user input is applied to the field dateviewed
 filter: date_viewed {
  type: date
   suggest_dimension: dateviewed_raw
   sql: {% condition date_viewed %}
    ${dateviewed_raw}
    {% endcondition %};;
 }

###----This is the parameter for 2 ways of calculating Reach,
##-----Reach is written in the way that by default it calcs on an account level, but adding this switch allows to chage to profile and back
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


#####-----These are parameters for averaging available to the user, we can add more - they will need to be referenced in a avg_breakdown_by dimension
##----- that provides the list of fields to add to sql_distinct_key for the main calc
parameter: average_by {
  allowed_value: {
    label: "Episode"
    value: "episode"
  }
  allowed_value: {
    label: "Season"
    value: "season"
  }
  allowed_value: {
    label: "Title"
    value: "title"
  }
  allowed_value: {
    label: "Year"
    value: "year"
  }
  allowed_value: {
    label: "Year & Quarter"
    value: "year_quarter"
  }
  allowed_value: {
    label: "Quarter"
    value: "quarter"
  }
  allowed_value: {
    label: "Month"
    value: "month"
  }
  allowed_value: {
    label: "Week"
    value: "week"
  }
  allowed_value: {
    label: "Day"
    value: "day"
  }
}

###------Very important - this needs to be consistent with the list of allowed values in the parameter above
##-------Note how date fields need to be descriptive of the level - quarter is Q1,Q2 etc, whereas Year&Quarter is 2020-Q1, 2020-Q2 etc
##-----This field is referenced in Avg_Reach calculations below to provide a unique identifier for each level of detail that sum_distinct will rely on
##-----in addition to main fields of rid, [profileid], sampledate
dimension: avg_breakdown_by {
sql: {% if average_by._parameter_value == "'episode'" %} concat_ws(', ',metadata.nftitleid, metadata.nfseasonnumber, metadata.nfepisodenumber)
{% elsif average_by._parameter_value == "'season'" %} concat_ws(', ',metadata.nftitleid, metadata.nfseasonnumber)
{% elsif average_by._parameter_value == "'title'" %} concat_ws(', ',metadata.nftitleid)
{% elsif average_by._parameter_value == "'year'" %} concat_ws(', ',year(dateviewed))
{% elsif average_by._parameter_value == "'year_quarter'" %} concat_ws(', ',date_trunc('quarter',dateviewed))
{% elsif average_by._parameter_value == "'quarter'" %} concat_ws(', ',quarter(dateviewed))
{% elsif average_by._parameter_value == "'month'" %} concat_ws(', ',month(dateviewed))
{% elsif average_by._parameter_value == "'week'" %} concat_ws(', ',date_trunc('week',dateviewed))
{% elsif average_by._parameter_value == "'day'" %} concat_ws(', ',to_date(dateviewed))
{% else %}  {% endif %}
;;
}


##
#####################################################################################################################################################



#####################################################################################################################################################
## SAMPLE DATE AND REACH JOIN DIMENSIONS

##----One of the most important elements of the new methodology is a sample date for Reach, it should be dynamic to represent the end of the period
##----for each part of the breakdown, but it can't be a measure, because one measure (Reach) can't reference another measure, a measure also can't be used in join

##----The solution- keep it dimensional, since the main Reach logic doesn't depend on what breakdowns are thrown to it, the only set of scenarios we need to
##----consider is whether we take a differnt sample date for each year in the breakdown or whether we use a single date (weights are then fixed at high, not cool)

##---so the only breakdown that matters is by date variations (MAKE SURE IF YOU ADD ANY MORE TIMEFRAMES FOR DATEVIEWED TO REPRESENT THEM HERE)
##---this means we can write the logic for each scenario
##---even better, cause our logic is always latest date within the period - ie last day of year, month, week etc, we can calculate them detached from what dates have actually been viewed
##---so for each row with it's date we'd determine this date's relative last day of year/month/week etc by a simple sequence of
##--- take the date (ie 11/02/20), truncate to desired level (01/01/2020 for year), add 1 to the level (+1 year => 01/01/2021) and take away 1 day (31/12/20)
##---example for month will be (11/02/20), truncate to month (01/02/2020), add 1 to the level (+1 month => 01/03/20) and take away 1 day (29/02/20)


  dimension: sample_date_d {
    type: date
    label: "testing field"
    sql: {% if dateviewed_year._is_selected %}
      dateadd(day,-1,dateadd(year,1,(date_trunc(year,${dateviewed_raw}))))
      {% elsif dateviewed_quarter._is_selected or dateviewed_quarter_of_year._is_selected %}
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
      {% if date_viewed._is_filtered %} {% date_end date_viewed %} {% else %} '{{ _user_attributes['soda_new_metrics_date_end'] }}' {% endif %}
      {% endif %};;
    hidden: yes
  }



##------on the previous step you must have wondered "what about today for instance" 11/02/21 would take us to 31/12/21 for end of year which is in the future
##----so we need to adjust the sample date to always sit within the extremes of either available data (user attributes) or a selection driven by the data filter
##----below looks at whether filter is applied (in which case boundaries are set by filter
##---- if its not applied then boundaries are determined by user attributes (important to keep admin up to date for all client users!)
##----the logic is simple - if sample date calculated above is cool with the boundaries, just take it, if it's before start date - overwrite it with
##-- the start date (of user attributes or filter respectively),
##-- same for if sample date is on or after then end date - overwrite with end date


## This is correction for when max date of a date part (week, quarter etc) is outside the filter, to not show 0 it will take either end of the filter
  dimension: sample_date_d_final {
    type: date
    label: "Sample Date Dimension"
    sql:{% if date_viewed._is_filtered %}
    case when {% condition date_viewed %} ${sample_date_d} {% endcondition %} then ${sample_date_d}
    when ${sample_date_d}<{% date_start date_viewed %} then {% date_start date_viewed %}
    when ${sample_date_d}>={% date_end date_viewed %} then dateadd(day,-1,{% date_end date_viewed %}) end
    {% else %}
    case when ${sample_date_d}< '{{ _user_attributes['soda_new_metrics_date_start'] }}' then '{{ _user_attributes['soda_new_metrics_date_start'] }}'
    when ${sample_date_d}>='{{ _user_attributes['soda_new_metrics_date_end'] }}' then dateadd(day,-1,'{{ _user_attributes['soda_new_metrics_date_end'] }}')
    else ${sample_date_d} end
    {% endif %}
    ;;
  }

##----This is just for easier referencing, so that don't have to type in view name all the time
dimension: weight_for_reach {
  type: number
  sql: ${weights_reach.weight} ;;
}



##
#####################################################################################################################################################


#####################################################################################################################################################
##    MEASURES


##---Streams is as simle as summarizing the weights of the original base view (extended in case we need to add any decorative fields)
##---As it's joined on rid, date there should be no ambiguity
measure: Streams {
  value_format: "# ### ### ##0\" K\""
  type: sum
  sql: ${ds_weights_streams_ext.weight} ;;
}



#-----------------REACH

measure: Reach_Account {
  value_format: "# ### ### ##0\" K\""
  type: sum_distinct
  # sql_distinct_key: concat_ws(', ',${ds_weights_reach_ext.rid},${ds_weights_reach_ext.dateofactivity_date}) ;;
  sql_distinct_key:
  concat_ws(', ',${weights_reach.rid},${weights_reach.dateofactivity});;
  sql: ${weight_for_reach} ;;
  hidden: yes
}


  measure: Reach_Profile {
    value_format: "# ### ### ##0\" K\""
    type: sum_distinct
    # sql_distinct_key: concat_ws(', ',${ds_weights_reach_ext.rid},${ds_weights_reach_ext.dateofactivity_date}) ;;
    sql_distinct_key:
      concat_ws(', ',${weights_reach.rid},${weights_reach.profileid},${weights_reach.dateofactivity});;
    sql: ${weight_for_reach} ;;
    hidden: yes
  }

measure: Reach {
  value_format: "# ### ### ##0\" K\""
  type: number
  sql: {% if reach_account_granularity._parameter_value == "'profile'" %} ${Reach_Profile} {% else %} ${Reach_Account} {% endif %} ;;
  # html: {{value}} {{reach_account_granularity._parameter_value}} ;; ##This is just to check if liquid picks up the param value, for some reason it needed both sets of quotes around the value, which is weird
}

#------------------------------

  measure: sample_size {
    type: number
    label: "Sample size (Reach)"
    description: "Number of Households involved in Reach calculation"
    sql: count(distinct ${weights_reach.rid}) ;;
    html: {% if {{value}} < 5 %} {{rendered_value}} Low Sample! {% else %} {{rendered_value}} {% endif %};;
}

#-----------------------------AVERAGE REACH
#### By defaul average reach calculation counts cases where there was some viewing on the date (week/title whatever),
##but that viewing was from outside the sample as 0, hence cutting the totals by quite a lot
##as this happens cause of the calculation taking into account rows originating from paneldata, I've added a couple of conditions below (Avg_Reach)
##If the whole sum comes base as 0 it nulls it, if only part of the components (some days when averaged by day but we're looking at total number)
##come back as 0s then we just need to adjust the denominator (so it does't take into account the unique identifier(avg_breakdown_by) for those rows)


  measure: Avg_Reach_Account {
    value_format: "# ### ### ##0\" K\""
    type: sum_distinct
    # sql_distinct_key: concat_ws(', ',${ds_weights_reach_ext.rid},${ds_weights_reach_ext.dateofactivity_date}) ;;
    sql_distinct_key:
      concat_ws(', ',${weights_reach.rid},${weights_reach.dateofactivity},${avg_breakdown_by});;
    sql: ${weight_for_reach} ;;
    hidden: yes
  }


  measure: Avg_Reach_Profile {
    value_format: "# ### ### ##0\" K\""
    type: sum_distinct
    # sql_distinct_key: concat_ws(', ',${ds_weights_reach_ext.rid},${ds_weights_reach_ext.dateofactivity_date}) ;;
    sql_distinct_key:
      concat_ws(', ',${weights_reach.rid},${weights_reach.profileid},${weights_reach.dateofactivity},${avg_breakdown_by});;
    sql: ${weight_for_reach};;
    hidden: yes
  }

  measure: Avg_Reach {
    value_format: "# ### ### ##0\" K\""
    type: number
    sql:
    {% if average_by._is_selected %}
                {% if reach_account_granularity._parameter_value == "'profile'" %}
               case when count(weights_reach.rid)  = 0 then null else ${Avg_Reach_Profile}/count(distinct (case when weights_reach.rid is null then null else ${avg_breakdown_by} end)) end
                {% else %}
                case when count(weights_reach.rid)  = 0 then null else ${Avg_Reach_Account}/count(distinct (case when weights_reach.rid is null then null else ${avg_breakdown_by} end) ) end
                {% endif %}
    {% else %}
    1
    {% endif %}
    ;;
    html: {% if average_by._is_selected %} {{rendered_value}} {% else %} Please add an averaging parameter {% endif %}  ;;
  }


#----------------------------------------------

##
#####################################################################################################################################################



#####################################################################################################################################################
##     DIMENSIONS






}



  # dimension: FK_Weights_Reach_full {
  #   sql: concat_ws(', ', ${rid}, ${profileid},${sample_date_d_final}) ;;
  #   hidden: yes
  # }

  # dimension: FK_Weights_Reach_no_date {
  #   sql:concat_ws(', ', ${rid}, ${profileid});;
  #   hidden: yes
  # }
