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
  view_label: "CALCULATIONS"
  type: date
   suggest_dimension: dateviewed_raw
   sql: {% condition date_viewed %}
    ${dateviewed_raw}
    {% endcondition %};;
 }


#####------Reach threshold
parameter: minutes_threshold{
  view_label: "CALCULATIONS"
  label: "Minutes threshold for Reach"
  description: "Minumum number of minutes in a session to qualify for Reach calculations (viewed at least this number of mins)"
  type: number
  default_value: "0"
}


####------Sample date overwrite
parameter: sample_date_overwrite {
  view_label: "CALCULATIONS"
  type: date
}


###----This is the parameter for 2 ways of calculating Reach,
##-----Reach is written in the way that by default it calcs on an account level, but adding this switch allows to chage to profile and back
parameter: reach_account_granularity {
  view_label: "CALCULATIONS"
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
  view_label: "CALCULATIONS"
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
  allowed_value: {
    label: "Hour of Day"
    value: "hour"
  }
  allowed_value: {
    label: "Day of Week"
    value: "day_of_week"
  }
}

###------Very important - this needs to be consistent with the list of allowed values in the parameter above
##-------Note how date fields need to be descriptive of the level - quarter is Q1,Q2 etc, whereas Year&Quarter is 2020-Q1, 2020-Q2 etc
##-----This field is referenced in Avg_Reach calculations below to provide a unique identifier for each level of detail that sum_distinct will rely on
##-----in addition to main fields of rid, [profileid], sampledate
dimension: avg_breakdown_by {
sql: {% if average_by._parameter_value == "'episode'" %} concat_ws(', ',metadata.nftitleid, ifnull(metadata.nfseasonnumber,1), ifnull(metadata.nfepisodenumber,1))
{% elsif average_by._parameter_value == "'season'" %} concat_ws(', ',metadata.nftitleid, ifnull(metadata.nfseasonnumber,1))
{% elsif average_by._parameter_value == "'title'" %} concat_ws(', ',metadata.nftitleid)
{% elsif average_by._parameter_value == "'year'" %} concat_ws(', ',year(dateviewed))
{% elsif average_by._parameter_value == "'year_quarter'" %} concat_ws(', ',date_trunc('quarter',dateviewed))
{% elsif average_by._parameter_value == "'quarter'" %} concat_ws(', ',quarter(dateviewed))
{% elsif average_by._parameter_value == "'month'" %} concat_ws(', ',month(dateviewed))
{% elsif average_by._parameter_value == "'week'" %} concat_ws(', ',date_trunc('week',dateviewed))
{% elsif average_by._parameter_value == "'day'" %} concat_ws(', ',to_date(dateviewed))
{% elsif average_by._parameter_value == "'hour'" %} concat_ws(', ',hour(dateviewed))
{% elsif average_by._parameter_value == "'day_of_week'" %} concat_ws(', ',date_part('weekday',dateviewed))
{% else %}  {% endif %}
;;
hidden: yes
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
    view_label: "CALCULATIONS"
    type: date
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
      {% else %}
      {% if date_viewed._is_filtered %} dateadd(day,-1,{% date_end date_viewed %}) {% else %} dateadd(day,-1,'{{ _user_attributes['soda_new_metrics_date_end'] }}') {% endif %}
      {% endif %};;
    hidden: yes
  }



######----This service dimension checks if any user defined value has been passed into the sample_date_overwrite parameter and if so
##---replaces pre-calculated value with a user-defined
dimension: sample_date_o {
  hidden: yes
  sql: {% if sample_date_overwrite._is_filtered %} to_date({% parameter sample_date_overwrite %}) {% else %} ${sample_date_d} {% endif %}  ;;
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
    view_label: "CALCULATIONS"
    type: date
    label: "Sample Date Dimension"
    sql:{% if date_viewed._is_filtered %}
    case when {% condition date_viewed %} ${sample_date_o} {% endcondition %} then ${sample_date_o}
    when ${sample_date_o}<{% date_start date_viewed %} then {% date_start date_viewed %}
    when ${sample_date_o}>={% date_end date_viewed %} then dateadd(day,-1,{% date_end date_viewed %}) end
    {% else %}
    case when ${sample_date_o}< '{{ _user_attributes['soda_new_metrics_date_start'] }}' then '{{ _user_attributes['soda_new_metrics_date_start'] }}'
    when ${sample_date_o}>='{{ _user_attributes['soda_new_metrics_date_end'] }}' then dateadd(day,-1,'{{ _user_attributes['soda_new_metrics_date_end'] }}')
    else ${sample_date_o} end
    {% endif %}
    ;;
  }

