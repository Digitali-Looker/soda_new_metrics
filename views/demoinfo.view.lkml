view: demoinfo {
  sql_table_name: "CORE"."DEMOINFO"
    ;;
  view_label: "DEMO INFO"

  dimension: demoid {
    type: number
    value_format_name: id
    sql: ${TABLE}."DEMOID" ;;
  }

  dimension: rid {
    type: number
    value_format_name: id
    sql: ${TABLE}."RID" ;;
    primary_key: yes
    hidden: yes
  }

  measure: count {
    type: count
    drill_fields: []
    hidden: yes
  }

}
