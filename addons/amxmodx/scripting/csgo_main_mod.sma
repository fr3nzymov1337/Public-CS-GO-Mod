#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <engine>
#include <fakemeta>
#include <colorchat>
#include <hamsandwich>
#include <fakemeta_util>

#define GAME						// Использовать кастомное название игры?

#if defined GAME 
	#define GAME_NAME	"Public CS:GO" 		// Название игры
#endif

#define GetPlayerHullSize(%1)				((pev(%1, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN)

#define DEMONAME		"Public CS-GO"		// Название демо-файла

#define FLAG_ADMIN		ADMIN_RESERVATION	// Флаг - Админ Меню
#define FLAG_SKINS		ADMIN_LEVEL_A		// Флаг - Доступ к скинам
#define FLAG_SLAY		ADMIN_SLAY			// Флаг - Стукнуть Игрока
#define FLAG_TEAM		ADMIN_KICK			// Флаг - Команда Игрока

#define URL_SITE		"vk.com/bullzzzeye"	// Домен сайта сервера
#define URL_VK_MAIN		"vk.com/bullzzzeye"	// ID гл. админа сервера
#define URL_GROUP_VK	"vk.com/bullzzzeye"	// ID группы ВКонтакте
#define URL_VK_CREATE	"vk.com/bullzzzeye"	// ID владельца сервера

#define MAIN_ADMIN		"x FR3NZYMOV x"		// Никнейм гл. админа
#define CREATE_SERVER	"x FR3NZYMOV x"		// Никнейм владельца сервера

#define ADVERT_ALL						// Показывать всем?
#define REPEAT_TIME		35.0			// Время между сообщениями

const XoWeapon 			= 4;
const XoPlayer         		= 5;
const m_pPlayer 		= 41;
const m_flNextPrimaryAttack	= 46;
const m_flTimeWeaponIdle	= 48;
const m_fInSpecialReload 	= 55;
const m_flNextAttack 		= 83;
const m_pActiveItem 		= 373;
const m_iId 			= 43;

new const wpns_without_inspect = (1 << CSW_C4) | (1 << CSW_HEGRENADE) | (1 << CSW_FLASHBANG) | (1 << CSW_SMOKEGRENADE);
new const wpns_scoped = (1 << CSW_AUG) | (1 << CSW_AWP) | (1 << CSW_G3SG1) | (1 << CSW_SCOUT) | (1 << CSW_SG550) | (1 << CSW_SG552);

new g_deagle_overide[33];

new const start_sounds[][] =
{
        "csgo_mod/events/roundstart1.wav",
        "csgo_mod/events/roundstart2.wav"
}

new const end_sound[] = "csgo_mod/events/roundend.wav"

new inspect_anim[] = 
{
	0,	//null
	7,	//p228
	0,	//shield
	5,	//scout
	0,	//hegrenade
	7,	//xm1014
	0,	//c4
	6,	//mac10
	6,	//aug
	0,	//smoke grenade
	16,	//elites
	6,	//fiveseven
	6,	//ump45
	5,	//sg550
	6,	//galil
	6,	//famas
	16,	//usp
	13,	//glock
	6,	//awp
	6,	//mp5
	5,	//m249
	7,	//m3
	15,	//m4a1
	6,	//tmp
	6,	//g3sg1
	0,	//flashbang
	6,	//deagle
	6,	//sg552
	6,	//ak47
	8,	//knife
	6	//p90
}

new Float:idle_calltime[] = 
{
	0.0,	//null
	6.5,	//p228
	0.0,	//shield
	5.3,	//scout
	0.0,	//hegrenade
	4.6,	//xm1014
	0.0,	//c4
	5.3,	//mac10
	4.4,	//aug
	0.0,	//smoke grenade
	4.6,	//elites
	6.5,	//fiveseven
	6.9,	//ump45
	5.3,	//sg550
	4.6,	//galil
	6.4,	//famas
	6.5,	//usp
	6.5,	//glock
	5.0,	//awp
	7.7,	//mp5
	6.9,	//m249
	5.6,	//m3
	5.1,	//m4a1
	7.4,	//tmp
	4.5,	//g3sg1
	0.0,	//flashbang
	5.7,	//deagle
	4.4,	//sg552
	4.6,	//ak47
	6.3,	//knife
	5.4	//p90
}

new weapon_classnames[][] =
{
	"weapon_p228",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_usp",
	"weapon_glock18",
	"weapon_deagle",
	"weapon_ak47",
	"weapon_m4a1",
	"weapon_awp",
	"weapon_mp5navy",
	"weapon_ump45",
	"weapon_galil",
	"weapon_famas",
	"weapon_sg552",
	"weapon_aug",
	"weapon_mac10",
	"weapon_tmp",
	"weapon_scout",
	"weapon_m3",
	"weapon_xm1014",
	"weapon_g3sg1",
	"weapon_sg550",
	"weapon_m249",
	"weapon_knife",
	"weapon_p90"
}

new Float:g_fLastCmdTime[33];
new CheckTime;

enum Coordinate { Float:X, Float:Y, Float:Z };

new adMessages[256][192];
new ad_count, iMessgCount;

new bool:g_bAllowRecord[33];

new keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<7|1<<8|1<<9)
new KnifeId[33], Ak47Id[33], AwpId[33], M4A1sId[33], DeagleId[33], Glock18Id[33], USPsId[33];

new Trie:g_tReplaceInfoMsg;

