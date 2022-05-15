# Marek Traczyński (261748)
# Technologie sieciowe
# Lista 2

using Graphs
using Random
using Distributions
include("create_graph.jl")

global_graph = create_graph()

function generate_traffic(graph::Graph)
    traffic_matrix = Array{Int64}(undef, nv(graph), nv(graph))

    for i in 1:nv(graph)
        for j in 1:nv(graph)
            if j == i
                traffic_matrix[i, j] = 0
            else
                traffic_matrix[i, j] = rand(1:20)
            end
        end
    end

    return traffic_matrix
end

function check_edges(path::Vector{Edge{Int64}}, edge::Edge)
    for i in 1:length(path)
        if path[i] == edge || (dst(path[i]) == src(edge) && src(path[i]) == dst(edge))
            return true
        end
    end

    return false
end

function flow_function(graph::Graph, traffic_matrix::Array{Int64})
    graph_edges = collect(edges(graph))
    vertices_count::Int64 = nv(graph)
    edges_count::Int64 = ne(graph)
    lambda::Array{Int64} = zeros(edges_count)

    for edge in 1:edges_count
        for i in 1:vertices_count
            for j in 1:vertices_count
                if (i == j)
                    continue
                end
                path = a_star(graph, i, j)
                if check_edges(path, graph_edges[edge]) == true
                    lambda[edge] += traffic_matrix[i, j]
                end
            end
        end
    end

    return lambda
end

function bandwidth_function(graph::Graph, lambdas::Array{Int64}, byte_size::Int64)
    packet_size::Int64 = byte_size * 8
    edges_count = ne(graph)
    c_value::Array{Int64} = zeros(edges_count)

    for edge in 1:edges_count
        c_value[edge] = rand(5:10) * lambdas[edge] * packet_size
    end

    return c_value
end

function latency_function(graph::Graph, traffic_matrix::Array{Int64}, lambdas::Vector{Int64}, c_values::Vector{Int64}, byte_size::Int64)
    packet_size::Int64 = byte_size * 8
    traffic_sum::Int64 = 0
    t_sum::Float64 = 0
    vertices_count = nv(graph)
    edges_count = ne(graph)

    for i in 1:vertices_count
        for j in 1:vertices_count
            traffic_sum += traffic_matrix[i, j]
        end
    end

    for edge in 1:edges_count
        t_sum += (lambdas[edge] / ((c_values[edge]/packet_size) - lambdas[edge]))
    end 

    return (1/sum(lambdas)) * t_sum 
end

function reliability_test(traffic_matrix::Array{Int64}, probability::Float64, max_latency::Float64, byte_size::Int64, c_array::Array{Int64}, reps::Int64)
    packet_size::Int64 = byte_size * 8
    successes::Int64 = 0
    success_rate::Float64 = 0
    test_latency::Float64 = 0


    println("----------PARAMETERS----------")
    println("Probability: $probability")
    println("T_max: $max_latency")
    println("Packet size (in bytes): $byte_size")
    println("Repetitions: $reps")
    println("------------------------------")


    for i in 1:reps
        tested_graph = deepcopy(global_graph)
        tested_edges = collect(edges(tested_graph))
        
        for edge in 1:ne(global_graph)
            random = rand(Uniform(0, 1))

            if random > probability
                rem_edge!(tested_graph, tested_edges[edge])
            end
        end
        
        if is_connected(tested_graph) == false
            continue
        end

        tested_edges = collect(edges(tested_graph))
        tested_lambda = flow_function(tested_graph, traffic_matrix)
        
        for edge in 1:ne(tested_graph)
            if tested_lambda[edge] >= (c_array[edge] / packet_size)
                break
            end

            if edge == ne(tested_graph)
                tested_avg_latency = latency_function(tested_graph, traffic_matrix, tested_lambda, c_array, 1500)

                if tested_avg_latency < max_latency
                    test_latency += tested_avg_latency
                    successes += 1
                end
            end
        end

        if rem(i, (reps/20)) == 0
            println("$i out of $reps tests done (", (i/reps)*100, "%)")
        end
    end

    success_rate = 100 * (successes / reps)

    print("------------------------------")
    print("\nSUCCESS RATE: $success_rate%")
    println()

    return success_rate
end

function main()
    traffic = generate_traffic(global_graph)
    probability = 0.99
    max_latency = 0.00065
    byte_packet_size = 1500
    repetitions = 1000

    file = open("data.csv", "w+") 
    write(file, "data; success_rate;\n")

    start_lambda = flow_function(global_graph, traffic)
    bandwidth = bandwidth_function(global_graph, start_lambda, byte_packet_size)

    @time begin
        for i in 1:20
            println()
            println("\t==========STARTING NETWORK RELIABILITY TEST $i==========")
            println()

            rate = reliability_test(traffic, probability, max_latency, byte_packet_size, bandwidth, repetitions)
        
            write(file, "$i; $rate;\n")
        end
        
        close(file)
    end
end

main()