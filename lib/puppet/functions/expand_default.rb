Puppet::Functions.create_function(:expand_default) do
	def expand_default(string_to_expand)
		expanded_string = string_to_expand
		string_to_expand.scan(/\[\[[^\]]+\]\]/) do |expansion|
			hiera_key = expansion.gsub(/[\[\]]*/, "")
			if !hiera_key.include?(":")
				hiera_key = "atomia::config::" + hiera_key
			end

			expanded_value = call_function('hiera', hiera_key)
			expanded_string = expanded_string.gsub(expansion, expanded_value)
		end

		expanded_string
	end
end
