include: "/[!model]*/*"

view: ds_paneldata_ext {
  extends: [paneldata]
  view_label: "PANELDATA"

  dimension_group: dateviewed {
    can_filter: no
  }

 filter: date_viewed {
  type: date
   suggest_dimension: dateviewed_raw
   sql: {% condition date_viewed %}
${dateviewed_raw}
{% endcondition %} ;;
 }

  measure: sample_date_m {
    type: date
    label: "sample date"
    description: "max_date within selection"
    sql:
    max(${dateviewed_date}) ;;
  }

  dimension: sample_date_d {
    type: date_raw
    label: "SAMPLE date DIMENSION"
    description: "max_date within selection"
    sql:
      {% if dateviewed_year._is_selected %}
      date_trunc(year,${dateviewed_date})
      {% endif %};;
  }


}
