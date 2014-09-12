---
---

if not d3.chart?
    d3.chart = {}

d3.chart.force_bezier = ->
    width = 960
    height = width * 0.618
    color_value = (d) -> d.class
    color = d3.scale.category20()
    link_distance = 10
    link_strength = 2
    circle_radius = 5

    chart = (selection) ->
        selection.each (data) ->
            force = d3.layout.force()
                .linkDistance link_distance 
                .linkStrength link_strength 
                .size [width, height] 

            # select the svg if it exists
            svg = d3.select this
                .selectAll "svg"
                .data [data]

            # otherwise create the skeletal chart
            g_enter = svg.enter()
                .append "svg"
                .append "g"

            g_enter.append "g"
                .classed "links", true

            g_enter.append "g"
                .classed "nodes", true

            g_enter.append "g"
                .classed "color_legends", true

            g_enter.append "g"
                .classed "link_legends", true

            svg
                .attr "width", width 
                .attr "height", height 

            g = svg.select "g"

            nodes = data.nodes.slice()
            links = []
            bilinks = []
            data.links.forEach (link) ->
                s = nodes[link.source]
                t = nodes[link.target]
                i = {} # intermediate node
                nodes.push i
                links.push(
                    {source: s, target: i},
                    {source: i, target: t}
                )
                bilink = [s, i, t]
                bilink.type = link.type
                bilinks.push bilink

            force
                .nodes(nodes)
                .links(links)
                .start()

            link = g.select ".links"
                .selectAll ".link" 
                .data bilinks 

            link
                .enter()
                .append "path" 
                .attr "class", (d) -> "link #{d.type}" 

            node = g.select ".nodes"
                .selectAll ".node" 
                .data data.nodes 

            node
                .enter()
                .append "circle" 
                .attr "class", "node" 
                .attr "r", circle_radius 
                .style "fill", (d) ->
                    color color_value d
                .call(force.drag)

            node
                .append "title" 
                .text (d) -> d.name

            node.exit().remove()
            link.exit().remove()

            force.on "tick", ->
                
                link.attr "d", (d) ->
                    "M#{d[0].x},#{d[0].y}S#{d[1].x},#{d[1].y} #{d[2].x},#{d[2].y}"

                node.attr "transform", (d) ->
                    "translate(#{d.x}, #{d.y})"

            color_legends = g.select "g.color_legends"
                .selectAll "g.legend"
                .data color.domain()

            color_legends
                .enter()
                .append "g"
                .classed "legend", true

            color_legends
                .each (d) ->
                    circles = d3.select this
                        .selectAll "circle"
                        .data [d]
                    circles
                        .enter()
                        .append "circle"
                        .attr "cx", width - circle_radius
                        .attr "cy", 9
                        .attr "r", circle_radius
                    circles
                        .style "fill", color
                    texts = d3.select this
                        .selectAll "text"
                        .data [d]
                    texts.enter()
                        .append "text"
                        .attr "x", width - 2 * circle_radius - 2
                        .attr "y", 9
                        .attr "dy", circle_radius
                        .style "text-anchor", "end"
                    texts
                        .text (d) -> d

            color_legends
                .attr "transform", (d, i) ->
                    "translate(0, #{(4 * circle_radius + 2) * i})"

            color_legends.exit().remove()

            #get unique link types
            link_names = (l.type for l in bilinks).filter (d, i, self) ->
                self.indexOf d == i

            console.log (l.type for l in bilinks)
            console.log link_names

            link_legends = g.select "g.link_legends"
                .selectAll "g.legend"
                .data link_names

            link_legends
                .enter()
                .append "g"
                .classed "legend", true

            link_legends
                .each (d) ->
                    links = d3.select this
                        .selectAll "path"
                        .data [d]
                    links
                        .enter()
                        .append "path"
                        .attr "d", "M#{width - 2 * circle_radius},9L#{width},9"
                        .attr "class", (d) -> "link #{d}" 
                    texts = d3.select this
                        .selectAll "text"
                        .data [d]
                    texts.enter()
                        .append "text"
                        .attr "x", width - 2 * circle_radius - 2
                        .attr "y", 9
                        .attr "dy", circle_radius
                        .style "text-anchor", "end"
                    texts
                        .text (d) -> d

            offset = 4 * circle_radius * color.domain().length + 4 * circle_radius
            console.log offset
            link_legends
                .attr "transform", (d, i) ->
                    "translate(0, #{offset + (4 * circle_radius + 2) * i})"

            link_legends.exit().remove()


    chart.width = (value) ->
        if not arguments.length
            return width
        width = value
        chart

    chart.height = (value) ->
        if not arguments.length
            return height
        height = value
        chart

    chart.color = (value) ->
        if not arguments.length
            return color
        color = value
        chart

    chart.color_value = (value) ->
        if not arguments.length
            return color_value
        color_value = value
        chart

    chart.link_distance = (value) ->
        if not arguments.length
            return link_distance
        link_distance = value
        chart

    chart.link_strength = (value) ->
        if not arguments.length
            return link_strength
        link_strength = value
        chart

    return chart
