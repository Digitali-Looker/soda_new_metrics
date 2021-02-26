 include: "/[!model]*/*"

#####################################################################################################################################################
##This view is the extension of the base paneldata view.
##Most calculations are to be written here to avoid invoking simmetric aggregate where possible (will still have to kick in for reach because of the nature of that measure)

view: paneldata_ext {
    extends: [paneldata]
    view_label: "PANELDATA"



#################### ---- FILTERS AND PARAMETERS

  filter: date_viewed {
    view_label: "CALCULATIONS"
    type: date
    suggest_dimension: dateviewed_raw
    sql: {% condition date_viewed %}
          ${dateviewed_raw}
          {% endcondition %};;
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

parameter: minutes_threshold {
  type: number
  view_label: "CALCULATIONS"
  label: "Minimum minutes in a session for Reach calculations (inclusive)"
  # sql: {% condition minutes_threshold %} ${bookmark_mins} {% endcondition %};;
  default_value: "0"
}


parameter: percentile_selection {
  type: number
  default_value: "50"
  allowed_value: {
    label: "25"
    value: "25"
  }
  allowed_value: {
    label: "50"
    value: "50"
  }
  allowed_value: {
    label: "75"
    value: "75"
  }
  allowed_value: {
    label: "100"
    value: "100"
  }
  view_label: "CALCULATIONS"
  label: "Manual overwrite of the default percentile(50) for sample date configuration"
  description: "Sample date is selected based on the day when accumulation of streams for the item
  (row in your data-table, i.e. title, season of a title, date breakdown or a combination of a few dimensions)
  hit the desired % of total (percentile in this selection). Default is 50 - middle of the streams accumulation trend."
}

parameter: sample_date_overwrite {
  type: date
  view_label: "CALCULATIONS"
  label: "Sample Date Overwrite"
}



  parameter: frequency_type {
    default_value: "episodes"
    allowed_value: {
      label: "Number of sessions"
      value: "sesions"
    }
    allowed_value: {
      label: "Number of episodes"
      value: "episodes"
    }
    view_label: "CALCULATIONS"
  }

parameter: minimum_frequency {
  type: number
  view_label: "CALCULATIONS"
  default_value: "1"
}


#-----------------REACH

##-----Below calculations for Reach consist of 3 parts: 1 calculates Reach for account level, one - for Profile level,
##-----and third is just a shell that decides which one to use depending on the parameter value


###----for account level we sum weights of distinct pairs respondantid+sampledate (sample_date = dateofctivity brought through from weights_reach table)
###----so this will allows us to avoid double-counting weights and as sample weight calculation is dynamic, the date breakdown will affect Reach accordingly

  measure: Reach_Account {
    value_format: "0"
    type: sum_distinct
    # sql_distinct_key: concat_ws(', ',${ds_weights_reach_ext.rid},${ds_weights_reach_ext.dateofactivity_date}) ;;
    sql_distinct_key:
      concat_ws(', ',${weights_reach.rid},${weights_reach.dateofactivity});;
    sql: ${weights_reach.weight};;
    hidden: yes
  }



####----Same logic as above, except we add one more partitioning field - Profileid. So for each profile within the HH the weight will be counted once more
  measure: Reach_Profile {
    value_format: "0"
    type: sum_distinct
    # sql_distinct_key: concat_ws(', ',${ds_weights_reach_ext.rid},${ds_weights_reach_ext.dateofactivity_date}) ;;
    sql_distinct_key:
      concat_ws(', ',${weights_reach.rid},${weights_reach.profileid},${weights_reach.dateofactivity});;
    sql: ${weights_reach.weight} ;;
    hidden: yes
  }





dimension: frequency{
  sql: {% if frequency_type._parameter_value == "'episodes'" %} ${frequency_ndt.frequency_episodes} {% else %} ${frequency_ndt.frequency_sessions} {% endif %} ;;
  type: number
  label:"Frequency"
  value_format: "0 \" +\""
  html: {% if {{value}} == 0 %} Below threshold {% else %} {{rendered_value}} {% endif %} ;;
  view_label: "CALCULATIONS"
  description: "Number of Episodes as a default type, add a frequency type parameter to change to number of sessions. Please use only to evaluate Reach breakdown and avoid adding other measures into the table with frequency."
}


##--If the parameter is set to profile reach will refer to Reach_Profile, in all other cases (including when parameter is not selected at all it will go to account lvl)
  measure: Reach {
    view_label: "CALCULATIONS"
    group_label: "REACH"
    value_format: "0"
    type: number
    sql: {% if reach_account_granularity._parameter_value == "'profile'" %} ${Reach_Profile} {% else %} ${Reach_Account} {% endif %} ;;
    # html: {{value}} {{reach_account_granularity._parameter_value}} ;; ##This is just to check if liquid picks up the param value, for some reason it needed both sets of quotes around the value, which is weird
    link: {
      label: "Reach x Frequency"
      url: "{{ link }}"
    }
    drill_fields: [frequency,Reach]
    html: {% if frequency._in_query and frequency._value == 0 %} Value not available {% else %} {{rendered_value}} {% endif %} ;;
 }



  measure: streams {
    view_label: "CALCULATIONS"
    group_label: "STREAMS"
    label: "Streams"
    value_format: "0"
    type: sum
    sql: ${weights.weight} ;;
  }



#### tried to tie it all to 1 ndt but then we can't use frequency fields to drill or filter as it creates circular dependency

# dimension: Reach_Frequency_Episodes {
#   sql: 'Reach' ;;
#   html: <a href="{{ link }}"><button>Reach by Number of Episodes </button></a>;;
#   drill_fields: [reach_ndt.frequency_episodes,paneldata.Reach]
# }

#   dimension: Reach_Frequency_Sessions {
#     sql: 'Reach' ;;
#     html: <a href="{{ link }}"><button>Reach by Number of Sessions</button></a>;;
#     drill_fields: [reach_ndt.frequency_sessions,paneldata.Reach]
#   }


    }



#### The issue with using a parameter is that unquoted one doesn't accept liquid syntax (says only letters, numbers, underscores and $ are allowed)
#### When type string is builds it ok but wraps in quotes and no quoting combinations on default value or parameter value seem to undo that
#### the result it that instead of a sql statement we end up with a single string called as selected_list field that then obviously doesn't do partitioning correctly
# parameter: selected_list_test {
#   type: string
#   default_value:"concat_ws('', '',
#   ---------paneldata fields --------------
#   {% if paneldata.rid._is_selected %} {{paneldata.rid._name}}, {% else %} {% endif %}
#   {% if paneldata.profileid._is_selected %} {{paneldata.profileid._name}}, {% else %} {% endif %}
#   {% if paneldata.bookmark_mins._is_selected %} {{paneldata.bookmark_mins._name}}, {% else %} {% endif %}
#   {% if paneldata.countryviewed._is_selected %} {{paneldata.countryviewed._name}}, {% else %} {% endif %}
#   {% if paneldata.devicetype._is_selected %} {{paneldata.devicetype._name}}, {% else %} {% endif %}
#   {% if paneldata.duration_mins._is_selected %} {{paneldata.duration_mins._name}}, {% else %} {% endif %}
#   {% if paneldata.dateviewed_raw._is_selected %} paneldata.dateviewed, {% else %} {% endif %}
#   {% if paneldata.dateviewed_date._is_selected %} to_date(paneldata.dateviewed), {% else %} {% endif %}
#   {% if paneldata.dateviewed_week._is_selected %} date_trunc('week',paneldata.dateviewed), {% else %} {% endif %}
#   {% if paneldata.dateviewed_month._is_selected %} date_trunc('month',paneldata.dateviewed), {% else %} {% endif %}
#   {% if paneldata.dateviewed_quarter._is_selected %} date_trunc('quarter',paneldata.dateviewed), {% else %} {% endif %}
#   {% if paneldata.dateviewed_year._is_selected %} year(paneldata.dateviewed), {% else %} {% endif %}
#   {% if paneldata.daypart_viewed_hour_of_day._is_selected %} hour(paneldata.dateviewed), {% else %} {% endif %}
#   {% if paneldata.daypart_viewed_quarter_of_year._is_selected %} quarter(paneldata.dateviewed), {% else %} {% endif %}
#   {% if paneldata.daypart_viewed_day_of_week._is_selected %} DAYOFWEEKISO(paneldata.dateviewed), {% else %} {% endif %}
#   --------------metadata fields----------------
#   {% if metadata.image._is_selected %} {{metadata.image._name}}, {% else %} {% endif %}
#   {% if metadata.imdbid._is_selected %} {{metadata.imdbid._name}}, {% else %} {% endif %}
#   {% if metadata.nfdatefetched._is_selected %} to_date(metadata.nfdatefetched), {% else %} {% endif %}
#   {% if metadata.nfepisodeid._is_selected %} {{metadata.nfepisodeid._name}}, {% else %} {% endif %}
#   {% if metadata.nfepisodename._is_selected %} {{metadata.nfepisodename._name}}, {% else %} {% endif %}
#   {% if metadata.nfepisodenumber._is_selected %} {{metadata.nfepisodenumber._name}}, {% else %} {% endif %}
#   {% if metadata.nfseasonnumber._is_selected %} {{metadata.nfseasonnumber._name}}, {% else %} {% endif %}
#   {% if metadata.nftitleid._is_selected or metadata.nftitlename._is_selected %} {{metadata.nftitleid._name}}, {% else %} {% endif %}
#   {% if metadata.nfvideotype._is_selected %} {{metadata.nfvideotype._name}}, {% else %} {% endif %}
#   {% if metadata.unogsdate._is_selected %} to_date(metadata.unogsdate), {% else %} {% endif %}
#   ------------demoinfo fields--------------------
#   {% if demoinfo.demoid._is_selected %} {{demoinfo.demoid._name}}, {% else %} {% endif %}
#   1
#   )"
#   # hidden: yes
# }
