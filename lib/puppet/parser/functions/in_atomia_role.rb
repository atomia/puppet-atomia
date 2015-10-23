module Puppet::Parser::Functions
	newfunction(:in_atomia_role, :type => :rvalue) do |args|
		role_name = args[0]
		lookupvar('atomia_role_1') == role_name || lookupvar('atomia_role_2') == role_name || lookupvar('atomia_role_3') == role_name
	end
end
