using SHA
using MultiFormats
export multiHash, hashWrap, hashUnwrap

codecs = MultiFormats.codecSymbolList

for incodec in codecs
	if codecTag(incodec) == MultiFormats.MULTIHASH
		if isdefined(SHA, incodec)
			if incodec == :identity
				continue
				# struct IDENTITY_CTX end
				# quote
					# function multiHash(a::IDENTITY_CTX, bytes::Vector{UInt8})
						# identity(bytes)
					# end
				# end
			else
				ctx = Symbol(uppercase(incodec |> string)*"_CTX")
				quote
					function multiHash(cntxt::$ctx, bytes::Vector{UInt8})
						update!(cntxt, bytes)
						digest!(cntxt)
					end
					function Base.length(a::$ctx)
						return SHA.digestlen($ctx)
					end
					function Base.length(a::Type{$ctx})
						return SHA.digestlen($ctx)
					end
				end |> eval
			end
		end
	end
end

function multiHash(a::Symbol, bytes::Vector{UInt8})
	@assert codecTag(a) == MultiFormats.MULTIHASH
	cntxt = Base.getproperty(SHA, Symbol(uppercase(a |> string)*"_CTX"))()
	multiHash(cntxt, bytes)
end

function hashWrap(a::Symbol, bytes::Vector{UInt8})
	@assert codecTag(a) == MultiFormats.MULTIHASH
	cntxt = Base.getproperty(SHA, Symbol(uppercase(a|>string)*"_CTX"))()
	len = length(cntxt) |> UInt |> UVarInt
	pushfirst!(copy(bytes),  (codecCode(a) |> UVarInt)..., (len)...)
end

function hashUnwrap(a::Symbol, bytes::Vector{UInt8})
	@assert codecTag(a) == MultiFormats.MULTIHASH
	code = codecCode(a) |> UInt |> UVarInt
	cntxt = Base.getproperty(SHA, Symbol(uppercase(a |> string)*"_CTX"))()
	len = length(cntxt) |> UInt |> UVarInt
	@assert bytes[1:(code |> length)] == code "Codec Code doesn't match"
	@assert bytes[length(code)+1:length(code) + (len |> length)] == len
	return bytes[(len|>length)+length(code)+1:end]
end

