using Random
using Distributions

const FRAME_FLAG = "01111110"
const PACKET_LENGTH = 50
const CRC_LENGTH = 32
const DAMAGE_TENDENCY = 0.5

function frame_packet(input::IO)
    sequence::String = read(input, String)
    frames_count::Int = ceil(length(sequence) / PACKET_LENGTH)
    frames = Vector{String}(undef, frames_count)

    println("Packet length: $(PACKET_LENGTH) bits\nCRC length: $(CRC_LENGTH) bits\nFrame flag: [$(FRAME_FLAG)]\nStarting bit sequence: [$(sequence)]\n")

    output = open("framed_packets.txt", "w")
    
    println("Packets before framing (FLAG || PACKET | CRC || FLAG):")
    for i in 1:frames_count
        lower_bound::Int = ((i - 1) * PACKET_LENGTH)   
        upper_bound::Int = i * PACKET_LENGTH

        if upper_bound > length(sequence)  
            upper_bound = length(sequence)
        end

        chunk::String = SubString(sequence, lower_bound + 1, upper_bound)
        chunk_crc::UInt32 = Base._crc32c(chunk)
        crc_binary = bitstring(chunk_crc)

        println("> Packet number $i: [$(FRAME_FLAG)] || [$(chunk)] | [$(crc_binary)] || [$(FRAME_FLAG)]")

        chunk *= crc_binary
        chunk = replace(chunk, "11111" => "111110")
        frames[i] = "$(FRAME_FLAG)$(chunk)$(FRAME_FLAG)"
        
        write(output, "$(frames[i])\n")
    end

    close(output)

    damaged_output = open("damaged_packets.txt", "w")

    println("\nPackets after framing:")
    for i in 1:frames_count   
        random = rand(Uniform(0, 1))
        
        println("> Frame number $i: [$(frames[i])]")

        if random > DAMAGE_TENDENCY
            damaged_chunk = SubString(frames[i], 51:55)
            frames[i] = replace(frames[i], damaged_chunk => "00000")
        end

        write(damaged_output, "$(frames[i])\n")
    end

    close(damaged_output)
end

function restore_packet(input::IO, output::IO)
    sequence::String = read(input, String)
    
    sequence = replace(sequence, "\n" => "")
    sequence = replace(sequence, FRAME_FLAG => "")
    sequence = replace(sequence, "111110" => "11111")
    
    frames_count::Int = ceil(length(sequence) / (PACKET_LENGTH + CRC_LENGTH))
    frames_packet = Array{String}(undef, frames_count)
    frames_crc = Array{String}(undef, frames_count)

    println("After restoring:")
    for i in 1:frames_count 
        packet_lower_bound::Int = ((i - 1) * (PACKET_LENGTH + CRC_LENGTH))
        packet_crc_shift::Int = (i * PACKET_LENGTH) + ((i - 1) * CRC_LENGTH)
        crc_upper_bound::Int = i * (PACKET_LENGTH + CRC_LENGTH)

        if crc_upper_bound > length(sequence)
            packet_crc_shift = length(sequence) - CRC_LENGTH
            crc_upper_bound = length(sequence)
        end

        frames_packet[i] = SubString(sequence, packet_lower_bound + 1, packet_crc_shift)
        frames_crc[i] = SubString(sequence, packet_crc_shift + 1, crc_upper_bound)
        new_crc::UInt32 = Base._crc32c(frames_packet[i])

        println("> Packet number $i: [$(frames_packet[i])]")
        print(" \\--> Old CRC: [$(frames_crc[i])] | New CRC: [$(bitstring(new_crc))] | ")
        if bitstring(new_crc) == frames_crc[i]
            print("CRC check: TRUE (frame saved in restored_sequence.txt)\n")
            write(output, "$(frames_packet[i])")
        else
            print("CRC check: FALSE (frame skipped)\n")
        end
    end

end

function main()

    println("\n==================================[ FRAMING ]==================================\n")

    starting_bits = open("start_sequence.txt", "r")
    println("\t+---------------------------------------------------------------+")
    println("\t|Reading file start_sequence.txt to frame data with bit stuffing|")
    println("\t+---------------------------------------------------------------+\n")
    frame_packet(starting_bits)
    println("\nBit stuffed packets saved in \"framed_packets.txt\"")
    close(starting_bits)

    println("\n==================================[ RESTORING ]==================================\n")

    stuffed_bits = open("framed_packets.txt", "r")
    restored = open("restored_sequence.txt", "w")
    println("\t+-----------------------------------------------------------+")
    println("\t|Reading file framed_packets.txt to restore data from frames|")
    println("\t+-----------------------------------------------------------+\n")
    restore_packet(stuffed_bits, restored)
    println("\nRestored packets saved in \"restored_sequence.txt\"")
    close(restored)
    close(stuffed_bits)

    println("\n===========================[ RESTORING DAMAGED FRAMES ]===========================\n")

    damaged_packets = open("damaged_packets.txt", "r")
    restored_damaged = open("restored_damaged_sequence.txt", "w")
    println("\t+-----------------------------------------------------------+")
    println("\t|Reading file damaged_frames.txt to restore data from frames|")
    println("\t+-----------------------------------------------------------+\n")
    restore_packet(damaged_packets, restored_damaged)
    println("\nRestored damaged packets possibly saved in \"restored_damaged_sequence.txt\"")
    close(restored_damaged)
    close(stuffed_bits)

    println("\n================================================================================\n")
end

main()