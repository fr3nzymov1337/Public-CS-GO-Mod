#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <xs>

#define MAX_PLAYERS 32

new const PLUGIN[] 	= "[CS:GO MOD] Short Throw Grenade"
new const VERSION[]	= "1.0" 

enum
{
	normal,
	slower,
	medium
}
new const GrenadeClassNames[][] =
{
	"weapon_flashbang",
	"weapon_hegrenade",
	"weapon_smokegrenade"
}
new const Float:VelocityMultiplier[] =
{
	1.0,
	0.5,
	0.7
}
const m_pPlayer  = 	41
const XoCGrenade = 	4

new HandleThrowType[MAX_PLAYERS+1]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, "EFFx, HamletEagle, hellmonja, x FR3NZYMOV x")

	for(new i; i < sizeof GrenadeClassNames; i++)
	{
		RegisterHam(Ham_Weapon_SecondaryAttack, GrenadeClassNames[i], "CBasePlayerWpn_SecondaryAttack", false)
	}
}
public CBasePlayerWpn_SecondaryAttack(const grenadeEntity)
{
	if(pev_valid(grenadeEntity))
	{
		new id = get_pdata_cbase(grenadeEntity, m_pPlayer, XoCGrenade)
		new buttons = pev(id, pev_button)
		
		if(buttons & IN_ATTACK)
		{
			HandleThrowType[id] = medium
		}
		else 
		{
			HandleThrowType[id] = slower
		}
		
		ExecuteHamB(Ham_Weapon_PrimaryAttack, grenadeEntity)
	}
}
public grenade_throw(id, grenadeEntity, grenadeWeaponIndex) 
{
	if(pev_valid(grenadeEntity))
	{
		new Float:grenadeVelocity[3]
		pev(grenadeEntity, pev_velocity, grenadeVelocity)
		
		new Float:multiplier = VelocityMultiplier[HandleThrowType[id]]
		xs_vec_mul_scalar(grenadeVelocity, multiplier, grenadeVelocity)
		set_pev(grenadeEntity, pev_velocity, grenadeVelocity)
		
		if(HandleThrowType[id] == slower)
		set_weapon_anim(id, 4)		
		
		HandleThrowType[id] = normal
	}
}  
set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
	
	set_pev(id, pev_weaponanim, anim);
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id);
	write_byte(anim);
	write_byte(pev(id, pev_body));
	message_end();
}