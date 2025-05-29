# Configure static file serving
Takarik.configure do |config|
  config.static_files(
    public_dir: "./public",
    cache_control: "public, max-age=3600",
    enable_etag: true,
    enable_last_modified: true
  )
end