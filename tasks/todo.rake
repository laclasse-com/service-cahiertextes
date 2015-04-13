desc 'show a todolist from all the TODO tags in the source'
task :todo do
  underyellow = "\e[4;33m%s\e[0m"
  underred    = "\e[4;31m%s\e[0m"
  undergreen  = "\e[4;32m%s\e[0m"
  undercolor = ''

  color = ''

  Dir.glob('{api,config,migrations,lib,models,spec,public/app/{index.html,scripts,styles,views}}/**/*.{rb,html,xhtml,js}') do |file| # rubocop:disable Metrics/LineLength
    lastline = todo = comment = long_comment = false

    File.readlines(file).each_with_index do |line, lineno|
      lineno      += 1
      comment      = line =~ /^\s*?[#\/].*?$/
      long_comment = line =~ /^=begin/
      long_comment = line =~ /^=end/

      todo = true if line =~ /TODO|FIXME|THINK/ && (long_comment || comment)
      todo = false if line.gsub('#', '').strip.empty?
      todo = false unless comment || long_comment

      undercolor = underyellow if line =~ /TODO/
      undercolor = underred    if line =~ /FIXME/
      undercolor = undergreen  if line =~ /THINK/

      color = undercolor.gsub('4', '0')

      if todo
        unless lastline && lastline + 1 == lineno
          puts
          puts undercolor % "#{file}# #{lineno} : "
        end

        l = '  . ' + line.strip.gsub(/^#\s*/, '')
        # print '  . ' unless l =~ /^-/
        puts color % l
        lastline = lineno
      end
    end # File.readlines
  end
end # task :todo
