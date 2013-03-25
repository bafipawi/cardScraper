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
allNames = []
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
      allNames << tmp
    end
  }
end

editions = {}
for name in 0..allNames.count-1 do
  found = false
  searchName = allNames[name]
  #searchName = searchName.gsub(" ", "%20")
  #searchName = searchName.gsub("ö", "o")
  searchName = URI.encode(searchName)
  puts searchName
  page = open("http://deckbox.org/mtg/#{searchName}")

  countCost = 0
  costDone = false
  foundEditions = false
  editionsCount = 0

  cardPrice = ""
  cardRules = ""
  cardManaCost = ""
  cardType = ""
  cardEditions = []

  page.each_line { |line|

    # Price
    if (line =~ /\$/)
      foundCost = true
    end
    if (foundCost)
      countCost += 1
    end
    if (countCost == 2 && costDone == false)
      countCost = 0
      foundCost = false
      cardCost = line.split(">")[2]
      cardPrice = cardCost.split("<")[0]
      costDone = true
    end
    # Price
    
    # Rules
    if (line =~ /Rules/)
      tmpRules = line.split("<td>")[1]
      tmpRules = tmpRules.split("</td>")[0]
      cardRules = tmpRules
    end
    # Rules

    # Mana Cost
    if (line =~ /mtg_mana_/)
      manaOccurance = line.scan(/mtg_mana_/).count
      for i in 1..manaOccurance do
        tmpManaCost = line.split("mtg_mana_")[i]
        cardManaCost << tmpManaCost[0]
      end
    end
    # Mana Cost

    # Type
    if (line =~ /Type/)
      tmpType = line.split("<td>")[1]
      tmpType = tmpType.split("</td>")[0]
      cardType = tmpType
    end
    # Type

    # Editions
    if (line =~ /card_edition/)
      foundEditions = true
    end
    if (foundEditions && line =~ /alt=/)
      tmpEdition = line.split("alt=\"")[1]
      tmpEdition = tmpEdition.split(" (")[0]
      cardEditions << tmpEdition
      foundEditions = false
    end
    # Editions
    
    if (line =~ /card_statistics/)
      break
    end
  }

  card = {}
  card["name"] = allNames[name]
  card["rules"] = cardRules
  card["mana cost"] = cardManaCost
  card["type"] = cardType
  # Insert into hash
  for b in 0..cardEditions.count do
    if (!editions.has_key?(cardEditions[b]))
      editions[cardEditions[b]] = []
    end
    editions[cardEditions[b]] << card
  end

end
f = File.new('cards.json', 'w')
f.puts editions.to_json
f.close