new g_Sounds[][] = 
{
	// ak47 sounds
	"sound/weapons/csgo_mod/ak47/boltpull.wav",
	"sound/weapons/csgo_mod/ak47/clipin.wav",
	"sound/weapons/csgo_mod/ak47/clipout.wav",
	"sound/weapons/csgo_mod/ak47/draw.wav",
	
	// aug sounds
	"sound/weapons/csgo_mod/aug/boltpull.wav",
	"sound/weapons/csgo_mod/aug/boltrelease.wav",
	"sound/weapons/csgo_mod/aug/clipin.wav",
	"sound/weapons/csgo_mod/aug/clipout.wav",
	"sound/weapons/csgo_mod/aug/cliptap.wav",
	"sound/weapons/csgo_mod/aug/draw.wav",
	
	// awp sounds
	"sound/weapons/csgo_mod/awp/boltdown.wav",
	"sound/weapons/csgo_mod/awp/boltup.wav",
	"sound/weapons/csgo_mod/awp/clipin.wav",
	"sound/weapons/csgo_mod/awp/clipout.wav",
	"sound/weapons/csgo_mod/awp/cliptap.wav",
	"sound/weapons/csgo_mod/awp/draw.wav",
	
	// beretta sounds
	"sound/weapons/csgo_mod/berettas/slide.wav",
	"sound/weapons/csgo_mod/berettas/taunt_tap.wav",
	"sound/weapons/csgo_mod/berettas/clipin.wav",
	"sound/weapons/csgo_mod/berettas/clipout.wav",
	"sound/weapons/csgo_mod/berettas/hammer.wav",
	"sound/weapons/csgo_mod/berettas/draw.wav",
	
	// butterfly sounds
	"sound/weapons/csgo_mod/butterfly/backstab.wav",
	"sound/weapons/csgo_mod/butterfly/deploy_end.wav",
	"sound/weapons/csgo_mod/butterfly/deploy_start.wav",
	"sound/weapons/csgo_mod/butterfly/inspect_end.wav",
	"sound/weapons/csgo_mod/butterfly/inspect_flip1.wav",
	"sound/weapons/csgo_mod/butterfly/inspect_flip2.wav",
	"sound/weapons/csgo_mod/butterfly/inspect_flip3.wav",
	"sound/weapons/csgo_mod/butterfly/inspect_start.wav",
	
	// c4 bomb sounds
	"sound/weapons/csgo_mod/c4/disarmfinish.wav",
	"sound/weapons/csgo_mod/c4/disarmstart.wav",
	"sound/weapons/csgo_mod/c4/draw.wav",
	"sound/weapons/csgo_mod/c4/initiate.wav",
	"sound/weapons/csgo_mod/c4/plant_quiet.wav",
	"sound/weapons/csgo_mod/c4/press1.wav",
	"sound/weapons/csgo_mod/c4/press2.wav",
	"sound/weapons/csgo_mod/c4/press3.wav",
	"sound/weapons/csgo_mod/c4/press4.wav",
	"sound/weapons/csgo_mod/c4/press5.wav",
	"sound/weapons/csgo_mod/c4/press6.wav",
	"sound/weapons/csgo_mod/c4/press7.wav",
	
	// deagle sounds
	"sound/weapons/csgo_mod/deagle/slideback.wav",
	"sound/weapons/csgo_mod/deagle/slideforward.wav",
	"sound/weapons/csgo_mod/deagle/clipin.wav",
	"sound/weapons/csgo_mod/deagle/clipout.wav",
	"sound/weapons/csgo_mod/deagle/inspect_roll.wav",
	"sound/weapons/csgo_mod/deagle/draw.wav",
	
	// falchion sounds
	"sound/weapons/csgo_mod/falchion/catch.wav",
	"sound/weapons/csgo_mod/falchion/deploy_end.wav",
	"sound/weapons/csgo_mod/falchion/deploy_start.wav",
	"sound/weapons/csgo_mod/falchion/inspect_end.wav",
	"sound/weapons/csgo_mod/falchion/inspect_start.wav",
	
	// famas sounds
	"sound/weapons/csgo_mod/famas/boltback.wav",
	"sound/weapons/csgo_mod/famas/boltforward.wav",
	"sound/weapons/csgo_mod/famas/cliphit.wav",
	"sound/weapons/csgo_mod/famas/clipin.wav",
	"sound/weapons/csgo_mod/famas/clipout.wav",
	"sound/weapons/csgo_mod/famas/draw.wav",
	
	// fiveseven sounds
	"sound/weapons/csgo_mod/fiveseven/slideback.wav",
	"sound/weapons/csgo_mod/fiveseven/sliderelease.wav",
	"sound/weapons/csgo_mod/fiveseven/clipin.wav",
	"sound/weapons/csgo_mod/fiveseven/clipout.wav",
	"sound/weapons/csgo_mod/fiveseven/draw.wav",
	
	// g3sg1 sounds
	"sound/weapons/csgo_mod/g3sg1/slideback.wav",
	"sound/weapons/csgo_mod/g3sg1/slideforward.wav",
	"sound/weapons/csgo_mod/g3sg1/clipin.wav",
	"sound/weapons/csgo_mod/g3sg1/clipout.wav",
	"sound/weapons/csgo_mod/g3sg1/draw.wav",
	
	// galil sounds
	"sound/weapons/csgo_mod/galil/boltback.wav",
	"sound/weapons/csgo_mod/galil/boltrelease.wav",
	"sound/weapons/csgo_mod/galil/clipin.wav",
	"sound/weapons/csgo_mod/galil/clipout.wav",
	"sound/weapons/csgo_mod/galil/draw.wav",
	
	// glock18 sounds
	"sound/weapons/csgo_mod/glock18/slideback.wav",
	"sound/weapons/csgo_mod/glock18/sliderelease.wav",
	"sound/weapons/csgo_mod/glock18/clipin.wav",
	"sound/weapons/csgo_mod/glock18/clipout.wav",
	"sound/weapons/csgo_mod/glock18/draw.wav",
	
	// grenades sounds
	"sound/weapons/csgo_mod/grenades/draw.wav",
	"sound/weapons/csgo_mod/grenades/pinpull.wav",
	"sound/weapons/csgo_mod/grenades/throw.wav",
	
	// knife sounds
	"sound/weapons/csgo_mod/knife/deploy.wav",
	
	// m4a1-s sounds
	"sound/weapons/csgo_mod/m4a1s/boltback.wav",
	"sound/weapons/csgo_mod/m4a1s/boltforward.wav",
	"sound/weapons/csgo_mod/m4a1s/boltpull.wav",
	"sound/weapons/csgo_mod/m4a1s/clipin.wav",
	"sound/weapons/csgo_mod/m4a1s/clipout.wav",
	"sound/weapons/csgo_mod/m4a1s/m4a1_deploy.wav",
	"sound/weapons/csgo_mod/m4a1s/m4a1_silencer_screw_1.wav",
	"sound/weapons/csgo_mod/m4a1s/m4a1_silencer_screw_2.wav",
	"sound/weapons/csgo_mod/m4a1s/m4a1_silencer_screw_3.wav",
	"sound/weapons/csgo_mod/m4a1s/m4a1_silencer_screw_4.wav",
	"sound/weapons/csgo_mod/m4a1s/m4a1_silencer_screw_5.wav",
	"sound/weapons/csgo_mod/m4a1s/m4a1_silencer_screw_off_end.wav",
	"sound/weapons/csgo_mod/m4a1s/m4a1_silencer_screw_on_start.wav",
	
	// mac-10 sounds
	"sound/weapons/csgo_mod/mac10/boltback.wav",
	"sound/weapons/csgo_mod/mac10/boltforward.wav",
	"sound/weapons/csgo_mod/mac10/clipin.wav",
	"sound/weapons/csgo_mod/mac10/clipout.wav",
	"sound/weapons/csgo_mod/mac10/draw.wav",
	
	// mp5sd sounds
	"sound/weapons/csgo_mod/mp5/slideback.wav",
	"sound/weapons/csgo_mod/mp5/slideforward.wav",
	"sound/weapons/csgo_mod/mp5/clipin.wav",
	"sound/weapons/csgo_mod/mp5/clipout.wav",
	"sound/weapons/csgo_mod/mp5/draw.wav",
	
	// mp9 sounds
	"sound/weapons/csgo_mod/mp9/slideback.wav",
	"sound/weapons/csgo_mod/mp9/slideforward.wav",
	"sound/weapons/csgo_mod/mp9/clipin.wav",
	"sound/weapons/csgo_mod/mp9/clipout.wav",
	"sound/weapons/csgo_mod/mp9/draw.wav",
	
	// negev sounds
	"sound/weapons/csgo_mod/negev/chain.wav",
	"sound/weapons/csgo_mod/negev/coverup.wav",
	"sound/weapons/csgo_mod/negev/coverdown.wav",
	"sound/weapons/csgo_mod/negev/pump.wav",
	"sound/weapons/csgo_mod/negev/boxin.wav",
	"sound/weapons/csgo_mod/negev/boxout.wav",
	"sound/weapons/csgo_mod/negev/draw.wav",
	
	// nova sounds
	"sound/weapons/csgo_mod/nova/bolt.wav",
	"sound/weapons/csgo_mod/nova/draw.wav",
	"sound/weapons/csgo_mod/nova/insert.wav",
	
	// p90 sounds
	"sound/weapons/csgo_mod/p90/boltback.wav",
	"sound/weapons/csgo_mod/p90/boltrelease.wav",
	"sound/weapons/csgo_mod/p90/clipin.wav",
	"sound/weapons/csgo_mod/p90/clipout.wav",
	"sound/weapons/csgo_mod/p90/tap.wav",
	
	// p250 sounds
	"sound/weapons/csgo_mod/p250/slideback.wav",
	"sound/weapons/csgo_mod/p250/sliderelease.wav",
	"sound/weapons/csgo_mod/p250/clipin.wav",
	"sound/weapons/csgo_mod/p250/clipout.wav",
	"sound/weapons/csgo_mod/p250/draw.wav",
	
	// scar-20 sounds
	"sound/weapons/csgo_mod/scar20/boltback.wav",
	"sound/weapons/csgo_mod/scar20/boltforward.wav",
	"sound/weapons/csgo_mod/scar20/clipin.wav",
	"sound/weapons/csgo_mod/scar20/clipout.wav",
	
	// sg553 sounds
	"sound/weapons/csgo_mod/sg553/pull.wav",
	"sound/weapons/csgo_mod/sg553/release.wav",
	"sound/weapons/csgo_mod/sg553/clipin.wav",
	"sound/weapons/csgo_mod/sg553/clipout.wav",
	"sound/weapons/csgo_mod/sg553/draw.wav",
	
	// stiletto sounds
	"sound/weapons/csgo_mod/stiletto/deploy.wav",
	"sound/weapons/csgo_mod/stiletto/flip_1.wav",
	"sound/weapons/csgo_mod/stiletto/flip_2.wav",
	"sound/weapons/csgo_mod/stiletto/flip_3.wav",
	"sound/weapons/csgo_mod/stiletto/flip_4.wav",
	
	// ssg-08 sounds
	"sound/weapons/csgo_mod/ssg08/boltback.wav",
	"sound/weapons/csgo_mod/ssg08/boltrelease.wav",
	"sound/weapons/csgo_mod/ssg08/clipin.wav",
	"sound/weapons/csgo_mod/ssg08/clipout.wav",
	"sound/weapons/csgo_mod/ssg08/cliptap.wav",
	"sound/weapons/csgo_mod/ssg08/draw.wav",
	
	// ump45 sounds
	"sound/weapons/csgo_mod/ump45/boltslap.wav",
	"sound/weapons/csgo_mod/ump45/boltrelease.wav",
	"sound/weapons/csgo_mod/ump45/clipin.wav",
	"sound/weapons/csgo_mod/ump45/clipout.wav",
	"sound/weapons/csgo_mod/ump45/draw.wav",
	
	// usp sounds
	"sound/weapons/csgo_mod/usp/clipin.wav",
	"sound/weapons/csgo_mod/usp/clipout.wav",
	"sound/weapons/csgo_mod/usp/draw.wav",
	"sound/weapons/csgo_mod/usp/draw_slide.wav",
	"sound/weapons/csgo_mod/usp/silencer_screw1.wav",
	"sound/weapons/csgo_mod/usp/silencer_screw2.wav",
	"sound/weapons/csgo_mod/usp/silencer_screw3.wav",
	"sound/weapons/csgo_mod/usp/silencer_screw4.wav",
	"sound/weapons/csgo_mod/usp/silencer_screw5.wav",
	"sound/weapons/csgo_mod/usp/silencer_screw_off_end.wav",
	"sound/weapons/csgo_mod/usp/silencer_screw_on_start.wav",
	
	// xm1014 sounds
	"sound/weapons/csgo_mod/xm1014/draw.wav",
	"sound/weapons/csgo_mod/xm1014/insert.wav",
	"sound/weapons/csgo_mod/xm1014/movement1.wav"
}

new g_KnifeModels[][] =
{
	"models/csgo/skins/knife/v_bayonet.mdl", 		"models/csgo/skins/knife/p_bayonet.mdl",
	"models/csgo/skins/knife/v_falchion.mdl", 		"models/csgo/skins/knife/p_falchion.mdl",
	"models/csgo/skins/knife/v_gut.mdl", 			"models/csgo/skins/knife/p_gut.mdl",
	"models/csgo/skins/knife/v_karambit.mdl", 		"models/csgo/skins/knife/p_karambit.mdl",
	"models/csgo/skins/knife/v_m9bayonet.mdl", 		"models/csgo/skins/knife/p_m9bayonet.mdl",
	"models/csgo/skins/knife/v_butterfly.mdl", 		"models/csgo/skins/knife/p_butterfly.mdl",
	"models/csgo/skins/knife/v_stiletto.mdl", 		"models/csgo/skins/knife/p_stiletto.mdl",
	"models/csgo/skins/knife/v_classic.mdl", 		"models/csgo/skins/knife/p_classic.mdl",
	"models/csgo/skins/knife/v_knives_tt.mdl", 		"models/csgo/skins/knife/p_knives_tt.mdl",
	"models/csgo/skins/knife/v_knives_ct.mdl", 		"models/csgo/skins/knife/p_knives_ct.mdl"
}

new g_Ak47Models[][] =
{
	"models/csgo/skins/skin/v_ak47_asiimov.mdl", 		"models/csgo/skins/skin/p_ak47_asiimov.mdl",
	"models/csgo/skins/skin/v_ak47_blood.mdl", 		"models/csgo/skins/skin/p_ak47_blood.mdl",
	"models/csgo/skins/skin/v_ak47_fireserpent.mdl", 	"models/csgo/skins/skin/p_ak47_fireserpent.mdl",
	"models/csgo/skins/skin/v_ak47_neon.mdl", 		"models/csgo/skins/skin/p_ak47_neon.mdl",
	"models/csgo/default/v_ak47.mdl", 			"models/csgo/default/p_ak47.mdl"
}

new g_AwpModels[][] =
{
	"models/csgo/skins/skin/v_awp_dream.mdl", 		"models/csgo/skins/skin/p_awp_dream.mdl",
	"models/csgo/skins/skin/v_awp_lore.mdl", 		"models/csgo/skins/skin/p_awp_lore.mdl",
	"models/csgo/skins/skin/v_awp_medusa.mdl", 		"models/csgo/skins/skin/p_awp_medusa.mdl",
	"models/csgo/skins/skin/v_awp_noir.mdl", 		"models/csgo/skins/skin/p_awp_noir.mdl",
	"models/csgo/default/v_awp.mdl", 			"models/csgo/default/p_awp.mdl"
}

new g_M4A1sModels[][] =
{
	"models/csgo/skins/skin/v_m4a1_beast.mdl", 		"models/csgo/skins/skin/p_m4a1_beast.mdl",
	"models/csgo/skins/skin/v_m4a1_decimator.mdl", 		"models/csgo/skins/skin/p_m4a1_decimator.mdl",
	"models/csgo/skins/skin/v_m4a1_fire.mdl", 		"models/csgo/skins/skin/p_m4a1_fire.mdl",
	"models/csgo/skins/skin/v_m4a1_nightmare.mdl", 		"models/csgo/skins/skin/p_m4a1_nightmare.mdl",
	"models/csgo/default/v_m4a1.mdl", 			"models/csgo/default/p_m4a1.mdl"
}

