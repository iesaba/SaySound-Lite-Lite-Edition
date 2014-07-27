#pragma semicolon 1
#pragma dynamic 65536

#include <sourcemod>
#include <sdktools>

// last play time, filehandle, cache
new Float:g_lastplay[MAXPLAYERS + 1];
new Handle:g_listkv       = INVALID_HANDLE;
new Handle:g_precacheTrie = INVALID_HANDLE;

public Plugin:myinfo =
{
	name        = "SaysoundsLLE",
	author      = "k725",
	description = "Saysounds(Lite Lite Edition)",
	version     = "1.0",
	url         = ""
};

// �v���O�C��������
public OnPluginStart()
{
	AddCommandListener(Command_Say, "say");
}

// �v���O�C���I��
public OnPluginEnd()
{
	Handles_Close();
}

// �}�b�v�X�^�[�g�C�x���g
public OnMapStart()
{
	for (new index = 1; index <= MAXPLAYERS; index++) 
		g_lastplay[index] = 0.0;

	if (g_precacheTrie == INVALID_HANDLE)
		g_precacheTrie = CreateTrie();
	else
		ClearTrie(g_precacheTrie);

	CreateTimer(0.1, Timer_LoadConfig);
}

// �}�b�v�I���C�x���g
public OnMapEnd()
{
	Handles_Close();
}

// �N���C�A���g�F�؃C�x���g
public OnClientAuthorized(client, const String:auth[])
{
	if(client != 0)
		g_lastplay[client] = 0.0;
}

// �N���[�Y����
Handles_Close()
{
	if (g_listkv != INVALID_HANDLE)
	{
		CloseHandle(g_listkv);
		g_listkv = INVALID_HANDLE;
	}
}

// �N���C�A���g�m�F
public IsValidClient(client)
{
	if (client == 0)
		return false;

	if (!IsClientConnected(client))
		return false;

	if (IsFakeClient(client))
		return false;

	if (!IsClientInGame(client))
		return false;

	return true;
}

// �T�E���h�pcfg�ǂݍ���
public Action:Timer_LoadConfig(Handle:timer)
{
	Cfg_LoadDefault();

	return Plugin_Handled;
}

// cfg�ǂݍ���
Cfg_LoadDefault()
{
	decl String:cfgfile[PLATFORM_MAX_PATH + 1];

	if (g_listkv != INVALID_HANDLE)
	{
		CloseHandle(g_listkv);
		g_listkv = INVALID_HANDLE;
	}

	BuildPath(Path_SM, cfgfile, sizeof(cfgfile), "configs/saysounds.cfg");
	if(FileExists(cfgfile))
	{
		g_listkv = CreateKeyValues("Sound Combinations");
		FileToKeyValues(g_listkv, cfgfile);
		KvRewind(g_listkv);

		if (KvGotoFirstSubKey(g_listkv))
		{
			decl String:filelocation[PLATFORM_MAX_PATH + 1];
			decl String:file[8];
			new count;

			do {
				// �ϐ�������
				count = KvGetNum(g_listkv, "count", 1);
				filelocation[0] = '\0';

				KvGetString(g_listkv, "file", filelocation, sizeof(filelocation), "");
				if (filelocation[0] != '\0')
				{
					Format(filelocation, sizeof(filelocation), "sound/%s", filelocation);
					AddFileToDownloadsTable(filelocation);
				}

				// �����t�@�C���L�[
				for (new filenum = 1; filenum <= count; filenum++)
				{
					filelocation[0] = '\0';

					Format(file, sizeof(file), "file%d", filenum);
					KvGetString(g_listkv, file, filelocation, sizeof(filelocation), "");
					if (filelocation[0] != '\0')
					{
						Format(filelocation, sizeof(filelocation), "sound/%s", filelocation);
						AddFileToDownloadsTable(filelocation);
					}
				}
			} while (KvGotoNextKey(g_listkv));
		}
	}
}

// say�R�}���h�t�b�N
public Action:Command_Say(client, const String:command[], argc)
{
	// �L�[����ʒu����
	decl String:speech[64];
	new startidx = 0;

	if (GetCmdArgString(speech, sizeof(speech)) < 1)
		return Plugin_Continue;

	if (speech[strlen(speech) - 1] == '"')
	{
		speech[strlen(speech) - 1] = '\0';
		startidx = 1;
	}

	// !saycommand
	if(strcmp(speech[startidx], "!saycommand", false) == 0)
	{
		ShowMOTDPanel(client, "Title", "http://files.iesaba.com/csmap/html/?f=saycommand.php", MOTDPANEL_TYPE_URL);
		return Plugin_Handled;
	}

	// �L�[���[�h�m�F
	if(Sound_CheckKeyword(client, speech[startidx]))
		return Plugin_Continue;

	return Plugin_Continue;
}

// �L�[���[�h�m�F
bool:Sound_CheckKeyword(client, const String:speech[])
{
	if(g_listkv != INVALID_HANDLE)
	{
		KvRewind(g_listkv);
		if (KvJumpToKey(g_listkv, speech))
		{
			decl String:filelocation[PLATFORM_MAX_PATH + 1];
			new String:file[8] = "file";
			new count          = KvGetNum(g_listkv, "count", 1);
			new bool:trievalue = false;

			// �����t�@�C���L�[
			if (count > 1)
			{
				for (new filenum = 1; filenum <= count; filenum++)
				{
					Format(file, sizeof(file), "file%d", filenum);

					filelocation[0] = '\0';
					KvGetString(g_listkv, file, filelocation, sizeof(filelocation));

					if(filelocation[0] != '\0')
					{
						if (!GetTrieValue(g_precacheTrie, filelocation, trievalue))
							SetTrieValue(g_precacheTrie, filelocation, true);
						else
							break;
					}
				}

				Format(file, sizeof(file), "file%d", GetRandomInt(1, count));
			}

			filelocation[0] = '\0';
			KvGetString(g_listkv, file, filelocation, sizeof(filelocation));

			// file1����
			if (filelocation[0] == '\0' && StrEqual(file, "file1"))
				KvGetString(g_listkv, "file", filelocation, sizeof(filelocation), "");

			if (filelocation[0] != '\0')
			{
				Sound_CreateTimer(client, speech, filelocation);

				return true;
			}
		}
	}

	return false;
}

// DataTimer�쐬
Sound_CreateTimer(client, const String:name[], const String:filelocation[])
{
	new Float:thetime = GetGameTime();

	if (g_lastplay[client] < thetime)
	{
		if (name[0] && IsValidClient(client))
		{
			new Handle:pack;

			CreateDataTimer(0.1, Sound_Timer, pack, TIMER_FLAG_NO_MAPCHANGE);

			// datapack
			WritePackCell(pack, client);
			WritePackString(pack, name);
			WritePackString(pack, filelocation);

			ResetPack(pack);
		}
	}
}

// �f�[�^�^�C�}�[
public Action:Sound_Timer(Handle:timer, Handle:pack)
{
	decl String:filelocation[PLATFORM_MAX_PATH + 1];
	decl String:name[PLATFORM_MAX_PATH + 1];
	new Float:thetime = GetGameTime();

	// pack�ǂݍ���
	new client = ReadPackCell(pack);
	ReadPackString(pack, name, sizeof(name));
	ReadPackString(pack, filelocation, sizeof(filelocation));

	g_lastplay[client] = thetime;

	Sound_Play(filelocation);
	PrintToServer("[iesaba] %N played %s", client, name);

	return Plugin_Handled;
}

// �Đ�
Sound_Play(const String:filelocation[])
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
			ClientCommand(i, "play *%s", filelocation);
	}
}