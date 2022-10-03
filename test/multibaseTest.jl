using MultiFormats
using Base64
using Test

inputString = "light work"

io = IOBuffer()
write(io, inputString)
seek(io, 0)

buf = read(io)
buf = rand(UInt8, 33)

encodedString = MultiFormats.multiEncode(:base64, buf)

@testset "Encode and decode" begin
	@test base64encode(buf) == (multiEncode(:base64, buf) |> String)
	@test base64decode(encodedString) == multiDecode(:base64, encodedString |> collect .|> UInt8)
	@test base64encode(buf)  == multiEncode(:base64, buf) |> String
end

# TODO check for large strings and bytes

