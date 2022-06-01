import Base.@kwdef
using Random

logs = open("simulation_logs.txt", "w")


#############
#  STRUCTS  #
#############

@kwdef mutable struct Station
    name::String = ""
    position::Int = 0
    frames_count::Int = 0
    delay::Int = 0
    jams_detected::Int = 0
    is_active::Bool = false
    jammed::Bool = false
end

@kwdef mutable struct Packet
    source_station::Station = nothing
    direction::Int = 0
    special_packet::Bool = source_station.jammed
end

@kwdef mutable struct Ethernet
    wire_length::Int = 0
    wire_packets::Vector{Vector{Packet}} = fill_vector([], wire_length)
    stations_positions::Vector{Station} = fill_vector(Station(), wire_length)
    transmitting_stations::Vector{Station} = []
    stations_copy::Vector{Station} = []
end


#########################
#  UTILITIES FUNCTIONS  #
#########################

function fill_vector(element::Any, limit::Int)
    return [element for i in 1:limit]
end

function check_packets_traffic(wire::Vector{Vector{Packet}})
    for fragment in wire
        if !(isempty(fragment))
            return false
        end
    end
    
    return true
end

function add_station(ethernet::Ethernet, station::Station)
    station_copy = deepcopy(station)
    if station.position < 1 || station.position > ethernet.wire_length
        println("Can't place station outside the network!")
    else
        ethernet.stations_positions[station.position] = station
        push!(ethernet.transmitting_stations, station)
        push!(ethernet.stations_copy, station_copy)
    end
end


################
#  SIMULATION  #
################

function simulation(ethernet::Ethernet)
    iteration::Int = 1
    
    file_header::String = header_logger(ethernet)
    print(file_header)
    write(logs, "$(file_header)")

    while isempty(ethernet.transmitting_stations) == false || check_packets_traffic(ethernet.wire_packets) == false
        wire_logs::String = wire_logger(ethernet.wire_packets)
        print("Iteration $(iteration):\t$(wire_logs)")
        write(logs, "Iteration $(iteration):\t$(wire_logs)")

        simulation_tick(ethernet)
        print("\n")
        write(logs, "\n")

        iteration += 1
    end
    
    simulation_results::String = results_logger(ethernet)
    print(simulation_results)
    write(logs, "$(simulation_results)")
end

function simulation_tick(ethernet::Ethernet)
    temp_packets::Vector{Vector{Packet}} = fill_vector([], ethernet.wire_length)
    move_packets!(ethernet, temp_packets)
    stations_transmit!(ethernet, temp_packets)
    ethernet.wire_packets = temp_packets
end

function move_packets!(ethernet::Ethernet, temp_packets::Vector{Vector{Packet}})
    for (i, wire_fragment) in enumerate(ethernet.wire_packets)
        for packet in wire_fragment
            if packet.direction == 1 && i < ethernet.wire_length
                push!(temp_packets[i + 1], packet)
            elseif packet.direction == -1 && i > 1
                push!(temp_packets[i - 1], packet)
            elseif packet.direction == 0
                if i > 1 
                    push!(temp_packets[i - 1], Packet(source_station = packet.source_station, direction = -1))
                end
                if i < ethernet.wire_length
                    push!(temp_packets[i + 1], Packet(source_station = packet.source_station, direction = 1))
                end 
            end
        end        
    end
end

