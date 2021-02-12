view: paneldata {
  sql_table_name: "CORE"."PANELDATA"
    ;;

    view_label: "PANELDATA"

  dimension: bookmark_mins {
    type: number
    sql: case when ${TABLE}."BOOKMARK_MINS" > ${duration_mins} then ${duration_mins} else ${TABLE}."BOOKMARK_MINS" end;;
    label: "Minutes Viewed (unweighted)"
  }

  dimension: countryviewed {
    type: string
    sql: ${TABLE}."COUNTRYVIEWED" ;;
    label: "Country Viewed (code)"
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
      quarter_of_year,
      year
    ]
    sql: ${TABLE}."DATEVIEWED" ;;
    # allow_fill: no
    label: "Date Of Acivity"
  }

  dimension: devicetype {
    type: string
    sql: ${TABLE}."DEVICETYPE" ;;
    label: "Device ID"
  }

  dimension: duration_mins {
    type: number
    sql: ${TABLE}."DURATION_MINS" ;;
    label: "Duration Minutes"
  }

  dimension: episodeid {
    type: string
    sql: ${TABLE}."EPISODEID" ;;
    hidden: yes
  }

  dimension: netflixid {
    type: string
    sql: ${TABLE}."NETFLIXID" ;;
    hidden: yes
  }

  dimension: profileid {
    type: string
    sql: ${TABLE}."PROFILEID" ;;
    label: "Profile ID"
  }

  dimension: rid {
    type: string
    sql: ${TABLE}."RID" ;;
    label: "Respondant ID"
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
    hidden: yes
  }

  dimension: seriestitle {
    type: string
    sql: ${TABLE}."SERIESTITLE" ;;
    hidden: yes
  }

  dimension: title {
    type: string
    sql: ${TABLE}."TITLE" ;;
    hidden: yes
  }

  dimension: videotitle {
    type: string
    sql: ${TABLE}."VIDEOTITLE" ;;
    hidden: yes
  }

  # dimension: viewig_rate {
  #   type: number
  #   sql: ${TABLE}."VIEWIG_RATE" ;;
  #   hidden: yes
  # }
  ##This calculation doesn't take into consideration to bring bookmark value that exceeds duration to duration value

  dimension: vieworder {
    type: number
    sql: ${TABLE}."VIEWORDER" ;;
    hidden: yes
  }

  measure: count {
    type: count
    drill_fields: []
    hidden: yes
  }

dimension: FK_Metadata {
  sql: coalesce(${episodeid},${netflixid}) ;;
  hidden: yes
}

  dimension: FK_Weights_Streams {
    sql: concat_ws(', ', ${rid}, ${dateviewed_date}) ;;
    hidden: yes
  }



}
