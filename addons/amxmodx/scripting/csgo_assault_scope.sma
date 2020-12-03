#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>

new const PLUGIN[] = "[CS:GO MOD] Assault Scope";
new const VERSION[] = "1.6";
new const AUTHOR[] = "hellmonja";

#define HIDEHUD_CROSSHAIR (1<<6)
#define m_iHideHUD 361

new const AUG_SCOPE[] = "models/csgo/default/v_aug_scope.mdl";
new const SIG_SCOPE[] = "models/csgo/default/v_sg553_scope.mdl";
new const AUG[] = "models/csgo/default/v_aug.mdl";
new const SG552[] = "models/csgo/default/v_sg553.mdl";

new weapon_weapon[][] =
{
	"weapon_aug",
	"weapon_sg552"
}
	
new g_Zoom[32], Float:g_ZoomTime[33], cvar_crosshair;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_event("HLTV", "Event_New_Round", "a", "1=0", "2=0");
	register_forward(FM_CmdStart, "FW_CmdStart");
	
	for(new i = 0; i < sizeof weapon_weapon; i++)
		RegisterHam(Ham_Weapon_Reload, weapon_weapon[i], "fw_Weapon_Reload_Post", 1)
	
	cvar_crosshair = register_cvar("ascope_crosshair", "0");
}

public plugin_precache()
{
	precache_model(AUG_SCOPE);
	precache_model(SIG_SCOPE);
}

public Event_New_Round()
{
	new id, players[32], num;
	get_players(players, num, "ac");
	for (new i = 0; i < num; i++)
	{
		id = players[i];
		if(get_user_weapon(id) == CSW_AUG || get_user_weapon(id) == CSW_SG552)
			UnScope(id);
	}
}

public FW_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
		
	if(is_user_bot(id))
		return FMRES_IGNORED
		
	static NewButton, zoom;
	NewButton = get_uc(uc_handle, UC_Buttons);
	
	if(NewButton & IN_ATTACK2)
	{
		if(get_user_weapon(id) == CSW_AUG || get_user_weapon(id) == CSW_SG552)
			if(get_gametime() > g_ZoomTime[id])
			{
				zoom = cs_get_user_zoom(id);
				if(g_Zoom[id] && zoom == 1)
					UnScope(id);
				else if (!g_Zoom[id] && zoom == 4)
					Scope(id);
				
				g_ZoomTime[id] = get_gametime();
			}
	}
	
	return FMRES_HANDLED
}

public fw_Weapon_Reload_Post(ent)
{
	static id;
	id = pev(ent, pev_owner);
	new zoom = cs_get_user_zoom(id);
	
	if(get_user_weapon(id) == CSW_AUG || get_user_weapon(id) == CSW_SG552)
		if(zoom == 1)
			UnScope(id);
		
	return HAM_HANDLED
}

public client_disconnect(id)
	UnScope(id);

stock Scope(id)
{
	g_Zoom[id] = 1;
	
	if(get_user_weapon(id) == CSW_AUG)
		entity_set_string(id, EV_SZ_viewmodel, AUG_SCOPE);
	else if (get_user_weapon(id) == CSW_SG552)
		entity_set_string(id, EV_SZ_viewmodel, SIG_SCOPE);
	
	if(get_pcvar_num(cvar_crosshair) == 0)
		set_pdata_int(id, m_iHideHUD, get_pdata_int(id, m_iHideHUD) | HIDEHUD_CROSSHAIR);
}

stock UnScope(id)
{	
	g_Zoom[id] = 0;

	if(get_user_weapon(id) == CSW_AUG)
		entity_set_string(id, EV_SZ_viewmodel, AUG);
	else if (get_user_weapon(id) == CSW_SG552)
		entity_set_string(id, EV_SZ_viewmodel, SG552);
			
	set_pdata_int(id, m_iHideHUD, get_pdata_int(id, m_iHideHUD) & ~HIDEHUD_CROSSHAIR);
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
