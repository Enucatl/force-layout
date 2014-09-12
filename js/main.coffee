---
---

$ ->
    force_bezier = d3.chart.force_bezier()

    class_scale = d3.scale.ordinal()
        .domain ["naturalisti", "moralisti"] 
        .range ["#a1d99b", "#aec7e8"] 

    gender_scale = d3.scale.ordinal()
        .domain ["m", "f"] 
        .range ["#aec7e8", "#f7b6d2"] 

    scales = {
        class: class_scale
        gender: gender_scale
    }
    scale_values = {
        class: (d) -> d.class
        gender: (d) -> d.gender
    }

    d3.json "spetteguless.json", (error, data) ->
        force_bezier
            .color class_scale 
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
