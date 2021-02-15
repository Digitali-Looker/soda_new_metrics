view: weights_reach {
  derived_table: {
    sql:
    SELECT --DISTINCT
      w.RID,
      p.PROFILEID,
      w.DATEOFACTIVITY,
      w.LOADID,
      w.WEIGHT
    FROM core.WEIGHTS w
    LEFT JOIN (SELECT DISTINCT rid, profileid FROM core.PANELDATA) p
    ON w.RID = p.RID
    ;;
    ######## WHen have more than 1 country, it is to be added as a field and into the join both here and in the model
  }

  dimension: rid {
    hidden: yes
  }

  dimension: profileid {
    hidden: yes
  }

  dimension: dateofactivity {
    type: date
    hidden: yes
  }

  dimension: loadid {
    hidden: yes
  }

  # dimension: demoid {
  #   hidden: no
  # }

  dimension: weight {
    type: number
    view_label: "WEIGHTS"
    label: "Weight for Reach"
  }

  }
