#include maps/mp/zombies/_zm_unitrigger;
#include maps/mp/zombies/_zm_stats;
#include maps/mp/zombies/_zm_score;
#include maps/mp/zombies/_zm_powerups;
#include maps/mp/zombies/_zm_weapons;
#include maps/mp/zombies/_zm_magicbox;
#include maps/mp/zombies/_zm_utility;
#include maps/mp/_utility;
#include common_scripts/utility;
/*
	Developer: DoktorSAS & fed
	Discord: Discord.io/Sorex
	Mod: Bank Fix
	Description: This is a script able to fix the bank problem
	
	Copyright: The script was created by DoktorSAS & fed and no one else can 
			   say they created it. The script is free and accessible to 
			   everyone, it is not possible to sell the script.
*/
init()
{
	/*
		It is necessary to avoid that the bank 
		is loaded in the maps where the bank is not active or not present
	*/
	if (getDvar("g_gametype") != "zclassic") {
		return;
	}
	if (getDvar("mapname") != "zm_buried" && getDvar("mapname") != "zm_highrise" && getDvar("mapname") != "zm_transit") {
		return;
	}
	onplayerconnect_callback( ::onplayerconnect_bank_deposit_box );
	if ( !isDefined( level.ta_vaultfee ) )
	{
		level.ta_vaultfee = 100;
	}
	if ( !isDefined( level.ta_tellerfee ) )
	{
		level.ta_tellerfee = 100;
	}
	/*
		level.looking_for_bank_money is the variable which allows you to manage when multiple 
		users are trying to access the dvar containing the bank data
	*/
	level.looking_for_bank_money = false; 
	/*
		level thread sync_bank_onEnd(); Update bank values on iw4m as soon as the game ends
	*/
	level thread sync_bank_onEnd();
}
sync_bank_onEnd() {
	level waittill("end_game");
	setAccountValues();
}
setAccountValues() {
	/*
		Update bank values on iw4m as soon as the game ends. All the information is 
		written on the log file that will be read by iw4m admin
	*/
	players = [];
	for (i = 0; i < level.players.size; i++) {
		players[i] = [];
		players[i]["Guid"] = level.players[i] getGuid();
		players[i]["Money"] = level.players[i].account_value;

	}
	logPrint("IW4MBANK_ALL;" + json_encode(players) + "\n"); // Pirnt on the log file
}
main()
{
	if (getDvar("g_gametype") != "zclassic") {
		return;
	}
	if (getDvar("mapname") != "zm_buried" && getDvar("mapname") != "zm_highrise" && getDvar("mapname") != "zm_transit") {
		return;
	}
	if ( !isDefined( level.banking_map ) )
	{
		level.banking_map = level.script;
	}
	level thread bank_teller_init();
	level thread bank_deposit_box();
}

bank_teller_init()
{
	level.bank_teller_dmg_trig = getent( "bank_teller_tazer_trig", "targetname" );
	if ( isDefined( level.bank_teller_dmg_trig ) )
	{
		level.bank_teller_transfer_trig = getent( level.bank_teller_dmg_trig.target, "targetname" );
		level.bank_teller_powerup_spot = getstruct( level.bank_teller_transfer_trig.target, "targetname" );
		level thread bank_teller_logic();
		level.bank_teller_transfer_trig.origin += vectorScale( ( 0, 0, -1 ), 25 );
		level.bank_teller_transfer_trig trigger_off();
		level.bank_teller_transfer_trig sethintstring( &"ZOMBIE_TELLER_GIVE_MONEY", level.ta_tellerfee );
	}
}

bank_teller_logic()
{
	level endon( "end_game" );
	while ( 1 )
	{
		level.bank_teller_dmg_trig waittill( "damage", damage, attacker, direction, point, type, tagname, modelname, partname, weaponname, blah );
		if ( isDefined( attacker ) && isplayer( attacker ) && damage == 1500 && type == "MOD_MELEE" )
		{
			bank_teller_give_money();
			level.bank_teller_transfer_trig trigger_off();
		}
	}
}

