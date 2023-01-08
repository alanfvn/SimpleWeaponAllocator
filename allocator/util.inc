#include <cstrike>

enum RoundType {
	FULL_BUY_ROUND, 
	PISTOL_ROUND, 
	DEAGLE_ROUND
};

static const CSWeaponID grenades[] =  {
	CSWeapon_MOLOTOV, 
	CSWeapon_SMOKEGRENADE, 
	CSWeapon_HEGRENADE, 
	CSWeapon_FLASHBANG, 
};


stock bool ValidPlayer(int client) {
	if (client <= 0 || client > MaxClients) {
		return false;
	}
	if (!IsClientInGame(client)) {
		return false;
	}
	if (IsClientSourceTV(client)) {
		return false;
	}
	if (IsClientReplay(client)) {
		return false;
	}
	if (!IsPlayerAlive(client)) {
		return false;
	}
	return true;
}

stock CSWeaponID GetRandomGrenade() {
	int random = GetRandomInt(0, 3);
	return grenades[random];
}

stock RoundType GetRandomRound() {
	int random = GetRandomInt(0, 2);
	return view_as<RoundType>(random);
}

stock void GetRoundMessage(RoundType round, char out[256]) {
	char rname[15];
	if (round == FULL_BUY_ROUND)
		rname = "FULL BUY ROUND";
	else if (round == PISTOL_ROUND)
		rname = "PISTOL ROUND";
	else if (round == DEAGLE_ROUND)
		rname = "DEAGLE ROUND";
	Format(out, sizeof(out), "[L7] Now is %s", rname);
}

stock int GetRoundMoney(RoundType rt) {
	if (rt == FULL_BUY_ROUND)
		return 5000;
	else if (rt == DEAGLE_ROUND)
		return 1000;
	else if (rt == PISTOL_ROUND)
		return 800;
	return 0;
}

stock void ClearPlayer(int client) {
	int weapon;
	//clear inventory
	for (int i = 0; i <= 3; i++) {
		if ((weapon = GetPlayerWeaponSlot(client, i)) != -1) {
			RemovePlayerItem(client, weapon);
			AcceptEntityInput(weapon, "Kill");
		}
	}
	if ((weapon = GetPlayerWeaponSlot(client, CS_SLOT_GRENADE)) != -1) {
		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "Kill");
	}
	//clear helmet and armor.
	SetEntProp(client, Prop_Send, "m_ArmorValue", 0);
	SetEntProp(client, Prop_Send, "m_bHasHelmet", 0);
	SetEntProp(client, Prop_Send, "m_bHasDefuser", 0);
}


stock void GiveGun(int client, CSWeaponID wid) {
	if (wid == CSWeapon_NONE) {	return;	}
	char gun[33];
	CS_WeaponIDToAlias(wid, gun, sizeof(gun));
	Format(gun, sizeof(gun), "weapon_%s", gun); 
	GivePlayerItem(client, gun);
}

stock void GiveGuns(int client, CSWeaponID[] guns, int size) {
	for (int i = 0; i < size; i++) {
		GiveGun(client, guns[i]);
	}
}

stock bool IsWarmup() {
	return GameRules_GetProp("m_bWarmupPeriod") == 1;
}

stock int GetItemPrice(int client, CSWeaponID item) {
	int price = CS_GetWeaponPrice(client, item, true);
	return price;
}

stock void GetLoadout(RoundType rt, int team, char[] primary, char[] secondary, CSWeaponID guns[2]) {
	if (rt == FULL_BUY_ROUND) {
		guns[0] = GetGun(primary, team);
		guns[1] = GetGun(secondary, team);
	} else if (rt == PISTOL_ROUND) {
		guns[0] = CSWeapon_NONE;
		guns[1] = GetGun(secondary, team);
	} else if (rt == DEAGLE_ROUND) {
		guns[0] = CSWeapon_NONE;
		guns[1] = CSWeapon_DEAGLE;
	}
}

CSWeaponID GetGun(char[] name, int team) {
	bool ct = team == CS_TEAM_CT;
	
	//primaries
	if (StrEqual("p_starter", name))
		return ct ? CSWeapon_M4A1 : CSWeapon_AK47;
	else if (StrEqual("p_galil_famas", name))
		return ct ? CSWeapon_FAMAS : CSWeapon_GALILAR;
	else if (StrEqual("p_ssg", name))
		return CSWeapon_SSG08;
	else if (StrEqual("p_aug_sg", name))
		return ct ? CSWeapon_AUG : CSWeapon_SG556;
	//secondaries
	else if (StrEqual("s_starter", name))
		return ct ? CSWeapon_HKP2000 : CSWeapon_GLOCK;
	else if (StrEqual("s_berettas", name))
		return CSWeapon_ELITE;
	else if (StrEqual("s_p250", name))
		return CSWeapon_P250;
	else if (StrEqual("s_t9_fseven", name))
		return ct ? CSWeapon_FIVESEVEN : CSWeapon_TEC9;
	else if (StrEqual("s_cz", name))
		return CSWeapon_FIVESEVEN;
	else if (StrEqual("s_deagle", name))
		return CSWeapon_DEAGLE;
	else if (StrEqual("s_r8", name))
		return CSWeapon_DEAGLE;
	//invalid weapon
	return CSWeapon_NONE;
}
