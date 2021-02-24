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



# dimension: selected_list {
#   type: string
#   sql: concat_ws(', ',{% if paneldata.rid._is_selected %} {{paneldata.rid._name}} {% else %} '1' {% endif %});;
#   # hidden: yes
# }

# parameter: selected_list_param {
#   suggest_dimension: selected_list
#   default_value: "{{ paneldata.selected_list }}"
# }

# measure: test_sum_streams {
#   type: sum
#   sql: ${reach_ndt.test_streams} ;;
# }


  measure: streams {
    view_label: "CALCULATIONS"
    group_label: "STREAMS"
    label: "Streams"
    value_format: "0"
    type: sum
    sql: ${weights.weight} ;;
  }






    }
