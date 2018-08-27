import Soundcard
using Test

install = Soundcard.init(Soundcard)
@test  install == "C:\\Drivers\\Julia\\soundcard_api.dll"

let (ndev, digest) = Soundcard.device()
    @test ndev > 0
    @info "Soundcard device populate" digest
end