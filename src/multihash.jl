using SHA

abstract type AbstractMultiHash end

struct MultiHash{T} <: AbstractMultiHash where T<:AbstractMultiCodec
end

function wrap(a::MultiHash{T}, b) where T
	code = getCodeCode(T)
end

# for codec in codecSymbolList
	# sName = "MultiHash_"*replace(string(codec), "-"=>"_") |> Symbol
# 
	# function wrap(a::MultiHash{T}, b)
		# code()
	# end
# end


