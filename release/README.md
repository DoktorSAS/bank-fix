# Black Ops II Zombies Bank Fix
Developed by [**fed**](https://github.com/fedddddd) & [**DoktorSAS**](https://github.com/DoktorSAS)

Through these files it will be possible to get the Zombies Server Bank Fully Working. Implementing the following scripts is very easy, in fact they are only two drag and drop files.

## Contributors
- [**fed**](https://github.com/fedddddd) has dedicated himself to the IW4M plugin in C#
- [**DoktorSAS**](https://github.com/DoktorSAS) has dedicated itself to the GSC part of the code and the logic of the script

### Prerequisites:
- [*IW4M Admin*](https://github.com/RaidMax/IW4M-Admin/releases): To have the bank running on a server you must have IW4M 

### How does this work?
Everything in the script is done easy to understand it better. This script uses IW4MAdmin to store bank information related to a specific user using DVARs. When a player enters the game, IW4MAdmin takes the bank data stored in a database and sends it to the GSC code that will set the value of the player's bank contents in the game. When the player leavse the game, the GSC sends a message to the log file, which IW4MAdmin reads, and stores the player's bank information to a database.

### How to use it?
To implement these features takes two minutes, just follow this guide carefully and you will understand how to implement the bank on your servers.

### Guide  
1. Download the [**compiled files**](https://github.com/DoktorSAS/bank-fix) and not the source code 
2. Take/Copy the **BankFix.dll** file and put it in the **plugins** folder of **IW4M Admin**
3. Take/Copy the file **_zm_banking.gsc** and put it in the plutonium **zombies** folder. Follow the path **t6r/maps/mp/** and if the zombies folder doesn't exist you create it and put the file in it, otherwise if the folder already exists you put directly in it.
4. Start the server and start IW4M Admin and if you have done all the steps correctly then you will have the bank working

### How to disable bank print?
Write on your .cfg file **set bank_print 0**

### Video Preview
[![Watch the video](https://images2.alphacoders.com/795/795968.png)](https://youtu.be/7UgtPc1LcqU)

## Download
Download the files from [Github](https://github.com/DoktorSAS/bank-fix)


## Source Code
Download and/or read the source files from [Github](https://github.com/DoktorSAS/bank-fix)