##----This is just for easier referencing, so that don't have to type in view name all the time
dimension: weight_for_reach {
  hidden: yes
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
  view_label: "CALCULATIONS"
  group_label: "STREAMS"
  label: "Streams"
  value_format: "# ### ### ##0\" K\""
  type: sum
  sql: ${ds_weights_streams_ext.weight} ;;
}




#-----------------REACH

##-----Below calculations for Reach consist of 3 parts: 1 calculates Reach for account level, one - for Profile level,
##-----and third is just a shell that decides which one to use depending on the parameter value


###----for account level we sum weights of distinct pairs respondantid+sampledate (sample_date = dateofctivity brought through from weights_reach table)
###----so this will allows us to avoid double-counting weights and as sample weight calculation is dynamic, the date breakdown will affect Reach accordingly

measure: Reach_Account {
  value_format: "# ### ### ##0\" K\""
  type: sum_distinct
  # sql_distinct_key: concat_ws(', ',${ds_weights_reach_ext.rid},${ds_weights_reach_ext.dateofactivity_date}) ;;
  sql_distinct_key:
  concat_ws(', ',${weights_reach.rid},${weights_reach.dateofactivity});;
  sql: ${weight_for_reach} ;;
  hidden: yes
}



####----Same logic as above, except we add one more partitioning field - Profileid. So for each profile within the HH the weight will be counted once more
  measure: Reach_Profile {
    value_format: "# ### ### ##0\" K\""
    type: sum_distinct
    # sql_distinct_key: concat_ws(', ',${ds_weights_reach_ext.rid},${ds_weights_reach_ext.dateofactivity_date}) ;;
    sql_distinct_key:
      concat_ws(', ',${weights_reach.rid},${weights_reach.profileid},${weights_reach.dateofactivity});;
    sql: ${weight_for_reach} ;;
    hidden: yes
  }




##--If the parameter is set to profile reach will refer to Reach_Profile, in all other cases (including when parameter is not selected at all it will go to account lvl)
measure: Reach {
  view_label: "CALCULATIONS"
  group_label: "REACH"
  value_format: "# ### ### ##0\" K\""
  type: number
  sql: {% if reach_account_granularity._parameter_value == "'profile'" %} ${Reach_Profile} {% else %} ${Reach_Account} {% endif %} ;;
  # html: {{value}} {{reach_account_granularity._parameter_value}} ;; ##This is just to check if liquid picks up the param value, for some reason it needed both sets of quotes around the value, which is weird
}





#############-----FREQUENCY

  measure: frequency_base_Account {
    # value_format: "# ### ### ##0\" K\""
    type: count_distinct
    view_label: "CALCULATIONS"
    group_label: "FREQUENCY"
    # sql_distinct_key: concat_ws(', ',${ds_weights_reach_ext.rid},${ds_weights_reach_ext.dateofactivity_date}) ;;
    # sql_distinct_key:  concat_ws(', ',${weights_reach.rid},${dateviewed_raw},COALESCE(${episodeid},${netflixid}));;
    sql:  concat_ws(', ',${weights_reach.rid},${dateviewed_raw},COALESCE(${episodeid},${netflixid}));;
    hidden: yes
  }



####----Same logic as above, except we add one more partitioning field - Profileid. So for each profile within the HH the weight will be counted once more
  measure: frequency_base_Profile {
    # value_format: "# ### ### ##0\" K\""
    type: count_distinct
    view_label: "CALCULATIONS"
    group_label: "FREQUENCY"
    # sql_distinct_key: concat_ws(', ',${ds_weights_reach_ext.rid},${ds_weights_reach_ext.dateofactivity_date}) ;;
    sql:concat_ws(', ',${weights_reach.rid},${weights_reach.profileid},${dateviewed_raw},COALESCE(${episodeid},${netflixid}));;
    # sql: ${weights_reach.frequencycounter} ;;
    hidden: yes
  }




##--If the parameter is set to profile reach will refer to Reach_Profile, in all other cases (including when parameter is not selected at all it will go to account lvl)
  measure: avg_frequency {
    view_label: "CALCULATIONS"
    group_label: "FREQUENCY"
    value_format: "0"
    type: number
    sql: {% if reach_account_granularity._parameter_value == "'profile'" %} ${frequency_base_Profile} {% else %} ${frequency_base_Account} {% endif %}/${sample_size} ;;
    # html: {{value}} {{reach_account_granularity._parameter_value}} ;; ##This is just to check if liquid picks up the param value, for some reason it needed both sets of quotes around the value, which is weird
  }






