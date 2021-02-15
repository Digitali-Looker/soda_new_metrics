include: "/views/*"

view: ds_weights_streams_ext {
 extends: [weights]
  ########Discovered later - this can be a refinement view - meaning no changes would need to be made to joins etc but can still add fields and tweaks to base view



view_label: "WEIGHTS"


dimension: PK {
  sql: concat_ws(', ',${rid},${dateofactivity_date}) ;;
  primary_key: yes
  hidden: yes
}


 }
