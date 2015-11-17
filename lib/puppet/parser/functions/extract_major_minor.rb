module Puppet::Parser::Functions
	newfunction(:extract_major_minor, :type => :rvalue) do |args|
		versions = args[0]
		versions.map { |version| version.split(".").slice(0, 2).join(".") }
	end
end
