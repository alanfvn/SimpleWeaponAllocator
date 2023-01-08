#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sourcemod>
#include <clientprefs>
#include "allocator/util.inc"

//Round control
RoundType ROUND_TYPE;
bool AWP_CT = false;
bool AWP_T = false;

//ClientPrefs
Handle HPWeapon = INVALID_HANDLE;
Handle HSWeapon = INVALID_HANDLE;
char PWeapon[MAXPLAYERS + 1][15];
char SWeapon[MAXPLAYERS + 1][15];

/*
	TODO: Implement economy for each round, add guns variants and the awp chances.
*/

public Plugin myinfo =  {
	name = "SimpleWeaponAllocator", 
	author = "alanfvn", 
	description = "Simple weapon allocator for retakes.", 
	version = "0.0.1", 
	url = "https://github.com/alanfvn"
};

//EVENTS
public void OnPluginStart() {
	HPWeapon = RegClientCookie("pw_cookie", "Cookie that saves the preferences of the simple weapon allocator (primary guns).", CookieAccess_Private);
	HSWeapon = RegClientCookie("sw_cookie", "Cookie that saves the preferences of the simple weapon allocator (sec guns).", CookieAccess_Private);
	RegConsoleCmd("sm_guns", Command_Guns, "Choose what guns you want to receive.");
	HookEvent("round_start", E_RoundStart, EventHookMode_Pre);
}

public void OnPluginEnd(){
	for (int i = 1; i <= MaxClients; i++){
		OnClientDisconnect(i);
	} 
}

public void OnClientConnected(int client){
	Format(PWeapon[client], sizeof(PWeapon), "p_starter");
	Format(SWeapon[client], sizeof(SWeapon), "s_starter");
}

public void OnClientDisconnect(int client){
	SetClientCookie(client, HPWeapon, PWeapon[client]);
	SetClientCookie(client, HSWeapon, SWeapon[client]);
}

public void OnClientCookiesCached(int client){
	char p_prefs[15];
	char s_prefs[15];
	
	GetClientCookie(client, HPWeapon, p_prefs, sizeof(p_prefs));
	GetClientCookie(client, HSWeapon, s_prefs, sizeof(s_prefs));
	
	if (p_prefs[0] != '\0')
		Format (PWeapon[client], sizeof(p_prefs), p_prefs);
	if (s_prefs[0] != '\0')
		Format (SWeapon[client], sizeof(s_prefs), s_prefs);
}


public void E_RoundStart(Event event, const char[] name, bool dontBroadcast) {
	if (IsWarmup()) {
		return;
	}
	char message[256];
	ROUND_TYPE = GetRandomRound();
	AWP_CT = false;
	AWP_T = false;
	
	GetRoundMessage(ROUND_TYPE, message);
	PrintToChatAll("%s", message);	
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!ValidPlayer(i)) { continue; }
		ClearPlayer(i);
		GiveEquipment(i, GetClientTeam(i));
	}
}

//COMMANDS
public Action Command_Guns(int client, int args) {
	MainMenu(client);
	return Plugin_Handled;
}

//USEFUL METHODS
stock void GiveEquipment(int client, int team) {
	bool ct = team == CS_TEAM_CT;
	int money = GetRoundMoney(ROUND_TYPE);
	CSWeaponID loadout[2];
	
	//Equip the player.
	GivePlayerItem(client, ct ? "weapon_knife" : "weapon_knife_t");
	GetLoadout(ROUND_TYPE, team, PWeapon[client], SWeapon[client], loadout);
	GiveGuns(client, loadout, sizeof(loadout));
	
	// Armor
	if(money >= 650){
		SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
		money -= 650;
		if(money >= 350){
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
			money -= 350;
		}
	}
	
	// Nades
	CSWeaponID nade = GetRandomGrenade();
	int nade_cost = GetItemPrice(client, nade);
	
	if (money >= nade_cost) {
		GiveGun(client, nade);
		money -= nade_cost;
	}
	
	// Defuse
	if (ct && money >= 400) {
		SetEntProp(client, Prop_Send, "m_bHasDefuser", 1);
		money -= 400;
	}
}

//MENUS
void MainMenu(int client) {
	Menu menu = new Menu(Main_Callback);
	menu.ExitButton = true;
	menu.SetTitle("Guns Menu");
	menu.AddItem("primary", "Primary");
	menu.AddItem("secondary", "Secondary");
	menu.Display(client, MENU_TIME_FOREVER);
}

void PrimaryMenu(int client) {
	Menu menu = new Menu(Primary_Callback);
	menu.ExitButton = true;
	menu.SetTitle("Primary");
	menu.AddItem("p_starter", "AK-47 / M4A1");
	menu.AddItem("p_galil_famas", "Galil AR / FAMAS");
	menu.AddItem("p_ssg", "SSG 08");
	menu.AddItem("p_aug_sg", "SG 553 / AUG");
	menu.Display(client, MENU_TIME_FOREVER);
}

void SecondaryMenu(int client) {
	Menu menu = new Menu(Secondary_Callback);
	menu.ExitButton = true;
	menu.SetTitle("Secondary");
	menu.AddItem("s_starter", "Glock-18 / USP-s");
	menu.AddItem("s_berettas", "Dual Berettas");
	menu.AddItem("s_p250", "P250");
	menu.AddItem("s_t9_fseven", "Tec-9 / Five-Seven");
	menu.AddItem("s_cz", "CZ75-Auto");
	menu.AddItem("s_deagle", "Desert Eagle");
	menu.AddItem("s_r8", "R8 Revolver");
	menu.Display(client, MENU_TIME_FOREVER);
}

//MENU CALLBACKS
stock int Main_Callback(Menu menu, MenuAction action, int client, int selection) {
	if (action != MenuAction_Select) {
		delete menu;
		return;
	}
	if(selection == 0){
		PrimaryMenu(client);
	}else if(selection == 1){
		SecondaryMenu(client);
	}else {
		delete menu;
	}
}

stock int Primary_Callback(Menu menu, MenuAction action, int client, int selection) {
	if (action != MenuAction_Select) {
		delete menu;
		return;
	}
	char sBuffer[15];
	menu.GetItem(selection, sBuffer, sizeof(sBuffer));
	Format (PWeapon[client], sizeof(PWeapon), sBuffer);
}

stock int Secondary_Callback(Menu menu, MenuAction action, int client, int selection) {
	if (action != MenuAction_Select) {
		delete menu;
		return;
	}
	char sBuffer[15];
	menu.GetItem(selection, sBuffer, sizeof(sBuffer));
	Format (SWeapon[client], sizeof(SWeapon), sBuffer);
}