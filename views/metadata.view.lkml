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

  dimension: nfdatefetched {
  type: date
    sql: ${TABLE}."NFDATEFETCHED" ;;
    hidden: yes
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
    # type: number
    # sql: ${TABLE}."NFVIDEOTYPE" ;;
    label: "Video Type"
    case: {
      when: {
      sql: ${TABLE}.nfvideotype = 1;;
      label: "Movie"
      }
      else: "Series"
          }
  }

  dimension: platformid {
    type: number
    value_format_name: id
    sql: ${TABLE}."PLATFORMID" ;;
    label: "Platform Id"
    hidden: yes
  }

  dimension: unogsdate {
    type: date
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
