#include <amxmodx>

#define DELAYED_START 	 0	// Через сколько можно сменить карту / голосование. 0 - отключить
#define MAX_NOMINATE_MAP 5 	// Максимальное количество карт в номинации
#define INCLUDE_AMX_MAP		// Добавить команду amx_map
//#define FORCE_CHANGELEVEL  	// Смена сразу после выбора(Актуально для CSDM, GunGame и прочих noround серверов)
				// Закомментируйте, если хотите, чтобы карта менялась в начале раунда

enum _:MENUS
{
	CHANGEMAP,
	VOTEMAP
}
enum _:st
{
	None,
	Select,
	Voting,
	Changelevel
}
new g_stMenus;

enum _:DATA { Menu, Pos, MenuId, MenuIdAccept, Insider, nNum, Votes[MAX_NOMINATE_MAP + 1], Nominated[MAX_NOMINATE_MAP + 1], NewMap[32] }
new g_iMapsMenu[DATA];

new Array:g_aMaps;
new g_iMapsCount;
#if DELAYED_START > 0
	new g_iStartMap;
#endif
#if AMXX_VERSION_NUM < 183
	#include <colorchat>
	#define engine_changelevel(%0) server_cmd("changelevel %s", %0)
#endif	
public plugin_init()
{
	register_plugin("[CS:GO MOD] Maps Menu", "1.4.1", "neugomon");
	
	register_clcmd("amx_mapmenu", 		"CmdMapMenu", 		ADMIN_MAP);
	register_clcmd("amx_votemapmenu", 	"CmdVoteMapMenu", 	ADMIN_VOTE);
	register_concmd("amx_votemap", 		"CmdAmxVote", 		ADMIN_VOTE);
#if defined INCLUDE_AMX_MAP
	register_concmd("amx_map", 		"CmdAmxMap", 		ADMIN_MAP);
#endif	
	g_iMapsMenu[MenuId] = register_menuid("Maps Menu");
	g_iMapsMenu[MenuIdAccept] = register_menuid("Accept Menu");
	register_menucmd(g_iMapsMenu[MenuId], 1023, "mapsmenu_handler");
	register_menucmd(g_iMapsMenu[MenuIdAccept], MENU_KEY_1|MENU_KEY_2, "acceptmenu_handler");
	register_menucmd(register_menuid("Vote Map"), (-1^(-1<<(MAX_NOMINATE_MAP+1))), "votemap_handler");
#if !defined FORCE_CHANGELEVEL	
	register_event("HLTV", "eRoundStart", "a", "1=0", "2=0");
#endif
#if DELAYED_START > 0
	g_iStartMap = get_systime();
#endif
}

public plugin_cfg()
{
	g_aMaps = ArrayCreate(32);
	new fp = fopen("addons/amxmodx/configs/csgo/csgo_maps.ini", "rt");
	if(!fp) set_fail_state("Map file not found!");
	
	new szMapName[32], buff[32];
	while(!feof(fp))
	{
		fgets(fp, buff, charsmax(buff));
		remove_quotes(buff); trim(buff);
		
		if(buff[0] && buff[0] != ';' && parse(buff, szMapName, charsmax(szMapName)) && is_map_valid(szMapName))
			ArrayPushString(g_aMaps, szMapName);
	}
	fclose(fp);
	
	g_iMapsCount = ArraySize(g_aMaps);
	if(!g_iMapsCount) 
		set_fail_state("Maps not found");
}

public plugin_end()
	ArrayDestroy(g_aMaps);
#if !defined FORCE_CHANGELEVEL
public eRoundStart()
	if(g_stMenus == Changelevel && g_iMapsMenu[NewMap][0])
		engine_changelevel(g_iMapsMenu[NewMap]);			
#endif
public CmdMapMenu(id, flags)
	return PreOpenMenu(id, flags, CHANGEMAP);

public CmdVoteMapMenu(id, flags)
	return PreOpenMenu(id, flags, VOTEMAP);	

