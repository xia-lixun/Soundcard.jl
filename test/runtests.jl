import Soundcard
using Test
using Statistics
using SharedArrays
using WAV




let (ndev, digest) = Soundcard.device()
    @test ndev > 0
    @info "Soundcard device populate" digest
end


let x = 10^(-20/20) * randn(192000,1), ms = zeros(1,2)
    ms[1,2] = 1
    y = Soundcard.play(x, ms, 48000)
    @test y == nothing
end

let mm = zeros(8,1)
    mm[2,1] = 1
    y = Soundcard.record(48000, mm, 48000)
    @test typeof(y) == Matrix{Float32}
end

let x = 10^(-20/20) * randn(192000,1), ms = zeros(1,2), mm = zeros(8,1)
    ms[1,1] = 1
    mm[2,1] = 1
    y = Soundcard.playrecord(x, ms, mm, 48000)
    @info "loop gain" std(y)/std(x)
    @test std(y)/std(x) < 1e-4

    ms[1,2] = 1
    mm[2,1] = 1
    y = Soundcard.playrecord(x, ms, mm, 48000)
    @info "loop gain" std(y)/std(x)
    @test std(y)/std(x) > 0.1
end


let out = 10^(-20/20) * randn(192000,1), ms = zeros(1,2)
    ms[1,2] = 1
    x = Soundcard.mixer(convert(Matrix{Float32},out), ms)
    y = SharedArray{Float32,1}(Soundcard.interleave(x))
    r = Soundcard.play(size(x), y, 48000)
        # async tasks...
    # fetch(done)
    @info r
    @test r == 0
end


let out = 10^(-20/20) * randn(192000,1), mm = zeros(8,1)
    mm[2,1] = 1
    samples = 96000
    y = SharedArray{Float32,1}(zeros(Float32, size(mm,1)*samples))
    Soundcard.record(y, size(mm), samples, 48000)
        # async tasks...
    # fetch(done)
    recording = Soundcard.mixer(transpose(reshape(y,size(mm,1),samples)), mm)
    @test typeof(recording) == Matrix{Float32}
end


let out = 10^(-20/20) * randn(192000,1), ms = zeros(1,2), mm = zeros(8,1)
    ms[1,1] = 1
    mm[2,1] = 1
    samples = size(out,1)
    x = Soundcard.mixer(convert(Matrix{Float32},out), ms)
    y = SharedArray{Float32,1}(Soundcard.interleave(x))
    z = SharedArray{Float32,1}(zeros(Float32,size(mm,1)*samples))
    r = Soundcard.playrecord(size(x), y, z, size(mm), 48000)
        # async tasks...
    # fetch(done)
    recording = Soundcard.mixer(transpose(reshape(z,size(mm,1),samples)), mm)
    @info r
    @test r == 0
    @test typeof(recording) == Matrix{Float32}
end

let s = 10^(-10/20) * sinpi.(2*1000*(0:48000-1)/48000), ms = zeros(1,2), mm = zeros(8,1)
    x = s[:,:]
    ms[1,2] = 1
    mm[2,1] = 1
    y = Soundcard.playrecord(x, ms, mm, 48000)
    wavwrite(y, "loop.wav", Fs=48000, nbits=32)
    # m = Libaudio.zerocrossingrate(s)
    # n = Libaudio.zerocrossingrate(y[:,1])
    # @info length(m[m.==1.0])
    # @info length(n[n.==1.0])
end