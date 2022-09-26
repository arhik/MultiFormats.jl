using CSV
using DataFrames

# TODO artifact or a permanent location
basetable = download("https://raw.githubusercontent.com/multiformats/multibase/master/multibase.csv")

multibaseTable = CSV.read(open(basetable), DataFrame, stripwhitespace=true)

allowmissing(multibaseTable)

# Base Header
quote
	@enum BaseHeader $(
		(
			names(multibaseTable) .|> (x) -> "Base"*x .|> uppercase .|> Symbol
		)...
	)
end |> eval


# Base Status
baseStatusList = select(multibaseTable, "status").status .|> (x) -> "Base"*x

quote
	@enum BaseStatus $(
		(
			unique(baseStatusList)  .|> uppercase .|> Symbol
		)...
	)
end |> eval


# Base Code
# TODO temporary 
baseCodeList = begin 
	codeUntyped = []
	codes = select(multibaseTable, "code").code
	for (idx, code) in enumerate(codes)
		push!(codeUntyped, (length(code) > 1 ? Meta.parse(code) : code[1]))
	end
	codeUntyped
end


# Base descriptions
baseDescriptions = select(multibaseTable, "description").description

abstract type AbstractMultiBase end

for (idx, name) in enumerate(select(multibaseTable, "encoding").encoding)
	sName = "Base-"*name
	structName = join(split(sName, "-") |> (x) -> map(uppercasefirst, x)) |> Symbol

	description = baseDescriptions[idx]
	code = baseCodeList[idx]
	status = baseStatusList[idx] .|> uppercase .|> Symbol
	
	mName = replace(name, "-" => "_")

	quote 
		struct $structName <: AbstractMultiBase
		end

		getBaseName(a::$structName) = $name
		getBaseName(a::Type{$structName}) = $name
		getBaseName(a::Val{Symbol($mName)}) = $name
		getBaseName(a::Val{$code}) = $name
		

		getBaseSymbol(a::$structName) = Symbol($mName)
		getBaseSymbol(a::Type{$structName}) = Symbol($mName)
		getBaseSymbol(a::Val{Symbol($mName)}) = a
		getBaseSymbol(a::Val{$code}) = a
		
		getBase(a::Val{Symbol($mName)}) = $structName
		getBase(a::Val{$code}) = $structName
		
		getBaseCode(a::$structName) = $code
		getBaseCode(a::Type{$structName}) = $code
		getBaseCode(a::Val{Symbol($mName)}) = getBaseCode(getBase(a))
		getBaseCode(a::Val{$code}) = getBaseCode(getBase(a))
			
		getBaseStatus(a::$structName) = $status
		getBaseStatus(a::Type{$structName}) = $status
		getBaseStatus(a::Val{Symbol($mName)}) = getBaseStatus(getBase(a))
		getBaseStatus(a::Val{$code}) = getBaseStatus(getBase(a))
		
		getBaseDescription(a::$structName) = $description
		getBaseDescription(a::Type{$structName}) = $description
		getBaseDescription(a::Val{Symbol($mName)}) = getBaseDescription(getBase(a))
		getBaseDescription(a::Val{$code}) = getBaseDescription(getBase(a))

		# TODO
		Base.show(a::$structName) = begin
			"Base : $structName $(getBaseStatus(a)), $(getBaseCode(a))"
		end		

		# TODO
		Base.display(a::$structName) = begin
			"Base : $structName $(getBaseStatus(a)), $(getBaseCode(a))"
		end	
	end |> eval
end

base(name::Symbol) = getBase(Val(name))
base(id::Union{Unsigned, Char}) = getBase(Val(id))

function base(code::String)
	if code == "0x00"
		return base(0x00)
	else
		return base(code[1])
	end
end

baseCode(name::Symbol) = getBaseCode(Val(name))
baseCode(id::Union{Unsigned, Char}) = getBaseCode(Val(id))
baseName(name::Symbol) = getBaseName(Val(name))
baseName(id::Union{Unsigned, Char}) = getBaseName(Val(id))
baseSymbol(name::Symbol) = getBaseSymbol(Val(name))
baseSymbol(id::Union{Unsigned, Char}) = getBaseSymbol(Val(id))
baseStatus(name::Symbol) = getBaseStatus(Val(name))
baseStatus(id::Union{Unsigned, Char}) = getBaseStatus(Val(id))
baseDescription(name::Symbol) = getBaseDescription(Val(name))
baseDescription(ud::Union{Unsigned, Char}) = getBaseDescription(Val(id))

# TODO
function encodebase(::Type{BaseType}, bytes::Vector{UInt8}) where BaseType<:AbstractMultiBase
	pushfirst!(baseCode(BaseType), bytes)
end

# TODO
function decodebase(::Type{BaseType}, bytes::Vector{UInt8}) where BaseType<:AbstractMultiBase
	popfirst!(baseCode(BaseType), bytes)
end

function encodebase(symbol::Symbol, bytes::Vector{UInt8})
	code = reinterpret(UInt8, [baseCode(symbol)]) |> reverse
	pushfirst!(bytes, code...)
end

function decodebase(symbol::Symbol, bytes::Vector{UInt8})
	code = reinterpret(UInt8, [baseCode(symbol)]) |> reverse
	@assert code == bytes[1:length(code)] "Given bytes doesnot match encoding $symbol"
	for i in code
		r = popfirst!(bytes)
		@assert r == i "Removed bytes content!!!"
	end
	bytes
end

export base, baseName, baseSymbol, baseCode, 
	baseStatus, baseDescription,
	encodebase, decodebase

