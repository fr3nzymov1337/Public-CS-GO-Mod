#include <amxmodx>
#include <amxmisc>

/** skip autoloading since it's optional */
#define AMXMODX_NOAUTOLOAD
#include <cstrike>

new g_menuPosition[33]
new g_menuPlayers[33][32]
new g_menuPlayersNum[33]
new g_menuOption[33]
new g_menuSettings[33]

#define MAX_CLCMDS 24

new g_clcmdName[MAX_CLCMDS][32]
new g_clcmdCmd[MAX_CLCMDS][64]
new g_clcmdMisc[MAX_CLCMDS][2]
new g_clcmdNum

new g_coloredMenus

new Array:g_bantimes;

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}

public plugin_init()
{
	register_plugin("[CS:GO MOD] Ban Menu", AMXX_VERSION_STR, "AMXX Dev Team / x FR3NZYMOV x")

	register_clcmd("amx_banmenu", "cmdBanMenu", ADMIN_BAN, "- displays ban menu")
	register_menucmd(register_menuid("Ban Menu"), 1023, "actionBanMenu")

	
	
	g_bantimes = ArrayCreate();
	// Load up the old default values
	ArrayPushCell(g_bantimes, 0);
	ArrayPushCell(g_bantimes, 60);
	ArrayPushCell(g_bantimes, 360);
	ArrayPushCell(g_bantimes, 720);
	ArrayPushCell(g_bantimes, 1440);
	ArrayPushCell(g_bantimes, 10400);
	ArrayPushCell(g_bantimes, 43100);
	
	register_srvcmd("amx_plmenu_bantimes", "plmenu_setbantimes");

	g_coloredMenus = colored_menus()

	new clcmds_ini_file[64]
	get_configsdir(clcmds_ini_file, 63)
	format(clcmds_ini_file, 63, "%s/clcmds.ini", clcmds_ini_file)
	load_settings(clcmds_ini_file)
}
public plmenu_setbantimes()
{
	new buff[32];
	new args = read_argc();
	
	if (args <= 1)
	{
		server_print("usage: amx_plmenu_bantimes <time1> [time2] [time3] ...");
		server_print("   use time of 0 for permanent.");
		
		return;
	}
	
	ArrayClear(g_bantimes);
	
	for (new i = 1; i < args; i++)
	{
		read_argv(i, buff, charsmax(buff));
		
		ArrayPushCell(g_bantimes, str_to_num(buff));
		
	}
	
}
public module_filter(const module[])
{
	if (equali(module, "cstrike"))
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

public actionBanMenu(id, key)
{
	switch (key)
	{
		case 7:
		{
			
			++g_menuOption[id]
			g_menuOption[id] %= ArraySize(g_bantimes);

			g_menuSettings[id] = ArrayGetCell(g_bantimes, g_menuOption[id]);

			displayBanMenu(id, g_menuPosition[id])
		}
		case 8: displayBanMenu(id, ++g_menuPosition[id])
		case 9: displayBanMenu(id, --g_menuPosition[id])
		default:
		{
			new player = g_menuPlayers[id][g_menuPosition[id] * 7 + key]
			new name[32], name2[32], authid[32], authid2[32]
		
			get_user_name(player, name2, 31)
			get_user_authid(id, authid, 31)
			get_user_authid(player, authid2, 31)
			get_user_name(id, name, 31)
			
			new userid2 = get_user_userid(player)

			log_amx("Ban: ^"%s<%d><%s><>^" ban and kick ^"%s<%d><%s><>^" (minutes ^"%d^")", name, get_user_userid(id), authid, name2, userid2, authid2, g_menuSettings[id])

			if (g_menuSettings[id]==0) // permanent
			{
				new maxpl = get_maxplayers();
				for (new i = 1; i <= maxpl; i++)
				{
					show_activity_id(i, id, name, "Бан %s навсегда", name2);
				}
			}
			else
			{
				new tempTime[32];
				formatex(tempTime,sizeof(tempTime)-1,"%d",g_menuSettings[id]);
				new maxpl = get_maxplayers();
				for (new i = 1; i <= maxpl; i++)
				{
					show_activity_id(i, id, name, "Бан %s на %d минут", name2, tempTime);
				}
			}
			/* ---------- check for Steam ID added by MistaGee -------------------- 
			IF AUTHID == 4294967295 OR VALVE_ID_LAN OR HLTV, BAN PER IP TO NOT BAN EVERYONE */
			
			if (equal("4294967295", authid2)
				|| equal("HLTV", authid2)
				|| equal("STEAM_ID_LAN", authid2)
				|| equali("VALVE_ID_LAN", authid2))
			{
				/* END OF MODIFICATIONS BY MISTAGEE */
				new ipa[32]
				get_user_ip(player, ipa, 31, 1)
				
				server_cmd("addip %d %s;writeip", g_menuSettings[id], ipa)
			}
			else
			{
				server_cmd("banid %d #%d kick;writeid", g_menuSettings[id], userid2)
			}

			server_exec()

			displayBanMenu(id, g_menuPosition[id])
		}
	}
	
	return PLUGIN_HANDLED
}

displayBanMenu(id, pos)
{
	if (pos < 0)
		return

	get_players(g_menuPlayers[id], g_menuPlayersNum[id])

	new menuBody[512]
	new b = 0
	new i
	new name[32]
	new start = pos * 7

	if (start >= g_menuPlayersNum[id])
		start = pos = g_menuPosition[id] = 0

	new len = format(menuBody, 511, g_coloredMenus ? "\r[#] \wБан меню\R%d/%d^n\w^n" : "\r[#] \wБан меню \w%d/%d^n^n", pos + 1, (g_menuPlayersNum[id] / 7 + ((g_menuPlayersNum[id] % 7) ? 1 : 0)))
	new end = start + 7
	new keys = MENU_KEY_0|MENU_KEY_8

	if (end > g_menuPlayersNum[id])
		end = g_menuPlayersNum[id]

	for (new a = start; a < end; ++a)
	{
		i = g_menuPlayers[id][a]
		get_user_name(i, name, 31)

		if (is_user_bot(i) || (access(i, ADMIN_IMMUNITY) && i != id))
		{
			++b
			
			if (g_coloredMenus)
				len += format(menuBody[len], 511-len, "\r[%d] \w%s^n\w", b, name)
			else
				len += format(menuBody[len], 511-len, "\r[#] \w%s^n", name)
		} else {
			keys |= (1<<b)
				
			if (is_user_admin(i))
				len += format(menuBody[len], 511-len, g_coloredMenus ? "\r[%d] \w%s\r*^n\w" : "\r[%d] \w%s\r*^n", ++b, name)
			else
				len += format(menuBody[len], 511-len, "\r[%d] %s^n", ++b, name)
		}
	}

	if (g_menuSettings[id])
		len += format(menuBody[len], 511-len, "^n\r[8] \wБан на \r%d \wминут^n", g_menuSettings[id])
	else
		len += format(menuBody[len], 511-len, "^n\r[8] \wБан \rнавсегда^n")

	if (end != g_menuPlayersNum[id])
	{
		format(menuBody[len], 511-len, "^n\r[9] \wДальше...^n\r[9] \w%d", pos ? "Назад" : "Выход")
		keys |= MENU_KEY_9
	}
	else
		format(menuBody[len], 511-len, "^n\r[0] \w%s", pos ? "Назад" : "Выход")

	show_menu(id, keys, menuBody, -1, "Ban Menu")
}

public cmdBanMenu(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	g_menuOption[id] = 0
	
	if (ArraySize(g_bantimes) > 0)
	{
		g_menuSettings[id] = ArrayGetCell(g_bantimes, g_menuOption[id]);
	}
	else
	{
		// should never happen, but failsafe
		g_menuSettings[id] = 0
	}
	displayBanMenu(id, g_menuPosition[id] = 0)

	return PLUGIN_HANDLED
}
load_settings(szFilename[])
{
	if (!file_exists(szFilename))
		return 0

	new text[256], szFlags[32], szAccess[32]
	new a, pos = 0

	while (g_clcmdNum < MAX_CLCMDS && read_file(szFilename, pos++, text, 255, a))
	{
		if (text[0] == ';') continue

		if (parse(text, g_clcmdName[g_clcmdNum], 31, g_clcmdCmd[g_clcmdNum], 63, szFlags, 31, szAccess, 31) > 3)
		{
			while (replace(g_clcmdCmd[g_clcmdNum], 63, "\'", "^""))
			{
				// do nothing
			}

			g_clcmdMisc[g_clcmdNum][1] = read_flags(szFlags)
			g_clcmdMisc[g_clcmdNum][0] = read_flags(szAccess)
			g_clcmdNum++
		}
	}

	return 1
}
