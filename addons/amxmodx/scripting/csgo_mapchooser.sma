#include <amxmodx>
#include <dhudmessage>
#include <fakemeta>

#define TimeVote 15 // Сколько будет длится голосование

new g_szMaps[5][64];
new g_Votes[5];
new g_iTimerVote[33];
new g_szWinMap[64];
new g_iNumRTV;
new g_iPlayerProcc;
new bool:g_LastRound;
new b_HasRTV[33];
new Float:g_iLastSec[33];
new bool:g_Vote;
new bool:b_HasAlreadyVoted[33];
new iAllVoted;

new const szSoundTimer[6][] = {"","fvox/one","fvox/two","fvox/three","fvox/four","fvox/five"}

public plugin_init()
{
	register_plugin("[CS:GO MOD] MapManager", "1.0", "BlackSmoke / x FR3NZYMOV x");
	
	register_clcmd("say /rtv", "RockTheVote")
	register_clcmd("say /rockthevote", "RockTheVote")
	register_clcmd("say rtv", "RockTheVote")
	register_clcmd("say rockthevote", "RockTheVote")
	
	register_clcmd("say nextmap", "Show_Nextmap")
	register_clcmd("say /nextmap", "Show_Nextmap")
	
	register_menucmd(register_menuid("VoteMenu"), 1023, "ActionVoteMenu");
	
	register_logevent("RoundEnd", 2, "1=Round_End")
	
	set_task(121.0, "ClCmdVote", _, _, _, "d")
	
	register_cvar("amx_nextmap", "[Не определена]");
	set_cvar_string("amx_nextmap", "[Не определена]");
	
	LoadMapsInVote();
}

public plugin_natives()
	register_native("VoteMap", "ClCmdVote", 1)

public Show_Nextmap(id)
{
	new cmd[127];
	get_cvar_string("amx_nextmap", cmd, 126)
	ChatColor(0, "!y[!gCS:GO!y] !teamСледующая карта: !g%s", cmd)
}

public RoundEnd()
	if(g_LastRound)
		set_task(1.0, "changelevel");

public RockTheVote(id)
{
	if(g_Vote)
	{
		ChatColor(id, "!y[!gCS:GO!y] !teamГолосование уже начато. !g*RTV*")
		return PLUGIN_CONTINUE;
	}
	if(b_HasRTV[id])
	{
		ChatColor(id, "!y[!gCS:GO!y] !teamВы уже голосовали. !g*RTV*")
		return PLUGIN_CONTINUE;
	}
	new iNum, szPlayers[32];
	get_players(szPlayers, iNum, "hc")
	g_iNumRTV++;
	b_HasRTV[id] = true;
	if(g_iNumRTV == iNum)
	{
		ChatColor(0, "!y[!gCS:GO!y] !teamВсе игроки !g(%d) !teamзахотели досрочную смену карты. !g*RTV*", g_iNumRTV)
		set_task(5.0, "ClCmdVote");
	}
	else
		ChatColor(0, "!y[!gCS:GO!y] !teamЧтобы начать досрочное голосование нужно !g%d !teamголосов. !g*RTV*", iNum-g_iNumRTV)
		
	return PLUGIN_HANDLED;
}

public LoadMapsInVote()
{
	new szFileName[64], Len, iNumRandomMap, q, iRepeat, szMapName[32], szDirMaps[127];
	get_mapname(szMapName, 31);
	format(szFileName, 63, "addons/amxmodx/configs/csgo/csgo_maps.ini")
	q = random_num(0, file_size(szFileName, 1)-1)
	
	while(read_file(szFileName, q ,g_szMaps[iNumRandomMap], 63, Len))
	{		
		q = random_num(0, file_size(szFileName, 1)-1)
		
		if(iRepeat == q)
			continue;
		
		iRepeat = q;
		
		if(g_szMaps[iNumRandomMap][0] == ';' || Len == 0)
			continue
	
		format(szDirMaps, 126, "maps/%s.bsp", g_szMaps[iNumRandomMap]);
		if(!equali(szMapName, g_szMaps[iNumRandomMap]) && file_exists(szDirMaps))
			iNumRandomMap++
	
		if(iNumRandomMap > 4)
			break;
	}
}

public ClCmdVote()
	set_task(1.0, "ValueVote", _, _, _, "a", 6);

public ValueVote()
{
	new szSec[32];
	set_dhudmessage( 255,255,0, -1.0, -0.80, 0, 6.0, 0.001, 0.1, 1.5 )
	static timer = 6
	timer--
	switch(timer)
	{
		case 0: 
		{
			g_Vote = true;
			startvote()
			arrayset(g_Votes, 0, sizeof(g_Votes));
			arrayset(g_iTimerVote, TimeVote-10, 33);
			arrayset(b_HasAlreadyVoted, false, 33);
			set_task(float(TimeVote), "endvote");
			timer = 6;
			set_cvar_string("amx_nextmap", "[Идёт голосование]");
		}
		default: 
		{
			get_ending(timer, szSec, "у")
			show_dhudmessage(0, "Голосование пройдёт через %d %s", timer, szSec)
			client_cmd(0, "spk %s", szSoundTimer[timer])
		}
	}
}

public startvote()
{
	if(!g_Vote)
		return PLUGIN_CONTINUE;
		
	new szPlayers[32], iNum;
	get_players(szPlayers, iNum);
	iAllVoted = 0;
	
	for(new i; i < iNum; i++)
		ChooseMap(szPlayers[i])
	
	return PLUGIN_HANDLED;
}

