using MultiFormats

inputString = "Hello world! I am here. Did I reach there."

io = IOBuffer()
write(io, inputString)
seek(io, 0)

buf = read(io)

encbytes = MultiFormats.multiEncode(:base64, buf)

encbytes .|> Char |> String

decbytes = MultiFormats.multiDecode(:base64, encbytes)

outputString = decbytes .|> Char |> String

@testset "Encode and decode match" begin
	@test inputString == strip(outputString, '\0')
end

