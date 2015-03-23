# Kraken.io compressor

Helper gem for https://github.com/kraken-io/kraken-ruby

WIP, might destroy your data.

### :warning: Danger

- slow (not threaded)
- not very customizable
- known usage-limitations
- probably won't be very maintained 

You have been warned.

### Usage

With rails:

``` ruby
# lib/tasks/kraken.rake
if Rails.env.development?
  namespace :kraken do
    desc "Optimize assets"
    task compress: :environment do
      require 'kraken-io/compressor/task'
      require 'kraken-io'

      task = Kraken::Compressor::Task.new(
        'key',
        'secret',
        glob_path: '{app,public}/**/*.{jpg,png,gif}', # grab all images from app/ and public/ folder
        working_directory: './',
        upload:  proc { |file_name| file_name =~ /something/ ? { 'lossy' => true } : {} }, # should lossy compression be applied for that file
        exclude: proc { |file_name| file_name =~ /system\//i } # should this file be excluded?
      )

      task.prompt # summary with y/n prompt
    end
  end
end
```

This gem will store sha hashes in `.kraken` file (working directory), so it will detect updated/new/removed files.