function stations_transmit!(ethernet::Ethernet, temp_packets::Vector{Vector{Packet}})
    jam_delay::Int = 0

    for (i, station) in enumerate(ethernet.transmitting_stations)
        if station.is_active == false
            if station.delay == 0
                print("| Station [$(station.name)] started transmitting | ")
                write(logs, "| Station [$(station.name)] started transmitting | ")

                station.is_active = true
                station.delay = 2 * ethernet.wire_length
            else
                station.delay -= 1
            end
        elseif station.is_active == true && station.delay == 0
            print("| Station [$(station.name)] stopped transmitting | ")
            write(logs, "| Station [$(station.name)] stopped transmitting | ")

            station.is_active = false

            if station.jammed == true
                station.jams_detected += 1
                ethernet.stations_copy[i].jams_detected += 1
                
                jam_delay = 2 ^ min(station.jams_detected, 10) - 1

                station.jammed = false
                station.delay = rand(0:jam_delay)
            else
                station.frames_count -= 1
                station.jams_detected = 0

                if station.frames_count == 0
                    filter!(x -> x != station, ethernet.transmitting_stations)
                end
            end
        elseif station.is_active == true && station.delay > 0
            if station.jammed == false && !isempty(temp_packets[station.position])
                print("| Station [$(station.name)] detected jam | ")
                write(logs, "| Station [$(station.name)] detected jam | ")

                station.jammed = true
                station.delay = 2 * ethernet.wire_length
            end

            push!(temp_packets[station.position], Packet(source_station = station, direction = 0))
            station.delay -= 1
        end
    end
end


#######################
#  LOGGING FUNCTIONS  #
#######################

function wire_logger(wire::Vector{Vector{Packet}})
    log::String = "[ "
    for fragment in wire
        log *= "["
        for packet_position in 1:length(fragment)
            if fragment[packet_position].special_packet == true
                log *= "<$(fragment[packet_position].source_station.name)>"
            else
                log *= "$(fragment[packet_position].source_station.name)"
            end
        end
        if length(fragment) == 0
            log *= "_"
        end
        log *= "] "
    end
    log *= "]\t\t\t\t"

    return log
end

function stations_logger(stations::Vector{Station})
    log::String = "[ "
    for station in stations
        if station.name != ""
            log *= "[$(station.name)] "
        else
            log *= "[_] "
        end 
    end
    log *= "]\n"

    return log
end

function header_logger(ethernet::Ethernet)
    stations_logs::String = stations_logger(ethernet.stations_positions)

    header::String = "\n=============================[ CSMA/CD Simulation info ]=============================\n\n"
    header *= "Stations positions in the network: $(stations_logs)\n"
    header *= "\t       +---------------+\n"
    header *= "\t       | Stations info |\n"
    header *= "\t       +---------------+\n"

    header *= "\n---------------------------------------\n"
    for station in ethernet.transmitting_stations
        header *= "> Name: $(station.name)\n"
        header *= "|-> Position: $(station.position)\n"
        header *= "|--> Number of frames to transmit: $(station.frames_count)\n"
        header *= "\\---> Transmition start delay: $(station.delay)\n"
        header *= "---------------------------------------\n"
    end

    header *= "\n===============================[ Simulation started ]===============================\n\n"

    return header
end

function results_logger(ethernet::Ethernet)
    total_jams::Int = 0
    
    result::String = "\n"
    result *= "\t   +---------------------+\n"
    result *= "\t   | Simulation finished |\n"
    result *= "\t   +---------------------+\n"
    result *= "\n=============================[ Simulation results ]=============================\n\n"
    
    result *= "-----------------------------------\n"
    for station in ethernet.stations_copy
        result *= "> Station name: $(station.name)\n"
        result *= "\\-> Jams detected by station: $(station.jams_detected)\n"
        result *= "-----------------------------------\n"
        total_jams += station.jams_detected
    end

    result *= "\n>> Total jams detected: $(total_jams) <<\n"
    result *= "\n================================================================================\n"

    return result
end


##########
#  MAIN  #
##########

function main()
    network = Ethernet(wire_length = 8)

    add_station(network, Station(name = "A", position = 1, frames_count = 2, delay = 0))
    add_station(network, Station(name = "B", position = 4, frames_count = 1, delay = 6))
    add_station(network, Station(name = "C", position = 8, frames_count = 3, delay = 10))

    simulation(network)

    close(logs)
end
  
main()