
connection: "soda_new_metrics"

include: "/[!model]*/*"



explore:  ds_paneldata {
 from: paneldata
 label: "Test Explore for New Metrics DS version"

join: metadata {
  relationship: many_to_one
  sql_on: coalesce(${ds_paneldata.episodeid},${ds_paneldata.netflixid})=coalesce(${metadata.nfepisodeid},${metadata.nftitleid});;
  ##coalesce above will allow titles that don't have episode info in API yet to at least provide title link, can be excluded by adding sql_always_where in the model
}


}
