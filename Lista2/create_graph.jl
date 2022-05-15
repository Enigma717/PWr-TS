# Marek Traczyński (261748)
# Technologie sieciowe
# Lista 2

using Graphs
using GraphPlot, Compose
import Cairo, Fontconfig

function create_graph()
    graph::SimpleGraph = SimpleGraph(20, 0)

    add_edge!(graph, 1, 2)
    add_edge!(graph, 2, 3)
    add_edge!(graph, 3, 4)
    add_edge!(graph, 4, 5)
    add_edge!(graph, 5, 6)
    add_edge!(graph, 6, 7)
    add_edge!(graph, 7, 8)
    add_edge!(graph, 8, 9)
    add_edge!(graph, 9, 10)
    add_edge!(graph, 10, 11)
    add_edge!(graph, 11, 12)
    add_edge!(graph, 12, 1)

    add_edge!(graph, 13, 14)
    add_edge!(graph, 14, 15)
    add_edge!(graph, 15, 16)
    add_edge!(graph, 16, 17)
    add_edge!(graph, 17, 18)
    add_edge!(graph, 18, 15)
    add_edge!(graph, 18, 19)
    add_edge!(graph, 19, 20)
    add_edge!(graph, 20, 13)

    add_edge!(graph, 1, 13)
    add_edge!(graph, 2, 13)
    add_edge!(graph, 3, 14)
    add_edge!(graph, 4, 15)
    add_edge!(graph, 5, 16)
    add_edge!(graph, 7, 17)
    add_edge!(graph, 8, 18)
    add_edge!(graph, 9, 19)
    add_edge!(graph, 11, 20)

    # nodelabel = [i for i in 1:nv(graph)]
    # draw(PNG("graph.png", 20cm, 20cm), gplot(graph, nodelabel = nodelabel))

    return graph
end