new g_DeagleModels[][] =
{
	"models/csgo/skins/skin/v_deagle_blaze.mdl", 		"models/csgo/skins/skin/p_deagle_blaze.mdl",
	"models/csgo/skins/skin/v_deagle_codered.mdl", 		"models/csgo/skins/skin/p_deagle_codered.mdl",
	"models/csgo/skins/skin/v_deagle_crimson.mdl", 		"models/csgo/skins/skin/p_deagle_crimson.mdl",
	"models/csgo/skins/skin/v_deagle_dragon.mdl", 		"models/csgo/skins/skin/p_deagle_dragon.mdl",
	"models/csgo/default/v_deagle.mdl", 			"models/csgo/default/p_deagle.mdl"
}

new g_Glock18Models[][] =
{
	"models/csgo/skins/skin/v_glock18_fade.mdl", 		"models/csgo/skins/skin/p_glock18_fade.mdl",
	"models/csgo/skins/skin/v_glock18_moonrise.mdl", 	"models/csgo/skins/skin/p_glock18_moonrise.mdl",
	"models/csgo/skins/skin/v_glock18_wasteland.mdl", 	"models/csgo/skins/skin/p_glock18_wasteland.mdl",
	"models/csgo/skins/skin/v_glock18_water.mdl", 		"models/csgo/skins/skin/p_glock18_water.mdl",
	"models/csgo/default/v_glock18.mdl", 			"models/csgo/default/p_glock18.mdl"
}

new g_USPsModels[][] =
{
	"models/csgo/skins/skin/v_usp_cortex.mdl", 		"models/csgo/skins/skin/p_usp_cortex.mdl",
	"models/csgo/skins/skin/v_usp_kill.mdl", 		"models/csgo/skins/skin/p_usp_kill.mdl",
	"models/csgo/skins/skin/v_usp_noir.mdl", 		"models/csgo/skins/skin/p_usp_noir.mdl",
	"models/csgo/skins/skin/v_usp_orion.mdl", 		"models/csgo/skins/skin/p_usp_orion.mdl",
	"models/csgo/default/v_usp.mdl", 			"models/csgo/default/p_usp.mdl"
}

public plugin_init()
{
	register_plugin("[CS:GO Mod] Main System", "1.1 [up1]", "x FR3NZYMOV x");
	
	// load
	Show_HamSandwich()		// hamsandwich events	
	Show_HandleMenu()		// handles for menus
	Show_CurWeapon()		// curweapon events
	Show_ClCmd()			// client commands
	
	// if tt team win
	register_event("SendAudio", "t_win", "a", "2&%!MRAD_terwin")
 
	// if ct team win   
	register_event("SendAudio", "ct_win", "a", "2&%!MRAD_ctwin") 
	
	// if round start
	register_event("HLTV", "EV_StartRound", "a", "1=0", "2=0")
	
	// game name
	#if defined GAME
		register_forward(FM_GetGameDescription, "FM_GetGameDescription_Post");
	#endif
	
	// hook spray button
	register_impulse(201, "Impulse_HookSpray");
	
	// task for adverts in chat
	set_task(REPEAT_TIME, "Msg_AdvertChat", .flags="b");
	
	// impulse for inspect weapon (button F)
	register_impulse(100, "Inspect_Weapon");
	
	// check unstuck seconds
	CheckTime = register_cvar("csgo_unstuck_seconds", "10.0");
	
	// replace message
	register_message(get_user_msgid("TextMsg"),"Msg_MessageText");
	
	g_tReplaceInfoMsg = TrieCreate();
	Msg_ReplaceMessage();
}

Show_HandleMenu()
{
	// handles for menus
	register_menucmd(register_menuid("Show_KnifeMenu"), 	keys, 	"Handle_KnifeMenu");
	register_menucmd(register_menuid("Show_ServerMenu"), 	keys, 	"Handle_ServerMenu");
	register_menucmd(register_menuid("Show_GameMenu"), 	keys, 	"Handle_GameMenu");
	register_menucmd(register_menuid("Show_SkinsMenu"), 	keys, 	"Handle_SkinsMenu");
	register_menucmd(register_menuid("Show_AdminMenu"), 	keys, 	"Handle_AdminMenu");
	register_menucmd(register_menuid("Show_AK47_Menu"),	keys, 	"Handle_AK47_Menu");
	register_menucmd(register_menuid("Show_AWP_Menu"), 	keys, 	"Handle_AWP_Menu");
	register_menucmd(register_menuid("Show_M4A1s_Menu"), 	keys, 	"Handle_M4A1s_Menu");
	register_menucmd(register_menuid("Show_Deagle_Menu"), 	keys, 	"Handle_Deagle_Menu");
	register_menucmd(register_menuid("Show_Glock18_Menu"), 	keys, 	"Handle_Glock18_Menu");
	register_menucmd(register_menuid("Show_USPs_Menu"), 	keys, 	"Handle_USPs_Menu");
	register_menucmd(register_menuid("Show_PlayerContacts"),keys,	"Handle_PlayerContactsCmd");
}

Show_ClCmd()
{
	// server menu client commands
	register_clcmd("say /menu", 			"ClCmd_ServerMenu");
	register_clcmd("say_team /menu", 		"ClCmd_ServerMenu");
	register_clcmd("menu", 				"ClCmd_ServerMenu");
	register_clcmd("/menu", 			"ClCmd_ServerMenu");
	register_clcmd("chooseteam", 			"ClCmd_ServerMenu");
	
	// reset score client commands
	register_clcmd("say /rs", 			"ClCmd_ResetScore");
	register_clcmd("say /resetscore", 		"ClCmd_ResetScore");
	register_clcmd("say_team /rs", 			"ClCmd_ResetScore");
	register_clcmd("say_team /resetscore", 		"ClCmd_ResetScore");
	
	// price motd client commands
	register_clcmd("say /price",			"ClCmd_PriceMotd");
	register_clcmd("say_team /price",		"ClCmd_PriceMotd");
	
	// demo record client commands
	register_clcmd("joinclass", 			"ClCmd_StartDemo");
	register_clcmd("menuselect", 			"ClCmd_StartDemo");
	
	// hook radio menus
	register_clcmd("radio1", 			"ClCmd_HookRadio");
	register_clcmd("radio2", 			"ClCmd_HookRadio");
	register_clcmd("radio3", 			"ClCmd_HookRadio");
}

Show_CurWeapon()
{
	register_event("CurWeapon", "EV_KnifeReplace", 		"be", "1=1");	// knife
	register_event("CurWeapon", "EV_Ak47Replace", 		"be", "1=1");	// ak47
	register_event("CurWeapon", "EV_AwpReplace", 		"be", "1=1");	// awp
	register_event("CurWeapon", "EV_M4A1sReplace", 		"be", "1=1");	// m4a1-s
	register_event("CurWeapon", "EV_DeagleReplace", 	"be", "1=1");	// deagle
	register_event("CurWeapon", "EV_Glock18Replace",	"be", "1=1");	// glock-18
	register_event("CurWeapon", "EV_USPsReplace", 		"be", "1=1");	// usp-s
}

Show_HamSandwich()
{
	for(new i = 0; i < sizeof weapon_classnames; i++)
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_classnames[i], "Fw_Weapon_PrimaryAttack", 1);

	// two anim inspect's for deagle
	RegisterHam(Ham_Item_Deploy, 		"weapon_deagle", 	"Fw_Deagle_Disable");
	RegisterHam(Ham_Weapon_Reload, 		"weapon_deagle", 	"Fw_Deagle_Disable");
	
	// not inspect weapons on scope
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_aug", 		"Fw_Weapon_SecondaryAttack");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_awp", 		"Fw_Weapon_SecondaryAttack");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_g3sg1", 	"Fw_Weapon_SecondaryAttack");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_scout", 	"Fw_Weapon_SecondaryAttack");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_sg550", 	"Fw_Weapon_SecondaryAttack");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_sg552", 	"Fw_Weapon_SecondaryAttack");
}

public plugin_precache()
{
	// precache models
	for(new i; i < sizeof(g_KnifeModels); i++)
	{ 
		precache_model(g_KnifeModels[i]);
	}
	for(new i; i < sizeof(g_Ak47Models); i++)
	{ 
		precache_model(g_Ak47Models[i]);
	}
	for(new i; i < sizeof(g_AwpModels); i++)
	{ 
		precache_model(g_AwpModels[i]);
	}
	for(new i; i < sizeof(g_M4A1sModels); i++)
	{ 
		precache_model(g_M4A1sModels[i]);
	}
	for(new i; i < sizeof(g_DeagleModels); i++)
	{ 
		precache_model(g_DeagleModels[i]);
	}
	for(new i; i < sizeof(g_Glock18Models); i++)
	{ 
		precache_model(g_Glock18Models[i]);
	}
	for(new i; i < sizeof(g_USPsModels); i++)
	{ 
		precache_model(g_USPsModels[i]);
	}
	// precache sounds
	for(new i; i < sizeof(g_Sounds); i++)
	{ 
		precache_generic(g_Sounds[i]);
	}
	precache_sound(start_sounds[0]);
	precache_sound(start_sounds[1]);
	precache_sound(end_sound);
}
public plugin_cfg()
{
	new configsdir[64], filename[64], file;
	get_localinfo("amxx_configsdir", configsdir,charsmax(configsdir));
	formatex(filename, charsmax(filename), "%s/csgo/csgo_adverts.ini",configsdir);

	file = fopen(filename,"r");

	if(file)
	{
		new string[512], message[192];
		while((ad_count < 256) && !feof(file))
		{
			fgets(file, string, charsmax(string));

			if((string[0] != ';') && (string[0] != '/') && parse(string, message, charsmax(message)))
			{
				format_color(message, charsmax(message));
				copy(adMessages[ad_count], 192, message);
				ad_count++;
			}
		}
		fclose(file);
	}
	else
		log_amx("* Файла ^"%s^" не существует *", filename);
}

public EV_StartRound()
{
	client_cmd(0, "spk %s", start_sounds[random_num(0,1)]);
}

public t_win()
{
	client_cmd(0, "spk %s", end_sound);
}

public ct_win()
{
	client_cmd(0, "spk %s", end_sound);
}

public ClCmd_HookRadio(id)
{
	client_print(id, print_center, "* Радио сообщения недоступны *")
	return PLUGIN_HANDLED;
}

public Impulse_HookSpray(id)
{
	client_print(id, print_center, "* Рисование спрея недоступно *")
	return PLUGIN_HANDLED;
}

public Msg_AdvertChat()
{	
	if(!ad_count) return;
#if defined ADVERT_ALL
	client_print_color(0, 0, "%s", adMessages[iMessgCount == ad_count ? (iMessgCount = 0) : iMessgCount++]);
#else
	static players[32], pcount;
	get_players(players, pcount, "bch");
	for(new i; i < pcount; i++)
	{
		client_print_color(players[i], 0, "%s", adMessages[iMessgCount == ad_count ? (iMessgCount = 0) : iMessgCount++]);
	}
#endif	
}

