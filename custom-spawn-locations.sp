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
	
	spawnConfig = json_read_from_file(path);

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
		teamColor = "blu"
	}
	
	JSON_Object teamSpawns = spawnConfig.GetObject(teamColor);
	
	RandomlySelectTeamSpawnAndAttemptToSpawnPlayer(teamSpawns, clientid);
		
	return Plugin_Continue;
}

public RandomlySelectTeamSpawnAndAttemptToSpawnPlayer(JSON_Object teamSpawns, any clientid) {
	/*
	 * description:
	 * 	randomly selects a spawn from the associated json spawn config for this map and attemps to spawn the player
	 */
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
			
			float x = position.GetFloat("x");
			float y = position.GetFloat("y");
			float z = position.GetFloat("z");
			
			JSON_Object gazeDirection = spawn.GetObject("gaze direction");
			float yaw = gazeDirection.GetFloat("yaw");
			float pitch = gazeDirection.GetFloat("pitch");
			
			PrintToServer("about to respawn %s, at (%d, %d, %d) gazing at (%d, %d)", key, x, y, z, yaw, pitch);
			
			int client = GetClientOfUserId(clientid);
			
			float origin[3];
			origin[0] = x;
			origin[1] = y;
			origin[2] = z;
			
			float angles[3];
			angles[0] = pitch;
			angles[1] = yaw;
			angles[2] = 0.0;
			
			bool spawnFree = !PlayersNearSpawn(origin);
			
			if (spawnFree) {
				TeleportEntity(
					client,
					origin,
					angles,
					view_as<float>({0.0, 0.0, 0.0})
				);
			}	
		}
	}
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
	int safeDist = 100; 
		
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
