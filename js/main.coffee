---
---

$ ->
    force_bezier = d3.chart.force_bezier()

    class_scale = d3.scale.ordinal()
        .domain ["naturalisti", "moralisti", "socialisti"] 
        .range ["#4daf4a", "#377eb8", "#e41a1c"] 

    gender_scale = d3.scale.ordinal()
        .domain ["m", "f"] 
        #.range ["#aec7e8", "#f7b6d2"] 
        .range ["#6baed6", "#e7969c"] 

    scales = {
        class: class_scale
        gender: gender_scale
    }
    scale_values = {
        class: (d) -> d.class
        gender: (d) -> d.gender
    }

    d3.csv "nodes.csv", (error, nodes) ->
        d3.csv "links.csv", (link) ->
                source: parseInt link.source
                target: parseInt link.target
                type: link.type
            , (error, links) ->
                data = {
                    "nodes": nodes
                    "links": links
                }
                force_bezier
                    .color_value scale_values["gender"]
                    .color gender_scale 
                d3.select "#bezier_graph" 
                    .data [data] 
                    .call force_bezier 

    $('#scale-selector button').click ->
        $(this).addClass 'active'
            .siblings()
            .removeClass 'active'
        force_bezier
            .color_value scale_values[$(this).val()]
            .color scales[$(this).val()]
        force_bezier.update_color_legend()