bank_teller_give_money()
{
	level endon( "end_game" );
	level endon( "stop_bank_teller" );
	level.bank_teller_transfer_trig trigger_on();
	bank_transfer = undefined;
	while ( 1 )
	{
		level.bank_teller_transfer_trig waittill( "trigger", player );
		if ( !is_player_valid( player, 0 ) || player.score < ( 1000 + level.ta_tellerfee ) )
		{
			continue;
		}
		if ( !isDefined( bank_transfer ) )
		{
			bank_transfer = maps/mp/zombies/_zm_powerups::specific_powerup_drop( "teller_withdrawl", level.bank_teller_powerup_spot.origin + vectorScale( ( 0, 0, -1 ), 40 ) );
			bank_transfer thread stop_bank_teller();
			bank_transfer.value = 0;
		}
		bank_transfer.value += 1000;
		bank_transfer notify( "powerup_reset" );
		bank_transfer thread maps/mp/zombies/_zm_powerups::powerup_timeout();
		player maps/mp/zombies/_zm_score::minus_to_player_score( 1000 + level.ta_tellerfee );
		level notify( "bank_teller_used" );
	}
}

stop_bank_teller()
{
	level endon( "end_game" );
	self waittill( "death" );
	level notify( "stop_bank_teller" );
}

delete_bank_teller()
{
	wait 1;
	level notify( "stop_bank_teller" );
	bank_teller_dmg_trig = getent( "bank_teller_tazer_trig", "targetname" );
	bank_teller_transfer_trig = getent( bank_teller_dmg_trig.target, "targetname" );
	bank_teller_dmg_trig delete();
	bank_teller_transfer_trig delete();
}
onPlayerSpawned(){
    self endon("disconnect"); 
    /*
		self thread setAccountValue(); is the process that goes to see the dvar set by the iw4m 
		plugin. In fact the content of the dvar is extracted and the number of operations that the user can do is updated
	*/
	self waittill("spawned_player");
	/*
		while(level.looking_for_bank_money || getDvar("bank_clients_information") == "") 
			wait 0.01;
		If the dvar is empty or someone is reading the dvar the player remains in a loop and waits for 
		access to the dvar to withdraw the contents of the bank.
	*/
	while(getDvar("bank_clients_information") == "" || !self setAccountValue()) // As long as the value of the bank is not valid then it remains in the loop
		wait 0.001;
	if(isDefined("bank_printing") && getDvar("bank_printing") == 1)
    	self iprintln("Your bank ammount is ^2"+self.account_value*level.bank_deposit_ddl_increment_amount +"$");
    for(;;){
        self waittill("spawned_player");
    }
}
setAccountValue() {
	bank_data = strTok(getDvar("bank_clients_information"), "-"); // The dvar is divided into many elements so many players are in game
	for (i = 0; i < bank_data.size; i++) {
		client_data = strTok(bank_data[i], ","); // Divides each player's data into arrays with two values
		if (int(client_data[0]) == int(self.guid)) { // If the GUID matches the user in analysis then sets the value of the bank and says that the value is valid
			self.account_value = int(client_data[1]);
			return 1;
		}
	}
	return 0;
}
onPlayerDisconnect(){
	self waittill("disconnect");
	/*
		logPrint("IW4MBANK;" + self.guid + ";" + self.account_value + "\n"); is that message on the log 
		file that iw4m read to save the data
	*/
	logPrint("IW4MBANK;" + self.guid + ";" + self.account_value + "\n"); 
}
onplayerconnect_bank_deposit_box()
{
	self.account_value = 0; // The default value of the max number of operationthe user can do is 0
	/*
		self thread onPlayerDisconnect(); is the process that goes to see when the player exits and 
		then tells iw4m to save the data of the bank of the user who left the game.
	*/
	self thread onPlayerDisconnect(); 
	self thread onPlayerSpawned();

}
DecToHex( dec ) {
	hex = "";
	digits = strTok("0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F", ",");
	while (dec > 0) {
		hex = digits[int(dec) % 16] + hex;
		dec = floor(dec / 16);
	}
	return hex;
}
bank_deposit_box()
{
	level.bank_deposit_max_amount = 250000;
	level.bank_deposit_ddl_increment_amount = 1000;
	level.bank_account_max = level.bank_deposit_max_amount / level.bank_deposit_ddl_increment_amount;
	level.bank_account_increment = int( level.bank_deposit_ddl_increment_amount / 1000 );
	deposit_triggers = getstructarray( "bank_deposit", "targetname" );
	array_thread( deposit_triggers, ::bank_deposit_unitrigger );
	withdraw_triggers = getstructarray( "bank_withdraw", "targetname" );
	array_thread( withdraw_triggers, ::bank_withdraw_unitrigger );
}

