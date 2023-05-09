#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#include <json>

// this is where our encoding results will go
char output[1024];
 
JSON_Object spawnConfig;

public Plugin myinfo = {
	name = "custom-spawn-locations",
	description = "Support for custom spawn locations",
	author = "cuppajoeman",
	version = "1.0",
	url = "https://cuppajoeman.com"
}

public void OnPluginStart()
{
	PrintToServer("custom spawn locations enabled");
	
	
	char path[256];
    BuildPath(Path_SM, path, sizeof(path), "configs/custom-spawn-locations/harvest_spawns.json");
	
	spawnConfig = json_read_from_file(path)
	

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int clientid = GetClientUserId(client);
	
	//if (!ClientIsRealPlayer(client)) {
	//	return Plugin_Continue;
	//}	
	
	CreateTimer(0.1, AttemptToSpawnPlayer, clientid)
	
	// try to spawn a player in one of the open spawns on the map.
}

public Action AttemptToSpawnPlayer(Handle timer, any clientid) {
	/*
	 * preconditions:
	 *	customSpawns has been set 
	 *
	 * description:
	 * 	attempts to spawn the given player using the custom spawn locations
	 *  if for any reason it is not able to spawn the player, it recursively tries again.
	 * 
	 * authors:
	 *	cuppajoeman (2023)
	*/
	bool teamBasedSpawning = true;
	
	char teamColor[3 + 1];
	
	if (!teamBasedSpawning) {
		if (GetRandomInt(0, 1) == 1) {
			teamColor = "red"
		} else {
			teamColor = "blu"
		}
	} else {
		teamColor = "red"
	}
	
	JSON_Object teamSpawns = spawnConfig.GetObject(teamColor)
	

	
	int length = teamSpawns.Length;
	int key_length = 0;
	
	int randomSpawnIndex = GetRandomInt(0, length - 1);
	
	for (int i = 0; i < length; i += 1) {
		
		if (i == randomSpawnIndex) {
			
			key_length = teamSpawns.GetKeySize(i);
			char[] key = new char[key_length];
			teamSpawns.GetKey(i, key, key_length);
		
			// JSONCellType type = obj.GetType(key);
			// do whatever you want with the key and type information
			
			//char spawnName[key_length] = key;
			
			JSON_Object spawn = teamSpawns.GetObject(key);
			
			JSON_Object position = spawn.GetObject("position");
			
			int x = position.GetInt("x");
			int y = position.GetInt("y");
			int z = position.GetInt("z");
			
			JSON_Object gazeDirection = spawn.GetObject("gaze direction");
			int yaw = spawn.GetInt("yaw");
			int pitch = spawn.GetInt("pitch");
			
			PrintToServer("about to respawn %s, at (%d, %d, %d) gazing at (%d, %d)", key, x, y, z, yaw, pitch);
				
		}
	}
		
	return Plugin_Continue;
}

//public char[] GetRandomTeamColor() {
//	if (GetRandomInt(0, 1) == 1) {
//		return "Red"
//	} else {
//		return "Blu"
//	}
//}

public bool PlayersNearSpawn(float spawnLocation[3]) {
	// hammer units: https://developer.valvesoftware.com/wiki/TF2/Team_Fortress_2_Mapper%27s_Reference
	float safeDist = 100; 
		
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			float playerOrigin[3];
			GetClientAbsOrigin(i, playerOrigin);
			if (GetVectorDistance(spawnLocation, playerOrigin) < safeDist) {
				return true;
			}
		}
	} 
	return false;
}
