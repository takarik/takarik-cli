# Cakefile for takarik-cli project

desc "Build the project in release mode"
task :build do
  execute(
    cmd: "shards build --release",
    announce: "Building takarik in release mode...",
    success: "Build completed successfully!",
    error: "Build failed."
  )
end

desc "Build the project in development mode"
task :build_dev do
  execute(
    cmd: "shards build",
    announce: "Building takarik in development mode...",
    success: "Development build completed!",
    error: "Build failed."
  )
end

desc "Install dependencies"
task :install do
  execute(
    cmd: "shards install",
    announce: "Installing dependencies...",
    success: "Dependencies installed successfully!",
    error: "Failed to install dependencies."
  )
end

desc "Clean build artifacts"
task :clean do
  # Cross-platform compatible clean command
  {% if flag?(:win32) %}
    execute "if exist bin\\takarik.exe del bin\\takarik.exe"
    execute "if exist bin\\takarik.pdb del bin\\takarik.pdb"
    execute "if exist bin\\takarik del bin\\takarik"
  {% else %}
    execute "rm -f bin/takarik bin/takarik.dwarf"
  {% end %}
  log "Build artifacts cleaned!"
end

desc "Full build pipeline: install deps, and build"
task :all do
  invoke! :install
  invoke! :build
  log "Full build pipeline completed successfully!"
end