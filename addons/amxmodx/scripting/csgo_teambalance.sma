// *************************************************************************************//
// Плагин загружен с  www.neugomon.ru                                                   //
// Автор: Neygomon  [ https://neugomon.ru/members/1/ ]                                  //
// Официальная тема поддержки: https://neugomon.ru/threads/549/                         //
// При копировании материала ссылка на сайт www.neugomon.ru ОБЯЗАТЕЛЬНА!                //
// *************************************************************************************//

#include <amxmodx>
#include <cstrike>
#include <hamsandwich>

new bool:g_bChangeTeam[33];

public plugin_init()
{
	register_plugin("[CS:GO MOD] Team Balance", "1.0", "neygomon");
	register_logevent("LogEventRoundEnd", 2, "1=Round_End");
	RegisterHam(Ham_Spawn, "player", "fwdHamSpawnPre", false);
}

public LogEventRoundEnd()
{
	new pl[32], tt, ct; 
	get_players(pl, tt, "e", "TERRORIST");
	get_players(pl, ct, "e", "CT");
	
	new diff = abs(tt - ct) / 2;
	if(!diff) return;
	
	new arr, sName[32];
	while(diff)
	{
		arr = random((tt > ct) ? tt : ct - 1);
		if(g_bChangeTeam[pl[arr]]) continue;
			
		g_bChangeTeam[pl[arr]] = true;
		get_user_name(pl[arr], sName, charsmax(sName));
		client_print(0, print_center, "* Игрок %s перемещен в команду %s *", sName, (tt > ct) ? "контр-террористов" : "террористов");
		diff--;	
	}
}

public fwdHamSpawnPre(pClient)
{
	if(!g_bChangeTeam[pClient]) return;
	
	switch(get_user_team(pClient))
	{
		case 1: cs_set_user_team(pClient, CS_TEAM_CT);
		case 2: cs_set_user_team(pClient, CS_TEAM_T);
	}
	g_bChangeTeam[pClient] = false;
}