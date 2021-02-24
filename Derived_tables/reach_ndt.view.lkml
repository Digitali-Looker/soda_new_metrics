include: "/[!model]*/*"

view: reach_ndt {
  derived_table: {
    explore_source: paneldata{
      column: diid {field:paneldata.diid}
      column: rid {field:paneldata.rid}
      column: weight {field: weights.weight}
      derived_column: test_streams {
        sql: sum(weight) over (partition by 1) ;;
      }
      bind_all_filters: yes
    }
  }
  dimension: diid {hidden:yes
    primary_key:yes}
  dimension: rid {hidden:yes}
  dimension: weight {hidden:yes}
  dimension: test_streams {hidden:yes}
}
