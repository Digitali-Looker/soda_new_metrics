 include: "/[!model]*/*"

#####################################################################################################################################################
##This view is the extension of the base paneldata view.
##Most calculations are to be written here to avoid invoking simmetric aggregate where possible (will still have to kick in for reach because of the nature of that measure)

view: paneldata_ext {
    extends: [paneldata]
    view_label: "PANELDATA"

  filter: date_viewed {
    view_label: "CALCULATIONS"
    type: date
    suggest_dimension: dateviewed_raw
    sql: {% condition date_viewed %}
          ${dateviewed_raw}
          {% endcondition %};;
  }



dimension: selected_list {
  type: string
  sql: concat_ws(', ',
  ---------paneldata fields --------------
  {% if paneldata.rid._is_selected %} {{paneldata.rid._name}}, {% else %} {% endif %}
  {% if paneldata.profileid._is_selected %} {{paneldata.profileid._name}}, {% else %} {% endif %}
  {% if paneldata.bookmark_mins._is_selected %} {{paneldata.bookmark_mins._name}}, {% else %} {% endif %}
  {% if paneldata.countryviewed._is_selected %} {{paneldata.countryviewed._name}}, {% else %} {% endif %}
  {% if paneldata.devicetype._is_selected %} {{paneldata.devicetype._name}}, {% else %} {% endif %}
  {% if paneldata.duration_mins._is_selected %} {{paneldata.duration_mins._name}}, {% else %} {% endif %}
  {% if paneldata.dateviewed_raw._is_selected %} {{paneldata.dateviewed_raw._name}}, {% else %} {% endif %}
  {% if paneldata.dateviewed_date._is_selected %} to_date(paneldata.dateviewed), {% else %} {% endif %}
  {% if paneldata.dateviewed_week._is_selected %} date_trunc('week',paneldata.dateviewed), {% else %} {% endif %}
  {% if paneldata.dateviewed_month._is_selected %} date_trunc('month',paneldata.dateviewed), {% else %} {% endif %}
  {% if paneldata.dateviewed_quarter._is_selected %} date_trunc('quarter',paneldata.dateviewed), {% else %} {% endif %}
  {% if paneldata.dateviewed_year._is_selected %} year(paneldata.dateviewed), {% else %} {% endif %}
  {% if paneldata.daypart_viewed_hour_of_day._is_selected %} hour(paneldata.dateviewed), {% else %} {% endif %}
  {% if paneldata.daypart_viewed_quarter_of_year._is_selected %} quarter(paneldata.dateviewed), {% else %} {% endif %}
  {% if paneldata.daypart_viewed_day_of_week._is_selected %} DAYOFWEEKISO(paneldata.dateviewed), {% else %} {% endif %}
  --------------metadata fields----------------
  {% if metadata.image._is_selected %} {{metadata.image._name}}, {% else %} {% endif %}
  {% if metadata.imdbid._is_selected %} {{metadata.imdbid._name}}, {% else %} {% endif %}
  {% if metadata.nfdatefetched._is_selected %} to_date(metadata.nfdatefetched), {% else %} {% endif %}
  {% if metadata.nfepisodeid._is_selected %} {{metadata.nfepisodeid._name}}, {% else %} {% endif %}
  {% if metadata.nfepisodename._is_selected %} {{metadata.nfepisodename._name}}, {% else %} {% endif %}
  {% if metadata.nfepisodenumber._is_selected %} {{metadata.nfepisodenumber._name}}, {% else %} {% endif %}
  {% if metadata.nfseasonnumber._is_selected %} {{metadata.nfseasonnumber._name}}, {% else %} {% endif %}
  {% if metadata.nftitleid._is_selected or metadata.nftitlename._is_selected %} {{metadata.nftitleid._name}}, {% else %} {% endif %}
  {% if metadata.nfvideotype._is_selected %} {{metadata.nfvideotype._name}}, {% else %} {% endif %}
  {% if metadata.unogsdate._is_selected %} to_date(metadata.unogsdate), {% else %} {% endif %}
  ------------demoinfo fields--------------------
  {% if demoinfo.demoid._is_selected %} {{demoinfo.demoid._name}}, {% else %} {% endif %}
  1
  );;
  # hidden: yes
}




  measure: streams {
    view_label: "CALCULATIONS"
    group_label: "STREAMS"
    label: "Streams"
    value_format: "0"
    type: sum
    sql: ${weights.weight} ;;
  }






    }
