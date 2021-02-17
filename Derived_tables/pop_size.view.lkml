include: "/[!model]*/*"


######## Tried making pop size through NDT and a separate explore - again it wouldn't work cause we need to configure the partitioning by depending on what
## demoinfo fields are selected, and referencing them from a different explore doesn't seem to work

##---Another way I've tried is sum_distinct, but with that join on rid becomes a filtering entity - if we sum weights by distinct rids, profiles and whatever
##---demoinfo fields are passed into the query, any rids that get filtered out from paneldata as not having had viewing would reduce the sum, so basically this will be reach

##Hence we want sums to be pre-calulated in a derived table.

##It's easier than in a former model because date breakdown is covered by sample date selection and a consequent join on dateofactivity = sample date.
## So the only conditional filtering and partitioning needs to be coded for fields relating to demographic information

##At the moment it's only one field - demoid

## Adding/Removing Profileid from the CTE affects the level at which the population is calculated - profile vs account. As all profiles within a rid
## have the same demoid and the same weight, it doesn't need to come through any further than CTE - doen't need to be a dimension to participate in a join

view: pop_size {
  derived_table: {
    sql:
    WITH ONE AS (    SELECT DISTINCT
      w.RID,
      {% if ds_paneldata.reach_account_granularity._parameter_value == "'profile'" %} p.PROFILEID, {% else %} {% endif %}
      ------Profile will be added to multiply weights by number of profiles if the profile granularity is selected
      w.DATEOFACTIVITY,
      w.LOADID,
      w.WEIGHT,
      d.demoid,
      sum(weight) over (partition by dateofactivity,
      demoid
      ) POP_SIZE
    FROM core.WEIGHTS w
    {% if ds_paneldata.reach_account_granularity._parameter_value == "'profile'" %} LEFT JOIN (SELECT DISTINCT rid, profileid FROM core.PANELDATA) p ON w.RID = p.RID {% else %} {% endif %}
    ------Profile join will be added to multiply weights by number of profiles if the profile granularity is selected
    left join core.demoinfo d on W.rid = d.rid
    --------------------------------------------------------------------------------------------
    ------ This joins dynamic targeting table if any field from it is filtered (only filter fields from this table are available for users)
    ------ Can become a persistent join, but conditional will potentially reduce the load on the system
    {% if dynamic_targeting.*._in_query %}
    {% if ds_paneldata.reach_account_granularity._parameter_value == "'profile'" %} inner join ${dynamic_targeting.SQL_TABLE_NAME} as dynamic_targeting on w.rid = dynamic_targeting.rid and p.PROFILEID = dyamic_targeting.profileid
    {% else %} inner join (select distinct rid from ${dynamic_targeting.SQL_TABLE_NAME}) as dynamic_targeting on w.rid = dynamic_targeting.rid {% endif %}
    {% else %} {% endif %}
    )
    SELECT distinct
    dateofactivity,
    demoid,
    POP_SIZE
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

    dimension: demoid {
      hidden: yes
    }

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
