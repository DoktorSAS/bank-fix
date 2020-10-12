# Black op II Zombies Bank Fix {SOURCE CODE}
Developed by [**fed**](https://github.com/fedddddd) & [**DoktorSAS**](https://github.com/DoktorSAS)

- [**fed**](https://github.com/fedddddd) has dedicated himself to the IW4M plugin in C#
- [**DoktorSAS**](https://github.com/DoktorSAS) has dedicated itself to the GSC part of the code and the logic of the script

### # Prerequisites 
- [*IW4M Admin*](https://github.com/RaidMax/IW4M-Admin/releases): To have the bank running on a server you must have IW4M 

### How this work?
Everything is done to make it easy to understand the script. This script uses IW4M Admin to store bank information related to a specific user. When a player enters the game IW4M Admin takes the data and sends it to the GSC code that will transform the message of IW4M Admin in the value of the bank of the game. When the player will leave the game on the log file I will be written when the player remains in the bank and IW4M Admin will take this data and update the saved data. 

## GSC Explanations

#### Avoid that the bank is loaded in the maps where the bank is not active or not present
```
    if (getDvar("g_gametype") != "zclassic") {
		return;
	}
	if (getDvar("mapname") != "zm_buried" && getDvar("mapname") != "zm_highrise" && getDvar("mapname") != "zm_transit") {
		return;
	}
```

#### Avoid writing dvar from multiple users
The dvar that contains the bank data must be accessible to only one user at a time because every time the user takes the data from the dvar automatically remove it from the dvar so as to decrease the size of the dvar
```
   init(){
       ...
       level.looking_for_bank_money = false; 
   }
   setAccountValue(){
   while(level.looking_for_bank_money || getDvar("bank_clients_information") == "") 
		wait 0.01;
	level.looking_for_bank_money = true; 	
   	...
	level.looking_for_bank_money = false; 
   }
```