#------------------------------

##---For sample size we just count how many distict rids our join of the weight table for reach has brought through
##---If the figure is less then 5 print not just value, but also a warning
##---5 is a demo value, real threshold will need determining based on real sample with real weights
  measure: sample_size {
    view_label: "CALCULATIONS"
    type: number
    label: "Sample size (Reach)"
    description: "Number of Households involved in Reach calculation"
    sql: {% if reach_account_granularity._parameter_value == "'profile'" %} count(distinct ${weights_reach.profileid}) {% else %} count(distinct ${weights_reach.rid}) {% endif %} ;;
    html: {% if {{value}} < 5 %} {{rendered_value}} Low Sample! {% else %} {{rendered_value}} {% endif %};;
}


#-----------------------------AVERAGE REACH
###---Average reach basically follows same logic as normal reach (that is summing weights for distinct values of specified sets of fields)
##----except it needs to be calculated not at levels determined by what fields are in the data table, but at levels specified by a user in a parameter
##--- so apart from our normal rid, [profileid], sampledate we might want to add netflixid & seasonnumber for season level reach calculation,
##----or month of date-of-viewing for Reach pre-calculated for individual months
###----these pre-calculated values then need to be averaged across if the data table configuration is at a broader level
##----imagine you look at year by year and want to see an average monthly reach for each year
##----below avg_reach_account and avg_reach_profile measure will precalculate reach values for each individual month within the selection
##----the avg_reach measure will then average across these values for each year in the table by dividing the sum of reach figures for every month by a number of those months
##----to avoid writing a million scenarios for each averaging parameter within a mesure, they are all pre-configured by the Avg_Reach_Profile dimension described at the top
##----so that dimension not only determines what are the fields to take into consideration when pre-calculating reach for selected level, but also
##----how many distinct values there are that this sum needs to be divided by

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
    view_label: "CALCULATIONS"
    group_label: "REACH"
    value_format: "# ### ### ##0\" K\""
    type: number
    sql: {% if average_by._is_filtered %}
                {% if reach_account_granularity._parameter_value == "'profile'" %}
               case when count(weights_reach.rid)  = 0 then null else ${Avg_Reach_Profile}/count(distinct (case when weights_reach.rid is null then null else ${avg_breakdown_by} end)) end
                {% else %}
                case when count(weights_reach.rid)  = 0 then null else ${Avg_Reach_Account}/count(distinct (case when weights_reach.rid is null then null else ${avg_breakdown_by} end) ) end
                {% endif %}
        {% else %}
        1
        {% endif %}
    ;;
     html: {% if average_by._is_filtered %} {{rendered_value}} {% else %} Please add an averaging parameter {% endif %}  ;;
  }

####---------Why all the additional case when above?
#### By defaul average reach calculation counts cases where there was some viewing on the date (week/title whatever),
##but that viewing was from outside the sample as 0, hence cutting the totals by quite a lot
##as this happens cause of the calculation taking into account rows originating from paneldata, I've added a couple of conditions below (Avg_Reach)
##If the whole sum comes base as 0 it nulls it, if only part of the components (some days when averaged by day but we're looking at total number)
##come back as 0s then we just need to adjust the denominator (so it does't take into account the unique identifier(avg_breakdown_by) for those rows)



######--------------AVERAGE STREAMS

measure: Avg_Streams {
  view_label: "CALCULATIONS"
  group_label: "STREAMS"
  type: number
  value_format: "# ### ### ##0\" K\""
  sql: {% if average_by._is_filtered %} ${Streams}/count(distinct${avg_breakdown_by}) {% else %} ${Streams} {% endif %} ;;
  html: {% if average_by._is_filtered %} {{rendered_value}} {% else %} Please add an averaging parameter {% endif %}  ;;
  label: "Average Streams"
  description: "Average number of Streams by selected averaging parameter"
}


######--------------NUMBER OF DISTINCT EPISODES

