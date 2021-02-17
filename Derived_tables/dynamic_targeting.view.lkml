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
