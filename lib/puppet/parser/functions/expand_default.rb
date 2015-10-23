module Puppet::Parser::Functions
	newfunction(:expand_default, :type => :rvalue) do |args|
		expanded_string = string_to_expand = args[0]
		string_to_expand.scan(/\[\[[^\]]+\]\]/) do |expansion|
			hiera_key = expansion.gsub(/[\[\]]*/, "")
			if !hiera_key.include?(":")
				hiera_key = "atomia::config::" + hiera_key
			end

			expanded_value = function_hiera([hiera_key])
			expanded_string = expanded_string.gsub(expansion, expanded_value)
		end

		expanded_string
	end
end
