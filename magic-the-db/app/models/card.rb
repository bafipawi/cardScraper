require 'nokogiri'
require 'open-uri'

class Card < ActiveRecord::Base
  attr_accessible  :name, :url, :img_url, :price, :type, :rules, :editions, :formats, :rulings




  def self.scrape_cards()
    list_url = "http://deckbox.org/games/mtg/cards?p="
    doc = Nokogiri::HTML(open(list_url + 1 .to_s))
    last_page_num = doc.search("div#set_cards_table div.controls div.pagination_controls a").last["href"].split("=").last.to_i
    # last_page_num = 3
    threads = []
    urls = []

    (1..last_page_num).each do |i|
      url = list_url + i.to_s
      dom = Nokogiri::HTML(open(url))

      anchors = dom.search("td.card_name a.simple")
      urls << anchors.map{|a| a["href"]}

    end
    urls
  end
end