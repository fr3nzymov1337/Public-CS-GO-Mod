/*
					Часть кода с обходом лимита предоставил Freedo.m, за что ему спасибо
*/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>

#pragma semicolon 1

new g_MapName[32], bool:g_VIPMap = false;

public plugin_init()
{
	register_plugin("[CS:GO MOD] Change Team", "1.1", "neygomon");
	register_clcmd("jointeam", "ShowMenu");
	register_menucmd(register_menuid("Team Menu"), MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_5|MENU_KEY_6|MENU_KEY_0, "HandleMenu");
	register_message(96, "MessageShowMenu");
	register_message(114, "MessageVGUIMenu");
	get_mapname(g_MapName, charsmax(g_MapName));
	if(containi(g_MapName, "as_") != -1) g_VIPMap = true;
}

public ShowMenu(id)
{
	new szMenu[512], iLen = formatex(szMenu, charsmax(szMenu), "\yВыбор команды:^n^n"), iKeys = MENU_KEY_0;
	new iNumTe = get_teamplayersnum(CS_TEAM_T), iNumCt = get_teamplayersnum(CS_TEAM_CT), CsTeams:iTeam = cs_get_user_team(id);
	if(iNumTe > iNumCt) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[1] \dТеррористы^n");
	else
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[1]\w Террористы^n");
		iKeys |= MENU_KEY_1;
	}
	if(iNumCt > iNumTe) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[2] \dКонтр-террористы^n^n");
	else
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[2] \wКонтр-террористы^n^n");
		iKeys |= MENU_KEY_2;
	}
	if(g_VIPMap)
	{
		if(iTeam != CS_TEAM_CT) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[3] \dСтать VIP^n^n");
		else
		{
			iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[3] \wСтать VIP^n^n");
			iKeys |= MENU_KEY_3;
		}
	}
	if(iTeam == CS_TEAM_SPECTATOR) iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[6] \dНаблюдение^n");
	else
	{
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[6] \wНаблюдение^n");
		iKeys |= MENU_KEY_6;
	}
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[0] \wВыход");
	return show_menu(id, iKeys, szMenu, -1, "Team Menu");
}

public HandleMenu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			set_pdata_int(id, 125, get_pdata_int(id, 125) & ~(1<<8));
			engclient_cmd(id, "jointeam", "1");
		}
		case 1:
		{
			set_pdata_int(id, 125, get_pdata_int(id, 125) & ~(1<<8));
			engclient_cmd(id, "jointeam", "2");
		}
		case 2:
		{
			set_pdata_int(id, 125, get_pdata_int(id, 125) & ~(1<<8));
			engclient_cmd(id, "jointeam", "3");
		}
		case 5:
		{
			user_kill(id, 1);
			engclient_cmd(id, "jointeam", "6");
		}
	}
	return PLUGIN_HANDLED;
}

public MessageShowMenu(iMsgId, iMsgDest, iReceiver)
{
	static szArg4[20]; get_msg_arg_string(4, szArg4, charsmax(szArg4));
	if(equal(szArg4, "#Team_Select", 12) || equal(szArg4, "#IG_Team_Select", 15) || equal(szArg4, "#IG_VIP_Team_Select", 19))
	{
		set_pdata_int(iReceiver, 205, 0);
		return ShowMenu(iReceiver);
	}
	return PLUGIN_CONTINUE;
}

public MessageVGUIMenu(iMsgId, iMsgDest, iReceiver)
{
	if(get_msg_arg_int(1) == 2)
	{
		set_pdata_int(iReceiver, 205, 0);
		return ShowMenu(iReceiver);
	}
	return PLUGIN_CONTINUE;
}

get_teamplayersnum(const CsTeams:iTeam)
{
	static players[32], iNum;
	get_players(players, iNum, "che", iTeam == CS_TEAM_T ? "TERRORIST" : "CT");	
	return iNum;
}