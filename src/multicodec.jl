using CSV
using DataFrames
using Downloads

export codec, codecName, codecSymbol, codecCode, 
	codecTag, codecStatus, codecDescription

# TODO artifact or a permanent location
table = Downloads.download(
	"https://raw.githubusercontent.com/multiformats/multicodec/master/table.csv"
)

multicodecTable = CSV.read(open(table), DataFrame, stripwhitespace=true)

allowmissing(multicodecTable)

# Codec Header
quote
	@enum CodecHeader $(
		(
			names(multicodecTable) .|> uppercase .|> Symbol
		)...
	)
end |> eval

# Codec Tag
codecTagList = select(multicodecTable, "tag").tag
quote
	@enum CodecTag $(
		(
			unique(codecTagList) .|> uppercase .|> Symbol
		)...
	)
end |> eval

# Codec Status
codecStatusList = select(multicodecTable, "status").status 

quote
	@enum CodecStatus $(
		(
			unique(codecStatusList) .|> uppercase .|> Symbol
		)...
	)
end |> eval

# Codec Code
codecCodeList = select(multicodecTable, "code").code .|> Meta.parse

# Codec descriptions
descriptions = select(multicodecTable, "description").description
abstract type AbstractMultiCodec end

codecNameList = select(multicodecTable, "name").name .|> (x) -> replace(x, "-"=>"_")
codecSymbolList = codecNameList .|> Symbol

for (idx, name) in enumerate(codecNameList)
	sName = "MultiCodec_"*name
	structName = sName |> Symbol

	description = descriptions[idx]
	code = codecCodeList[idx]
	tag = codecTagList[idx] .|> uppercase .|> Symbol
	status = codecStatusList[idx] .|> uppercase .|> Symbol
	
	mName = replace(name, "-" => "_")

	quote 
		struct $structName <: AbstractMultiCodec
		end

		getCodecName(a::$structName) = $name
		getCodecName(a::Type{$structName}) = $name
		getCodecName(a::Val{Symbol($mName)}) = $name
		getCodecName(a::Val{$code}) = $name

		getCodecSymbol(a::$structName) = Symbol($mName)
		getCodecSymbol(a::Type{$structName}) = Symbol($mName)
		getCodecSymbol(a::Val{Symbol($mName)}) = a
		getCodecSymbol(a::Val{$code}) = a
		
		getCodec(a::Val{Symbol($mName)}) = $structName
		getCodec(a::Val{$code}) = $structName
		
		getCodecCode(a::$structName) = $code
		getCodecCode(a::Type{$structName}) = $code
		getCodecCode(a::Val{Symbol($mName)}) = getCodecCode(getCodec(a))
		getCodecCode(a::Val{$code}) = getCodecCode(getCodec(a))
			
		getCodecTag(a::$structName) = $tag
		getCodecTag(a::Type{$structName}) = $tag
		getCodecTag(a::Val{Symbol($mName)}) = getCodecTag(getCodec(a))
		getCodecTag(a::Val{$code}) = getCodecTag(getCodec(a))
		
		getCodecStatus(a::$structName) = $status
		getCodecStatus(a::Type{$structName}) = $status
		getCodecStatus(a::Val{Symbol($mName)}) = getCodecStatus(getCodec(a))
		getCodecStatus(a::Val{$code}) = getCodecStatus(getCodec(a))
		
		getCodecDescription(a::$structName) = $description
		getCodecDescription(a::Type{$structName}) = $description
		getCodecDescription(a::Val{Symbol($mName)}) = getCodecDescription(getCodec(a))
		getCodecDescription(a::Val{$code}) = getCodecDescription(getCodec(a))

		# TODO
		Base.show(a::$structName) = begin
			"Codec : $structName $(getCodecStatus(a)), $(getCodecCode(a))"
		end		

		# TODO
		Base.display(a::$structName) = begin
			"Codec : $structName $(getCodecStatus(a)), $(getCodecCode(a))"
		end	
	end |> eval
end

codec(name::Symbol) = getCodec(Val(name))
codec(id::Unsigned) = getCodec(Val(id))
codecCode(name::Symbol) = getCodecCode(Val(name))
codecCode(id::Unsigned) = getCodecCode(Val(id))
codecName(name::Symbol) = getCodecName(Val(name))
codecName(id::Unsigned) = getCodecName(Val(id))
codecSymbol(name::Symbol) = getCodecSymbol(Val(name))
codecSymbol(id::Unsigned) = getCodecSymbol(Val(id))
codecTag(name::Symbol) = getCodecTag(Val(name))
codecTag(id::Unsigned) = getCodecTag(Val(id))
codecStatus(name::Symbol) = getCodecStatus(Val(name))
codecStatus(id::Unsigned) = getCodecStatus(Val(id))
codecDescription(name::Symbol) = getCodecDescription(Val(name))
codecDescription(ud::Unsigned) = getCodecDescription(Val(id))

# TODO
function wrap(::Type{CodecType}, bytes::Vector{UInt8}) where CodecType<:AbstractMultiCodec
	pushfirst!(codecCode(CodecType), bytes)
end

# TODO
function unwrap(::Type{CodecType}, bytes::Vector{UInt8}) where CodecType<:AbstractMultiCodec
	popfirst!(codecCode(CodecType), bytes)
end

function wrap(symbol::Symbol, bytes::Vector{UInt8})
	code = reinterpret(UInt8, [codecCode(symbol)]) |> reverse
	pushfirst!(bytes, code...)
end

function unwrap(symbol::Symbol, bytes::Vector{UInt8})
	code = reinterpret(UInt8, [codecCode(symbol)]) |> reverse
	@assert code == bytes[1:length(code)] "Given bytes doesnot match encoding $symbol"
	for i in code
		r = popfirst!(bytes)
		@assert r == i "Removed bytes content!!!"
	end
	bytes
end