public client_putinserver(id)
{
	// if player connected
	KnifeId[id] = 9
	Ak47Id[id] = 5
	AwpId[id] = 5
	M4A1sId[id] = 5
	DeagleId[id] = 5
	Glock18Id[id] = 5
	USPsId[id] = 5
}

public ClCmd_StartDemo(id)
{
	// start rec demo
	if(g_bAllowRecord[id])
	{
		Msg_StartDemo(id);
		g_bAllowRecord[id] = false;
	}
}
public Msg_StartDemo(id)
{
	// chat message of rec demo
	if(!is_user_connected(id))
	return;
		
	client_cmd(id, "stop; record ^"%s^"", DEMONAME);	
	new datee[30];get_time("%d.%m.%Y | %H:%M:%S", datee, charsmax(datee));
	SendMsg(id, "* Идет запись демо %s.dem *", DEMONAME);
	SendMsg(id, "* Время записи: ^4%s^1 *", datee);
}
public Msg_ReplaceMessage()
{
	// replace messages
	TrieSetString(g_tReplaceInfoMsg, "#Game_Commencing",					"* Игра началась *");
	TrieSetString(g_tReplaceInfoMsg, "#Game_will_restart_in",				"* Рестарт игры произойдет через %s секунд *");
	TrieSetString(g_tReplaceInfoMsg, "#CTs_Win",						"* Контр-Террористы победили *");
	TrieSetString(g_tReplaceInfoMsg, "#Terrorists_Win",					"* Террористы победили *");
	TrieSetString(g_tReplaceInfoMsg, "#Round_Draw",						"* Раунд закончился вничью *");
	TrieSetString(g_tReplaceInfoMsg, "#Target_Bombed",					"* Цель уничтожена *");
	TrieSetString(g_tReplaceInfoMsg, "#Target_Saved",					"* Цель спасена *");
	TrieSetString(g_tReplaceInfoMsg, "#Hostages_Not_Rescued",				"* Не удалось спасти заложников *");
	TrieSetString(g_tReplaceInfoMsg, "#All_Hostages_Rescued",				"* Все заложники спасены *");
	TrieSetString(g_tReplaceInfoMsg, "#VIP_Escaped",					"* VIP-игрок спасен *");
	TrieSetString(g_tReplaceInfoMsg, "#VIP_Assassinated",					"* VIP-игрок убит *");
	TrieSetString(g_tReplaceInfoMsg, "#C4_Arming_Cancelled",				"* Бомба может быть установлена только в зоне установки бомбы *");
	TrieSetString(g_tReplaceInfoMsg, "#C4_Plant_Must_Be_On_Ground",				"* Для установки бомбы Вы должны находиться на земле *");
	TrieSetString(g_tReplaceInfoMsg, "#Defusing_Bomb_With_Defuse_Kit",			"* Обезвреживание бомбы с набором сапёра *");
	TrieSetString(g_tReplaceInfoMsg, "#Defusing_Bomb_Without_Defuse_Kit",			"* Обезвреживание бомбы без набора сапёра *");
	TrieSetString(g_tReplaceInfoMsg, "#Weapon_Cannot_Be_Dropped",				"* Нельзя выбросить данное оружие *");
	TrieSetString(g_tReplaceInfoMsg, "#C4_Plant_At_Bomb_Spot",				"* Бомба может быть установлена только в зоне установки бомбы *");
	TrieSetString(g_tReplaceInfoMsg, "#Cannot_Carry_Anymore",				"* Вы не можете взять больше *");
	TrieSetString(g_tReplaceInfoMsg, "#Already_Have_Kevlar",				"* У вас уже имеется бронежилет *");
	TrieSetString(g_tReplaceInfoMsg, "#Already_Have_Kevlar_Helmet",				"* У вас уже имеется бронежилет и шлем *");
	TrieSetString(g_tReplaceInfoMsg, "#Switch_To_BurstFire",				"* Переключен в режим пулеметного огня *");
	TrieSetString(g_tReplaceInfoMsg, "#Switch_To_FullAuto",					"* Переключен в автоматический режим *");
	TrieSetString(g_tReplaceInfoMsg, "#Switch_To_SemiAuto",					"* Переключен в полуавтоматический режим *");
	TrieSetString(g_tReplaceInfoMsg, "#Already_Own_Weapon",					"* У вас уже имеется данное оружие *");
	TrieSetString(g_tReplaceInfoMsg, "#Command_Not_Available",				"* Данное действие недоступно в Вашем местонахождении *");
	TrieSetString(g_tReplaceInfoMsg, "#Got_bomb",						"* Вы подобрали бомбу *");
	TrieSetString(g_tReplaceInfoMsg, "#Game_bomb_pickup",					"* %s подобрал бомбу *");
	TrieSetString(g_tReplaceInfoMsg, "#Game_bomb_drop",					"* %s выбросил бомбу *");
	TrieSetString(g_tReplaceInfoMsg, "#Bomb_Planted",					"* Бомба установлена *");
	TrieSetString(g_tReplaceInfoMsg, "#Bomb_Defused",					"* Бомба обезврежена *");
	TrieSetString(g_tReplaceInfoMsg, "#Cant_buy",						"* %s секунд уже истекли. Покупка арсенала запрещена *");
	TrieSetString(g_tReplaceInfoMsg, "#Name_change_at_respawn",				"* Ваше имя будет изменено после следующего возрождения *");
	TrieSetString(g_tReplaceInfoMsg, "#Auto_Team_Balance_Next_Round",			"* Автоматический баланс команды наступит в следующем раунде *");
}

public Msg_MessageText() 
{
	new szMsg[192], szArg3[32];
	get_msg_arg_string(2, szMsg, charsmax(szMsg));
	if(TrieGetString(g_tReplaceInfoMsg, szMsg, szMsg, charsmax(szMsg)))
	{
		if(get_msg_args() > 2) 
		{
			get_msg_arg_string(3, szArg3, charsmax(szArg3));
			replace(szMsg, charsmax(szMsg), "%s", szArg3);
		}
		set_msg_arg_string(2, szMsg);
	}
}

public plugin_end() 
{
	TrieDestroy(g_tReplaceInfoMsg);
}

public ClCmd_PriceMotd(id,level,cid) 
{
	// price motd
	if (!cmd_access(id,level,cid,1))
	return PLUGIN_CONTINUE
	 
	show_motd(id,"pricelist.txt","Покупка привилегий")
	return PLUGIN_CONTINUE   
}

public ClCmd_ResetScore(id)
{
	// reset score
	cs_set_user_deaths(id, 0)
	set_user_frags(id, 0)
	cs_set_user_deaths(id, 0)
	set_user_frags(id, 0)

	// chat message of reseting score
	client_print(id, print_chat, "* Вы обнулили свой счет! *")
	client_cmd(id,"spk buttons/bell1.wav")
}

public ClCmd_ServerMenu(id) return Show_ServerMenu(id);

Show_ServerMenu(id)
{
	// main server menu
	new szMenu[512]
	new iLen = 0
	iLen = format(szMenu[iLen], 511, "\r[CS:GO] \yМеню Сервера^n^n");

	iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\w Игровое \yменю^n");
	
	if(get_user_flags(id) & FLAG_SKINS)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\w Меню \yскинов^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\d Меню скинов^n^n");
	}
	if(is_user_alive(id))
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\w Сменить \yкоманду^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\d Сменить команду^n^n");
	}
	if(get_user_flags(id) & FLAG_ADMIN)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\w Панель \yадминистратора^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\d Панель администратора^n^n");	
	}
	iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\w Топ-15 \yигроков сервера^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[6]\w Застрял? \rНажми!^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[7]\w Статистика^n^n");
	
	format(szMenu[iLen], 511 - iLen, "\r[0]\w Выход");
	return show_menu(id, keys, szMenu, -1, "Show_ServerMenu");
}

public Handle_ServerMenu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			return Show_GameMenu(id);
		}
		case 1:
		{
			if(get_user_flags(id) & FLAG_SKINS)
			{
				return Show_SkinsMenu(id);
			}
			else
			{
				client_print(id, print_chat, "* Только VIP-игрок имеет доступ к меню! *");
				client_cmd(id, "spk buttons/blip2.wav");
				return PLUGIN_HANDLED;
			}
		}
		case 2:
		{
			if(is_user_alive(id))
			{
				client_cmd(id, "jointeam");
				return PLUGIN_HANDLED;
			}
			else
			{
				client_print(id, print_chat, "* Только живые игроки могут использовать этот пункт! *");
				client_cmd(id, "spk buttons/blip2.wav");
				return PLUGIN_HANDLED;
			}
		}
		case 3:
		{
			if(get_user_flags(id) & FLAG_ADMIN)
			{
				return Show_AdminMenu(id);
			}
			else
			{
				client_print(id, print_chat, "* Только Администратор имеет доступ к меню! *");
				client_cmd(id, "spk buttons/blip2.wav");
				return PLUGIN_HANDLED;
			}
		}
		
		case 4:
		{
			client_cmd(id, "say /top15");
			return PLUGIN_HANDLED;
		}
		
		case 5:
		{
			if(is_user_alive(id))
			{
				return Unstuck_Player(id)
			}
			else
			{
				client_print(id, print_chat, "* Только живые игроки могут использовать этот пункт! *");
				client_cmd(id, "spk buttons/blip2.wav");
				return PLUGIN_HANDLED;
			}
		}
		
		case 6:
		{
			client_cmd(id, "say /statsme");
			return PLUGIN_HANDLED;
		}
		
		case 9:
		{
			return PLUGIN_HANDLED;
		}
	}
	return Show_ServerMenu(id);
}

Show_GameMenu(id)
{
	// player menu
	new szMenu[512]
	new iLen = 0
	iLen = format(szMenu[iLen], 511, "\r[CS:GO] \yИгровое Меню^n^n");
	
	iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\w Обнулить \yсчёт^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\w Сменить \yкарту^n^n");
	
	iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\w Забанить \yигрока^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\w Номинация \yкарты^n^n");
	
	iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\w Реквизиты \yсервера^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[6]\w Цены на \yпривилегии^n^n");
	
	iLen += format(szMenu[iLen], 511 - iLen, "\r[9]\w Назад^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[0]\w Выход^n");
	return show_menu(id, keys, szMenu, -1, "Show_GameMenu");
}

public Handle_GameMenu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			client_cmd(id, "say /rs");
			return PLUGIN_HANDLED;
		}
		case 1:
		{
			client_cmd(id, "say /rtv");
			return PLUGIN_HANDLED;
		}
		case 2:
		{
			client_cmd(id, "say /voteban");
			return PLUGIN_HANDLED;
		}
		case 3:
		{
			client_cmd(id, "say /maps");
			return PLUGIN_HANDLED;
		}
		case 4:
		{
			return Show_PlayerContacts(id)
		}
		case 5:
		{
			client_cmd(id, "say /price");
			return PLUGIN_HANDLED;
		}
		case 8:
		{
			return Show_ServerMenu(id);
		}
		case 9:
		{
			return PLUGIN_HANDLED;
		}
	}
	return Show_GameMenu(id);
}

