

require "typhoeus"
require 'nokogiri'
require 'open-uri'

class Card < ActiveRecord::Base
  attr_accessible  :name, :url, :img_url, :price, :type, :rules, :editions, :formats, :rulings

  @card_index_url = "http://deckbox.org/games/mtg/cards?p="

  def self.handle_card_response
    proc do |r|
      r.on_complete do |response|
        dom = Nokogiri::HTML(response.body)
        card_img = dom.search("img#card_image")
        {card_img: card_img}
      end
    end
  end

  def self.get_card(url)
    dom = Nokogiri::HTML(open(url))
    return {img_url: get_card_img_url(dom),
            }
  end

  def self.get_card_responses(card_links)
    requests = card_links.map{ |url| Typhoeus::Request.new(url)}
    cards_page_arrays = []
    requests.map(&handle_card_response)

    hydra = Typhoeus::Hydra.new

    for request in requests
      hydra.queue(request)
    end

    hydra.run
    requests
  end

  def self.scrape_index_card_links(max)
    doc = Nokogiri::HTML(open(@card_index_url + 1 .to_s))
    max = get_max_index(doc, max)

    index_urls = (1..max).to_a.map(&generate_url_from_index)

    requests = index_urls.map{ |url| Typhoeus::Request.new(url)}
    requests.map(&handle_get_card_links)

    hydra = Typhoeus::Hydra.new

    for request in requests
      hydra.queue(request)
    end
    hydra.run

    return requests.map{ |r| r.response.handled_response }
  end

  private


  def self.get_max_index(doc, max)
    last_page_num = doc.search("div#set_cards_table div.controls div.pagination_controls a").last["href"].split("=").last.to_i
    max > last_page_num ? last_page_num : max
  end

  def self.handle_card_response
    proc do |response|
      dom = Nokogiri::HTML(response.body)
      anchors = dom.search("td.card_name a.simple").map{|a| a["href"]}
    end
  end

  def self.get_card_img_url(dom)
    dom.search("img#card_image").first["src"]
  end

  def self.get_card_price_attributes(dom)
    price_str = dom.search(".card_properties tr")[0].children[4].text
    values = price_str.scan(/\d+.\d+/).map{&:to_f}
  end

  def self.get_card_attributes(dom)
    attr_rows = dom.search("table.card_properties tbody tr")
    data = attr_rows
  end

  def self.handle_get_card_links
    proc do |r|
      r.on_complete(&handle_card_response)
    end
  end

  def self.generate_url_from_index
    proc do |i|
      @card_index_url + i.to_s
    end
  end

end