public ChooseMap(id)
{
	if(!g_Vote)
		return PLUGIN_CONTINUE;
	
	new szMenu[512], iLen, iKey, szSec[32]
	get_ending(g_iTimerVote[id], szSec, "а");
	iLen = format(szMenu[iLen], charsmax(szMenu)-iLen, "\r[CS:GO] \yПора выбирать следующую карту.^n\dУ вас \r%d \dсек, чтобы подумать^n", g_iTimerVote[id], szSec)
	for(new q; q < 5; q++)
	{
		if(!b_HasAlreadyVoted[id])
			iLen += format(szMenu[iLen], charsmax(szMenu)-iLen, "^n\r[%d] \w%s \d[\y%d%%\d]",q+1, g_szMaps[q], g_Votes[q] * g_iPlayerProcc) 
		else
			iLen += format(szMenu[iLen], charsmax(szMenu)-iLen, "^n\d[%s] [\y%d%%\d]", g_szMaps[q], g_Votes[q] * g_iPlayerProcc) 
	}
	
	if(!b_HasAlreadyVoted[id])
	{
		iKey |= MENU_KEY_0;
		iLen += format(szMenu[iLen], charsmax(szMenu)-iLen, "^n^n\r[0] \wНичего")
	}
	
	iLen += format(szMenu[iLen], charsmax(szMenu)-iLen, "^n^n\yПроголосовало: \r%d \dчеловек", iAllVoted) 
	
	iKey |= MENU_KEY_0|MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5
	
	if(b_HasAlreadyVoted[id])
		iKey &= ~(MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5);
	
	show_menu(id, iKey, szMenu, -1, "VoteMenu");
	return PLUGIN_HANDLED;
}

public ActionVoteMenu(id, iKey)
{
	if(!g_Vote)
		return PLUGIN_CONTINUE;
		
	new szName[32]
	get_user_name(id, szName, 31)
	
	if(iKey == 9)
	{
		if(!b_HasAlreadyVoted[id])
			ChatColor(0, "!g%s !teamне принял участие в голосовании.", szName);
		b_HasAlreadyVoted[id] = true
		return PLUGIN_CONTINUE;
	}
	
	iAllVoted++;
	
	g_Votes[iKey]++, b_HasAlreadyVoted[id] = true;
	ChatColor(0, "!y[!gCS:GO!y] !g%s !teamвыбрал !g%s", szName, g_szMaps[iKey]);
	
	return PLUGIN_HANDLED;
}

public endvote()
{
	g_Vote = false;
	new win = 0, szDirFile[127];
	for(new i; i < sizeof(g_Votes); i++)
	{		
		if(win < g_Votes[i])
		{
			win = i
			format(g_szWinMap, 63, g_szMaps[win])
		}
	}

	if(win < g_Votes[0])
	{
		win = 0;
		format(g_szWinMap, 63, g_szMaps[win]);
	}
	
	if(!g_szWinMap[0])
	{
		LoadMapsInVote();
		set_task(5.0, "ClCmdVote");
		ChatColor(0, "!y[!gCS:GO!y] !teamГолосование отложено.")
		return PLUGIN_CONTINUE;
	}
	format(szDirFile, 126, "maps/%s.bsp", g_szWinMap);
	if(!file_exists(szDirFile))
	{
		LoadMapsInVote();
		set_task(5.0, "ClCmdVote");
		ChatColor(0, "!teamГолосование отложено из за отсутствующей карты.")
		return PLUGIN_CONTINUE;
	}
	set_dhudmessage( 149,68,0, -1.0, -0.70, 2, 4.0, 11.0, 0.01, 1.5 )
	show_dhudmessage(0, "Следующая карта: %s^nКарта сменится по окончанию раунда",g_szWinMap, win)
	ChatColor(0, "!y[!gCS:GO!y] !teamСледующая карта: !g%s", g_szWinMap)
	set_cvar_string("amx_nextmap", g_szWinMap);
	set_cvar_float("mp_timelimit", 0.0)
	g_LastRound = true;
	
	return PLUGIN_HANDLED;
}

public changelevel()
{
	server_cmd("changelevel %s", g_szWinMap);
}

public client_PreThink(id)
{
	if(!g_Vote)
		return;
		
	if(g_iTimerVote[id] <= -1)
		return;
	
	if(iAllVoted)
		g_iPlayerProcc = 100 / iAllVoted;
	else
		g_iPlayerProcc = 0;
	
	if((get_gametime() - g_iLastSec[id]) >= 1.0)
		if(g_iTimerVote[id] != 0)
			g_iTimerVote[id]--, ChooseMap(id), g_iLastSec[id] = get_gametime();
		else
			show_menu(id, 0, "^n"), g_iTimerVote[id] = -1;
}

stock get_ending(num, output[32], const l[])
{
    new num100=num%100, num10=num%10;
    if(num100>=5&&num100<=20||num10==0||num10>=5&&num10<=9) format(output, 31, "секунд");
    else if(num10==1) format(output, 31, "секунд%s", l);
    else if(num10>=2&&num10<=4) format(output, 31, "секунды");
}

stock ChatColor(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
	format(msg, sizeof(msg), "%s", msg)
	replace_all(msg, 190, "!g", "^4") // Green Color
	replace_all(msg, 190, "!y", "^1") // Default Color
	replace_all(msg, 190, "!team", "^3") // Team Color
	
	if (id) players[0] = id; else get_players(players, count, "ch")
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
				write_byte(players[i]);
				write_string(msg); 
				message_end();
			}
		}
	}
}
