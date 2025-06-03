require "option_parser"
require "file_utils"

# TODO: Write documentation for `Takarik::Cli`
module Takarik::Cli
  VERSION = "0.0.1"

  # Template processing
  private def self.read_template(template_path : String, substitutions : Hash(String, String)) : String
    template_content = File.read(File.join(__DIR__, "..", "templates", template_path))

    substitutions.each do |placeholder, value|
      template_content = template_content.gsub("{{#{placeholder}}}", value)
    end

    template_content
  end

  def self.run(args = ARGV)
    command = nil
    app_name = nil
    target_path = nil

    parser = OptionParser.new do |parser|
      parser.banner = "Usage: takarik <command> [options]"

      parser.on("new", "Create a new application") do
        command = "new"
        parser.banner = "Usage: takarik new <app_name> <path> [options]"
      end

      parser.on("cake", "Execute cake commands") do
        command = "cake"
        parser.banner = "Usage: takarik cake <cake_command> [args...]"
      end

      parser.on("console", "Start an interactive Crystal console (ICR)") do
        command = "console"
        parser.banner = "Usage: takarik console [options]"
      end

      parser.on("c", "Start an interactive Crystal console (ICR) - alias for console") do
        command = "console"
        parser.banner = "Usage: takarik c [options]"
      end

      parser.on("-h", "--help", "Show help") do
        puts parser
        exit
      end

      parser.on("-v", "--version", "Show version") do
        puts "Takarik CLI v#{VERSION}"
        exit
      end

      parser.unknown_args do |before_dash, after_dash|
        case command
        when "new"
          if before_dash.size < 2
            puts "Error: 'new' command requires <app_name> and <path>"
            puts "Example: takarik new my-app ."
            exit(1)
          end
          app_name = before_dash[0]
          target_path = before_dash[1]
        when "cake"
          if before_dash.empty?
            puts "Error: 'cake' command requires at least one argument"
            puts "Example: takarik cake migrate"
            exit(1)
          end
          cake_command = before_dash[0]
          cake_args = before_dash[1..] + after_dash
          handle_cake_command(cake_command, cake_args)
          exit
        when "console"
          # Handle console command - no additional args needed
          handle_console_command(before_dash + after_dash)
          exit
        else
          unless before_dash.empty?
            # Check if the command starts with ":"
            if before_dash[0].starts_with?(":")
              cake_command = before_dash[0][1..]  # Remove the ":"
              cake_args = before_dash[1..] + after_dash
              handle_cake_command(cake_command, cake_args)
              exit
            else
              puts "Error: Unknown command '#{before_dash[0]}'"
              puts parser
              exit(1)
            end
          end
        end
      end
    end

    begin
      parser.parse(args)
    rescue ex : OptionParser::Exception
      puts "Error: #{ex.message}"
      puts parser
      exit(1)
    end

    if command.nil?
      puts parser
      exit(1)
    end

    case command
    when "new"
      handle_new_command(app_name.not_nil!, target_path.not_nil!)
    when "console"
      handle_console_command([] of String)
    when "cake"
      # This case is handled in unknown_args block above
      # but we include it here for completeness
    end
  end

  private def self.handle_new_command(app_name, target_path)
    # Resolve the target path
    full_path = File.expand_path(target_path)
    app_dir = File.join(full_path, app_name)

    puts "Creating new application '#{app_name}' in #{app_dir}"

    create_app_structure(app_name, app_dir)

    puts "✅ Application '#{app_name}' created successfully!"
    puts "Next steps:"
    puts "  cd #{app_name}"
    puts "  shards install"
  end

  private def self.handle_cake_command(command, args)
    # Execute the globally installed cake command with arguments
    full_args = [command] + args
    status = Process.run("cake", full_args, input: Process::Redirect::Inherit, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
    exit(status.exit_code)
  end

  private def self.handle_console_command(args)
    puts "🔮 Starting Takarik interactive console..."
    puts ""

    # Check if ICR is available first
    icr_available = system("which icr > /dev/null 2>&1") || system("where icr > NUL 2>&1")

    # Check if we're in a Takarik project directory
    if File.exists?("shard.yml")
      puts "📦 Detected Takarik project"

      # Look for the app structure: app/APP_NAME.cr
      app_main_file = find_app_main_file()

      if icr_available && app_main_file
        puts "🚀 Using ICR with your app loaded"
        puts "📚 Loading: #{app_main_file}"
        puts ""

        # Use ICR with the app file
        status = Process.run("icr", ["-r", "./#{app_main_file}"],
                           input: Process::Redirect::Inherit,
                           output: Process::Redirect::Inherit,
                           error: Process::Redirect::Inherit)
        exit(status.exit_code)
      elsif icr_available
        puts "🚀 Using ICR (no main app file found)"
        puts "💡 You can manually require files with: require \"./app/your_file\""
        puts ""

        status = Process.run("icr", [] of String,
                           input: Process::Redirect::Inherit,
                           output: Process::Redirect::Inherit,
                           error: Process::Redirect::Inherit)
        exit(status.exit_code)
      else
        # Fall back to our simple console
        puts "⚠️  ICR not found - using simple Takarik console"
        if app_main_file
          puts "📚 Will load: #{app_main_file}"
          start_simple_console(app_main_file)
        else
          puts "⚠️  No main app file found"
          puts "💡 Expected structure: app/your_app_name.cr"
          puts "🔧 Starting basic console instead"
          start_simple_console(nil)
        end
      end
    else
      puts "⚡ Not in a Takarik project directory"

      if icr_available
        puts "🚀 Using ICR"
        status = Process.run("icr", [] of String,
                           input: Process::Redirect::Inherit,
                           output: Process::Redirect::Inherit,
                           error: Process::Redirect::Inherit)
        exit(status.exit_code)
      else
        puts "⚠️  ICR not found - starting simple console"
        start_simple_console(nil)
      end
    end
  end

  private def self.find_app_main_file() : String?
    return nil unless Dir.exists?("app")

    # Look for app/APP_NAME.cr based on current directory name
    current_dir = File.basename(Dir.current)
    main_file = "app/#{current_dir}.cr"

    if File.exists?(main_file)
      return main_file
    end

    # Also check for any .cr files in app/ directory
    if Dir.exists?("app")
      Dir.glob("app/*.cr").each do |file|
        return file unless file.includes?("_spec.cr")
      end
    end

    nil
  end

  private def self.start_simple_console(main_file : String?)
    puts ""
    puts "🎯 Takarik Simple Console"
    puts "💡 This will load your app and show available components"
    puts ""

    # Create a simple script that loads the app and shows info
    console_script = create_console_script(main_file)
    temp_file = ".takarik_console.cr"

    begin
      File.write(temp_file, console_script)

      # Execute the console script
      status = Process.run("crystal", ["run", temp_file],
                         input: Process::Redirect::Inherit,
                         output: Process::Redirect::Inherit,
                         error: Process::Redirect::Inherit)
      exit(status.exit_code)
    ensure
      File.delete(temp_file) if File.exists?(temp_file)
    end
  end

  private def self.create_console_script(main_file : String?) : String
    script = String.build do |str|
      str << "# Takarik Console Script\n\n"

      # Load the main file if provided
      if main_file
        str << "# Load the main application file\n"
        str << "begin\n"
        str << "  require \"./#{main_file}\"\n"
        str << "  puts \"✅ Successfully loaded: #{main_file}\"\n"
        str << "rescue ex\n"
        str << "  puts \"❌ Error loading #{main_file}: \#{ex.message}\"\n"
        str << "  puts \"   Make sure your app file is valid Crystal code\"\n"
        str << "  exit(1)\n"
        str << "end\n\n"
      end

      str << "puts \"\\n🎯 Takarik Console Ready!\"\n"
      str << "puts \"\\n💡 Your Takarik app is loaded and verified!\"\n"
      str << "puts \"\\n📋 To get a full interactive REPL experience:\"\n"
      str << "puts \"   1. Install ICR: 'git clone https://github.com/crystal-community/icr.git && cd icr && make install'\"\n"
      str << "puts \"   2. Run 'takarik console' again to use ICR automatically\"\n"
      str << "puts \"\\n🔧 Alternative: Use 'crystal i' directly (experimental)\"\n"

      if main_file
        str << "puts \"\\n📖 Your app file (#{main_file}) is working correctly!\"\n"
        str << "puts \"   You can now develop with confidence that your code compiles\"\n"
      end

      str << "puts \"\\n Press Enter to exit...\"\n"
      str << "STDIN.gets\n"
    end

    script
  end

  private def self.create_app_structure(app_name, app_dir)
    # Create main directories
    directories = [
      "app",
      "spec",
      "config",
      "models",
      "db/migrations",
      "public",
      "views/layouts",
      "lib"
    ]

    directories.each do |dir|
      dir_path = File.join(app_dir, dir)
      FileUtils.mkdir_p(dir_path)
      puts "📁 Created directory: #{dir}"
    end

    # Create all files from templates
    create_files_from_templates(app_name, app_dir)
  end

  # Helper to recursively find all files including hidden ones
  private def self.find_all_files(dir : String, files : Array(String))
    Dir.each(dir) do |entry|
      next if entry == "." || entry == ".."
      full_path = File.join(dir, entry)
      if File.directory?(full_path)
        find_all_files(full_path, files)
      else
        files << full_path
      end
    end
  end

  private def self.create_files_from_templates(app_name, app_dir)
    module_name = app_name.split(/[-_]/).map(&.capitalize).join

    substitutions = {
      "APP_NAME" => app_name,
      "MODULE_NAME" => module_name
    }

    templates_dir = File.join(__DIR__, "..", "templates")

    # Process all files in templates directory recursively
    all_files = [] of String
    find_all_files(templates_dir, all_files)

    all_files.each do |template_path|
      # Skip directories
      next if File.directory?(template_path)

      # Get relative path from templates directory
      relative_path = Path[template_path].relative_to(templates_dir)
      target_relative_path = relative_path.to_s

      # Apply substitutions to the filename/path as well
      substitutions.each do |placeholder, value|
        target_relative_path = target_relative_path.gsub("{{#{placeholder}}}", value)
      end

      # Create target file path
      target_file_path = File.join(app_dir, target_relative_path)

      # Ensure target directory exists
      FileUtils.mkdir_p(File.dirname(target_file_path))

      # Read template and apply substitutions
      content = read_template(relative_path.to_s, substitutions)

      # Write the file
      File.write(target_file_path, content)

      # Show friendly output
      display_path = Path[target_file_path].relative_to(app_dir)
      puts "📄 Created #{display_path}"
    end
  end
end
