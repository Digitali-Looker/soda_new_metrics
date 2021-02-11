view: demoinfo {
  sql_table_name: "CORE"."DEMOINFO"
    ;;

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
  }

  measure: count {
    type: count
    drill_fields: []
  }

}
