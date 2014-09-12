---
---

if not d3.chart?
    d3.chart = {}

d3.chart.force_bezier = ->
    width = 960
    height = width * 0.618
    color_value = (d) -> d.class
    color = d3.scale.category20()
    link_distance = 20
    friction = 0.95
    link_strength = 1
    circle_radius = 5
    link_legend = {
        "broom": "passion"
        "lemon": "lemon"
    }
    position_value = (d) -> d.gender

    count_occurrences = (array, item, accessor=(d) -> d) ->
        result = 0
        for element in array
            if accessor(element) == item
                result++
        return result

    chart = (selection) ->
        selection.each (data) ->
            force = d3.layout.force()
                .linkDistance link_distance 
                .linkStrength link_strength 
                .friction friction
                .charge -70
                .gravity 0
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

            nodes_with_occurrences = data.nodes.map (d, i) ->
                d.counts = (
                    count_occurrences(
                        data.links, i, (e) -> e.target
                    ) +
                    count_occurrences(
                        data.links, i, (e) -> e.source)
                )
                return d

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
                .data nodes_with_occurrences

            node
                .enter()
                .append "g"
                .attr "class", "node" 
                .call(force.drag)

            node
                .append "circle" 
                .attr "class", "node-circle" 
                .attr "r", (d) ->
                    circle_radius + d.counts
                .style "fill", (d) ->
                    color color_value d

            node
                .append "text"
                .attr "dy", ".35em"
                .text (d) -> d.name

            node
                .append "title" 
                .text (d) -> d.name

            node.exit().remove()
            link.exit().remove()

            #get unique position names
            position_names = (position_value(l) for l in data.nodes).filter (d, i, self) ->
                self.indexOf(d) == i

            center = {
                x: width / 2
                y: height / 2
            }

            fixed_vertex = {
                x: (1 - 0.618) * width / 2
                y: height / 2
            }

            r = 0.618 * width / 2
            n = position_names.length

            vertices = {}
            for d, i in position_names
                if not i
                    continue
                vertices[d] = {
                    x: center.x + r * Math.cos(2 * Math.PI * i / n)
                    y: center.y + r * Math.sin(2 * Math.PI * i / n)
                }
            vertices[position_names[0]] = fixed_vertex

            force.on "tick", (e) ->

                k = 0.1 * e.alpha
                nodes.forEach (o, i) ->
                    o.y += k * (vertices[position_value(o)].y - o.y)
                    o.x += k * (vertices[position_value(o)].x - o.x)

                node
                    .selectAll "circle"
                    .attr "cx", (d) -> d.x
                    .attr "cy", (d) -> d.y
                                     
                link.attr "d", (d) ->
                    "M#{d[0].x},#{d[0].y}S#{d[1].x},#{d[1].y} #{d[2].x},#{d[2].y}"

                node.attr "transform", (d) ->
                    "translate(#{d.x}, #{d.y})"
                node
                    .selectAll "text"
                    .transition()
                    .attr "dx", (d) ->
                        if d.x > width / 2
                            circle_radius + d.counts
                        else
                            -circle_radius - d.counts
                    .style "text-anchor", (d) ->
                        if d.x > width / 2
                            "start"
                        else
                            "end"

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
                        .attr "cx", width - 2 * circle_radius
                        .attr "cy", 9
                        .attr "r", circle_radius
                    circles
                        .style "fill", color
                    texts = d3.select this
                        .selectAll "text"
                        .data [d]
                    texts.enter()
                        .append "text"
                        .attr "x", width - 4 * circle_radius - 2
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
                self.indexOf(d) == i

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
                        .attr "d", "M#{width - 4 * circle_radius},9L#{width},9"
                        .attr "class", (d) -> "link #{d}" 
                    texts = d3.select this
                        .selectAll "text"
                        .data [d]
                    texts.enter()
                        .append "text"
                        .attr "x", width - 4 * circle_radius - 2
                        .attr "y", 9
                        .attr "dy", circle_radius
                        .style "text-anchor", "end"
                    texts
                        .text (d) -> link_legend[d]

            offset = 4 * circle_radius * color.domain().length + 4 * circle_radius
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

    chart.position_value = (value) ->
        if not arguments.length
            return position_value
        position_value = value
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
