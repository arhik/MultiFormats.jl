#
#

using MultiFormats

bytes = rand(UInt8, 4)

wrappedBytes = hashWrap(:sha1, bytes)

returnBytes = hashUnwrap(:sha1, wrappedBytes)

@testset "MultiHash tests" begin
	@test bytes == returnBytes
end

