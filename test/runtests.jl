import Soundcard
using Test


let install = Soundcard.init(Soundcard)
    @test install == "C:\\Drivers\\Julia\\soundcard_api.dll"
    # ndev, digest = Soundcard.device()
    # @test ndev > 0
    # @info "Soundcard device populate" digest
end