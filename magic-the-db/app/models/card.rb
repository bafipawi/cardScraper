

require "typhoeus"
require 'nokogiri'
require 'open-uri'

class Card < ActiveRecord::Base
  attr_accessible  :name, :url, :img_url, :price, :type, :rules, :editions, :formats, :rulings




  def self.scrape_cards(max)
    list_url = "http://deckbox.org/games/mtg/cards?p="

    doc = Nokogiri::HTML(open(list_url + 1 .to_s))

    last_page_num = doc.search("div#set_cards_table div.controls div.pagination_controls a").last["href"].split("=").last.to_i
    max_num = max > last_page_num ? last_page_num : max

    index_urls = (1..max_num).map { |i| list_url + i.to_s }
    card_urls = []

    requests = index_urls.map{ |url| Typhoeus::Request.new(url)}
    requests.map do |r|
      r.on_complete do |response|
        dom = Nokogiri::HTML(response.body)
        anchors = dom.search("td.card_name a.simple").map{|a| a["href"]}
        card_urls << anchors
        anchors
      end
    end

    hydra = Typhoeus::Hydra.new

    for request in requests
      hydra.queue(request)
    end
    hydra.run

    card_urls
  end
end

reload!

Card.scrape_cards(2)