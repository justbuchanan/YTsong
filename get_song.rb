#!/usr/bin/env ruby


require 'net/http'
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'json'
# require 'id3lib'


OUTPUT_DIR = ENV['HOME'] + "/Downloads/music/"


def search_youtube(queryStr)
	search_string = queryStr.gsub(" ", "+")	#	urlify

	youtube_url = "http://www.youtube.com/results?search_query=#{search_string}"
	results_page = Nokogiri::HTML(open(youtube_url))
	unprocessed_ytresults = results_page.css("ol[id=search-results] > li")

	# extract the info we want
	unprocessed_ytresults.collect do |rslt|
		{
			:title => rslt['data-context-item-title'],
			:id => rslt['data-context-item-id']
		}
	end
end


def download_soundtrack(youtubeID, filepath, verbose = false)
	puts "[Finding mp3]" if verbose

	r = "1367152401314"	#FIXME: timestamp?

	url = "http://www.youtube-mp3.org/a/itemInfo/?video_id=#{youtubeID}&ac=www&t=grp&r=#{r}"
	jsonStr = open(url).read[7..-1].chomp(';')
	info = JSON.parse(jsonStr)
	h = info["h"]
	
	url2 = "http://www.youtube-mp3.org/get?video_id=#{youtubeID}&h=#{h}&r=#{r}"

	puts "[Downloading mp3]" if verbose

	# ensure that the output directory exists
	Dir.mkdir(OUTPUT_DIR) unless Dir.exists?(OUTPUT_DIR)

	# download the mp3 and write it to the file
	File.open(filepath, 'w') do |file|
		file.write(open(url2).read)
	end

	puts "[Saved mp3 to '#{OUTPUT_DIR}']" if verbose
end




if ARGV.length != 1
	puts "usage: get_song <song name>"
	exit
end
search_keywords = ARGV[0]

# search youtube
puts "[Searching YouTube]"
ytresults = search_youtube(search_keywords)

# limit the number of results we show
max_results = 5
ytresults = ytresults.take(max_results)

# print the results out in order
i = 0
ytresults.each do |rslt|
	puts "#{i+=1} \"#{rslt[:title]}\""
end

# ask the user to choose one
puts "Enter result #:"
chosenIndex = Integer($stdin.gets.chomp!) - 1

# validate choice index
if chosenIndex < 0 || chosenIndex >= ytresults.size
	puts "Invalid Choice, aborting"
	exit
end
rslt = ytresults[chosenIndex]

# get it!
filepath = File.join(OUTPUT_DIR, "#{search_keywords}.mp3")
mp3File = download_soundtrack(rslt[:id], filepath, true)


# # tag the file
# puts "\nTag mp3?"
# answer = $stdin.gets.chomp!
# if answer == "yes" || answer == "y"
# 	tag = ID3Lib::Tag.new(filepath)

# 	%w(title, artist, album).each do |prop|
# 		puts "#{prop.capitalize}:"
# 		tag.send "#{prop}=".to_sym, $stdin.gets.chomp!
# 	end

# 	tag.update!
# end


# open the file
puts "\nOpen?"
answer = $stdin.gets.chomp!
if answer == "yes" || answer == "y"
	system("open \"#{filepath}\"")
end

