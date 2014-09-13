---
---

if not d3.chart?
    d3.chart = {}

d3.chart.force_bezier = ->
    width = 960
    height = width * 0.7
    color_value = (d) -> d.class
    color = d3.scale.category20()
    link_distance = 20
    friction = 0.95
    link_strength = 1
    circle_radius = 5
    transition_lasts = 1000

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
                .size [width, height] 

            # select the svg if it exists
            svg = d3.select this
                .selectAll "svg"
                .data [data]

            # otherwise create the skeletal chart
            g_enter = svg.enter()
                .append "svg"
                .append "g"

            defs = g_enter.append "defs"
            filter = defs.append "filter"
                .attr "id", "dropshadow"
                .attr "x", "-50%"
                .attr "y", "-50%"
                .attr "height", "200%"
                .attr "width", "200%"
            filter.append 'feGaussianBlur' 
                .attr 'in', 'SourceGraphic' 
                .attr 'stdDeviation', 3  # !!! important parameter - blur
                .attr 'result', 'blur'

            # append offset filter to result of gaussion blur filter
            filter.append 'feOffset' 
                .attr 'in', 'blur'
                .attr 'dx', 0  # !!! important parameter - x-offset
                .attr 'dy', 0  # !!! important parameter - y-offset
                .attr 'result', 'offsetBlur'

            # merge result with original image
            feMerge = filter.append 'feMerge'

            # first layer result of blur and offset
            feMerge.append 'feMergeNode' 
                .attr 'in', 'offsetBlur'

            # original image on top
            feMerge.append 'feMergeNode'
                .attr 'in', 'SourceGraphic'
            # end filter stuff

            g_enter.append "g"
                .classed "links", true

            g_enter.append "g"
                .classed "nodes", true

            g_enter.append "g"
                .classed "color_legends", true

            g_enter.append "g"
                .classed "link_legends", true

            g_enter.append "g"
                .classed "size_legends", true

            svg
                .attr "width", width 
                .attr "height", height 

            g = svg.select "g"

            nodes = data.nodes.slice()
            links = []
            bilinks = []
            data.links.forEach (link, j) ->
                s = nodes[link.source]
                t = nodes[link.target]
                i = {} # intermediate node
                nodes.push i
                links.push(
                    {source: s, target: i},
                    {source: i, target: t}
                )
                bilink = [s, i, t]
                bilink.index = j
                bilink.type = link.type
                bilinks.push bilink

            passion_links = data.links.filter (d) -> d.type == "passion"
            nodes_with_occurrences = data.nodes.map (d, i) ->
                d.counts = (
                    count_occurrences(
                        passion_links, i, (e) -> e.target
                    ) +
                    count_occurrences(
                        passion_links, i, (e) -> e.source)
                ) - 1
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
                .attr "id", (d) -> "link-#{d.index}"
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
                .attr "id", (d) -> "node-#{d.index}"
                .attr "r", (d) ->
                    circle_radius + d.counts
                .style "fill", (d) ->
                    color color_value d
                .on "mouseover", (d) ->
                    connected = ["#node-#{d.index}"]
                    for e in bilinks
                        if e[0].index == d.index
                            connected.push "#link-#{e.index}", "#node-#{e[2].index}"
                        else if e[2].index == d.index
                            connected.push "#link-#{e.index}", "#node-#{e[0].index}"
                    d3.selectAll connected.join()
                        .classed "active", true
                        .attr "filter", "url(#dropshadow)"
                .on "mouseout", (d) ->
                    connected = ["#node-#{d.index}"]
                    for e in bilinks
                        if e[0].index == d.index
                            connected.push "#link-#{e.index}", "#node-#{e[2].index}"
                        else if e[2].index == d.index
                            connected.push "#link-#{e.index}", "#node-#{e[0].index}"
                    d3.selectAll connected.join()
                        .classed "active", false
                        .attr "filter", null

            node
                .append "text"
                .attr "dy", ".35em"
                .text (d) -> d.name

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
                node
                    .selectAll "text"
                    .transition(transition_lasts)
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

            chart.update_color_legend = ->
                node.selectAll "circle"
                    .transition(transition_lasts)
                    .style "fill", (d) ->
                        color color_value d

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
                            .classed "node-circle", true
                            .attr "cx", width - 2 * circle_radius
                            .attr "cy", 9
                            .attr "r", circle_radius
                        circles
                            .transition()
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

            chart.update_color_legend()

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
                        .text (d) -> d

            offset = 4 * circle_radius * color.domain().length + 4 * circle_radius
            link_legends
                .attr "transform", (d, i) ->
                    "translate(0, #{offset + (4 * circle_radius + 2) * i})"

            link_legends.exit().remove()

            size_legends = g.select "g.size_legends"
                .selectAll "text"
                .data ["r = #passion"]

            size_legends
                .enter()
                .append "text"
                .attr "x", width
                .attr "y", 9 + 2 * offset
                .attr "dy", circle_radius
                .style "text-anchor", "end"
                .text (d) -> d

            size_legends.exit().remove()



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
