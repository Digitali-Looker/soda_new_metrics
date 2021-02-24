include: "/views/*"

view: +weights {

    view_label: "WEIGHTS"


    dimension: PK {
      sql: concat_ws(', ',${rid},${dateofactivity_date}) ;;
      primary_key: yes
      hidden: yes
    }


  }
