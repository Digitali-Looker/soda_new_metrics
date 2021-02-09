view: metadata {
  sql_table_name: "CORE"."METADATA"
    ;;

  view_label: "METADATA"

  dimension: image {
    type: string
    sql: ${TABLE}."IMAGE" ;;
  }

  dimension: imdbid {
    type: string
    sql: ${TABLE}."IMDBID" ;;
  }

  dimension_group: nfdatefetched {
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
    sql: ${TABLE}."NFDATEFETCHED" ;;
  }

  dimension: nfepisodeid {
    type: number
    value_format_name: id
    sql: ${TABLE}."NFEPISODEID" ;;
  }

  dimension: nfepisodename {
    type: string
    sql: ${TABLE}."NFEPISODENAME" ;;
  }

  dimension: nfepisodenumber {
    type: number
    sql: ${TABLE}."NFEPISODENUMBER" ;;
  }

  dimension: nfseasonnumber {
    type: number
    sql: ${TABLE}."NFSEASONNUMBER" ;;
  }

  dimension: nftitleid {
    type: number
    value_format_name: id
    sql: ${TABLE}."NFTITLEID" ;;
  }

  dimension: nftitlename {
    type: string
    sql: ${TABLE}."NFTITLENAME" ;;
  }

  dimension: nfvideotype {
    type: number
    sql: ${TABLE}."NFVIDEOTYPE" ;;
  }

  dimension: platformid {
    type: number
    value_format_name: id
    sql: ${TABLE}."PLATFORMID" ;;
  }

  dimension_group: unogsdate {
    type: time
    timeframes: [
      raw,
      date,
      week,
      month,
      quarter,
      year
    ]
    convert_tz: no
    datatype: date
    sql: ${TABLE}."UNOGSDATE" ;;
  }

  measure: count {
    type: count
    drill_fields: [nftitlename, nfepisodename]
  }
}
