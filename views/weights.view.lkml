view: weights {
  sql_table_name: "CORE"."WEIGHTS"
    ;;

  view_label: "WEIGHTS"

  dimension_group: dateofactivity {
    type: time
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    sql: ${TABLE}."DATEOFACTIVITY" ;;
    hidden: yes
  }

  # dimension: demoid {
  #   type: number
  #   value_format_name: id
  #   sql: ${TABLE}."DEMOID" ;;
  # }

  dimension: loadid {
    type: number
    value_format_name: id
    sql: ${TABLE}."LOADID" ;;
    hidden: yes
  }

  dimension: rid {
    type: number
    value_format_name: id
    sql: ${TABLE}."RID" ;;
    hidden: yes
  }

  dimension: weight {
    type: number
    sql: ${TABLE}."WEIGHT" ;;
    label: "Streams Weight"
  }

  measure: count {
    type: count
    drill_fields: []
    hidden: yes
  }
}
