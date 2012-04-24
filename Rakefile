#!/usr/bin/env rake
require "bundler/gem_tasks"

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "lumber #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :changelog do

  changelog_file = 'CHANGELOG'
  entries = ""

  # Get a list of current tags
  tags = `git tag -l`.split

  # If we already have a changelog, make the last tag be the
  # last one in the changelog, and the next one be the one
  # following that in the tag list
  if File.exist?(changelog_file)
    entries = File.read(changelog_file)
    head = entries.split.first
    if head =~ /\d\.\d\.\d/
      last_tag = "v#{head}"
      idx = tags.index(last_tag)
      current_tag = tags[idx + 1]
    end
  end

  # Figure out last/current tags dn do some validation
  last_tag ||= tags[-2]
  current_tag ||= tags[-1]

  if last_tag.nil? && current_tag.nil?
    puts "Cannot generate a changelog without first tagging your repository"
    puts "Tags should be in the form vN.N.N"
    exit
  end
  
  if last_tag == current_tag
    puts "Nothing to do for equal revisions: #{last_tag}..#{current_tag}"
    exit
  end


  # Generate changelog from repo
  log=`git log --pretty='format:%s <%h> [%cn]' #{last_tag}..#{current_tag}`

  # Strip out maintenance entries
  log = log.lines.to_a.delete_if {|l| l =~ /^Regenerated gemspec/ || l =~ /^Version bump/ || l =~ /^Updated changelog/ }

  # Write out changelog file
  File.open(changelog_file, 'w') do |out|
    out.puts current_tag.gsub(/^v/, '')
    out.puts "-----"
    out.puts "\n"
    out.puts log
    out.puts "\n"
    out.puts entries
  end

  # Commit and push
  sh "git ci -m'Updated changelog' #{changelog_file}"
  sh "git push"
end
