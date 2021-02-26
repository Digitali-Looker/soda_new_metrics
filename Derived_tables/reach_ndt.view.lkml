include: "/[!model]*/*"

view: reach_ndt {
  derived_table: {
    ########----This section should be exactly the same as in Reach_ndt table, if any changes are made in either, please make sure to mirror them!
    ########----This section should contain all visible fields that a user can potentially try to partition things by, however unlikely
    explore_source: paneldata{
      column: diid {field:paneldata.diid}
      column: rid {field:paneldata.rid}
      column: profileid {field:paneldata.profileid}
      column: bookmark_mins {field:paneldata.bookmark_mins}
      column: countryviewed {field:paneldata.countryviewed}
      column: devicetype {field:paneldata.devicetype}
      column: duration_mins {field:paneldata.duration_mins}
      column: dateviewed {field:paneldata.dateviewed_raw}
      column: image {field:metadata.image}
      column: imdbid {field:metadata.imdbid}
      column: nfdatefetched {field:metadata.nfdatefetched}
      column: nfepisodeid {field:metadata.nfepisodeid}
      column: nfepisodename {field:metadata.nfepisodename}
      column: nfepisodenumber {field:metadata.nfepisodenumber}
      column: nfseasonnumber {field:metadata.nfseasonnumber}
      column: nftitleid {field:metadata.nftitleid}
      column: nfvideotype {field:metadata.nfvideotype}
      column: unogsdate {field:metadata.unogsdate}
      column: demoid {field:demoinfo.demoid}
      column: weight {field: weights.weight}
      derived_column: selected_list {
        ##### Full list from above (except only diid) whould be reflected within this column
        sql: concat_ws(', ',
        ---------paneldata fields --------------
        {% if paneldata.rid._is_selected %} rid, {% else %} {% endif %}
        {% if paneldata.profileid._is_selected %} profileid, {% else %} {% endif %}
        {% if paneldata.bookmark_mins._is_selected %} bookmark_mins, {% else %} {% endif %}
        {% if paneldata.countryviewed._is_selected %} countryviewed, {% else %} {% endif %}
        {% if paneldata.devicetype._is_selected %} devicetype, {% else %} {% endif %}
        {% if paneldata.duration_mins._is_selected %} duration_mins, {% else %} {% endif %}
        {% if paneldata.dateviewed_raw._is_selected %} dateviewed, {% else %} {% endif %}
        {% if paneldata.dateviewed_date._is_selected %} to_date(dateviewed), {% else %} {% endif %}
        {% if paneldata.dateviewed_week._is_selected %} date_trunc('week',dateviewed), {% else %} {% endif %}
        {% if paneldata.dateviewed_month._is_selected %} date_trunc('month',dateviewed), {% else %} {% endif %}
        {% if paneldata.dateviewed_quarter._is_selected %} date_trunc('quarter',dateviewed), {% else %} {% endif %}
        {% if paneldata.dateviewed_year._is_selected %} year(dateviewed), {% else %} {% endif %}
        {% if paneldata.daypart_viewed_hour_of_day._is_selected %} hour(dateviewed), {% else %} {% endif %}
        {% if paneldata.daypart_viewed_quarter_of_year._is_selected %} quarter(dateviewed), {% else %} {% endif %}
        {% if paneldata.daypart_viewed_day_of_week._is_selected %} DAYOFWEEKISO(dateviewed), {% else %} {% endif %}
        --------------metadata fields----------------
        {% if metadata.image._is_selected %} image, {% else %} {% endif %}
        {% if metadata.imdbid._is_selected %} imdbid, {% else %} {% endif %}
        {% if metadata.nfepisodeid._is_selected %} ifnull(nfepisodeid,1), {% else %} {% endif %}
        {% if metadata.nfepisodename._is_selected %} ifnull(nfepisodename,1), {% else %} {% endif %}
        {% if metadata.nfepisodenumber._is_selected %} ifnull(nfepisodenumber,1), {% else %} {% endif %}
        {% if metadata.nfseasonnumber._is_selected %} ifnull(nfseasonnumber,1), {% else %} {% endif %}
        {% if metadata.nftitleid._is_selected or metadata.nftitlename._is_selected %} nftitleid, {% else %} {% endif %}
        {% if metadata.nfvideotype._is_selected %} nfvideotype, {% else %} {% endif %}
        {% if metadata.unogsdate._is_selected %} to_date(unogsdate), {% else %} {% endif %}
        ------------demoinfo fields--------------------
        {% if demoinfo.demoid._is_selected %} demoid, {% else %} {% endif %}
        1
        );;
      }
      #####################   END OF SECTION
      #
      #####------Here is where reach/sample date business starts, these are not same as in frequency_ndt
      derived_column: running_streams {
        sql: sum(weight) over (partition by selected_list order by dateviewed rows between unbounded preceding and current row) ;;
      }
      derived_column: total_streams {
        sql: sum(weight) over (partition by selected_list order by dateviewed rows between unbounded preceding and unbounded following) ;;
      }
      derived_column: percentile {
        sql: TO_NUMERIC((running_streams/total_streams)*100) ;;
      }
      bind_all_filters: yes
    }
  }
  dimension: diid {hidden:yes
    primary_key:yes}
  dimension: rid {hidden:yes}
  dimension: profileid {hidden:yes}
  dimension: weight {hidden:no}
  dimension: running_streams {hidden:yes}
  dimension: total_streams {hidden:yes}
  dimension: percentile {hidden:yes}
  dimension: selected_list {hidden:no}
  dimension: bookmark_mins {hidden:yes}


}
