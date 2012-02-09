# Files that need to be required first
require File.join(File.dirname(__FILE__), 'pubget_paths/publisher/base.rb')
require File.join(File.dirname(__FILE__), 'pubget_paths/publisher/highwire.rb')
require File.join(File.dirname(__FILE__), 'pubget_paths/publisher/atypon.rb')
require File.join(File.dirname(__FILE__), 'pubget_paths/publisher/nature.rb')
require File.join(File.dirname(__FILE__), 'pubget_paths/publisher/scitation.rb')
require File.join(File.dirname(__FILE__), 'pubget_paths/publisher/bmc.rb')
require File.join(File.dirname(__FILE__), 'pubget_paths/publisher/literatumonline.rb')
require File.join(File.dirname(__FILE__), 'pubget_paths/publisher/taylorandfrancis.rb')
require File.join(File.dirname(__FILE__), 'pubget_paths/publisher/metapress.rb')
require File.join(File.dirname(__FILE__), 'pubget_paths/publisher/allen_press.rb')

# Everything else
librbfiles = File.join(File.dirname(__FILE__), "**", "*.rb")
Dir.glob(librbfiles).each do |file|
  require file
end