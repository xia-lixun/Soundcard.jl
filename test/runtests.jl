import Soundcard
using Test




let (ndev, digest) = Soundcard.device()
    @test ndev > 0
    @info "Soundcard device populate" digest
end