include: "/views/*"

view: ds_weights_streams_ext {
 extends: [weights]

view_label: "WEIGHTS"

dimension: PK {
  sql: concat_ws(', ',${rid},${dateofactivity_date}) ;;
  primary_key: yes
}


 }
