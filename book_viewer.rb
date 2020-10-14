require 'tilt/erubis'
require "sinatra"
require "sinatra/reloader"

def public_files
  Dir.glob("./public/*.*").map! {|name| File.basename(name)}
end 

def sort_files(par)
  if params[:sort] == "descend"
    [public_files.sort.reverse, "Sort A-Z", "?sort=ascend"]
  else
    [public_files.sort, "Sort Z-A", "?sort=descend"]
  end 
end

def chp_name
  @toc[@number.to_i - 1]
end 

# def matching_chps_lines
#   nums = []
#   lines = []
#   1.upto(@toc.size) do |chp_num|
#     IO.readlines("data/chp#{chp_num}.txt").each do |ln| 
#       if ln.include?(params[:query])
#       lines << ln 
#       nums << chp_num.to_i 
#       end 
#     end 
#   end 
#   [nums.uniq, lines]
# end 

def chps_lines
  chp_lines = {}
  return chp_lines unless params[:query]
  1.upto(@toc.size) do |chp_num|
    if in_paragraphs(chp_num.to_s).join.include?(params[:query])
      chp_lines[chp_num] = [] 
    end 
  end 
  chp_lines
end 

def matching_lines
  ids = []
  chapters_and_lines = chps_lines
  chapters_and_lines.each do |chp, lines|
    in_paragraphs(chp).each_with_index do |par, idx|
      if par.include?(params[:query])
        lines << par 
        ids << idx
      end 
    end
  end  
  [ids, chapters_and_lines]
end 

get "/search" do 
  @ids, @matches = matching_lines
  erb :search
end 


helpers do 
  def in_paragraphs(num)
    txt = File.readlines("data/chp#{num}.txt").join
    pars = txt.split("\n\n").map.with_index do |line, idx|
      "<p id=#{idx}>" + line + "</p>"
    end 
  end 

  def bold_search(search, line)
    line.sub(search, "<strong>#{search}</strong>")
  end 

end 

before do 
  @toc = IO.readlines("data/toc.txt")
end 

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  @files, @sort_button, @sort_url = sort_files(params[:sort])
  erb :home
end 

get "/chapters/:number" do 
  @number = params[:number]
  @title = "Chapter #{@number}: #{chp_name}"
  redirect "/" unless (1..@toc.size).cover?(@number.to_i)
  @text = in_paragraphs(@number).join
  erb :chapter
end 

# get "/search" do 
#   @chps, @lines = matching_chps_lines
#   @matches = @chps.map {|chp_num| @toc[chp_num - 1]}.zip(@chps)
#   erb :search
# end 


not_found do 
  redirect "/"
end 