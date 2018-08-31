module Soundcard
using SharedArrays
# int record(float * pcm_record, int64_t record_channels, int64_t record_frames, int64_t samplerate);
# int play(const float * pcm_play, int64_t play_channels, int64_t play_frames, int64_t samplerate);
# int playrecord(const float * pcm_play, int64_t play_channels, float * pcm_record, int64_t record_channels, int64_t common_frames, int64_t samplerate);


modulepath(name) = realpath(joinpath(dirname(pathof(name)),".."))
"""
    init()

install binary dependencies to "C:\\Drivers\\Julia\\"
"""
function __init__()
    mkpath("C:\\Drivers\\Julia\\")
    modpath = modulepath(Soundcard)
    cp(joinpath(modpath, "deps/usr/lib/portaudio_x64.dll"), "C:\\Drivers\\Julia\\portaudio_x64.dll", force=true)
    cp(joinpath(modpath, "deps/usr/lib/soundcard_api.dll"), "C:\\Drivers\\Julia\\soundcard_api.dll", force=true)
end


"""
    device()

populate soundcard devices attached to the workstation
"""
function device()
    buffer = zeros(Int8, 8192)
    numdev = ccall((:list_devices, "C:\\Drivers\\Julia\\soundcard_api"), Int32, (Ptr{Int8},), buffer)
    digest = ""
    for i in buffer
        digest = digest * string(Char(i))
    end
    report = split(digest,'\n')
    numdev, report[1:end-1]
end


"""
    record(dim, fs)

low level api for recording
"""
function record(dim::Tuple{Int64, Int64}, fs::Int64)    # -> Matrix{Float32}
    pcm = zeros(Float32, dim[2] * dim[1])
    ccall((:record, "C:\\Drivers\\Julia\\soundcard_api"), Int32, (Ptr{Float32}, Int64, Int64, Int64), pcm, dim[2], dim[1], fs)
    return transpose(reshape(pcm, dim[2], dim[1]))
end

"""
    play(dat, fs)

low level api for playback
"""
function play(dat::Matrix{Float32}, fs::Int64)
    pcm = interleave(dat)
    ccall((:play, "C:\\Drivers\\Julia\\soundcard_api"), Int32, (Ptr{Float32}, Int64, Int64, Int64), pcm, size(dat)[2], size(dat)[1], fs)
    return nothing
end


"""
    playrecord(dat, ch, fs)

low level api for simultaneous playback and recording
usually we have ch = size(mixmic,1)
"""
function playrecord(dat::Matrix{Float32}, ch::Int64, fs::Int64)    # -> Matrix{Float32}
    pcmo = interleave(dat)
    pcmi = zeros(Float32, size(dat)[1] * ch)
    ccall((:playrecord, "C:\\Drivers\\Julia\\soundcard_api"), Int32, (Ptr{Float32}, Int64, Ptr{Float32}, Int64, Int64, Int64), pcmo, size(dat)[2], pcmi, ch, size(dat)[1], fs)
    return transpose(reshape(pcmi, ch, size(dat)[1]))
end


function interleave(x::Matrix{T}) where T <: Number
    fr,ch = size(x)
    y = zeros(T, ch * fr)        
    k::Int64 = 0
    for i = 1:fr 
        y[k+1:k+ch] = x[i,:]
        k += ch
    end
    return y
end

"""
    mixer(x, mix)

apply mixing matrix 'mix' to input signal matrix 'x' for logical signal routing
"""
function mixer(x::AbstractMatrix{T}, mix::AbstractMatrix) where T <: AbstractFloat
    mm = convert(Matrix{T}, mix)
    y = x * mm
    maximum(abs.(y)) >= one(T) && (@error "soundcard mixer: sample clipping!")
    return y
end





                                    ## --------------------------
                                    ##    API for ease of use
                                    ## --------------------------

function playrecord(playing::Matrix, ms::Matrix, mm::Matrix, fs)::Matrix{Float32}
    out = convert(Matrix{Float32}, playing)
    recording = mixer(playrecord(mixer(out,ms), size(mm,1), convert(Int64,fs)), mm)
end

function play(playing::Matrix, ms::Matrix, fs)
    out = convert(Matrix{Float32}, playing)
    play(mixer(out, ms), Int64(fs))
end

function record(samples::Integer, mm::Matrix, fs)::Matrix{Float32}
    recording = mixer(record((convert(Int64,samples),size(mm,1)), Int64(fs)), mm)
end



                                    ## --------------------------
                                    ##  API for ultralow latency
                                    ## --------------------------
# x = Soundcard.mixer(convert(Matrix{Float32},out), ms)
# y = SharedArray{Float32,1}(Soundcard.interleave(x))
play(size_x::Tuple{Int64,Int64}, y::SharedArray{Float32,1}, fs) = 
    ccall((:play,"C:\\Drivers\\Julia\\soundcard_api"), Int32, (Ptr{Float32}, Int64, Int64, Int64), y, size_x[2], size_x[1], fs)  # remotecall
# async tasks...
# fetch(done)



# y = SharedArray{Float32,1}(zeros(Float32, size(mm,1)*samples))
record(y::SharedArray{Float32,1}, size_mm::Tuple{Int64,Int64}, samples, fs) = 
    ccall((:record,"C:\\Drivers\\Julia\\soundcard_api"), Int32, (Ptr{Float32}, Int64, Int64, Int64), y, size_mm[1], samples, fs)  # remotecall
# async tasks...
# fetch(done)
# recording = Soundcard.mixer(transpose(reshape(y,size(mm,1),samples)), mm)



# samples = size(out,1)
# x = Soundcard.mixer(convert(Matrix{Float32},out), ms)
# y = SharedArray{Float32,1}(Soundcard.interleave(x))
# z = SharedArray{Float32,1}(zeros(Float32,size(mm,1)*samples))
playrecord(size_x::Tuple{Int64,Int64}, y::SharedArray{Float32,1}, z::SharedArray{Float32,1}, size_mm::Tuple{Int64,Int64}, fs) =
    ccall((:playrecord, "C:\\Drivers\\Julia\\soundcard_api"), Int32, (Ptr{Float32}, Int64, Ptr{Float32}, Int64, Int64, Int64), y, size_x[2], z, size_mm[1], size_x[1], fs)
# async tasks...
# fetch(done)
# recording = Soundcard.mixer(transpose(reshape(z,size(mm,1),samples)), mm)



end # module
