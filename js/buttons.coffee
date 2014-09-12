$ ->
    force_bezier = d3.chart.force_bezier()

    class_scale = d3.scale.ordinal()
        .domain ["natural", "moral"] 
        .range ["#a1d99b", "#aec7e8"] 

    gender_scale = d3.scale.ordinal()
        .domain ["m", "f"] 
        .range ["#aec7e8", "#f7b6d2"] 

    d3.json("spetteguless.json", (error, data) ->
        force_bezier
            .color class_scale 
        d3.select "#bezier_graph" 
            .data [data] 
            .call force_bezier 

    $('#scale-selector button').click ->
        $(this)
            .addClass 'active'
            .siblings()
            .removeClass 'active'

        console.log(this.id)

        
