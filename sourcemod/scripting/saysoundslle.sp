#pragma semicolon 1
#pragma dynamic 65536

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

new Float:g_lastplay[MAXPLAYERS + 1];
new Handle:g_listkv = INVALID_HANDLE;
new Handle: g_Cookie_SaysoundEnabled = INVALID_HANDLE;
new bool: g_IsSaysoundEnabled[MAXPLAYERS + 1] = {
    false,
    ...
};

public Plugin:myinfo =
{
	name        = "SaysoundsLLE",
	author      = "k725",
	description = "Saysounds(Lite Lite Edition)",
	version     = "1.3.5",
	url         = ""
};

public OnPluginStart()
{
	AddCommandListener(Command_Say, "say");
	g_Cookie_SaysoundEnabled = RegClientCookie("saysound_enable", "Opt in or out of Saysound", CookieAccess_Private);
	RegConsoleCmd("sm_saysound", SetSaysoundEnabled, "Opt in or out of Saysounds");
}

public OnPluginEnd()
{
	Handles_Close();
}

public OnClientConnected(client) {
    if (IsFakeClient(client)) {
        return;
    }
    g_IsSaysoundEnabled[client] = true;

	/* enable playing by default for quickplayers */
	    new String: connect_method[5];
	    GetClientInfo(client, "cl_connectmethod", connect_method, sizeof(connect_method));
	    if (strncmp("quick", connect_method, 5, false) == 0 ||
	        strncmp("match", connect_method, 5, false) == 0) {
	        g_IsSaysoundEnabled[client] = true;
	    }

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


public OnClientCookiesCached(client) {
    new String: buffer[11];
    GetClientCookie(client, g_Cookie_SaysoundEnabled, buffer, sizeof(buffer));
    if (strlen(buffer) > 0) {
        g_IsSaysoundEnabled[client] = bool: StringToInt(buffer);
    }
}

public _ClientHasSaysoundEnabled(Handle: plugin, args) {
    return _: ClientHasSaysoundEnabled(GetNativeCell(1));
}
bool: ClientHasSaysoundEnabled(client) {
    return g_IsSaysoundEnabled[client];
}

public Action: SetSaysoundEnabled(int client, int args) {
    if (!ClientHasSaysoundEnabled(client)) {
        SetClientCookie(client, g_Cookie_SaysoundEnabled, "1");
        g_IsSaysoundEnabled[client] = true;
        PrintToChat(client, "enabled_saysound");

    } else {
        SetClientCookie(client, g_Cookie_SaysoundEnabled, "0");
        g_IsSaysoundEnabled[client] = false;
        PrintToChat(client, "disabled_saysound");
	}
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

    if (g_listkv != INVALID_HANDLE) {
        KvRewind(g_listkv);

        if (KvJumpToKey(g_listkv, speech)) {
            KvGetString(g_listkv, "file", filelocation, sizeof(filelocation));

            if (filelocation[0] != '\0') {
                if (g_lastplay[client] < thetime) {
                    if (speech[0] && IsValidClient(client)) {
                        g_lastplay[client] = thetime + 1.5;
                        Format(filelocationFake, sizeof(filelocationFake), "*%s", filelocation);
                        for (int i = 1; i <= MaxClients; i++) {
                            if (IsClientInGame(i) && (!IsFakeClient(i))) {
                                if (ClientHasSaysoundEnabled(i)) {
                                    EmitSoundToClient(client, filelocationFake, .volume = volume);
                                }
                            }
                        }
                    }
                } else
                    PrintToChat(client, "[iesaba] After using SaySounds to the last, it does not allow SaySounds for 1.5 seconds.");
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
