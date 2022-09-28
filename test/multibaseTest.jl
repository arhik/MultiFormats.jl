using MultiFormats
using Base64
using Test

inputString = "light work"

io = IOBuffer()
write(io, inputString)
seek(io, 0)

buf = read(io)

encodedString = MultiFormats.multiEncode(:base64, buf)

@testset "Encode and decode" begin
	@test base64encode(buf) == multiEncode(:base64, buf)
	@test base64encode(inputString) == multiEncode(:base64, inputString)
end

# TODO check for large strings and bytes