public CmdAmxVote(id, flags)
{
	if(id && !IsValidChange(id, flags, 1))
		return PLUGIN_HANDLED;
	if(read_argc() < 2)
	{
		console_print(id, "* Использование команды - amx_votemap <map1> [map2] [map3] [map4] *");
		return PLUGIN_HANDLED;
	}
	
	g_iMapsMenu[nNum] = 0;
	for(new i, x, argvmap[32], map[32]; i < MAX_NOMINATE_MAP; i++)
	{
		read_argv(i+1, argvmap, charsmax(argvmap));
		for(x = 0; x < g_iMapsCount; x++)
		{
			ArrayGetString(g_aMaps, x, map, charsmax(map));
			if(!strcmp(map, argvmap) && !is_map_selected(x))
			{
				g_iMapsMenu[Nominated][g_iMapsMenu[nNum]] = x;
				g_iMapsMenu[nNum]++;
				break;
			}	
		}
	}
	if(!g_iMapsMenu[nNum])
		console_print(id, "* Выбранные Вами карты отсутствуют на сервере!");
	else
	{
		g_iMapsMenu[Insider] = (id == 0) ? 33 : id;
		g_stMenus = Voting;
		VoteMap();
		WriteLogs(id, 6);
	}	
	return PLUGIN_HANDLED;
}
#if defined INCLUDE_AMX_MAP
public CmdAmxMap(id, flags)
{
	if(id && !IsValidChange(id, flags, 0))
		return PLUGIN_HANDLED;
	read_argv(1, g_iMapsMenu[NewMap], charsmax(g_iMapsMenu[NewMap]));
	for(new x, map[32]; x < g_iMapsCount; x++)
	{
		ArrayGetString(g_aMaps, x, map, charsmax(map));
		if(!strcmp(g_iMapsMenu[NewMap], map))
		{
			if(id) WriteLogs(id, 1);
		#if defined FORCE_CHANGELEVEL
			engine_changelevel(g_iMapsMenu[NewMap]);
		#else
			if(!id) engine_changelevel(g_iMapsMenu[NewMap]);
			else	g_stMenus = Changelevel;
		#endif
			return PLUGIN_HANDLED;
		}
	}
	console_print(id, "* Выбранная Вами карта отсутствует на сервере!");
	return PLUGIN_HANDLED;
}
#endif
public mapsmenu_handler(id, key)
{
	switch(key)
	{
		case 8: BuildMenu(id, ++g_iMapsMenu[Pos]);
		case 9:
		{
			g_iMapsMenu[Pos]--;
			if(g_iMapsMenu[Pos] < 0)
				ClearData();
			else	BuildMenu(id, g_iMapsMenu[Pos]);
		}	
		default:
		{
			switch(g_iMapsMenu[Menu])
			{
				case CHANGEMAP:
				{
					ArrayGetString(g_aMaps, g_iMapsMenu[Pos] * 8 + key, g_iMapsMenu[NewMap], charsmax(g_iMapsMenu[NewMap]));
				#if !defined FORCE_CHANGELEVEL
					new name[32]; get_user_name(id, name, charsmax(name));
					client_print_color(0, print_team_default, "^1[^4CS:GO^1] ^1Администратор ^3%s ^1сменил карту на ^3%s^1. Смена в начале раунда!", name, g_iMapsMenu[NewMap]);
				#else
					engine_changelevel(g_iMapsMenu[NewMap]);
				#endif
					WriteLogs(id, 1);
					
					g_stMenus = Changelevel;
				}
				case VOTEMAP:
				{
					if(key == 7)
					{
						VoteMap();
						
						g_stMenus = Voting;
						
						WriteLogs(id, 2);
					}
					else
					{
						g_iMapsMenu[Nominated][g_iMapsMenu[nNum]] = g_iMapsMenu[Pos] * 7 + key;
						g_iMapsMenu[nNum]++;
						
						if(g_iMapsMenu[nNum] == MAX_NOMINATE_MAP)
						{
							VoteMap();
							
							g_stMenus = Voting;
							
							WriteLogs(id, 2);
						}
						else	BuildMenu(id, g_iMapsMenu[Pos]);
					}	
				}
			}
		}
	}
}	

public votemap_handler(id, key)
{
	g_iMapsMenu[Votes][key]++;
	return PLUGIN_HANDLED;
}

public acceptmenu_handler(id, key)
{
	switch(key)
	{
		case 0:
		{
		#if !defined FORCE_CHANGELEVEL
			client_print_color(0, print_team_default, "^1[^4CS:GO^1] ^1Выбрана карта ^3%s^1. Смена в начале раунда!", g_iMapsMenu[NewMap]);
		#else
			engine_changelevel(g_iMapsMenu[NewMap]);
		#endif	
			WriteLogs(0, 3);
			g_stMenus = Changelevel;
		}	
		case 1:
		{
			client_print_color(0, print_team_default, "^1[^4CS:GO^1] ^1Результат не принят администратором!");
			WriteLogs(id, 4);
			ClearData();
		}
	}
	return PLUGIN_HANDLED;
}