bank_deposit_unitrigger()
{
	bank_unitrigger( "bank_deposit", ::trigger_deposit_update_prompt, ::trigger_deposit_think, 5, 5, undefined, 5 );
}

bank_withdraw_unitrigger()
{
	bank_unitrigger( "bank_withdraw", ::trigger_withdraw_update_prompt, ::trigger_withdraw_think, 5, 5, undefined, 5 );
}

bank_unitrigger( name, prompt_fn, think_fn, override_length, override_width, override_height, override_radius )
{
	unitrigger_stub = spawnstruct();
	unitrigger_stub.origin = self.origin;
	if ( isDefined( self.script_angles ) )
	{
		unitrigger_stub.angles = self.script_angles;
	}
	else
	{
		unitrigger_stub.angles = self.angles;
	}
	unitrigger_stub.script_angles = unitrigger_stub.angles;
	if ( isDefined( override_length ) )
	{
		unitrigger_stub.script_length = override_length;
	}
	else if ( isDefined( self.script_length ) )
	{
		unitrigger_stub.script_length = self.script_length;
	}
	else
	{
		unitrigger_stub.script_length = 32;
	}
	if ( isDefined( override_width ) )
	{
		unitrigger_stub.script_width = override_width;
	}
	else if ( isDefined( self.script_width ) )
	{
		unitrigger_stub.script_width = self.script_width;
	}
	else
	{
		unitrigger_stub.script_width = 32;
	}
	if ( isDefined( override_height ) )
	{
		unitrigger_stub.script_height = override_height;
	}
	else if ( isDefined( self.script_height ) )
	{
		unitrigger_stub.script_height = self.script_height;
	}
	else
	{
		unitrigger_stub.script_height = 64;
	}
	if ( isDefined( override_radius ) )
	{
		unitrigger_stub.script_radius = override_radius;
	}
	else if ( isDefined( self.radius ) )
	{
		unitrigger_stub.radius = self.radius;
	}
	else
	{
		unitrigger_stub.radius = 32;
	}
	if ( isDefined( self.script_unitrigger_type ) )
	{
		unitrigger_stub.script_unitrigger_type = self.script_unitrigger_type;
	}
	else
	{
		unitrigger_stub.script_unitrigger_type = "unitrigger_box_use";
		unitrigger_stub.origin -= anglesToRight( unitrigger_stub.angles ) * ( unitrigger_stub.script_length / 2 );
	}
	unitrigger_stub.cursor_hint = "HINT_NOICON";
	unitrigger_stub.targetname = name;
	maps/mp/zombies/_zm_unitrigger::unitrigger_force_per_player_triggers( unitrigger_stub, 1 );
	unitrigger_stub.prompt_and_visibility_func = prompt_fn;
	maps/mp/zombies/_zm_unitrigger::register_static_unitrigger( unitrigger_stub, think_fn );
}

trigger_deposit_update_prompt( player )
{
	if ( player.score < level.bank_deposit_ddl_increment_amount || player.account_value >= level.bank_account_max )
	{
		player show_balance();
		self sethintstring( "" );
		return 0;
	}
	self sethintstring( &"ZOMBIE_BANK_DEPOSIT_PROMPT", level.bank_deposit_ddl_increment_amount );
	return 1;
}

trigger_deposit_think()
{
	self endon( "kill_trigger" );
	while ( 1 )
	{
		self waittill( "trigger", player );
		while ( !is_player_valid( player ) )
		{
			continue;
		}
		if ( player.score >= level.bank_deposit_ddl_increment_amount && player.account_value < level.bank_account_max )
		{
			player playsoundtoplayer( "zmb_vault_bank_deposit", player );
			player.score -= level.bank_deposit_ddl_increment_amount;
			player.account_value += level.bank_account_increment;
			player maps/mp/zombies/_zm_stats::set_map_stat( "depositBox", player.account_value, level.banking_map );
			if ( isDefined( level.custom_bank_deposit_vo ) )
			{
				player thread [[ level.custom_bank_deposit_vo ]]();
			}
			if ( player.account_value >= level.bank_account_max )
			{
				self sethintstring( "" );
			}
			if(isDefined("bank_printing") && getDvar("bank_printing") == 1)
				player iprintln("Your bank ammount is ^2"+player.account_value*level.bank_deposit_ddl_increment_amount +"$");
		}
		else
		{
			player thread do_player_general_vox( "general", "exert_sigh", 10, 50 );
		}
		player show_balance();
	}
}

