#!/usr/bin/env ruby
# encoding: UTF-8
require 'open-uri'
require 'json'

page = open("http://deckbox.org/games/mtg/cards?p=1")
totalPages = ""
page.each_line { |line|
  if (line =~ /Page\ 1/)
    tmp = line.split(">")[1]
    tmp = tmp.split("<")[0]
    tmp = tmp.split(" ")[3]
    totalPages = tmp.to_i
  end
}
allNames = {}
for i in 1..totalPages do
  page = open("http://deckbox.org/games/mtg/cards?p=#{i}")
  count = 0
  found = false
  page.each_line { |line|
    if (line =~ /class=\"card_name\"/)
      found = true
    end

    if (found)
      count += 1
    end
    if (count == 3)
      count = 0
      found = false
      tmp = line.split(">")[1]
      tmp = tmp.split("<")[0]

      if (tmp =~ /&#x27;/)
        tmp = tmp.gsub("&#x27;", "'")
      end
      if (tmp =~ /&quot;/)
        tmp = tmp.gsub("&quot;", "\"")
      end
      if (tmp =~ /&amp;/)
        tmp = tmp.gsub("&amp;", "")
      end
      allNames[tmp] = {}
    end
  }
end

`rm cardNames.json`

f = File.new('cardNames.json', 'w')
f.puts allNames.to_json
f.close

removeOldCards = false

if (ARGV[0] == '-r')
  removeOldCards = true
end

tmpJson = ""

f = File.new('cardNames.json', 'r')
f.readlines.each do |line|
  tmpJson = line
end
f.close

allNames = JSON.parse(tmpJson)

tmpJson = ""

if (removeOldCards)
  `rm cards.json`
end

if (File.exists? 'cards.json')
  if (!File.zero? 'cards.json')
    f = File.new('cards.json', 'r')
    f.each_line { |line|
      tmpJson = line
    }
    f.close
  end
else
  `touch cards.json`
end

finishedCards = {}
if (tmpJson != "")
  finishedCards = JSON.parse(tmpJson)
end

if (finishedCards != {})
  # Take each card that's done out of the hash
  # We don't want to get these cards over again
  finishedCards.keys.each do |key|
    allNames.delete(key)
  end
end

if allNames.keys.count > 0
  allNames.keys.each do |name|
    searchName = URI.encode(name)
    page = ""
    begin
      page = open("http://deckbox.org/mtg/#{searchName}")
    rescue OpenURI::HTTPError => the_error
      puts "The name was #{name} and the error was #{the_error}"
    end
    
    countCost     = 0
    costDone      = false
    foundEditions = false
    foundManaCost = false
    editionsCount = 0

    cardPrice    = ""
    cardRules    = ""
    cardManaCost = ""
    cardColors   = [] 
    cardType     = []
    cardSubTypes = []
    cardEditions = []

    page.each_line { |line|
      #Price
      if (line =~ /\$/)
        foundCost = true
      end
      if (foundCost)
        countCost += 1
      end
      if (countCost == 2 && !costDone)
        countCost = 0
        foundCost = false
        cardCost  = line.split(">")[2]
        cardPrice = cardCost.split("<")[0]
        costDone  = true
      end

      #Rules
      if (line =~ /<td class=\"label\">Rules/)
        tmpRules = line.split("<td>")[1]
        tmpRules = tmpRules.split("</td>")[0]

        tmpRules = tmpRules.gsub('<br/>', "\n")
        tmpRules = tmpRules.gsub('<div class="', "")
        tmpRules = tmpRules.gsub('</div>', "")
        tmpRules = tmpRules.gsub('<img class="', "")
        tmpRules = tmpRules.gsub(' src="/images/icon_spacer.gif" />', "")
        tmpRules = tmpRules.gsub('mtg_tap inline_block">', "{tap}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_W"',    "{W}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_B"',    "{B}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_U"',    "{U}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_R"',    "{R}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_G"',    "{G}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_1"',    "{1}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_2"',    "{2}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_3"',    "{3}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_4"',    "{4}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_5"',    "{5}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_6"',    "{6}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_7"',    "{7}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_8"',    "{8}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_9"',    "{9}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_10"',   "{10}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_X"',    "{X}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_BR"',   "{BR}")
        tmpRules = tmpRules.gsub('mtg_mana mtg_mana_snow"', "{0}")
        tmpRules = tmpRules.gsub('mtg_chaos inline_block">', "{Choas}")
        tmpRules = tmpRules.gsub('<span class=\'mtg_keyword_explanation\'>', "")
        tmpRules = tmpRules.gsub('</span>', "")

        if (tmpRules =~ /<|>|img|class|mtg_mana/)
          puts tmpRules
        end
        cardRules = tmpRules
      end

      #Mana Cost
      if (line =~ /mtg_mana/ && !foundManaCost)
        manaOccurance = line.scan(/mtg_mana_/).count
        for i in 1..manaOccurance do
          tmpManaCost = line.split("mtg_mana_")[i]
          cardManaCost << tmpManaCost[0]
        end
        foundManaCost = true
      end

      #Type
      if (line =~ /Type/)
        tmpType  = line.split("<td>")[1]
        tmpType  = tmpType.split("</td>")[0]
        cardType = tmpType.split(" - ")[0]
        tmpType  = tmpType.split(" - ")[1]
        tmpType  = tmpType.split(" ")
        tmpType.each do |type|
          cardSubTypes << type
        end
      end
      
      #Colors
      if (cardManaCost =~ /R/)
        cardColors << "Red"
      elsif (cardManaCost =~ /W/)
        cardColors << "White"
      elsif (cardManaCost =~ /B/)
        cardColors << "Black"
      elsif (cardManaCost =~ /U/)
        cardColors << "Blue"
      elsif (cardManaCost =~ /G/)
        cardColors << "Green"
      elsif (cardType =~ /Land/)
        cardColors << "NA"
      else
        cardColors << "Colorless"
      end

      #Editions
      if (line =~ /card_edition/)
        foundEditions = true
      end
      if (foundEditions && line =~ /alt=/)
        tmpEdition    = line.split("alt=\"")[1]
        tmpEdition    = tmpEdition.split(" (")[0]
        tmpEdition    = tmpEdition.gsub('&#x27;', "'")
        tmpEdition    = tmpEdition.gsub('&quot;', "\"")
        cardEditions  << tmpEdition
        foundEditions = false
      end

      if (line =~ /card_statistics/)
        break
      end
    }
    finishedCards[name] = {"Name"      => name, 
                           "Price"     => cardPrice, 
                           "Rules"     => cardRules, 
                           "Mana Cost" => cardManaCost, 
                           "Colors"    => cardColors,
                           "Type"      => cardType,
                           "Subtype"   => cardSubTypes,
                           "Editions"  => cardEditions}

    `rm cards.json`
    f = File.new('cards.json', 'w')
    f.puts finishedCards.to_json
    f.close
  end
end
