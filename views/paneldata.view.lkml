view: paneldata {
  sql_table_name: "CORE"."PANELDATA"
    ;;

    view_label: "PANELDATA"

  dimension: bookmark_mins {
    type: number
    sql: ${TABLE}."BOOKMARK_MINS" ;;
  }

  dimension: countryviewed {
    type: string
    sql: ${TABLE}."COUNTRYVIEWED" ;;
  }

  dimension_group: dateviewed {
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
    sql: ${TABLE}."DATEVIEWED" ;;
  }

  dimension: devicetype {
    type: string
    sql: ${TABLE}."DEVICETYPE" ;;
  }

  dimension: duration_mins {
    type: number
    sql: ${TABLE}."DURATION_MINS" ;;
  }

  dimension: episodeid {
    type: string
    sql: ${TABLE}."EPISODEID" ;;
  }

  dimension: netflixid {
    type: string
    sql: ${TABLE}."NETFLIXID" ;;
  }

  dimension: profileid {
    type: string
    sql: ${TABLE}."PROFILEID" ;;
  }

  dimension: rid {
    type: string
    sql: ${TABLE}."RID" ;;
  }

  dimension_group: rundate {
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
    sql: ${TABLE}."RUNDATE" ;;
  }

  dimension: seriestitle {
    type: string
    sql: ${TABLE}."SERIESTITLE" ;;
  }

  dimension: title {
    type: string
    sql: ${TABLE}."TITLE" ;;
  }

  dimension: videotitle {
    type: string
    sql: ${TABLE}."VIDEOTITLE" ;;
  }

  dimension: viewig_rate {
    type: number
    sql: ${TABLE}."VIEWIG_RATE" ;;
  }

  dimension: vieworder {
    type: number
    sql: ${TABLE}."VIEWORDER" ;;
  }

  measure: count {
    type: count
    drill_fields: []
  }

dimension: FK_Metadata {
  sql: coalesce(${episodeid},${netflixid}) ;;
  hidden: yes
}

}
