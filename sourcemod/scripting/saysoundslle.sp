#pragma semicolon 1
#pragma dynamic 65536

#include <sourcemod>
#include <sdktools>

new Float:g_lastplay[MAXPLAYERS + 1];
new Handle:g_listkv = INVALID_HANDLE;

public Plugin:myinfo =
{
	name        = "SaysoundsLLE",
	author      = "k725",
	description = "Saysounds(Lite Lite Edition)",
	version     = "1.1",
	url         = ""
};

public OnPluginStart()
{
	AddCommandListener(Command_Say, "say");
}

public OnPluginEnd()
{
	Handles_Close();
}

public OnMapStart()
{
	for (new index = 1; index <= MAXPLAYERS; index++) 
		g_lastplay[index] = 0.0;

	Handles_Close();

	decl String:cfgfile[PLATFORM_MAX_PATH + 1];
	decl String:filelocation[PLATFORM_MAX_PATH + 1];
	decl String:filelocationFake[PLATFORM_MAX_PATH + 1];

	BuildPath(Path_SM, cfgfile, sizeof(cfgfile), "configs/saysounds.cfg");

	if(FileExists(cfgfile))
	{
		g_listkv = CreateKeyValues("Sound Combinations");
		FileToKeyValues(g_listkv, cfgfile);
		KvRewind(g_listkv);

		if (KvGotoFirstSubKey(g_listkv))
		{
			do {
				filelocation[0] = '\0';

				KvGetString(g_listkv, "file", filelocation, sizeof(filelocation), "");

				if (filelocation[0] != '\0')
				{
					Format(filelocationFake, sizeof(filelocationFake), "*%s", filelocation);
					Format(filelocation, sizeof(filelocation), "sound/%s", filelocation);

					AddFileToDownloadsTable(filelocation);
					AddToStringTable(FindStringTable("soundprecache"), filelocationFake);
				}
			} while (KvGotoNextKey(g_listkv));
		}
	}
}

public OnMapEnd()
{
	Handles_Close();
}

public OnClientAuthorized(client, const String:auth[])
{
	if(client != 0)
		g_lastplay[client] = 0.0;
}


public Action:Command_Say(client, const String:command[], argc)
{
	decl String:speech[64];
	new startidx = 0;

	if (GetCmdArgString(speech, sizeof(speech)) < 1)
		return Plugin_Continue;

	if (speech[strlen(speech) - 1] == '"')
	{
		speech[strlen(speech) - 1] = '\0';
		startidx = 1;
	}

	Sound_Play(client, speech[startidx], SNDCHAN_STATIC);

	return Plugin_Continue;
}

static Sound_Play(client, const String:speech[], channel)
{
	decl String:filelocation[PLATFORM_MAX_PATH + 1];
	decl String:filelocationFake[PLATFORM_MAX_PATH + 1];
	new Float:thetime = GetGameTime();

	if(g_listkv != INVALID_HANDLE)
	{
		KvRewind(g_listkv);

		if (KvJumpToKey(g_listkv, speech))
		{
			KvGetString(g_listkv, "file", filelocation, sizeof(filelocation));

			if (filelocation[0] != '\0')
			{
				if (g_lastplay[client] < thetime)
				{
					if (speech[0] && IsValidClient(client))
					{
						g_lastplay[client] = thetime + 2.5;

						Format(filelocationFake, sizeof(filelocationFake), "*%s", filelocation);
						EmitSoundToAll(filelocationFake, SOUND_FROM_PLAYER, channel);
					}
				}
				else
					PrintToChat(client, "[iesaba] After using SaySounds to the last, it does not allow SaySounds for 2.5 seconds.");
			}
		}
	}
}

static bool:IsValidClient(client)
{
	if (client == 0 || !IsClientConnected(client) || IsFakeClient(client) || !IsClientInGame(client))
		return false;

	return true;
}

static Handles_Close()
{
	if (g_listkv != INVALID_HANDLE)
	{
		CloseHandle(g_listkv);
		g_listkv = INVALID_HANDLE;
	}
}
