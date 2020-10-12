# Black op II Zombies Bank Fix {RELEASE}
Developed by [**fed**](https://github.com/fedddddd) & [**DoktorSAS**](https://github.com/DoktorSAS)

Through these files it will be possible to get the Zombies Server Bank Fully Working. Implementing the following scripts is very easy, in fact they are only two drag and drop files.

- [**fed**](https://github.com/fedddddd) has dedicated himself to the IW4M plugin in C#
- [**DoktorSAS**](https://github.com/DoktorSAS) has dedicated itself to the GSC part of the code and the logic of the script

### # Prerequisites 
- [*IW4M Admin*](https://github.com/RaidMax/IW4M-Admin/releases): To have the bank running on a server you must have IW4M 

### How this work?
Everything is done to make it easy to understand the script. This script uses IW4M Admin to store bank information related to a specific user. When a player enters the game IW4M Admin takes the data and sends it to the GSC code that will transform the message of IW4M Admin in the value of the bank of the game. When the player will leave the game on the log file I will be written when the player remains in the bank and IW4M Admin will take this data and update the saved data. 

### How to use it?

To implement these features takes two minutes, just follow this guide carefully and you will understand how to implement the bank on your servers.
##### Guide  setp by step
1. Download the [**compiled files**]() and not the source code 
2. Take/Copy the **BankFix.dll** file and put it in the **plugins** folder of **IW4M Admin**
3. Take/Copy the file **_zm_banking.gsc** and put it in the plutonium **zombies** folder. Follow the path **t6r/maps/mp/** and if the zombies folder doesn't exist you create it and put the file in it, otherwise if the folder already exists you put directly in it.
4. Start the server and start IW4M Admin and if you have done all the steps correctly then you will have the bank working
