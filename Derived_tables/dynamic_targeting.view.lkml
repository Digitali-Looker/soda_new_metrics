######## -- The idea behind this is similar to how it was done previously - we take existing explore's relationships (particularly metadata and demo joins)
##----to provide datapoints that paneldata table can be filtered on
##----The main idea is that we limit existing bulk of viewing statements to only those that fit the dynamic targeting parameters - by when viewing happened,
##-----what was viewed or who was watching, and limit the paneldata table to only those respondents that have viewing lines that fit the definition
##----this is ultimately detached from any weightings - we just identify all possible rids that fit the request, once we limited the subset,
##----all the calculations then go about their usual logic - one set of weights for streams, one for reach, etc
##----the filtering is applied to 1) model - through an inner join
##-- and 2) pop_size derived table - through an inner join (this one references database directly, so model join won't affect it but we want population
##-- to be based on our subset too

view: dynamic_targeting {
  derived_table: {
    explore_source: ds_paneldata {
      column: rid {field: ds_paneldata.rid}
      column: profileid {field: ds_paneldata.profileid}

      bind_filters: {
        to_field: ds_paneldata.date_viewed
        from_field: dynamic_targeting.date
      }

      bind_filters: {
        to_field: metadata.nftitlename
        from_field: dynamic_targeting.title
      }
      bind_filters: {
        to_field: metadata.nftitleid
        from_field: dynamic_targeting.titleid
      }

      bind_filters: {
        to_field: metadata.nfseasonnumber
        from_field: dynamic_targeting.seasonnumber
      }

      bind_filters: {
        to_field: metadata.nfepisodenumber
        from_field: dynamic_targeting.episodenumber
      }

      bind_filters: {
        to_field: metadata.nfepisodename
        from_field: dynamic_targeting.episode_title
      }

      bind_filters: {
        to_field: metadata.nfvideotype
        from_field: dynamic_targeting.videotype
      }

      bind_filters: {
        to_field: demoinfo.demoid
        from_field: dynamic_targeting.demoid
      }
    }
  }

  dimension: rid { hidden:yes}
  dimension: profileid {hidden:yes}


  filter: date {
    type: date
    label: "Date"
    suggest_dimension: ds_paneldata.dateviewed_date
  }

  filter: title {
    type: string
    label: "Title Name"
    suggest_dimension: metadata.nftitlename
  }

  filter: titleid {
    type: string
    label: "Title ID (Netflixid)"
    suggest_dimension:  metadata.nftitleid
  }

  filter: seasonnumber {
    type: number
    label: "Season Number"
    suggest_dimension: metadata.nfseasonnumber
  }

  filter: episodenumber {
    type: number
    label: "Episode Number"
    suggest_dimension: metadata.nfepisodenumber
  }

  filter: episode_title {
    type: string
    label: "Episode Name"
    suggest_dimension: metadata.nfepisodename
  }

  filter: videotype {
    label: "Video Type"
    suggest_dimension: metadata.nfvideotype
  }

  filter: demoid {
    label: "Demo ID code"
    suggest_dimension: demoinfo.demoid
  }

}
