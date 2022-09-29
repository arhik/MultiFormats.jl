using Test

for (root, dirs, files) in walkdir(".")
	for file in files
		include(file)
	end
end