Show_SkinsMenu(id)
{
	// skins menu
	new szMenu[512]
	new iLen = 0
	iLen = format(szMenu[iLen], 511, "\r[CS:GO] \wМеню Скинов^n^n");
	
	iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\w AK-47^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\w AWP^n")
	iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\w M4A1-s^n^n");
	
	iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\w Deagle^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\w Glock-18^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[6]\w USP-s^n^n");
	
	iLen += format(szMenu[iLen], 511 - iLen, "\r[7]\w Нож^n^n");

	iLen += format(szMenu[iLen], 511 - iLen, "\r[9]\w Назад^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[0]\w Выход^n");
	return show_menu(id, keys, szMenu, -1, "Show_SkinsMenu");
}

public Handle_SkinsMenu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			return Show_AK47_Menu(id);
		}
		case 1:
		{
			return Show_AWP_Menu(id);
		}
		case 2:
		{
			return Show_M4A1s_Menu(id);
		}
		case 3:
		{
			return Show_Deagle_Menu(id);
		}
		case 4:
		{
			return Show_Glock18_Menu(id);
		}
		case 5:
		{
			return Show_USPs_Menu(id);
		}
		case 6:
		{
			return Show_KnifeMenu(id);
		}
		case 8:
		{
			return Show_ServerMenu(id);
		}
		case 9:
		{
			return PLUGIN_HANDLED;
		}
	}
	return Show_SkinsMenu(id);
}

public Show_AK47_Menu(id)
{
	new szMenu[512]
	new iLen = 0
	iLen = format(szMenu[iLen], 511, "\r[CS:GO] \wСкины для \yAK-47^n^n");
	
	if(Ak47Id[id] == 1)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\d AK-47 | Asiimov \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\w AK-47 | Asiimov^n");
	}
	if(Ak47Id[id] == 2)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\d AK-47 | BloodSport\r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\w AK-47 | BloodSport^n");
	}
	if(Ak47Id[id] == 3)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\d AK-47 | Fire Serpent\r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\w AK-47 | Fire Serpent^n");
	}
	if(Ak47Id[id] == 4)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\d AK-47 | Neon Revolution\r[+]^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\w AK-47 | Neon Revolution^n^n");
	}
	if(Ak47Id[id] == 5)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\d Стандарт \r[+]^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\w Стандарт^n^n");
	}
	iLen += format(szMenu[iLen], 511 - iLen, "\r[9]\w Назад^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[0]\w Выход^n");
	return show_menu(id, keys, szMenu, -1, "Show_AK47_Menu");
}

public Handle_AK47_Menu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			if(Ak47Id[id] == 1)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				Ak47Id[id] = 1
				EV_Ak47Replace(id)
				client_print(id, print_chat, "* Вы взяли скин AK-47 | Asiimov *");
				return PLUGIN_HANDLED;
			}
		}
		case 1:
		{
			if(Ak47Id[id] == 2)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				AwpId[id] = 2
				EV_Ak47Replace(id)
				client_print(id, print_chat, "* Вы взяли скин AK-47 | BloodSport *");
				return PLUGIN_HANDLED;
			}
		}
		case 2:
		{
			if(Ak47Id[id] == 3)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				Ak47Id[id] = 3
				EV_Ak47Replace(id)
				client_print(id, print_chat, "* Вы взяли скин AK-47 | Fire Serpent *");
				return PLUGIN_HANDLED;
			}
		}
		case 3:
		{
			if(Ak47Id[id] == 4)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				Ak47Id[id] = 4
				EV_Ak47Replace(id)
				client_print(id, print_chat, "* Вы взяли скин AK-47 | Neon Revolution *");
				return PLUGIN_HANDLED;
			}
		}
		case 4:
		{
			if(Ak47Id[id] == 5)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				Ak47Id[id] = 5
				EV_Ak47Replace(id)
				client_print(id, print_chat, "* Вы взяли скин Стандартный AK-47 *");
				return PLUGIN_HANDLED;
			}
		}
		case 8:
		{
			return Show_SkinsMenu(id)
		}
		case 9:
		{
			return PLUGIN_HANDLED;
		}
	}
	return Show_AK47_Menu(id);
}

public Show_AWP_Menu(id)
{
	new szMenu[512]
	new iLen = 0
	iLen = format(szMenu[iLen], 511, "\r[CS:GO] \wСкины для \yAWP^n^n");
	
	if(AwpId[id] == 1)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\d AWP | Fever Dream \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\w AWP | Fever Dream^n");
	}
	if(AwpId[id] == 2)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\d AWP | Dragon Lore \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\w AWP | Dragon Lore^n");
	}
	if(AwpId[id] == 3)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\d AWP | Medusa \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\w AWP | Medusa^n");
	}
	if(AwpId[id] == 4)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\d AWP | Neo-Noir \r[+]^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\w AWP | Neo-Noir^n^n");
	}
	if(AwpId[id] == 5)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\d Стандарт \r[+]^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\w Стандарт^n^n");
	}
	iLen += format(szMenu[iLen], 511 - iLen, "\r[9]\w Назад^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[0]\w Выход^n");
	return show_menu(id, keys, szMenu, -1, "Show_AWP_Menu");
}

public Handle_AWP_Menu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			if(AwpId[id] == 1)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				AwpId[id] = 1
				EV_M4A1sReplace(id)
				client_print(id, print_chat, "* Вы взяли скин AWP | Fever Dream *");
				return PLUGIN_HANDLED;
			}
		}
		case 1:
		{
			if(AwpId[id] == 2)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				AwpId[id] = 2
				EV_AwpReplace(id)
				client_print(id, print_chat, "* Вы взяли скин AWP | Dragon Lore *");
				return PLUGIN_HANDLED;
			}
		}
		case 2:
		{
			if(AwpId[id] == 3)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				AwpId[id] = 3
				EV_AwpReplace(id)
				client_print(id, print_chat, "* Вы взяли скин AWP | Medusa *");
				return PLUGIN_HANDLED;
			}
		}
		case 3:
		{
			if(AwpId[id] == 4)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				AwpId[id] = 4
				EV_AwpReplace(id)
				client_print(id, print_chat, "* Вы взяли скин AWP | Neo-Noir *");
				return PLUGIN_HANDLED;
			}
		}
		case 4:
		{
			if(AwpId[id] == 5)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				AwpId[id] = 5
				EV_AwpReplace(id)
				client_print(id, print_chat, "* Вы взяли скин Стандартный AWP *");
				return PLUGIN_HANDLED;
			}
		}
		case 8:
		{
			return Show_SkinsMenu(id)
		}
		case 9:
		{
			return PLUGIN_HANDLED;
		}
	}
	return Show_AWP_Menu(id);
}

public Show_M4A1s_Menu(id)
{
	new szMenu[512]
	new iLen = 0
	iLen = format(szMenu[iLen], 511, "\r[CS:GO] \wСкины для \yM4A1-s^n^n");
	
	if(M4A1sId[id] == 1)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\d M4A1-s | Hyper Beast \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\w M4A1-s | Hyper Beast^n");
	}
	if(M4A1sId[id] == 2)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\d M4A1-s | Decimator \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\w M4A1-s | Decimator^n");
	}
	if(M4A1sId[id] == 3)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\d M4A1-s | Chantico Fire \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\w M4A1-s | Chantico Fire^n");
	}
	if(M4A1sId[id] == 4)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\d M4A1-s | NightMare \r[+]^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\w M4A1-s | NightMare^n^n");
	}
	if(M4A1sId[id] == 5)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\d Стандарт \r[+]^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\w Стандарт^n^n");
	}
	iLen += format(szMenu[iLen], 511 - iLen, "\r[9]\w Назад^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[0]\w Выход^n");
	return show_menu(id, keys, szMenu, -1, "Show_M4A1s_Menu");
}

public Handle_M4A1s_Menu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			if(M4A1sId[id] == 1)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				M4A1sId[id] = 1
				EV_M4A1sReplace(id)
				client_print(id, print_chat, "* Вы взяли скин M4A1-s | Hyper Beast *");
				return PLUGIN_HANDLED;
			}
		}
		case 1:
		{
			if(M4A1sId[id] == 2)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				M4A1sId[id] = 2
				EV_M4A1sReplace(id)
				client_print(id, print_chat, "* Вы взяли скин M4A1-s | Decimator *");
				return PLUGIN_HANDLED;
			}
		}
		case 2:
		{
			if(M4A1sId[id] == 3)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				M4A1sId[id] = 3
				EV_M4A1sReplace(id)
				client_print(id, print_chat, "* Вы взяли скин M4A1-s | Chantico Fire *");
				return PLUGIN_HANDLED;
			}
		}
		case 3:
		{
			if(M4A1sId[id] == 4)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				M4A1sId[id] = 4
				EV_M4A1sReplace(id)
				client_print(id, print_chat, "* Вы взяли скин M4A1-s | Nightmare *");
				return PLUGIN_HANDLED;
			}
		}
		case 4:
		{
			if(M4A1sId[id] == 5)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				M4A1sId[id] = 5
				EV_M4A1sReplace(id)
				client_print(id, print_chat, "* Вы взяли скин Стандартный M4A1-s *");
				return PLUGIN_HANDLED;
			}
		}
		case 8:
		{
			return Show_SkinsMenu(id)
		}
		case 9:
		{
			return PLUGIN_HANDLED;
		}
	}
	return Show_M4A1s_Menu(id);
}

public Show_Deagle_Menu(id)
{
	new szMenu[512]
	new iLen = 0
	iLen = format(szMenu[iLen], 511, "\r[CS:GO] \wСкины для \yDeagle^n^n");
	
	if(DeagleId[id] == 1)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\d Deagle | Blaze \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\w Deagle | Blaze^n");
	}
	if(DeagleId[id] == 2)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\d Deagle | Code Red \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\w Deagle | Code Red^n");
	}
	if(DeagleId[id] == 3)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\d Deagle | Crimson Web \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\w Deagle | Crimson Web^n");
	}
	if(DeagleId[id] == 4)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\d Deagle | Kumicho Dragon \r[+]^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\w Deagle | Kumicho Dragon^n^n");
	}
	if(DeagleId[id] == 5)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\d Стандарт \r[+]^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\w Стандарт^n^n");
	}
	iLen += format(szMenu[iLen], 511 - iLen, "\r[9]\w Назад^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[0]\w Выход^n");
	return show_menu(id, keys, szMenu, -1, "Show_Deagle_Menu");
}

