require 'digest'
require 'kraken-io'
require 'open-uri'

module Kraken
  module Compressor
    class Task
      HISTORY = '.kraken'
      attr_reader :kraken, :glob, :current_dir

      def initialize(key, secret, glob_path: nil, working_directory: nil)
        @kraken      = Kraken::API.new(api_key: key, api_secret: secret)
        @glob        = glob_path || "{app,public}/**/*.{jpg,png,gif}"
        @current_dir = working_directory || File.dirname(__FILE__) + "/"

        prepare
      end

      def prompt
        if anything?
          puts "Total files: #{@total} (#{(@size.to_f / 1024 / 1024).round(2)} MB)"
          puts "Continue? (y/n)"
          input = gets.strip
          case input
          when 'y'
            optimize
          else
            puts 'Aborting'
          end
        else
          puts "Hurray, nothing to optimize! Scanned: #{@total_files} files"
          save_history
        end
      end

      private

      def optimize
        @mapped.dup.each do |file_path, sha|

          data = upload_with_retry(file_path)

          if data.success
            puts "[OK]  #{file_path} | saved: #{(data.saved_bytes.to_f / 1024).round(2)} KB"
            puts "     -> downloading: #{data.kraked_url} (#{(data.kraked_size.to_f / 1024).round(2)} KB)"
            response = open(data.kraked_url).read
            new_sha = Digest::SHA256.hexdigest(response)
            File.write(file_path, response, { mode: 'wb' })
            @mapped[file_path] = new_sha
          else
            puts "[ERR] #{file_path}: #{data.message}"

            unless data.message =~ /optimized any further/i
              @mapped.delete(file_path) # something failed, don't save it in history - treat is as not optimized
            end
          end
        end

      ensure
        save_history
      end

      def upload_with_retry(file_path)
        kraken.upload(file_path)
      rescue Net::ReadTimeout
        puts "[ERR] #{file_path} upload failed, retrying..."
        retry
      end

      def save_history
        new_history = []
        @history.merge(@mapped).each do |key, value|
          new_history << "#{key};#{value}"
        end

        File.write(current_dir + HISTORY, new_history.sort.join("\n"))
      end

      def prepare
        @size, @total, @total_files = 0, 0, 0

        files = []
        @mapped = Dir[current_dir + glob].each_with_object({}) do |file_path, hash|
          @total_files += 1

          sha = Digest::SHA256.hexdigest File.read(file_path)
          files << file_path
          next if history[file_path] == sha # file already compressed

          @size += File.size(file_path)
          @total += 1
          hash[file_path] = sha
        end

        # files already removed
        @history.dup.each do |file_path, hash|
          @history.delete(file_path) unless files.include?(file_path)
        end
      end

      def anything?
        @total > 0
      end

      def history
        @history ||= if File.exists?(current_dir + HISTORY)
          File.read(current_dir + HISTORY).split("\n").each_with_object({}) do |line, hash|
            name, sha = line.split(";")
            hash[name] = sha
          end
        else
          {}
        end
      end
    end
  end
end