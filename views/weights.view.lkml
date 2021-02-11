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
  }

  dimension: rid {
    type: number
    value_format_name: id
    sql: ${TABLE}."RID" ;;
  }

  dimension: weight {
    type: number
    sql: ${TABLE}."WEIGHT" ;;
  }

  measure: count {
    type: count
    drill_fields: []
  }
}
