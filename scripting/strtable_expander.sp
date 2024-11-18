#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

#define MULTIPLIER (1 << 1)

// tableName="downloadables" maxentries=8192 udat_fixedsize=0 udat_networkbits=0 flags=0
// tableName="modelprecache" maxentries=4096 udat_fixedsize=1 udat_networkbits=2 flags=0
// tableName="genericprecache" maxentries=512 udat_fixedsize=1 udat_networkbits=2 flags=0
// tableName="soundprecache" maxentries=16384 udat_fixedsize=1 udat_networkbits=2 flags=0
// tableName="decalprecache" maxentries=512 udat_fixedsize=1 udat_networkbits=2 flags=0
// tableName="instancebaseline" maxentries=1024 udat_fixedsize=0 udat_networkbits=0 flags=0
// tableName="lightstyles" maxentries=64 udat_fixedsize=0 udat_networkbits=0 flags=0
// tableName="userinfo" maxentries=256 udat_fixedsize=0 udat_networkbits=0 flags=0
// tableName="DynamicModels" maxentries=4096 udat_fixedsize=1 udat_networkbits=1 flags=0
// tableName="server_query_info" maxentries=4 udat_fixedsize=0 udat_networkbits=0 flags=0
// tableName="ParticleEffectNames" maxentries=16384 udat_fixedsize=0 udat_networkbits=0 flags=0
// tableName="EffectDispatch" maxentries=1024 udat_fixedsize=0 udat_networkbits=0 flags=0
// tableName="VguiScreen" maxentries=256 udat_fixedsize=0 udat_networkbits=0 flags=0
// tableName="Materials" maxentries=1024 udat_fixedsize=0 udat_networkbits=0 flags=0
// tableName="InfoPanel" maxentries=128 udat_fixedsize=0 udat_networkbits=0 flags=0
// tableName="Scenes" maxentries=8192 udat_fixedsize=0 udat_networkbits=0 flags=0
// tableName="ServerMapCycle" maxentries=128 udat_fixedsize=0 udat_networkbits=0 flags=0
// tableName="ServerPopFiles" maxentries=128 udat_fixedsize=0 udat_networkbits=0 flags=0
// tableName="ServerMapCycleMvM" maxentries=128 udat_fixedsize=0 udat_networkbits=0 flags=0
// tableName="GameRulesCreation" maxentries=1 udat_fixedsize=0 udat_networkbits=0 flags=0

DynamicDetour g_hDHook_CreateStringTable;

public Plugin myinfo =
{
	name 		= "string table expander, for TF2",
	author 		= "PŠΣ™ SHUFEN, sappho.io",
	description = "Port of https://forums.alliedmods.net/showthread.php?t=322106 to TF2, fixes several stringtables that servers can often run up against the limits of",
	version 	= "0.x",
	url 		= ""
};

public void OnPluginStart()
{
	GameData hGameData = new GameData("strtable_expander");
	if (hGameData == null) {
		SetFailState("Cannot load ParticleStringTableExpander.games gamedata");
	}

	g_hDHook_CreateStringTable = DynamicDetour.FromConf(hGameData, "CNetworkStringTableContainer::CreateStringTable");

	delete hGameData;

	if (g_hDHook_CreateStringTable == null) {
		SetFailState("Cannot init g_hDHook_CreateStringTable detour");
	}

	g_hDHook_CreateStringTable.Enable(Hook_Pre, DHookCallback_CreateStringTable);
}

public MRESReturn DHookCallback_CreateStringTable(Address pThis, DHookReturn hReturn, DHookParam hParams)
{
	// PrintToServer("DHookCallback_CreateStringTable(%08x, %x, %x)", pThis, hReturn, hParams);

	char tableName[MAX_NAME_LENGTH];
	hParams.GetObjectVarString(1, 0, ObjectValueType_String, tableName, sizeof(tableName));
	int maxentries = hParams.Get(2);

	// PrintToServer("[strtable_expander] tableName=\"%s\" maxentries=%i udat_fixedsize=%i udat_networkbits=%i flags=%i", tableName, maxentries, hParams.Get(3), hParams.Get(4), hParams.Get(5));
	// LogMessage("[strtable_expander] tableName=\"%s\" maxentries=%i udat_fixedsize=%i udat_networkbits=%i flags=%i", tableName, maxentries, hParams.Get(3), hParams.Get(4), hParams.Get(5));

	if
	(
		MULTIPLIER != 1.0
		&&
		(
			StrEqual(tableName, "downloadables") // maxentries=8192 udat_fixedsize=0 udat_networkbits=0 flags=0
			||
			StrEqual(tableName, "modelprecache") // maxentries=4096 udat_fixedsize=1 udat_networkbits=2 flags=0
			||
			StrEqual(tableName, "genericprecache") // maxentries=512 udat_fixedsize=1 udat_networkbits=2 flags=0
			||
			StrEqual(tableName, "soundprecache") // maxentries=16384 udat_fixedsize=1 udat_networkbits=2 flags=0
			||
			StrEqual(tableName, "decalprecache") // maxentries=512 udat_fixedsize=1 udat_networkbits=2 flags=0
			||
			StrEqual(tableName, "ParticleEffectNames") // maxentries=16384 udat_fixedsize=0 udat_networkbits=0 flags=0
			||
			StrEqual(tableName, "DynamicModels") // maxentries=4096 udat_fixedsize=1 udat_networkbits=1 flags=0
			||
			StrEqual(tableName, "Scenes") // maxentries=8192 udat_fixedsize=0 udat_networkbits=0 flags=0
			||
			StrEqual(tableName, "ServerMapCycle") // maxentries=128 udat_fixedsize=0 udat_networkbits=0 flags=0
			||
			StrEqual(tableName, "ServerPopFiles") // maxentries=128 udat_fixedsize=0 udat_networkbits=0 flags=0
			||
			StrEqual(tableName, "ServerMapCycleMvM") // maxentries=128 udat_fixedsize=0 udat_networkbits=0 flags=0
		)
	)
	{
		int _maxentries = maxentries * MULTIPLIER;
		hParams.Set(2, _maxentries);

		PrintToServer("[strtable_expander] overrode maxentries for tableName=\"%s\" to ->%d<-\n", tableName, _maxentries);
		LogMessage("[strtable_expander] overrode maxentries for tableName=\"%s\" to ->%d<-\n", tableName, _maxentries);
		return MRES_ChangedHandled;
	}

	// PrintToServer("[strtable_expander] CreateStringTable: -> result=MRES_Ignored\n");
	return MRES_Ignored;
}
