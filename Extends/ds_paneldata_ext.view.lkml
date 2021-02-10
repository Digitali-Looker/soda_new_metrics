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
      {%else%}
      ${dateviewed_date}
      {% endif %};;
    hidden: yes
  }

  dimension: sample_date_d_final {
    type: date
    label: "Sample Date Dimension"
    sql: case when {% condition date_viewed %} ${sample_date_d} {% endcondition %} then ${sample_date_d}
    when ${sample_date_d}<{% date_start date_viewed %} then {% date_start date_viewed %}
    when ${sample_date_d}>={% date_end date_viewed %} then {% date_end date_viewed %} end;;
  }
}
