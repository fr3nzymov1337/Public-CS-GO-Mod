#include <amxmodx>
#include <amxmisc>

new const grenade_snds[][] = 
{
	"csgo_mod/ct_radio/ct_flashbang01.wav",
	"csgo_mod/ct_radio/ct_flashbang02.wav",
	"csgo_mod/ct_radio/ct_flashbang03.wav",
	"csgo_mod/ct_radio/ct_grenade01.wav",
	"csgo_mod/ct_radio/ct_grenade02.wav",
	"csgo_mod/ct_radio/ct_grenade03.wav",
	"csgo_mod/ct_radio/ct_smoke01.wav",
	"csgo_mod/ct_radio/ct_smoke02.wav",
	"csgo_mod/ct_radio/ct_smoke03.wav",
	"csgo_mod/t_radio/t_flashbang01.wav",
	"csgo_mod/t_radio/t_flashbang02.wav",
	"csgo_mod/t_radio/t_flashbang03.wav",
	"csgo_mod/t_radio/t_grenade01.wav",
	"csgo_mod/t_radio/t_grenade02.wav",
	"csgo_mod/t_radio/t_grenade03.wav",
	"csgo_mod/t_radio/t_smoke01.wav",
	"csgo_mod/t_radio/t_smoke02.wav",
	"csgo_mod/t_radio/t_smoke03.wav"
}

new grenade_txts[sizeof grenade_snds][65], g_txt_enabled = 1;

public plugin_init()
{
	register_plugin("[CS:GO MOD] Grenade Callouts", "1.0", "hellmonja");
	register_message(get_user_msgid("SendAudio"), "Block_Msg_Audio");
	register_message(get_user_msgid("TextMsg"), "Block_Msg_Text");
	
	//Config File
	new szFilepath[64];
	get_configsdir(szFilepath, charsmax(szFilepath));
	add(szFilepath, charsmax(szFilepath), "/csgo/csgo_callouts.ini");
	
	if(!file_exists(szFilepath))
	{
		g_txt_enabled = 0;
		return
	}

	new f = fopen(szFilepath, "rt");
	new szData[64], i = 0;

	while( !feof(f) && i < sizeof(grenade_snds)) 
	{ 
		fgets(f, szData, charsmax(szData));
		trim(szData);
		if(!szData[0] || szData[0] == ';' || szData[0] == '/' && szData[1] == '/')
			continue;
		
		copy(grenade_txts[i], charsmax(szData), szData);
		i++;
	}
	fclose(f);
}

public plugin_precache()
{
	for(new i = 0; i < sizeof grenade_snds - 1; i++)
		precache_sound(grenade_snds[i]);
}

public Block_Msg_Audio(msg_id, msg_dest, msg_entity)
{
	if(get_msg_args() != 3 || get_msg_argtype(2) != ARG_STRING)
		return PLUGIN_CONTINUE

	new arg2[20];
	get_msg_arg_string(2, arg2, 19);
	
	if(equal(arg2[1], "!MRAD_FIREINHOLE"))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public Block_Msg_Text()
{
	if(g_txt_enabled != 1)
		return PLUGIN_CONTINUE
	
	if(get_msg_args() != 5 || get_msg_argtype(3) != ARG_STRING || get_msg_argtype(5) != ARG_STRING)
		return PLUGIN_CONTINUE

	new arg3[16];
	get_msg_arg_string(3, arg3, 15);
    
	if(!equal(arg3, "#Game_radio"))
		return PLUGIN_CONTINUE

	new arg5[20];
	get_msg_arg_string(5, arg5, 19);
    
	if(equal(arg5, "#Fire_in_the_hole"))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public grenade_throw(id, grenid, wpnid)
{
	if(!is_user_alive(id))
		return
	
	new players[32], pnum, playername[32];
	new team = get_user_team(id), flag, temp;
	
	get_players(players, pnum, "a");
	get_user_name(id, playername, charsmax(playername));
	if(team == 2) flag = 0; else flag = 9;
	
	for(new i = 1; i < pnum + 1; i++)
		if(get_user_team(i) == team)
		{
			switch(wpnid)
			{    
				case CSW_FLASHBANG:
					temp = random_num(0, 2) + flag;
				case CSW_HEGRENADE:
					temp = random_num(3, 5) + flag;
				case CSW_SMOKEGRENADE:
					temp = random_num(6, 8) + flag;
			}

			client_cmd(i,"spk ^"%s^"", grenade_snds[temp]);
				
			if(g_txt_enabled == 1)
				color_print(i, "!t%s !y(RADIO): %s", playername, grenade_txts[temp]);
		}
}

stock color_print(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)
	format(msg, sizeof(msg), "%s", msg)
	replace_all(msg, 190, "!g", "^4") // Green Color
	replace_all(msg, 190, "!y", "^1") // Default Color
	replace_all(msg, 190, "!t", "^3") // Team Color
	
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