measure: episodes_num {
  view_label: "CALCULATIONS"
sql: count(distinct concat_ws(', ',metadata.nftitleid, ifnull(metadata.nfseasonnumber,1), ifnull(metadata.nfepisodenumber,1))) ;;
label: "Number of Episodes viewed"
value_format: "0"
type: number
html: {% if metadata.nftitlename._is_selected or metadata.nftitleid._is_selected %} {{rendered_value}} {% else %} Please add title and/or titleid field {% endif %};;
}


######-------------MINUTES RELATED METRICS

measure: avg_viewing_rate {
  view_label: "CALCULATIONS"
  group_label: "TIME VIEWED"
  label: "Average Episode Viewing Rate %"
  type: average
  value_format: "0.00%"
  sql: case when ${ds_weights_streams_ext.weight}>0 then (${bookmark_mins}/${duration_mins}) else null end;;
  description: "What % of available duration (of an episode or a movie) is completed within a viewing session on average"
}

measure: total_minutes {
  view_label: "CALCULATIONS"
  group_label: "TIME VIEWED"
  label: "Total Minutes Viewed"
  type: sum
  value_format: "# ### ### ##0\" K mins\""
  sql: ${bookmark_mins}*${ds_weights_streams_ext.weight} ;;
  description: "Total number of weighted minutes"
}

measure: average_minutes_viewers{
  view_label: "CALCULATIONS"
  group_label: "TIME VIEWED"
  label: "Average Minutes 000s (Viewers)"
  type: number
  value_format: "0"
  sql: ${total_minutes}/${Reach};;
  # html: {% if average_by._is_filtered %} {{rendered_value}} {% else %} Please add an averaging parameter {% endif %}  ;;
  description: "Average number of minutes a person that watched content watched"
}

  measure: average_minutes_all{
    view_label: "CALCULATIONS"
    group_label: "TIME VIEWED"
    label: "Average Minutes 000s (All)"
    type: number
    value_format: "0"
    sql: ${total_minutes}/${pop_size};;
    # html: {% if average_by._is_filtered %} {{rendered_value}} {% else %} Please add an averaging parameter {% endif %}  ;;
    description: "Average number of minutes a person in general watched"
  }


measure: avg_000s {
  view_label: "CALCULATIONS"
  group_label: "TIME VIEWED"
  type: number
  label: "Average Minute Audience Size for content-based calculations"
  description: "This measure is similar to TV's average 000s and represents the audience size on an average minute of the content.
  As this measure is tied to available content durations captured by the viewing file, it is most relevant to content-based analysis.
  This field doesn't require an averaging parameter."
  sql: {% if metadata.*._in_query %} sum((${bookmark_mins}*${ds_weights_streams_ext.weight}))/(${content_average_duration}*${episodes_num})
  {% else %} 1 {% endif %};;
  value_format: "# ### ### ##0\" K\""
  html: {% if metadata.*._in_query %} {{rendered_value}} {% else %} Please add a content related field or use a different measure {% endif %} ;;
}


measure: avg_000s_time {
  view_label: "CALCULATIONS"
  group_label: "TIME VIEWED"
  type: number
  label: "Average Minute Audience Size for time-based calculations"
  description: "This measure is similar to TV's average 000s and represents the audience size on an average minute.
  This calculation is detached from content durations and is based on an absolute number of minutes within the selected time-frame."
  sql: sum((${bookmark_mins}*${ds_weights_streams_ext.weight}))/${duration_no_content} ;;
  value_format: "# ### ### ##0\" K\""
  html: {% if metadata.*._in_query %} Please remove a content related field or use a different measure {% else %} {{rendered_value}} {% endif %} ;;
}


measure: duration_no_content {
  view_label: "CALCULATIONS"
  group_label: "TIME VIEWED"
  label: "TEST duration when no content selected"
  sql: datediff(minute,date_trunc('minute',min(${dateviewed_raw})),date_trunc('minute',max(${dateviewed_raw})))+1;;
  type: number
  ######This needs rethinking for things like quarter of the year - perhaps join a calendar or smth
  hidden: yes
}

measure: content_average_duration{
  view_label: "CALCULATIONS"
  group_label: "TIME VIEWED"
  type: average
  sql: ${duration_mins} ;;
  hidden: yes
}





#----------------------------------------------


######--------------POPULATION SIZE


measure: pop_size {
  view_label: "CALCULATIONS"
  label: "Population Size"
  value_format: "# ### ### ##0\" K\""
  type: sum_distinct
  sql_distinct_key: ${demoinfo.demoid} ;;
  sql: ${pop_size.pop_size} ;;
}

##
#####################################################################################################################################################





}
