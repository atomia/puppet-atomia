module Puppet::Parser::Functions
	newfunction(:path_split, :type => :rvalue) do |args|
		path = args[0]
		parts = path.split("/").select { |p| p.length > 1 }
		parts.each_with_index.map { |p, i| "/" + parts.slice(0, i + 1).join("/") }
	end
end
