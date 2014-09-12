---
---

if not d3.chart?
    d3.chart = {}

d3.chart.force_bezier = ->
    width = 960
    height = 500
    color = d3.scale.category20()
    force = d3.layout.force()
        .linkDistance 10 
        .linkStrength 2 
        .size [width, height] 

    svg = d3.select "body"
        .append "svg" 
        .attr "width", width 
        .attr "height", height 

    d3.json "miserables.json", (error, graph) ->
        nodes = graph.nodes.slice()
        links = []
        bilinks = []
        graph.links.forEach (link) ->
            s = nodes[link.source]
            t = nodes[link.target]
            i = {} # intermediate node
            nodes.push i
            links.push [
                {
                    source: s
                    target: i
                }
            ,
                {
                    source: i
                    target: t
                }
            ]

            bilinks.push [s, i, t]
            return

        force
            .nodes(nodes)
            .links(links)
            .start()

        #link = svg.selectAll ".link" 
            #.data bilinks 
            #.enter()
            #.append "path" 
            #.attr "class", "link" 

        #node = svg.selectAll ".node" 
            #.data graph.nodes 
            #.enter()
            #.append "circle" 
            #.attr "class", "node" 
            #.attr "r", 5 
            #.style "fill", (d) ->
                #color d.group
            #.call(force.drag)

        #node
            #.append "title" 
            #.text (d) -> d.name

        #force.on "tick", ->
            
            #link.attr "d", (d) ->
                #"M#{d[0].x},#{d[0].y}S#{d[1].x},#{d[1].y} #{d[2].x},#{d[2].y}"

            #node.attr "transform", (d) ->
                #"translate(#{d.x}, #{d.y})"

            #return

        return
