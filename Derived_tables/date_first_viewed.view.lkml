include: "/[!model]*/*"

view: date_first_viewed {
  derived_table: {
    sql:SELECT distinct
        m.NFTITLEID,
        m.NFEPISODEID,
        m.NFSEASONNUMBER,
        m.NFEPISODENUMBER,
        p.COUNTRYVIEWED ,
        min(to_date(p.DATEVIEWED)) OVER (PARTITION BY
        m.NFTITLEID,
        {% if metadata.nfseasonnumber._is_selected or metadata.content_name_granularity._parameter_value == "'season'" %} m.NFSEASONNUMBER {% else %} 1 {% endif %},
        {% if metadata.nfepisodenumber._is_selected or metadata.content_name_granularity._parameter_value == "'episode'" %} m.NFEPISODENUMBER {% else %} 1 {% endif %},
        {% if ds_paneldata.countryviewed._is_selected %} p.COUNTRYVIEWED {% else %} 1 {% endif %}
        ) date_first_viewed
        FROM
        core.METADATA m
        LEFT JOIN core.PANELDATA p ON COALESCE (m.NFEPISODEID,m.NFTITLEID) = COALESCE (p.EPISODEID , p.NETFLIXID)
        {% if ds_paneldata.countryviewed._is_filtered %}
        WHERE {% condition ds_paneldata.countryviewed %} p.COUNTRYVIEWED  {% endcondition %}
        {% endif %};;
  }

  dimension: nftitleid { hidden:yes}
  dimension: nfepisodeid { hidden:yes}
  dimension: countryviewed {hidden:yes}
  dimension: date_first_viewed {
    type: date
    view_label: "CALCULATIONS"
  }
}
