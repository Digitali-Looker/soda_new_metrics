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
    label: "Episode ID"
    description: "Info field - doesn't participate in calculations such as Date First Viewed"
  }

  dimension: nfepisodename {
    type: string
    sql: ${TABLE}."NFEPISODENAME" ;;
    label: "Episode Name"
    required_fields: [nftitleid, nfseasonnumber]
  }

  dimension: nfepisodenumber {
    type: number
    sql: ${TABLE}."NFEPISODENUMBER" ;;
    label: "Episode Number"
    required_fields: [nftitleid,nfseasonnumber]
  }

  dimension: nfseasonnumber {
    type: number
    sql: ${TABLE}."NFSEASONNUMBER" ;;
    label: "Season Number"
    required_fields: [nftitleid]
  }

  dimension: nftitleid {
    type: number
    value_format_name: id
    sql: ${TABLE}."NFTITLEID" ;;
    label: "Title ID (NetlfixID)"
  }

  dimension: nftitlename {
    type: string
    sql: ${TABLE}."NFTITLENAME" ;;
    label: "Title Name"
    required_fields: [nftitleid]
    ## This will always force an id in, so that titles with the same name don't end up merging values!
  }

  dimension: nfvideotype {
    type: number
    sql: ${TABLE}."NFVIDEOTYPE" ;;
    label: "Video Type"
  }

  dimension: platformid {
    type: number
    value_format_name: id
    sql: ${TABLE}."PLATFORMID" ;;
    label: "Platform Id"
    hidden: yes
  }

  dimension_group: unogsdate {
    type: time
    timeframes: [
      raw,
      date,
      year
    ]
    convert_tz: no
    datatype: date
    sql: ${TABLE}."UNOGSDATE" ;;
    label: "Netflix Release Date (UNOGS)"
  }

  measure: count {
    type: count
    drill_fields: [nftitlename, nfepisodename]
    hidden: yes
  }

  dimension: PK {
    sql: coalesce(${nfepisodeid},${nftitleid}) ;;
    primary_key: yes
    hidden: yes
  }
}
