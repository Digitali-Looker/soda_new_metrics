include: "/[!model]*/*"

view: pop_size {
  derived_table: {
    sql:
    WITH ONE AS (    SELECT DISTINCT
      w.RID,
      {% if ds_paneldata.reach_account_granularity._parameter_value == "'profile'" %} p.PROFILEID, {% else %} {% endif %}
      w.DATEOFACTIVITY,
      w.LOADID,
      w.WEIGHT,
      d.demoid
    FROM core.WEIGHTS w
    LEFT JOIN (SELECT DISTINCT rid, profileid FROM core.PANELDATA) p ON w.RID = p.RID
    left join core.demoinfo d on W.rid = d.rid
    where  {% if demoinfo.demoid._is_filtered %} {% condition demoinfo.demoid %} demoid  {% endcondition %} {% else %} 1=1 {% endif %}
    )
    SELECT *
    , sum(weight) over (partition by dateofactivity,
      {% if demoinfo.demoid._is_selected %} demoid {% else %} 1 {% endif %}
      ) POP_SIZE
    FROM ONE
    ;;
    ######## Whenever a new demoinfo field is added to that table (be it an account holder info or whatever),
    ####-----that field needs to be added into where (so any condition on it gets passed onto) and into the partitioning section so if a breakdown is selected it's affected
    }

    dimension: rid {
      hidden: yes
    }

    # dimension: profileid {
    #   hidden: yes
    # }

    dimension: dateofactivity {
      type: date
      hidden: yes
    }

    # dimension: loadid {
    #   hidden: yes
    # }

    # dimension: demoid {
    #   hidden: no
    # }

    # dimension: weight {
    #   type: number
    #   view_label: "WEIGHTS"
    #   label: "Weight for Reach"
    # }

    dimension: pop_size {
      sql: ${TABLE}."POP_SIZE" ;;
      hidden: yes
    }

  }