public CheckVotes()
{
	new b;
	for(new a; a < g_iMapsMenu[nNum]; a++)
	{
		if(g_iMapsMenu[Votes][b] < g_iMapsMenu[Votes][a])		
			b = a;
	}
	if(!g_iMapsMenu[Votes][b])
	{
		client_print_color(0, print_team_default, "^1[^4CS:GO^1] ^1Голосование не состоялось. Никто не голосовал за смену.");
		WriteLogs(0, 5);
		ClearData();
	}	
	else
	{
		ArrayGetString(g_aMaps, g_iMapsMenu[Nominated][b], g_iMapsMenu[NewMap], charsmax(g_iMapsMenu[NewMap]));
		
		if(g_iMapsMenu[Insider] == 33)
		{
		#if !defined FORCE_CHANGELEVEL
			client_print_color(0, print_team_default, "^1[^4CS:GO^1] ^1Выбрана карта ^3%s^1. Смена в начале раунда!", g_iMapsMenu[NewMap]);
		#else
			engine_changelevel(g_iMapsMenu[NewMap]);
		#endif	
			WriteLogs(0, 3);
			g_stMenus = Changelevel;
		}	
		else
		{
			new menu[128];
			formatex(menu, charsmax(menu), "\r[#] \yВыбрана карта \r%s^n\wПринять результат?^n^n\r[1] \yДа^n\r[2] \wНет", g_iMapsMenu[NewMap]);
			show_menu(g_iMapsMenu[Insider], MENU_KEY_1|MENU_KEY_2, menu, -1, "Accept Menu");
		}
	}
}

PreOpenMenu(id, flags, menu)
{
	if(id && !IsValidChange(id, flags, menu == CHANGEMAP ? 0 : 1))
		return PLUGIN_HANDLED;
	
	switch(g_stMenus)	// why not?! =)
	{
		case Select: CheckOpenMenus(id, g_iMapsMenu[Insider], g_iMapsMenu[MenuId]);
		case Voting: CheckOpenMenus(id, g_iMapsMenu[Insider], g_iMapsMenu[MenuIdAccept]);
	}
	switch(g_stMenus)
	{
		case None:
		{
			g_iMapsMenu[Pos] 	= 0;
			g_iMapsMenu[Menu]	= menu;
			g_iMapsMenu[Insider]	= id;
			g_stMenus 	 	= Select;
			
			BuildMenu(id, g_iMapsMenu[Pos]);
		}
		case Select: 
			client_print_color(id, print_team_default, "^1[^4CS:GO^1] ^1Администратор ^3уже выбирает ^1%s!", menu == VOTEMAP ? "карты" : "карту");
		case Voting:
			client_print_color(id, print_team_default, "^1[^4CS:GO^1] ^1Идет голосование за следующую карту!");
		case Changelevel:
			client_print_color(id, print_team_default, "^1[^4CS:GO^1] ^1Следующая карта определена! Смена в начале раунда!");
	}
	return PLUGIN_HANDLED;
}

BuildMenu(id, pos)
{
	new szMenu[512];
	new len;
	new start, end;
	new keys = MENU_KEY_0;
	new pages;
	
	if(g_iMapsMenu[Menu] == CHANGEMAP)
	{
		start = pos * 8;
		end   = start + 8;
		pages = (g_iMapsCount / 8 + ((g_iMapsCount % 8) ? 1 : 0));
	}
	else
	{
		start = pos * 7;
		end   = start + 7;
		pages = (g_iMapsCount / 7 + ((g_iMapsCount % 7) ? 1 : 0));
	}
	
	if(start >= g_iMapsCount)
		start = g_iMapsMenu[Pos] = 0;
	if(end > g_iMapsCount) 
		end = g_iMapsCount;
	
	switch(g_iMapsMenu[Menu])
	{
		case CHANGEMAP: len = formatex(szMenu, charsmax(szMenu), "\r[#] ");
		case VOTEMAP: 	len = formatex(szMenu, charsmax(szMenu), "\r[#] ");	
	}
	
	len += formatex(szMenu[len], charsmax(szMenu) - len, "\wВыберите карты\w\R%d/%d^n^n", pos + 1, pages);

	for(new i = start, a, map[32]; i < end; i++)
	{
		ArrayGetString(g_aMaps, i, map, charsmax(map));
		switch(g_iMapsMenu[Menu])
		{
			case CHANGEMAP: 
			{
				keys |= (1 << a++);
				len += formatex(szMenu[len], charsmax(szMenu) - len, "\r[%d] \w%s^n", a, map);
			}	
			case VOTEMAP:
			{
				if(is_map_selected(i))
					len += formatex(szMenu[len], charsmax(szMenu) - len, "\r# \d%s \d[\yВыбрано\d]^n", map);
				else
				{
					keys |= (1 << a);
					len += formatex(szMenu[len], charsmax(szMenu) - len, "\r[%d] \w%s^n", a+1, map);
				}
				a++;
			}
		}
	}
	if(g_iMapsMenu[Menu] == VOTEMAP)
	{
		if(g_iMapsMenu[nNum])
		{
			len += formatex(szMenu[len], charsmax(szMenu) - len, "^n\r[8] \yНачать \wголосование^n");
			keys |= MENU_KEY_8;
		}
		else	len += formatex(szMenu[len], charsmax(szMenu) - len, "^n\r# \dНачать голосование^n");
	}
	if(end != g_iMapsCount)
	{
		formatex(szMenu[len], charsmax(szMenu) - len, "^n\r[9] \wДалее^n\r[0] \y%s", pos ? "Назад" : "Выход");
		keys |= MENU_KEY_9;
	}
	else formatex(szMenu[len], charsmax(szMenu) - len, "^n\r[0] \w%s", pos ? "Назад" : "Выход");
	
	show_menu(id, keys, szMenu, -1, "Maps Menu");	
	return PLUGIN_HANDLED;
}

