require 'erb'

module RVideo
  class Reporter
    include ERB::Util

    def self.run
      Reporter.new.run
    end
    
    def run
      @current_report_path = Reporter.next_available_report_path(File.join(REPORT_PATH, 'generated_reports'))
      files = available_files
      recipes = available_recipes

      puts "\nInput files:\n--#{files.collect { |file| File.basename(file) }.join("\n--")}" 
      puts "\nInput recipes:\n--#{recipes.map {|name, recipe| name }.join("\n--")}"
      combinations = calculate_combinations_using recipes, files
      results = mass_transcode combinations
      build_report_from results
      puts "Done! Report available at #{@current_report_path}"
      puts "Launching report in browser..."
      exec "open #{@current_report_path}/index.html"
    end
    
    private
    
    def self.next_available_report_path(base_path)
      ordered_reports = Dir[File.join(base_path, "*")].sort_by {|name| File.basename(name).to_i }
      ordered_reports = ["0"] if ordered_reports.empty? 
      last_report = File.basename(ordered_reports.last)
      new_report_name = (last_report.to_i + 1).to_s
      new_dir = File.join(base_path, new_report_name)
      FileUtils.mkdir_p(new_dir)
      new_dir
    end

    def available_recipes
      recipes = []
      recipe_files = Dir[File.join(REPORT_PATH, "*.yml")]
      recipe_files.each do |recipe_file|
        YAML.load_file(recipe_file).each { |recipe| recipes << recipe }
      end
      if recipes.empty?
        puts "No recipes found. Add recipe YAML files to report/."
        exit
      else
        recipes
      end
    end

    def available_files
      files = Dir[File.join(REPORT_PATH, "files/input/*.*")]
      if files.empty?
        puts "No input files. Add files to report/files/input to test."
        exit
      else
        files
      end
    end

    def calculate_combinations_using(recipes, files)
      @combinations = {}
      files.each { |file| @combinations[file] = recipes }
      @combinations
    end

    def build_report_from(results, options = nil)
      @results = results
      #build main report
      report = load_view 'index'
      full_report_path = File.join(@current_report_path, "index.html")
      File.open(full_report_path, "w+") do |file|
        file.write report
      end
      #build individual reports
       @results.each do |input_file, recipes|
        recipes.each do |recipe_name, result|
          build_individual_report(input_file, recipe_name, result)
         end
       end
    end

    def build_individual_report(input_file, recipe_name, result)
      #instance variables may no longer be necessary...
      @input_file = input_file
      @recipe_name = recipe_name
      @result = result
      individual_report = load_view 'report'
      individual_report_name = "#{underscoreize_file_basename(input_file)}_#{recipe_name}.html"
      File.makedirs(File.join(@current_report_path, "individual_reports"))
      full_report_path = File.join(@current_report_path, "individual_reports", individual_report_name)
      File.open(full_report_path, "w+") do |file|
        file.write individual_report
      end
    end


    def load_view(template_name)
      template_file = "#{File.dirname(__FILE__)}/reporter/views/#{template_name}.html.erb"
      template = File.read(template_file).gsub(/^  /, '')
      ERB.new(template).result(binding)
    end

    def mass_transcode(combinations)
      results = {}
      combinations.each do |file, recipes|
        results[file] = {}
        recipes.each do |recipe_name, recipe|
          puts "Transcoding #{File.basename(file)} using recipe #{recipe_name}"
          
          #generate input/output file paths
          input_file  = File.expand_path(file)
          output_file = generate_output_file_using input_file, recipe_name, recipe 
          #raise output_file
          #input_file.gsub!(" ","\\ ")
          input_file = "#{File.dirname(input_file)}/\"#{File.basename(input_file)}\""
          
          #create logfile
          log_file_name = underscoreize_file_basename(input_file) + "_" + recipe_name + ".log" 
          log_file = create_log_file(log_file_name)
          RVideo::Transcoder.logger = Logger.new(log_file)

          transcoder, errors = transcode(recipe, input_file, output_file)
          
          #build the results object for the views
          results[file][recipe_name] = {}
          results[file][recipe_name]['output_file'] = output_file
          results[file][recipe_name]['transcoder'] = transcoder
          results[file][recipe_name]['errors'] = errors
          results[file][recipe_name]['recipe'] = recipe
          results[file][recipe_name]['log'] = log_file
        end
      end
      return results
    end

    def generate_output_file_using(selected_file, recipe_name, recipe)
      #File.join(@current_report_path, 'output_files')
      output_path = File.join(@current_report_path, 'output_files' + underscoreize_file_basename(selected_file))
      File.makedirs output_path
      output_filename = "#{recipe_name}.#{recipe['extension']}"
      output_file = File.join(output_path, output_filename)
      #output_file.gsub(" ","_")
    end

    def underscoreize_file_basename(file)
      File.basename(file).gsub(".","_").gsub(" ","_")
    end

    def transcode(recipe, input_file, output_file)
      command     = recipe['command']
      errors = nil

      #RVideo::Transcoder.logger = Logger.new(STDOUT)
      begin
      transcoder = RVideo::Transcoder.new
      transcoder.execute(command, {:input_file => input_file,
                                  :output_file => output_file})
      #rescue => errors
      end
      
      return transcoder, errors 
    end

    def create_log_file(log_file_name)
      log_path = File.join(@current_report_path, "logs")
      File.makedirs log_path
      logfile = File.join(log_path, log_file_name)
      File.open(logfile, "w+") { |file| }
      logfile
    end
  
  end

end