public Handle_Deagle_Menu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			if(DeagleId[id] == 1)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				DeagleId[id] = 1
				EV_DeagleReplace(id)
				client_print(id, print_chat, "* Вы взяли скин Deagle | Blaze *");
				return PLUGIN_HANDLED;
			}
		}
		case 1:
		{
			if(DeagleId[id] == 2)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				DeagleId[id] = 2
				EV_DeagleReplace(id)
				client_print(id, print_chat, "* Вы взяли скин Deagle | Code Red *");
				return PLUGIN_HANDLED;
			}
		}
		case 2:
		{
			if(DeagleId[id] == 3)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				DeagleId[id] = 3
				EV_DeagleReplace(id)
				client_print(id, print_chat, "* Вы взяли скин Deagle | Crimson Web *");
				return PLUGIN_HANDLED;
			}
		}
		case 3:
		{
			if(DeagleId[id] == 4)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				DeagleId[id] = 4
				EV_DeagleReplace(id)
				client_print(id, print_chat, "* Вы взяли скин Deagle | Kumicho Dragon *");
				return PLUGIN_HANDLED;
			}
		}
		case 4:
		{
			if(DeagleId[id] == 5)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				DeagleId[id] = 5
				EV_DeagleReplace(id)
				client_print(id, print_chat, "* Вы взяли скин Стандартный Deagle *");
				return PLUGIN_HANDLED;
			}
		}
		case 8:
		{
			return Show_SkinsMenu(id)
		}
		case 9:
		{
			return PLUGIN_HANDLED;
		}
	}
	return Show_Deagle_Menu(id);
}

public Show_Glock18_Menu(id)
{
	new szMenu[512]
	new iLen = 0
	iLen = format(szMenu[iLen], 511, "\r[CS:GO] \wСкины для \yGlock-18^n^n");
	
	if(Glock18Id[id] == 1)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\d Glock-18 | Fade \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\w Glock-18 | Fade^n");
	}
	if(Glock18Id[id] == 2)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\d Glock-18 | Moonrise \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\w Glock-18 | Moonrise^n");
	}
	if(Glock18Id[id] == 3)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\d Glock-18 | Wasteland Rebel \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\w Glock-18 | Wasteland Rebel^n");
	}
	if(Glock18Id[id] == 4)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\d Glock-18 | Water Elemental \r[+]^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\w Glock-18 | Water Elemental^n^n");
	}
	if(Glock18Id[id] == 5)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\d Стандарт \r[+]^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\w Стандарт^n^n");
	}
	iLen += format(szMenu[iLen], 511 - iLen, "\r[9]\w Назад^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[0]\w Выход^n");
	return show_menu(id, keys, szMenu, -1, "Show_Glock18_Menu");
}

public Handle_Glock18_Menu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			if(Glock18Id[id] == 1)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				Glock18Id[id] = 1
				EV_Glock18Replace(id)
				client_print(id, print_chat, "* Вы взяли скин Glock-18 | Fade *");
				return PLUGIN_HANDLED;
			}
		}
		case 1:
		{
			if(Glock18Id[id] == 2)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				Glock18Id[id] = 2
				EV_Glock18Replace(id)
				client_print(id, print_chat, "* Вы взяли скин Glock-18 | Moonrise *");
				return PLUGIN_HANDLED;
			}
		}
		case 2:
		{
			if(Glock18Id[id] == 3)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				Glock18Id[id] = 3
				EV_Glock18Replace(id)
				client_print(id, print_chat, "* Вы взяли скин Glock-18 | Wasteland Rebel *");
				return PLUGIN_HANDLED;
			}
		}
		case 3:
		{
			if(Glock18Id[id] == 4)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				Glock18Id[id] = 4
				EV_Glock18Replace(id)
				client_print(id, print_chat, "* Вы взяли скин Glock-18 | Water Elemental *");
				return PLUGIN_HANDLED;
			}
		}
		case 4:
		{
			if(Glock18Id[id] == 5)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				Glock18Id[id] = 5
				EV_Glock18Replace(id)
				client_print(id, print_chat, "* Вы взяли скин Стандартный Glock-18 *");
				return PLUGIN_HANDLED;
			}
		}
		case 8:
		{
			return Show_SkinsMenu(id)
		}
		case 9:
		{
			return PLUGIN_HANDLED;
		}
	}
	return Show_Glock18_Menu(id);
}


public Show_USPs_Menu(id)
{
	new szMenu[512]
	new iLen = 0
	iLen = format(szMenu[iLen], 511, "\r[CS:GO] \wСкины для \yUSP-s^n^n");
	
	if(USPsId[id] == 1)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\d USP-s | Cortex \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\w USP-s | Cortex^n");
	}
	if(USPsId[id] == 2)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\d USP-s | Kill Confirmed \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\w USP-s | Kill Confirmed^n");
	}
	if(USPsId[id] == 3)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\d USP-s | Neo-Noir \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\w USP-s | Neo-Noir^n");
	}
	if(USPsId[id] == 4)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\d USP-s | Orion \r[+]^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\w USP-s | Orion^n^n");
	}
	if(USPsId[id] == 5)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\d Стандарт \r[+]^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\w Стандарт^n^n");
	}
	iLen += format(szMenu[iLen], 511 - iLen, "\r[9]\w Назад^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[0]\w Выход^n");
	return show_menu(id, keys, szMenu, -1, "Show_USPs_Menu");
}

public Handle_USPs_Menu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			if(USPsId[id] == 1)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				USPsId[id] = 1
				EV_USPsReplace(id)
				client_print(id, print_chat, "* Вы взяли USP-s | Cortex *");
				return PLUGIN_HANDLED;
			}
		}
		case 1:
		{
			if(USPsId[id] == 2)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				USPsId[id] = 2
				EV_USPsReplace(id)
				client_print(id, print_chat, "* Вы взяли скин USP-s | Kill Confirmed *");
				return PLUGIN_HANDLED;
			}
		}
		case 2:
		{
			if(USPsId[id] == 3)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				USPsId[id] = 3
				EV_USPsReplace(id)
				client_print(id, print_chat, "* Вы взяли скин USP-s | Neo-Noir *");
				return PLUGIN_HANDLED;
			}
		}
		case 3:
		{
			if(USPsId[id] == 4)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				USPsId[id] = 4
				EV_USPsReplace(id)
				client_print(id, print_chat, "* Вы взяли скин USP-s | Orion *");
				return PLUGIN_HANDLED;
			}
		}
		case 4:
		{
			if(USPsId[id] == 5)
			{
				client_print(id, print_chat, "* У вас уже выбран этот скин! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				USPsId[id] = 5
				EV_USPsReplace(id)
				client_print(id, print_chat, "* Вы взяли скин Стандартный USP-s *");
				return PLUGIN_HANDLED;
			}
		}
		case 8:
		{
			return Show_SkinsMenu(id)
		}
		case 9:
		{
			return PLUGIN_HANDLED;
		}
	}
	return Show_USPs_Menu(id);
}

public Show_AdminMenu(id)
{
	// main admin menu
	new szMenu[512]
	new iLen = 0
	iLen = format(szMenu[iLen], 511, "\r[CS:GO] \wМеню Администратора^n^n");
	
	iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\w Заглушить \yигрока^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\w Кикнуть \yигрока^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\w Забанить \yигрока^n^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\w Сменить \yкарту^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\w Голосование за смену \yкарты^n");
	if(get_user_flags(id) & FLAG_SLAY)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[6]\w Стукнуть/\wУбить \yигрока^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[6]\d Стукнуть/Убить \yигрока^n");
	}
	if(get_user_flags(id) & FLAG_TEAM)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[7]\w Команда \yигрока^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[7]\d Команда \yигрока^n^n");
	}
	iLen += format(szMenu[iLen], 511 - iLen, "\r[9]\w Назад^n");
	iLen += format(szMenu[iLen], 511 - iLen, "\r[0]\w Выход^n");
	return show_menu(id, keys, szMenu, -1, "Show_AdminMenu");
}

public Handle_AdminMenu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			client_cmd(id, "amx_gagmenu");
			return PLUGIN_HANDLED;
		}
		case 1:
		{
			client_cmd(id, "amx_kickmenu");
			return PLUGIN_HANDLED;
		}
		case 2:
		{
			client_cmd(id, "amx_banmenu");
			return PLUGIN_HANDLED;
		}
		case 3:
		{
			client_cmd(id, "amx_mapmenu");
			return PLUGIN_HANDLED;
		}
		case 4:
		{
			client_cmd(id, "amx_votemapmenu");
			return PLUGIN_HANDLED;
		}
		case 5:
		{
			if(get_user_flags(id) & FLAG_SLAY)
			{
				client_cmd(id, "amx_slapmenu");
				return PLUGIN_HANDLED;
			}
			else
			{
				client_print(id, print_chat, "* Только Админ может пользоваться этой командой! *");
				client_cmd(id, "spk buttons/blip2.wav");
				return PLUGIN_HANDLED;
			}
		}
		case 6:
		{
			if(get_user_flags(id) & FLAG_TEAM)
			{
				client_cmd(id, "amx_teammenu");
				return PLUGIN_HANDLED;
			}
			else
			{
				client_print(id, print_chat, "* Только Админ может пользоваться этой командой! *");
				client_cmd(id, "spk buttons/blip2.wav");
				return PLUGIN_HANDLED;
			}
		}
		case 8:
		{
			return Show_ServerMenu(id);
		}
		case 9:
		{
			return PLUGIN_HANDLED;
		}
	}
	return Show_AdminMenu(id);
}

Show_KnifeMenu(id)
{
	// knife menu
	new szMenu[512]
	new iLen = 0
	iLen = format(szMenu[iLen], 511, "\r[CS:GO] \wНожевой Набор^n^n")
	
	if(KnifeId[id] == 1)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\d Bayonet | Autotronic \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[1]\w Bayonet | Autotronic^n");
	}
	if(KnifeId[id] == 2)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\d Falchion | Slaughter \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[2]\w Falchion | Slaughter^n");
	}
	if(KnifeId[id] == 3)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\d Gut | Case Hardened \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[3]\w Gut | Case Hardened^n");
	}
	if(KnifeId[id] == 4)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\d Karambit | Waves \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[4]\w Karambit | Waves^n");
	}
	if(KnifeId[id] == 5)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\d M9 Bayonet | Sapphire \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[5]\w M9 Bayonet | Sapphire^n");
	}
	if(KnifeId[id] == 6)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[6]\d Butterfly Knife | Fade \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[6]\w Butterfly Knife | Fade^n");
	}
	if(KnifeId[id] == 7)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[7]\d Stiletto | Crimson Web \r[+]^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[7]\w Stiletto | Crimson Web^n");
	}
	if(KnifeId[id] == 8)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[8]\d Classic Knife | Fade \r[+]^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[8]\w Classic Knife | Fade^n^n");
	}
	if(KnifeId[id] == 9)
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[9]\d Стандарт \r[+]^n^n");
	}
	else
	{
		iLen += format(szMenu[iLen], 511 - iLen, "\r[9]\w Стандарт^n^n");
	}
	iLen += format(szMenu[iLen], 511 - iLen, "\r[0]\w Выход^n");
	return show_menu(id, keys, szMenu, -1, "Show_KnifeMenu");
}

