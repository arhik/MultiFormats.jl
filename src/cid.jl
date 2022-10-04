using CodecBase
using Base58

export CIDv1, cidWrap, cidUnwrap

struct CIDv1
	base::Symbol
	version::Symbol
	codec::Symbol
	hash::Vector{UInt8}
end

cid = CIDv1(:base64, :v1, :dag_pb, rand(UInt8, 32))

function cidWrap(cid::CIDv1; binary=true)
	cidVersionCode = codecCode(Symbol(:cid, cid.version))
	codecCodeVal = codecCode(cid.codec) # hardcoded
	if binary == false
		push!(UInt8[], (cidVersionCode |> UVarInt)..., (codecCodeVal |> UVarInt)..., hash...)
	else binary == true
		base58encode(
			push!(
				UInt8[],
				baseCode(:base58btc),
				(cidVersionCode |> UVarInt)...,
				(codecCodeVal |> UVarInt)...,
				cid.hash...
			)
		)
	end
end

function cidUnwrap(cid::CIDv1, hash)
	# CID
end

