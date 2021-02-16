include: "/[!model]*/*"

view: ds_metadata_ext {
  extends: [metadata]
  ########Discovered later - this can be a refinement view - meaning no changes would need to be made to joins etc but can still add fields and tweaks to base view


dimension: title_season {
  type: string
  sql: ifnull( concat_ws(': ',${nftitlename},'Season '||${nfseasonnumber}),${nftitlename});;
  required_fields: [nftitleid, nfseasonnumber]
  view_label: "METADATA"
  label: "Title-Season"
}

# dimension: title_season_episode {
#   type: string
#   sql: concat_ws(': ',${nftitlename},'Season '||${nfseasonnumber},'Episode '||${nfepisodenumber}) ;;
#   required_fields: [nftitleid,nfseasonnumber,nfepisodenumber]
#   hidden: yes
# }


######--Below are the fields to be used only in dashboards, to avoid maintaining 2 different explores, switch them on to build dashboards, hide when in prod

parameter: content_name_granularity {
  view_label: "METADATA"
  allowed_value: {
    label: "Title Level"
    value: "title"
  }
  allowed_value: {
    label: "Season Level"
    value: "season"
  }
  allowed_value: {
    label: "Episode Level"
    value: "episode"
  }
}

dimension: dynamic_content_name {
  type: string
  sql: {% if content_name_granularity._parameter_value == "'title'" %} {{nftitlename._name}}
  {% elsif content_name_granularity._parameter_value == "'season'" %} ifnull(concat_ws(': ',{{nftitlename._name}},'Season '||{{nfseasonnumber._name}}),{{nftitlename._name}})
  {% elsif content_name_granularity._parameter_value == "'episode'" %} ifnull(concat_ws(': ',{{nftitlename._name}},'Season '||{{nfseasonnumber._name}},'Episode '||{{nfepisodenumber._name}}),{{nftitlename._name}})
  {% else %} ${nftitlename} {% endif %} ;;
}
####----This has to be done through the {{}} liquid, because if the actual field is referenced, Looker drags its required fields in all scenarios,
## not just when condition is true (which is very annoying as if it only pulled required fields relevant for the active option, this would be an ideal scenario
## because then all the calculations dependent on granularity could just feature a check of whether seasonnumber field is in query or episodenumber field is in query
## but now the granularity param will have to be a check too


}
