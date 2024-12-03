if package.loaded["modes"] then
	return
end

require("modes").setup()