public Handle_KnifeMenu(id, iKey)
{
	switch(iKey)
	{
		case 0:
		{
			if(KnifeId[id] == 1)
			{
				client_print(id, print_chat, "* У вас уже выбран этот Нож! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				KnifeId[id] = 1
				EV_KnifeReplace(id)
				client_print(id, print_chat, "* Вы взяли Нож Bayonet Autotronic *");
				return PLUGIN_HANDLED;
			}
		}
		case 1:
		{
			if(KnifeId[id] == 2)
			{
				client_print(id, print_chat, "* У вас уже выбран этот Нож! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				KnifeId[id] = 2
				EV_KnifeReplace(id)
				client_print(id, print_chat, "* Вы взяли Нож Falchion Slaughter *");
				return PLUGIN_HANDLED;
			}
		}
		case 2:
		{
			if(KnifeId[id] == 3)
			{
				client_print(id, print_chat, "* У вас уже выбран этот Нож! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				KnifeId[id] = 3
				EV_KnifeReplace(id)
				client_print(id, print_chat, "* Вы взяли Нож Gut Case Hardened *");
				return PLUGIN_HANDLED;
			}
		}
		case 3:
		{
			if(KnifeId[id] == 4)
			{
				client_print(id, print_chat, "* У вас уже выбран этот Нож! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				KnifeId[id] = 4
				EV_KnifeReplace(id)
				client_print(id, print_chat, "* Вы взяли Нож Karambit Waves *");
				return PLUGIN_HANDLED;
			}
		}
		case 4:
		{
			if(KnifeId[id] == 5)
			{
				client_print(id, print_chat, "* У вас уже выбран этот Нож! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				KnifeId[id] = 5
				EV_KnifeReplace(id)
				client_print(id, print_chat, "* Вы взяли Нож M9 Bayonet Sapphire *");
				return PLUGIN_HANDLED;
			}
		}
		case 5:
		{
			if(KnifeId[id] == 6)
			{
				client_print(id, print_chat, "* У вас уже выбран этот Нож! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				KnifeId[id] = 6
				EV_KnifeReplace(id)
				client_print(id, print_chat, "* Вы взяли Нож Butterfly Fade *");
				return PLUGIN_HANDLED;
			}
		}
		case 6:
		{
			if(KnifeId[id] == 7)
			{
				client_print(id, print_chat, "* У вас уже выбран этот Нож! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				KnifeId[id] = 7
				EV_KnifeReplace(id)
				client_print(id, print_chat, "* Вы взяли Нож Stiletto Crimson Web *");
				return PLUGIN_HANDLED;
			}
		}
		case 7:
		{
			if(KnifeId[id] == 8)
			{
				client_print(id, print_chat, "* У вас уже выбран этот Нож! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				KnifeId[id] = 8
				EV_KnifeReplace(id)
				client_print(id, print_chat, "* Вы взяли Нож Classic Knife Fade *");
				return PLUGIN_HANDLED;
			}
		}
		case 8:
		{
			if(KnifeId[id] == 9)
			{
				client_print(id, print_chat, "* У вас уже выбран этот Нож! *");
				return PLUGIN_HANDLED;
			}
			else
			{
				KnifeId[id] = 9
				EV_KnifeReplace(id)
				client_print(id, print_chat, "* Вы взяли Стандартный Нож *");
				return PLUGIN_HANDLED;
			}
		}
		case 9:
		{
			return PLUGIN_HANDLED;
		}
	}
	return Show_KnifeMenu(id);
}


Show_PlayerContacts(id)
{ 
	new szMenu[512], iLen = formatex(szMenu, charsmax(szMenu), "\r[CS:GO] \wРеквизиты сервера^n^n");
	
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \wВладелец • \r%s^n", CREATE_SERVER);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \wСайт • \r%s^n", URL_SITE);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \wГруппа VK • \r%s^n", URL_GROUP_VK);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \wГл. Админ • \r%s^n", MAIN_ADMIN);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \wВладелец VK • \r%s^n", URL_VK_CREATE);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\d[#] \wГл. Админ VK • \r%s^n^n", URL_VK_MAIN);
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[9] \wВывести в консоль • \r[\dНажми!\r]^n^n");
	formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r[0] \wВыход^n");
	
	return show_menu(id, (1<<8|1<<9), szMenu, -1, "Show_PlayerContacts");
}

public Handle_PlayerContactsCmd(id, iKey) 
{
	if(iKey == 9) return PLUGIN_HANDLED;
	if(iKey == 8)
	{
		new szIp[33]; get_user_ip(0, szIp, charsmax(szIp));
		new szNameServer[48]; get_user_name(0, szNameServer, charsmax(szNameServer));
		
		client_print(id, print_center, "* Информация была выведена в консоль *")
		client_print(id, print_chat, "* Информация была выведена в консоль вашей CS *")
		
		console_print(id, "==================================");
		console_print(id, "* Создатель Вконтакте: %s", URL_VK_CREATE);
		console_print(id, "* Гл. Админ ВК:  %s", URL_VK_MAIN);
		console_print(id, "* Ник Владельца: %s", CREATE_SERVER);
		console_print(id, "* Ник Гл. Админа: %s", MAIN_ADMIN);
		console_print(id, "* Группа VK: %s", URL_GROUP_VK);
		console_print(id, "* Сайт: %s", URL_SITE);
		console_print(id, "* IP Сервера: %s", szIp);
		console_print(id, "* Сервер: %s", szNameServer);
		console_print(id, "==================================");
	}
	return PLUGIN_HANDLED;
}

Unstuck_Player(const id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED;

	new Float:f_MinFrequency = get_pcvar_float(CheckTime);
	new Float:f_ElapsedCmdTime = get_gametime() - g_fLastCmdTime[id];

	if(f_ElapsedCmdTime < f_MinFrequency) 
	{
		set_hudmessage(255, 255, 255, -1.0, 0.65, 0, 6.0, 1.5, 0.1, 0.7);
		show_hudmessage(id, "Подождите %.f секунд, чтобы воспользоваться еще раз.", f_MinFrequency - f_ElapsedCmdTime);
		return PLUGIN_HANDLED;
	}

	g_fLastCmdTime[id] = get_gametime();

	if(UTIL_UnstickPlayer(id, 32, 128) == 1)
	{
		set_hudmessage(255, 255, 255, -1.0, 0.65, 0, 6.0, 1.5, 0.1, 0.7);
		show_hudmessage(id, "Вы извлечены!");
	}
	return PLUGIN_CONTINUE;
}

public EV_KnifeReplace(id)
{
	if(get_user_weapon(id) != CSW_KNIFE)
		return
	
	if(KnifeId[id] == 1)
	{
		set_pev(id, pev_viewmodel2, g_KnifeModels[0])
		set_pev(id, pev_weaponmodel2, g_KnifeModels[1])
	}
	
	else if(KnifeId[id] == 2)
	{
		set_pev(id, pev_viewmodel2, g_KnifeModels[2])
		set_pev(id, pev_weaponmodel2, g_KnifeModels[3])
	}
	
	else if(KnifeId[id] == 3)
	{
		set_pev(id, pev_viewmodel2, g_KnifeModels[4])
		set_pev(id, pev_weaponmodel2, g_KnifeModels[5])
	}
	
	else if(KnifeId[id] == 4)
	{
		set_pev(id, pev_viewmodel2, g_KnifeModels[6])
		set_pev(id, pev_weaponmodel2, g_KnifeModels[7])
	}
	
	else if(KnifeId[id] == 5)
	{
		set_pev(id, pev_viewmodel2, g_KnifeModels[8])
		set_pev(id, pev_weaponmodel2, g_KnifeModels[9])
	}
	
	else if(KnifeId[id] == 6)
	{
		set_pev(id, pev_viewmodel2, g_KnifeModels[10])
		set_pev(id, pev_weaponmodel2, g_KnifeModels[11])
	}
	
	else if(KnifeId[id] == 7)
	{
		set_pev(id, pev_viewmodel2, g_KnifeModels[12])
		set_pev(id, pev_weaponmodel2, g_KnifeModels[13])
	}
	
	else if(KnifeId[id] == 8)
	{
		set_pev(id, pev_viewmodel2, g_KnifeModels[14])
		set_pev(id, pev_weaponmodel2, g_KnifeModels[15])
	}
	
	else if(KnifeId[id] == 9)
	{
		if(get_user_team(id) == 1)
		{
			set_pev(id, pev_viewmodel2, g_KnifeModels[16])
			set_pev(id, pev_weaponmodel2, g_KnifeModels[17])
		}
		else if(get_user_team(id) == 2)
		{
			set_pev(id, pev_viewmodel2, g_KnifeModels[18])
			set_pev(id, pev_weaponmodel2, g_KnifeModels[19])
		}
	}
}

public EV_Ak47Replace(id)
{
	if(get_user_weapon(id) != CSW_AK47)
		return
	
	if(Ak47Id[id] == 1)
	{
		set_pev(id, pev_viewmodel2, g_Ak47Models[0])
		set_pev(id, pev_weaponmodel2, g_Ak47Models[1])
	}
	
	else if(Ak47Id[id] == 2)
	{
		set_pev(id, pev_viewmodel2, g_Ak47Models[2])
		set_pev(id, pev_weaponmodel2, g_Ak47Models[3])
	}
	
	else if(Ak47Id[id] == 3)
	{
		set_pev(id, pev_viewmodel2, g_Ak47Models[4])
		set_pev(id, pev_weaponmodel2, g_Ak47Models[5])
	}
	
	else if(Ak47Id[id] == 4)
	{
		set_pev(id, pev_viewmodel2, g_Ak47Models[6])
		set_pev(id, pev_weaponmodel2, g_Ak47Models[7])
	}
	
	else if(Ak47Id[id] == 5)
	{
		set_pev(id, pev_viewmodel2, g_Ak47Models[8])
		set_pev(id, pev_weaponmodel2, g_Ak47Models[9])
	}
}

public EV_AwpReplace(id)
{
	if(get_user_weapon(id) != CSW_AWP)
		return
	
	if(AwpId[id] == 1)
	{
		set_pev(id, pev_viewmodel2, g_AwpModels[0])
		set_pev(id, pev_weaponmodel2, g_AwpModels[1])
	}
	
	else if(AwpId[id] == 2)
	{
		set_pev(id, pev_viewmodel2, g_AwpModels[2])
		set_pev(id, pev_weaponmodel2, g_AwpModels[3])
	}
	
	else if(AwpId[id] == 3)
	{
		set_pev(id, pev_viewmodel2, g_AwpModels[4])
		set_pev(id, pev_weaponmodel2, g_AwpModels[5])
	}
	
	else if(AwpId[id] == 4)
	{
		set_pev(id, pev_viewmodel2, g_AwpModels[6])
		set_pev(id, pev_weaponmodel2, g_AwpModels[7])
	}
	
	else if(AwpId[id] == 5)
	{
		set_pev(id, pev_viewmodel2, g_AwpModels[8])
		set_pev(id, pev_weaponmodel2, g_AwpModels[9])
	}
}

public EV_M4A1sReplace(id)
{
	if(get_user_weapon(id) != CSW_M4A1)
		return
	
	if(M4A1sId[id] == 1)
	{
		set_pev(id, pev_viewmodel2, g_M4A1sModels[0])
		set_pev(id, pev_weaponmodel2, g_M4A1sModels[1])
	}
	
	else if(M4A1sId[id] == 2)
	{
		set_pev(id, pev_viewmodel2, g_M4A1sModels[2])
		set_pev(id, pev_weaponmodel2, g_M4A1sModels[3])
	}
	
	else if(M4A1sId[id] == 3)
	{
		set_pev(id, pev_viewmodel2, g_M4A1sModels[4])
		set_pev(id, pev_weaponmodel2, g_M4A1sModels[5])
	}
	
	else if(M4A1sId[id] == 4)
	{
		set_pev(id, pev_viewmodel2, g_M4A1sModels[6])
		set_pev(id, pev_weaponmodel2, g_M4A1sModels[7])
	}
	
	else if(M4A1sId[id] == 5)
	{
		set_pev(id, pev_viewmodel2, g_M4A1sModels[8])
		set_pev(id, pev_weaponmodel2, g_M4A1sModels[9])
	}
}

public EV_DeagleReplace(id)
{
	if(get_user_weapon(id) != CSW_DEAGLE)
		return
	
	if(DeagleId[id] == 1)
	{
		set_pev(id, pev_viewmodel2, g_DeagleModels[0])
		set_pev(id, pev_weaponmodel2, g_DeagleModels[1])
	}
	
	else if(DeagleId[id] == 2)
	{
		set_pev(id, pev_viewmodel2, g_DeagleModels[2])
		set_pev(id, pev_weaponmodel2, g_DeagleModels[3])
	}
	
	else if(DeagleId[id] == 3)
	{
		set_pev(id, pev_viewmodel2, g_DeagleModels[4])
		set_pev(id, pev_weaponmodel2, g_DeagleModels[5])
	}
	
	else if(DeagleId[id] == 4)
	{
		set_pev(id, pev_viewmodel2, g_DeagleModels[6])
		set_pev(id, pev_weaponmodel2, g_DeagleModels[7])
	}
	
	else if(DeagleId[id] == 5)
	{
		set_pev(id, pev_viewmodel2, g_DeagleModels[8])
		set_pev(id, pev_weaponmodel2, g_DeagleModels[9])
	}
}

public EV_Glock18Replace(id)
{
	if(get_user_weapon(id) != CSW_GLOCK18)
		return
	
	if(Glock18Id[id] == 1)
	{
		set_pev(id, pev_viewmodel2, g_Glock18Models[0])
		set_pev(id, pev_weaponmodel2, g_Glock18Models[1])
	}
	
	else if(Glock18Id[id] == 2)
	{
		set_pev(id, pev_viewmodel2, g_Glock18Models[2])
		set_pev(id, pev_weaponmodel2, g_Glock18Models[3])
	}
	
	else if(Glock18Id[id] == 3)
	{
		set_pev(id, pev_viewmodel2, g_Glock18Models[4])
		set_pev(id, pev_weaponmodel2, g_Glock18Models[5])
	}
	
	else if(Glock18Id[id] == 4)
	{
		set_pev(id, pev_viewmodel2, g_Glock18Models[6])
		set_pev(id, pev_weaponmodel2, g_Glock18Models[7])
	}
	
	else if(Glock18Id[id] == 5)
	{
		set_pev(id, pev_viewmodel2, g_Glock18Models[8])
		set_pev(id, pev_weaponmodel2, g_Glock18Models[9])
	}
}

public EV_USPsReplace(id)
{
	if(get_user_weapon(id) != CSW_USP)
		return
	
	if(USPsId[id] == 1)
	{
		set_pev(id, pev_viewmodel2, g_USPsModels[0])
		set_pev(id, pev_weaponmodel2, g_USPsModels[1])
	}
	
	else if(USPsId[id] == 2)
	{
		set_pev(id, pev_viewmodel2, g_USPsModels[2])
		set_pev(id, pev_weaponmodel2, g_USPsModels[3])
	}
	
	else if(USPsId[id] == 3)
	{
		set_pev(id, pev_viewmodel2, g_USPsModels[4])
		set_pev(id, pev_weaponmodel2, g_USPsModels[5])
	}
	
	else if(USPsId[id] == 4)
	{
		set_pev(id, pev_viewmodel2, g_USPsModels[6])
		set_pev(id, pev_weaponmodel2, g_USPsModels[7])
	}
	
	else if(USPsId[id] == 5)
	{
		set_pev(id, pev_viewmodel2, g_USPsModels[8])
		set_pev(id, pev_weaponmodel2, g_USPsModels[9])
	}
}

public Fw_Weapon_PrimaryAttack(weapon)
{
	static id;
	id = get_pdata_cbase(weapon, m_pPlayer, XoWeapon);
	
	if(!is_user_alive(id))
		return
	
	new wpn_id = get_user_weapon(id);
	static model[32];
	pev(id, pev_viewmodel2, model, 31);
		
	switch(wpn_id)
	{
		case CSW_DEAGLE:
			g_deagle_overide[id] = 1;
		case CSW_AWP, CSW_SCOUT, CSW_M3:
			set_pdata_float(weapon, m_flTimeWeaponIdle, 1.5, XoWeapon);
		case CSW_KNIFE:
			set_pdata_float(weapon, m_flTimeWeaponIdle, 2.0, XoWeapon);
		default:
			set_pdata_float(weapon, m_flTimeWeaponIdle, 0.5, XoWeapon);
	}
}

public Fw_Weapon_SecondaryAttack(weapon)
{
	static id;
	id = get_pdata_cbase(weapon, m_pPlayer, XoWeapon);
	new wpn_id = get_user_weapon(id);
	
	if(wpns_scoped & (1 << wpn_id) && cs_get_user_zoom(id) <= 1)
	{
		set_pev(id, pev_weaponanim, 0);
	
		message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id);
		write_byte(0);
		write_byte(pev(id, pev_body));
		message_end();
	}
}

public Fw_Deagle_Disable(weapon)
{
	static id;
	id = get_pdata_cbase(weapon, m_pPlayer, XoWeapon);
	remove_task(id)
}

#if defined GAME
public FM_GetGameDescription_Post() 
{
	forward_return(FMV_STRING, GAME_NAME); 
	return FMRES_SUPERCEDE; 
} 
#endif	 

public Deagle_Overide(id)
	g_deagle_overide[id] = 1;

public Inspect_Weapon(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return PLUGIN_HANDLED
		
	if(cs_get_user_shield(id))
		return PLUGIN_HANDLED
		
	if(cs_get_user_zoom(id) > 1)
		return PLUGIN_HANDLED
	
	new wpn_id = get_user_weapon(id);
	
	if(wpns_without_inspect & (1 << wpn_id))
		return PLUGIN_HANDLED

	static weapon; weapon = get_pdata_cbase(id, m_pActiveItem);
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, m_flNextAttack, XoPlayer);
	static Float:flNextPrimaryAttack; flNextPrimaryAttack = get_pdata_float(weapon, m_flNextPrimaryAttack, XoWeapon);

	if(flNextAttack <= 0 && flNextPrimaryAttack <= 0)
	{	
		static model[32]; pev(id, pev_viewmodel2, model, 31);

		new anim = inspect_anim[wpn_id];
		new current_anim = pev(get_pdata_cbase(weapon, m_pPlayer, XoWeapon), pev_weaponanim);

		switch (wpn_id)
		{
			case CSW_USP: if(cs_get_weapon_silen(weapon)) anim = 17;
			case CSW_M4A1:if(cs_get_weapon_silen(weapon)) anim = 14;
			case CSW_KNIFE: anim = 8;
			case CSW_DEAGLE:
			{
				if(wpn_id == CSW_DEAGLE && g_deagle_overide[id] == 1)
				{
					anim = random_num(6, 7)

					new Float:f_temp;
					if(anim == 10) f_temp = 8.53;
					else f_temp = idle_calltime[CSW_DEAGLE]
						
					play_inspect(id, anim);
					remove_task(id);
					g_deagle_overide[id] = 0;
					set_task(f_temp, "Deagle_Overide", id);
					return PLUGIN_CONTINUE
				}
			}
		}
			
		if(wpn_id == CSW_KNIFE && (current_anim == 8))
			return PLUGIN_HANDLED
			
		if(!get_pdata_int(weapon, m_fInSpecialReload, 4) && current_anim != anim)
		{
			play_inspect(id, anim);
			set_pdata_float(weapon, m_flTimeWeaponIdle, idle_calltime[wpn_id], XoWeapon);
		}
	}
	return PLUGIN_CONTINUE;
}

play_inspect(id, anim)
{
	set_pev(id, pev_weaponanim, anim);
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id);
	write_byte(anim);
	write_byte(pev(id, pev_body));
	message_end();	
}

UTIL_UnstickPlayer(const id, const i_StartDistance, const i_MaxAttempts)
{
	if(!is_user_alive(id))	return -1

	static Float:vf_OriginalOrigin[Coordinate], Float:vf_NewOrigin[Coordinate];
	static i_Attempts, i_Distance;

	pev(id, pev_origin, vf_OriginalOrigin);
	i_Distance = i_StartDistance;
	while(i_Distance < 1000)
	{
		i_Attempts = i_MaxAttempts;
		while(i_Attempts--)
		{
			vf_NewOrigin[X] = random_float(vf_OriginalOrigin[X] - i_Distance, vf_OriginalOrigin[X] + i_Distance);
			vf_NewOrigin[Y] = random_float(vf_OriginalOrigin[Y] - i_Distance, vf_OriginalOrigin[Y] + i_Distance);
			vf_NewOrigin[Z] = random_float(vf_OriginalOrigin[Z] - i_Distance, vf_OriginalOrigin[Z] + i_Distance);
            
			engfunc(EngFunc_TraceHull, vf_NewOrigin, vf_NewOrigin, DONT_IGNORE_MONSTERS, GetPlayerHullSize(id), id, 0);

			if(get_tr2(0, TR_InOpen) && !get_tr2(0, TR_AllSolid) && !get_tr2(0, TR_StartSolid))
			{
				engfunc(EngFunc_SetOrigin, id, vf_NewOrigin);
				return 1;
			}
		}
		i_Distance += i_StartDistance;
	}
	return 0;
}

stock format_color(message[], msglen)
{
	new string[256], len = charsmax(string);

	copy(string, len, message);

	replace_all(string, len, "!n", "^1");
	replace_all(string, len, "!t", "^3");
	replace_all(string, len, "!g", "^4");

	formatex(message, msglen, "^1%s", string);
}

SendMsg(id, const MSG[], any:...)
{
	new szMsg[190]; vformat(szMsg, charsmax(szMsg), MSG, 3);
	message_begin(MSG_ONE_UNRELIABLE, 76, .player = id);
	write_byte(id);
	write_string(szMsg);
	message_end();
}