ClearData()
{
	g_stMenus 		= None;
	g_iMapsMenu[nNum] 	= 0;
	g_iMapsMenu[Insider]	= 0;
	g_iMapsMenu[NewMap][0] 	= 0;
	
	arrayset(g_iMapsMenu[Nominated], 0, sizeof g_iMapsMenu[Nominated]);
}

VoteMap()
{
	new menu[300];
	new len;
	new keys;

	switch(g_iMapsMenu[nNum])
	{
		case 1:
		{
			ArrayGetString(g_aMaps, g_iMapsMenu[Nominated][0], g_iMapsMenu[NewMap], charsmax(g_iMapsMenu[NewMap]));
			len = formatex(menu, charsmax(menu), "\r[#] \wСменить карту на \r%s \y?^n^n", g_iMapsMenu[NewMap]);
			len += formatex(menu[len], charsmax(menu) - len, "\r[1] \wДа^n\r[2] \wНет");
			keys = MENU_KEY_1|MENU_KEY_2;
		}
		default:
		{
			len = formatex(menu, charsmax(menu), "\r[#] \wВыберите карту:^n^n");
			for(new i, map[32]; i < g_iMapsMenu[nNum]; i++)
			{
				ArrayGetString(g_aMaps, g_iMapsMenu[Nominated][i], map, charsmax(map));
				len += formatex(menu[len], charsmax(menu) - len, "\r[%d] \w%s^n", i+1, map);
				keys |= (1 << i);
			}
		}
	}
	show_menu(0, keys, menu, 15, "Vote Map");
	set_task(15.0, "CheckVotes");
}

WriteLogs(id, log)
{
	new name[32];
	if(id)
		get_user_name(id, name, charsmax(name));
	else	copy(name, charsmax(name), "Server Console");	
	switch(log)
	{
		case 1: log_amx("Администратор %s сменил карту на %s", name, g_iMapsMenu[NewMap]);
		case 2: log_amx("Администратор %s запустил голосование за %s", name, g_iMapsMenu[nNum] == 1 ? "карту" : "карты");
		case 3: log_amx("Голосование успешно! Следующая карта %s", g_iMapsMenu[NewMap]);
		case 4: log_amx("Результат голосования не принят администратором %s", name);
		case 5: log_amx("Голосование не состоялось! Никто не голосовал за смену");
		case 6:
		{
			new array[190];
			new len;
			len = formatex(array, charsmax(array), "Администратор %s номинировал ", name);
			
			for(new i, map[32]; i < g_iMapsMenu[nNum]; i++)
			{
				ArrayGetString(g_aMaps, g_iMapsMenu[Nominated][i], map, charsmax(map));
				len += formatex(array[len], charsmax(array) - len, "%s, ", map);
			}
			array[len - 2] = EOS;
			log_amx(array);
		}
	}	
}

bool:IsValidChange(id, flags, vote)
{
	if(~get_user_flags(id) & flags)
	{
		console_print(id, "* [%s] Недостаточно прав для использования этой команды!", vote ? "VoteMap" : "ChangeMap");
		return false;
	}
#if DELAYED_START > 0	
	new time = (get_systime() - g_iStartMap) / 60;
	if(DELAYED_START > time)
	{
		client_print_color(id, print_team_default, "^1[^4CS:GO^1] ^3%s ^1будет доступно через ^3%d ^1мин", vote ? "Голосование" : "Смена карты", DELAYED_START - time);
		console_print(id, "* %s будет доступно через %d мин!", vote ? "Голосование" : "Смена карты", DELAYED_START - time);
		return false;
	}
#endif	
	return true;
}

stock bool:is_map_selected(map)
{
	if(g_iMapsMenu[nNum] == 0) return false;
	for(new i; i < g_iMapsMenu[nNum]; i++)
	{
		if(g_iMapsMenu[Nominated][i] == map)
			return true;
	}
	return false;		
}

stock CheckOpenMenus(id, insider, menu)
{
	if(is_user_connected(insider))
	{
		new oldmenu, newmenu;
		player_menu_info(insider, oldmenu, newmenu);
		if(menu == oldmenu)
		{
			new szName[32];
			get_user_name(insider, szName, charsmax(szName));
			console_print(id, "* Администратор %s уже выполняет действия с картами!", szName);
		}
		else ClearData();
	}
	else ClearData();
}