trigger_withdraw_update_prompt( player )
{
	if ( player.account_value <= 0 )
	{
		self sethintstring( "" );
		player show_balance();
		return 0;
	}
	self sethintstring( &"ZOMBIE_BANK_WITHDRAW_PROMPT", level.bank_deposit_ddl_increment_amount, level.ta_vaultfee );
	return 1;
}

trigger_withdraw_think()
{
	self endon( "kill_trigger" );
	while ( 1 )
	{
		self waittill( "trigger", player );
		while ( !is_player_valid( player ) )
		{
			continue;
		}
		if ( player.account_value >= level.bank_account_increment )
		{
			player playsoundtoplayer( "zmb_vault_bank_withdraw", player );
			player.score += level.bank_deposit_ddl_increment_amount;
			level notify( "bank_withdrawal" );
			player.account_value -= level.bank_account_increment;
			player maps/mp/zombies/_zm_stats::set_map_stat( "depositBox", player.account_value, level.banking_map );
			if ( isDefined( level.custom_bank_withdrawl_vo ) )
			{
				player thread [[ level.custom_bank_withdrawl_vo ]]();
			}
			else
			{
				player thread do_player_general_vox( "general", "exert_laugh", 10, 50 );
			}
			player thread player_withdraw_fee();
			if ( player.account_value < level.bank_account_increment )
			{
				self sethintstring( "" );
			}
			if(isDefined("bank_printing") && getDvar("bank_printing") == 1)
				player iprintln("Your bank ammount is ^2"+player.account_value*level.bank_deposit_ddl_increment_amount +"$");
		}
		else
		{
			player thread do_player_general_vox( "general", "exert_sigh", 10, 50 );
		}
		player show_balance();
	}
}

player_withdraw_fee()
{
	self endon( "disconnect" );
	wait_network_frame();
	self.score -= level.ta_vaultfee;
}

show_balance()
{
/*
	iprintlnbold( "DEBUG BANKER: " + self.name + " account worth " + self.account_value );
*/
}

// Utilities for Json
arr2json(arr) {
	if (isObj(arr)) {
		return obj2json(arr);
	}
	keys = getArrayKeys(arr);
	string = "[";
	for (i = 0; i < keys.size; i++) {
		key = keys[i];
		if (!isObj(arr[key])) {
			if (isInt(arr[key])) {
				string += arr[key];
			} else {
				string += "\"" + arr[key] + "\"";
			}
		} else {
			string += obj2json(arr[key]);
		}
		if (i < keys.size - 1) {
			string += ", ";
		}
	}
	string += "]";
	return string;
}

isInt(var) {
	return int(var) == var;
}

json_encode(obj) {
	if (!IsArray(obj)) {
		return "\"" + obj + "\"\n";
	}
	if (!isObj(obj)) {
		return arr2json(obj) + "\n";
	}
	return obj2json(obj) + "\n";
}

obj2json(obj) {
	string = "{";
	keys = getArrayKeys(obj);
	if (!isDefined(keys)) {
		return "{ struct }";
	}
	for (i = 0; i < keys.size; i++) {
		key = keys[i];
		if (IsArray(obj[key])) {
			string += "\"" + key + "\": " + arr2json(obj[key]);
		} else {
			if (!isInt(obj[key])) {
				string += "\"" + key + "\": \"" + obj[key] + "\"";
			} else {
				string += "\"" + key + "\": " + obj[key];
			}
		}
		if (i < keys.size - 1) {
			string += ", ";
		}
	}
	string += "}";
	return string;
}

isObj(obj) {
	keys = getArrayKeys(obj);
	if (!isDefined(keys)) {
		return false;
	}
	for (i = 0; i < keys.size; i++) {
		if (int(keys[i]) == 0 && keys[i] != 0) {
			return true;
		}
	}
	return false;
}
