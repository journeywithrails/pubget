require 'ostruct'
require 'optparse'
require "test/dummy/config/environment.rb"
require "lib/pubget_paths"

module Grep
  module_function

  def perform_fetch()
    begin
      pub_class = "Publisher::#{options.publisher.camelize}".constantize.new
    rescue => e
      puts "Can't find publisher with name \"#{options.publisher}\", exiting."
      return
    end

    puts "\nTesting PMID: #{options.pmid}\n"

    #Article Info
    article = Article.find_by_pmid(options.pmid)

    # Calculate article's pdf path
    article.calculate_pdf_url(pub_class)
  end

  def parse_args(args)
    _opts_ = OptionParser.new do |opts|
      opts.default_argv = %w(-h) if args.size.zero?
      opts.banner = "Usage: run.rb [options]"

      opts.separator ""
      opts.separator "Specific options:"

      opts.on("-i pmid", "Specify PMID: -i 19831318") do |pmid|
        options.pmid = pmid
      end

      opts.on("-p publisher", "Specify publisher name: -i scielo") do |publisher|
        options.publisher = publisher
      end

      opts.on_tail("-h", "--help", "Display this help message.") do
        puts opts
        exit
      end
    end

    options.opts = _opts_
    _opts_.parse!
  end

  def options
    @options ||= OpenStruct.new
    @options.pmid ||= nil
    @options.publisher ||= nil
    @options
  end
end