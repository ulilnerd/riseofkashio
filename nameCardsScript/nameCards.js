var fs = require("fs");
const readline = require('readline');

async function processLineByLine() {
    const fileStream = fs.createReadStream('../kashio_battle_cards.lua');
  
    const rl = readline.createInterface({
      input: fileStream,
      crlfDelay: Infinity
    });

    var cards = []; // stores card names here
    var first = true; // first card doesn't have newspace
    for await (const line of rl) {
        var noSpace = line.trim().substring(0,4);
        var cardName = line.trim().replace(/,/g, ' ');
        
        if (noSpace == "name") {
            if (first == true) {
                cards.push("CARDS\n\n"+cardName);
                first = false;
            }   
            else {
                cards.push("\n"+cardName);
            }
        }
        // Shows descriptions
        // if (line.trim().substring(0,5) == "desc ") {
        //     cards.push("\n"+cardName+"\n")
        // }

        if (line.trim() == "local CONDITIONS =") {
            cards.push("\n\nCONDITIONS\n")
        }
        
    }
    console.log(cards)
    fs.writeFile('cardNames.txt', cards, function (err) {
        if (err) throw err;
        console.log('Saved!');
    });
};

processLineByLine()