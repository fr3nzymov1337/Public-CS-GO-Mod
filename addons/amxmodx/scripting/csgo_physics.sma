/*
	v0.1 -  v0.1c [02.08.2011] - first release + code fix
	v0.2 - [04.08.2011] - added lie flat
	v0.3 - [26.08.2011] (+KORD_12.7 optimizations) - 1)added reflect damage, 2)added sounds, 3)removed cvar "spin", 4)fixed cvar "jump"
	v0.4 - [17.10.2011] 1)removed sound cvar 2)added shoot reaction 3)optimizations
	v0.4a - [23.10.2011] 1)Added wp reflect avel
	v0.4b - [08.11.2011] 1)added new sounds 2)more realistic now 3)added sparks
	v0.4b1 - [09.11.2011] 1)added macros on SOUNDS 2)fixed sparks macros 3)added macros DEBUG
	v0.4b2 - [17.11.2011] 1)fixed grenades! in cstrike :D 2)added functionality
	v0.4b3 - [21.11.2011] 1)fixed stuck bug 2)fixed class registration in hl 3)physics now MORE REAL :D 4)added grenade shoot in cs/csz
	v0.5 - [9.12.2011] 1)code optimizations  2)added block message macros (in cs/csz) 3)little fix in shoot grenades 4)fixed cycled sounds 4)fixed bug with "sys_ticrate" cvar 5)changed cvars (damage, shoot) 6)now - shoots & shoot_grenades can be used separately 7)new system unstuck
	v0.6 - [23.07.2012] 1)Added Origin Fix to "armoury_entity" 2)Added "armoury_entity" menu & randomizer & configs(for maps) 3)Added Glass reflect on touch 4)New Code
	
	http://aghl.ru/forum/ - Russian Half-Life and Adrenaline Gamer Community

	Code from "Weapon_Physics" & "Lie_Flat" by author "Nomexous"
*/

#include <hl_weapon_physics_stock>

public plugin_init()
{
	_Flag_Add(flag_Precache_OFF);
	
	g_fMaxDamageMultiple = (Float:DAMAGE_DIVIDER * Float:MAX_DAMAGE_RECEIVED);
	g_iMaxPlayersSizeOf = (g_iMaxPlayers = get_maxplayers()) + 1;

	register_plugin("[CS:GO MOD] Weapon Physics", "0.6", "Nomexous");
	register_event("DeathMsg", "On_Client_Death", "a");
	
	RegisterHam(Ham_Spawn, "player", "On_Client_Spawn", 1);
	
// <====================>
	
#if defined BREAKABLE_REFLECT

	RegisterHam(Ham_Touch, "func_breakable", "On_Breakable_Touch_Post", 1);
	
#endif	

// <====================>

#if defined WEAPON_THROWING_ON

	cvar_WeaponThrowSpeedMultiple = register_cvar("hl_ThrowSpeedMultiple", "13");

#endif

// <====================>
	
#if !defined Half_Life	

	DisableHamForward(g_HamSpawnPostOFF);
	register_logevent("On_New_Round", 2, "1=Round_Start");
	
#if defined ARMOURY_ENTITY_RANDOMIZER
	
	register_clcmd(CLCMD_COMMAND, "Call_Menu");

	if(g_iArmouryEntityCounter)
	{
		On_New_Round();
	}
	
	else
	{
		DisableHamForward(g_HamSpawnPreOFF);
	}
	
#endif	
	
#if defined SHOOT_GRENADES_ON

	RegisterHam(Ham_TraceAttack, "grenade", "TraceAttack_Post", 1);
	
#endif	
	
	register_forward(FM_TraceLine, "Trace_Line_Pre", 0);
	
#else // Fix Half-Life - Trace_Line

	register_forward(FM_TraceLine, "Trace_Line_Post", 1);
	
#endif
}

public plugin_precache()
{	
	if(!file_exists("addons/amxmodx/configs/csgo/csgo_physics.ini"))
	{
		
#if !defined Half_Life
		
		if(!write_file("addons/amxmodx/configs/csgo/csgo_physics.ini", "// Print bellow blocked classes^n ^ngrenade^n"))
		
#else	
	
		if(!write_file("addons/amxmodx/configs/csgo/csgo_physics.ini", "// Print bellow blocked classes^n"))
		
#endif

		{
			set_fail_state("FATAL ERROR: Can't Read Config");
			
			return;
		}
	}
	
#if !defined Half_Life

	g_TrieWeaponPos = TrieCreate();

	EnableHamForward(g_HamSpawnPostOFF = RegisterHam(Ham_Spawn, "armoury_entity", "Armoury_Entity_Spawn_Post", 1));
	
#if defined ARMOURY_ENTITY_RANDOMIZER

	new sMapName[32];
	
	get_mapname(sMapName, charsmax(sMapName));
	formatex(g_sMapName, charsmax(g_sMapName), "%s%s%s", "maps/", sMapName, "csgo_physics.ini");
		
	if(!file_exists(g_sMapName))
	{
		if(!write_file(g_sMapName, ""))
		{
			set_fail_state("FATAL ERROR -> Cant Create Config File!");
				
			return;
		}
	}
			
	new 
			
	line_len,
	value;
		
	read_file(g_sMapName, 0, sMapName, charsmax(sMapName), line_len);
			
	switch((value = str_to_num(sMapName)))
	{
		case 0:
		{
			new sConfigLine[32];
					
			num_to_str((g_iBitWeaponList = g_iConstBitAllWeapons), sConfigLine, charsmax(sConfigLine));
					
			write_file(g_sMapName, sConfigLine, 0);
		}
			
		default:
		{
			g_iBitWeaponList = value;
		}
	}
	
	Armoury_Entity_Change();

	cvar_iWeaponsCount = register_cvar("hl_ArmouryEntityCount", "1");
	cvar_iWeaponsCountCheck = get_pcvar_num(cvar_iWeaponsCount);
	
	Check_Armoury_Entity_Cvar();
	
	EnableHamForward(g_HamSpawnPreOFF = RegisterHam(Ham_Spawn, "armoury_entity", "Armoury_Entity_Spawn_Pre", 0));
	
#endif
#endif	

	cvar_PhysicsEntitySpawnGravity = register_cvar("hl_PhysicsDefaultGravity", "2.0");
	
#if defined TRAILS_ON && defined WEAPON_THROWING_ON

	g_SpriteTrail = precache_model(SPRITE);
	
#endif
	g_TrieBlockedClasses = TrieCreate();
	
	register_forward(FM_SetModel, "Set_Model_Post", 1);

#if defined ARMOURY_ENTITY_RANDOMIZER && !defined Half_Life

	line_len = 0;
	
#else

#if  !defined ARMOURY_ENTITY_RANDOMIZER

	new line_len = 0;
	
#endif
#endif	

	new
	
	line = 0,
	string[32]
	
#if defined SOUNDS_ON	
	,
	i;
#else
	;
#endif
	
	while(read_file("addons/amxmodx/configs/csgo/csgo_physics.ini", line++, string, charsmax(string), line_len))
	{
		if(!string[0] || equali(string, "//", 2))
		{
			continue;
		}
		
		TrieSetCell(g_TrieBlockedClasses, string, _class_Blocked);
	}

#if defined SOUNDS_ON	

	for(i = 0; i < g_iPrecacheTouchSoundSizeOf; i++)
	{
		precache_sound(g_sTouchSounds[i]);
	}
	
	for(i = 0; i < g_iPrecacheHitSoundSizeOf; i++)
	{
		precache_sound(g_sHitSounds[i]);
	}
	
#endif
}

public Touch_Post(iEntity, iTouched)
{
	static 
	
	iTouchedFlags,
	iEntFlags;
	
	if(pev_valid(iEntity))
	{
		if(!iTouched)
		{
			return Enable_Physics(iEntity);
		}
		
		iEntFlags = ((pev(iEntity, pev_flags) & FL_ONGROUND) | is_Physics);
		
		if(iTouched > g_iMaxPlayers)
		{
			if(pev_valid(iTouched))
			{
				if(!(iTouchedFlags = Get_Entity_Flags(iTouched)))
				{
					if(pev(iTouched, pev_solid) & SOLID_BSP)
					{
						return Enable_Physics(iEntity);
					}
					
					return HAM_IGNORED;
				}
				
				switch(iTouchedFlags & is_Physics)
				{
					case 0:
					{
						static iParam;
						
						switch(iTouchedFlags & is_Breakable)
						{
							case 0:
							{
								iParam = is_Monster >> 0x1;	
							}
								
							default:
							{
								iParam = is_Breakable >> 0x1;	
								
								Enable_Physics(iEntity);
							}
						}
#if defined PUSH_MONSTERS							
						return Touch_Extension_Check(iEntity, iTouched, iEntFlags, iTouchedFlags, iParam);
#else
						return Touch_Extension_Check(iEntity, iTouched, iEntFlags, iParam);
#endif						
					}
						
					default:
					{
						if(iEntFlags ^ iTouchedFlags) // Physics Reflect :D
						{
							static 
				
							Float:fInflictorData[3],
							Float:fTouchedData[3],
							Float:fDifference[3],
							iCounter;
					
							switch((iCounter = pev(iEntity, PEV_DATA_SLOT)))
							{
								case COUNTS_TO_RESET:
								{
									set_pev(iEntity, PEV_DATA_SLOT, 0);
								}
					
								default:
								{
									set_pev(iEntity, PEV_DATA_SLOT, ++iCounter);
								
									return HAM_IGNORED;
								}
							}
					
							pev(iEntity, pev_origin, fTouchedData);
							pev(iTouched, pev_origin, fInflictorData);

							if(get_distance_f(fTouchedData, fInflictorData) < 16.0)
							{	
								fDifference[0] = float(random_num(64, 96));
					
								if(random(2))
								{
									fDifference[0] = -fDifference[0];
								}
					
								fDifference[1] = float(random_num(64, 96));
					
								if(random(2))
								{
									fDifference[1] = -fDifference[1];
								}
					
								fDifference[2] = float(random_num(32, 96));
				
								if(random(2))
								{
									set_pev(iTouched, pev_velocity, fDifference);
								}
								
								fDifference[0] = -fDifference[0];
								fDifference[1] = -fDifference[1];
								
								if(random(2))
								{
									set_pev(iEntity, pev_velocity, fDifference);
								}
								
								fDifference[0] *= random_float(1.25, 2.75);
								fDifference[1] *= random_float(1.25, 2.75);
								
								if(random(2))
								{
									fDifference[0] = -fDifference[0];
								}
								
								if(random(2))
								{
									fDifference[1] = -fDifference[1];
								}
								
								set_pev(iEntity, pev_avelocity, fDifference);
#if defined SOUNDS_ON					
								engfunc(EngFunc_EmitSound, iEntity, CHAN_AUTO, g_sHitSounds[random(g_iPrecacheHitSoundSizeOf)], Float:SOUND_HIT, ATTN_NORM, 0, PITCH_NORM);
#endif							
							}
							
							return HAM_HANDLED;
						}
					}
				}
			}
		}
		
		else if(bit_alive(iTouched))
		{
			
#if defined PUSH_MONSTERS		

			Touch_Extension_Check(iEntity, iTouched, iEntFlags, is_Player, 0);
			
#else		
	
			Touch_Extension_Check(iEntity, iTouched, iEntFlags, 0);
			
#endif

		}
	}
	
	return HAM_IGNORED;
}

#if !defined Half_Life
#if defined ARMOURY_ENTITY_RANDOMIZER
public Menu_Config(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu);
		
		return PLUGIN_HANDLED;
	}
	
	new 
	
	s_Data[6], 
	s_Name[16], 
	i_Access, 
	i_Callback,
	i;
	
	menu_item_getinfo(Menu, Item, i_Access, s_Data, charsmax(s_Data), s_Name, charsmax(s_Name), i_Callback);

	new i_Key = str_to_num(s_Data);
	
	new BitValues[5];
	
	switch(g_iClientMenuChoice[IndexFix(id)])
	{
		case 1:
		{
			switch(i_Key)
			{
				case 6:
				{
					i = 2;
				}
				
				default:
				{
					i = 1;
					
					BitValues =
					{
						_Bit_Weapon_Awp,
						_Bit_Weapon_G3sg1,
						_Bit_Weapon_Scout,
				
						_Bit_Weapon_Xm1014,
						_Bit_Weapon_M3
					};
				}
			}
		}
		
		case 2:
		{
			switch(i_Key)
			{
				case 6:
				{
					i = 1;	
				}
				
				case 7:
				{
					i = 3;
				}
				
				default:
				{
					i = 2;
					
					BitValues =
					{
						_Bit_Weapon_Aug,
						_Bit_Weapon_Sg552,
						_Bit_Weapon_M4a1,
						_Bit_Weapon_Ak47,
						_Bit_Weapon_M249
					};
				}
			}
		}
		
		case 3:
		{
			switch(i_Key)
			{
				case 5:
				{
					i = 2;
				}
				
				case 6:
				{
					i = 4;	
				}
				
				default:
				{
					i = 3;
					
					BitValues =
					{
						_Bit_Weapon_P90,
						_Bit_Weapon_Mp5Navy,
						_Bit_Weapon_Mac10,
						_Bit_Weapon_Tmp,
						0
					};
				}
			}
		}
		
		case 4:
		{
			switch(i_Key)
			{
				case 6:
				{
					i = 3;	
				}
				
				default:
				{
					i = 4;	
					
					BitValues =
					{
						_Bit_Weapon_Hegrenade,
						_Bit_Weapon_Flashbang,
						_Bit_Weapon_Smokegrenade,
						_Bit_Item_Kevlar,
						_Bit_Item_Assaultsuit
					};
				}
			}
		}
	}
	
	if(i_Key < 6 && BitValues[i_Key - 1])
	{
		enum
		{
			iMassiveSize = 31
		};
		
		g_iBitWeaponList ^= BitValues[i_Key - 1];
		
		new sConfigLine[iMassiveSize + 1];
		
		num_to_str(g_iBitWeaponList, sConfigLine, iMassiveSize);
		
		write_file(g_sMapName, sConfigLine, 0);
	}
	
	Main_Menu(id, i);
		
	return PLUGIN_HANDLED;
}

public Call_Menu(id)
{
	if(get_user_flags(id) & (ADMIN_FLAGS))
	{
		Main_Menu(id, 1);
	}
}
#endif

public On_New_Round()
{
#if defined ARMOURY_ENTITY_RANDOMIZER

	cvar_iWeaponsCountCheck = get_pcvar_num(cvar_iWeaponsCount);
	
	Check_Armoury_Entity_Cvar();
	
#endif	

	if(g_iArmouryEntityCounter)
	{
		
#if defined ARMOURY_ENTITY_RANDOMIZER	
	
		Armoury_Entity_Change();
		
#endif		
	
		new
		
		sWeaponIndex[6],
		Float:fOriginFix[3],
		i;
		
		while((i = fm_find_ent_by_class(i, "armoury_entity")))
		{
			if(pev_valid(i))
			{
				num_to_str(i, sWeaponIndex, charsmax(sWeaponIndex));
				TrieGetArray(g_TrieWeaponPos, sWeaponIndex, fOriginFix, 3);
			
				if(fOriginFix[0] || fOriginFix[1] || fOriginFix[2])
				{
					
#if defined ARMOURY_ENTITY_RANDOMIZER			
		
					ExecuteHamB(Ham_Spawn, i);
					
#endif					

					set_pev(i, pev_origin, fOriginFix);
					
					engfunc(EngFunc_DropToFloor, i);
					ExecuteHamB(Ham_Touch, i, 0);
				}	
			}
		}
	}
}

public Armoury_Entity_Spawn_Post(iEntity) // Enabled on - "plugin_precache" :: Disabled on - "plugin_init"
{
	if(pev_valid(iEntity))
	{
		Change_Rendering(iEntity);
		
#if !defined ARMOURY_ENTITY_RANDOMIZER	
	
		if(_Flag_NOT_Exists(flag_Precache_OFF))
		{
			g_iArmouryEntityCounter++;
		}
		
#endif		

		enum
		{
			iMassiveSize = 5
		};
		
		new 
		
		Float:fOriginFix[3],
		sWeaponIndex[iMassiveSize + 1];
		
		pev(iEntity, pev_origin, fOriginFix);

		num_to_str(iEntity, sWeaponIndex, iMassiveSize);
		TrieSetArray(g_TrieWeaponPos, sWeaponIndex, fOriginFix, 3);
	}
}
#endif

public client_disconnect(id)
{
	bit_alive_sub(id);
}

public On_Client_Spawn(id)
{
	bit_alive_add(id);
}

public On_Client_Death()
{
	bit_alive_sub(read_data(2));
}

public Take_Damage_Pre(iEntity, inflictor, idattacker, Float:fDamage, iDamagebits)
{
	if(fDamage < 1.0)
	{
		fDamage = 1.0;
	}
	
	static 

	Float:fTemp[3],

	iAgressor,
	iMaxMultiple,
	iParam;

	if(pev_valid(iEntity) && ((iAgressor = Get_Entity_Data(inflictor)) || (iAgressor = Get_Entity_Data(idattacker))))
	{
		if(fDamage > Float:MAX_DAMAGE_RECEIVED)
		{
			fDamage = Float:MAX_DAMAGE_RECEIVED;
		}
		
		enum
		{
			iDataVertical = 0,
			iDataHorizontal,
			iDataAngleHigh,
			iDataAngle
		}
		
		switch(pev(iEntity, PEV_GROUND_TYPE))
		{
			case iDataVertical, iDataHorizontal:
			{
				iParam = 0;	
			}
			
			case iDataAngleHigh, iDataAngle:
			{
				iParam = 1;	
			}
			
			default:
			{
				SetHamParamFloat(4, 0.0);
	
				return HAM_HANDLED;
			}
		}
		
		Make_Vectors(iAgressor, iEntity, fDamage, iDamagebits, fTemp, iParam);	
		
		if(fDamage < 32.0)
		{
			iMaxMultiple = 16;
		}
		
		else if(fDamage < 64.0)
		{
			iMaxMultiple = 12;
		}
		
		else if(fDamage < 96.0)
		{
			iMaxMultiple = 8;
		}
		
		else
		{
			iMaxMultiple = 4;
		}
		
		fTemp[1] = random_float(-fDamage, fDamage) * random_num(2, iMaxMultiple);
		
		if(fTemp[0] > Float:MAX_REFLECT_A_VELOCITY)
		{
			fTemp[0] = Float:MAX_REFLECT_A_VELOCITY;
		}
		
		else if(fTemp[0] < -Float:MAX_REFLECT_A_VELOCITY)
		{
			fTemp[0] = -Float:MAX_REFLECT_A_VELOCITY;
		}
		
		if(fTemp[2] > Float:MAX_REFLECT_A_VELOCITY)
		{
			fTemp[2] = Float:MAX_REFLECT_A_VELOCITY;
		}
		
		else if(fTemp[2] < -Float:MAX_REFLECT_A_VELOCITY)
		{
			fTemp[2] = -Float:MAX_REFLECT_A_VELOCITY;
		}
		
		static Float:fEntAngles[3];
		
		pev(iEntity, pev_angles, fEntAngles);
		
		xs_vec_add(fEntAngles, fTemp, fTemp);
		
		fTemp[1] *= 0.75;
		fTemp[2] *= random_float(0.5, 0.75);
		fTemp[0] *= random_float(0.5, 0.75);
		
		set_pev(iEntity, pev_avelocity, fTemp);
		
#if defined SOUNDS_ON	
	
		engfunc(EngFunc_EmitSound, iEntity, CHAN_AUTO, g_sHitSounds[random(g_iPrecacheHitSoundSizeOf)], Float:SOUND_HIT, ATTN_NORM, 0, PITCH_NORM);
		
#endif		

		SetHamParamFloat(4, 0.0);
	
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

public Set_Model_Post(iEntity, const sModel[])
{
	if(iEntity > g_iMaxPlayers && pev_valid(iEntity) && (1 << pev(iEntity, pev_movetype) & _:(AVAILABLE_MOVETYPE)))
	{
		new 
		
		classname[32],
		value = 0;
		
		pev(iEntity, pev_classname, classname, charsmax(classname));
		TrieGetCell(g_TrieBlockedClasses, classname, value);
		
		if(!value)
		{
			TrieSetCell(g_TrieBlockedClasses, classname, _class_Change);
			
			RegisterHamFromEntity(Ham_TraceAttack, iEntity, "TraceAttack_Post", 1);
			RegisterHamFromEntity(Ham_TakeDamage, iEntity, "Take_Damage_Pre", 0);
			RegisterHamFromEntity(Ham_Touch, iEntity, "Touch_Post", 1);
			
			value = _class_Change;
		}
		
		if(value & _class_Change)
		{
			new Float:fCvarGravityValue = get_pcvar_float(cvar_PhysicsEntitySpawnGravity);
			
			if(fCvarGravityValue < 0.0)
			{
				fCvarGravityValue = -fCvarGravityValue;
			}
			
			set_pev(iEntity, pev_health, 111.0);
			set_pev(iEntity, pev_takedamage, DAMAGE_YES);
			set_pev(iEntity, pev_movetype, MOVETYPE_BOUNCE);
			set_pev(iEntity, pev_gravity, fCvarGravityValue);
			
#if defined WEAPON_THROWING_ON	
			new Owner = 0;
			
			if(_PlayerEntity((Owner = pev(iEntity, pev_owner))))
#else
			if(_PlayerEntity(pev(iEntity, pev_owner)))
#endif
			{
#if defined WEAPON_THROWING_ON				
				new Float:Aiming[3];
				
				if(bit_alive(Owner))
				{
					new Float:fMultiple;
					
					velocity_by_aim(Owner, random_num(16, 32), Aiming);
				
					if((fMultiple = float(get_pcvar_num(cvar_WeaponThrowSpeedMultiple))) > 0.0 && get_user_oldbutton(Owner) & IN_USE && equali(classname, "weaponbox", 9))
					{
						xs_vec_mul_scalar(Aiming, fMultiple, Aiming);	
#if defined TRAILS_ON
						Entity_Trail(iEntity);
#endif
					}
				
					set_pev(iEntity, pev_basevelocity, Aiming);

				}
#else
				new Float:Aiming[3];
#endif
#if defined PHYSICS_RENDERING			
				Change_Rendering(iEntity);
#endif			
				Aiming[0] = random_float(-255.0, 255.0);
				Aiming[1] = random_float(-255.0, 255.0);
				Aiming[2] = random_float(-255.0, 255.0);
				
				set_pev(iEntity, pev_avelocity, Aiming);	
			}
		}
	}
}

#if !defined Half_Life
public Trace_Line_Pre(Float:start[3], Float:end[3], iNoMonsters, entToSkip, trace)
#else
public Trace_Line_Post(Float:start[3], Float:end[3], iNoMonsters, entToSkip, trace)
#endif
{
	if(_PlayerEntityAlive(entToSkip))
	{
		static 
		
		Float:endpt[3], 
		tr, 
		i,
		result;
		
		get_tr2(trace, TR_vecEndPos, endpt);
		
#if defined SHOOT_GRENADES_ON && !defined Half_Life	
		while((i = fm_find_ent_by_class(i, "grenade")))
		{
			if(pev_valid(i) && pev(i, pev_dmgtime))
			{
				engfunc(EngFunc_TraceModel, start, endpt, HULL_HEAD, i, tr);
			
				if(i == get_tr2(tr, TR_pHit))
				{				
					set_tr2(trace, TR_pHit, (g_iClientGrenade[IndexFix(entToSkip)] = i));
				
					break;
				}
			}
			
			g_iClientGrenade[IndexFix(entToSkip)] = 0;
		}
		
		if(!g_iClientGrenade[IndexFix(entToSkip)])
		{
#endif	
			while((i = engfunc(EngFunc_FindEntityInSphere, i, endpt, Float:SEARCHING_RADIUS)))
			{
				if(i > g_iMaxPlayers && pev_valid(i) && pev(i, pev_movetype) == MOVETYPE_BOUNCE)
				{
					engfunc(EngFunc_TraceModel, start, end, HULL_HEAD, i, tr);
		
					if((((result = get_tr2(tr, TR_pHit)) == i) || (result < 0 && Extension_Check(entToSkip, i, endpt))))
					{
						set_tr2(trace, TR_pHit, (g_iClientEntity[IndexFix(entToSkip)] = i));
						
						continue;
					}
				
					g_iClientEntity[IndexFix(entToSkip)] = 0;
					g_fClientDamage[IndexFix(entToSkip)] = 0.0;
				}
			
				else
				{
					g_iClientEntity[IndexFix(entToSkip)] = 0;
					g_fClientDamage[IndexFix(entToSkip)] = 0.0;
				}
			}
#if defined SHOOT_GRENADES_ON && !defined Half_Life			
		}
#endif
	}
}

public TraceAttack_Post(ent, idattacker, Float:damage, Float:direction[3], tracehandle, damagebits)
{	
	if(_PlayerEntity(idattacker))
	{
		if(!(damagebits & DMG_BULLET))
		{
			g_iClientEntity[IndexFix(idattacker)] = 0;
			g_fClientDamage[IndexFix(idattacker)] = 0.0;
			
			return;
		}
		
		g_fClientDamage[IndexFix(idattacker)] = damage;
		
#if !defined Half_Life && defined SHOOT_GRENADES_ON
		if(g_iClientGrenade[IndexFix(idattacker)] == ent && pev_valid(ent) && pev(ent, pev_dmgtime))
		{
			new deploy = 0;
			
			switch(get_pdata_int(ent, 114))
			{
				case FLASH_GRENADE:
				{
					if(!get_pdata_int(ent, 96))
					{						
						deploy = 0x1;						
					}
				}
							
				case HE_GRENADE:
				{
					deploy = 0x2;						
				}
							
				case SMOKE_GRENADE:
				{				
					set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_ONGROUND);
					
					deploy = 0x3;
				}
			}
		
			if(deploy)
			{
#if defined MESSAGE_ON						
				enum
				{
					iMassiveSize = 31
				};
				
				new Name[iMassiveSize + 1];
					
				new const grenade_id[][] =
				{
					"FlashBang",
					"HEGrenade",
					"SmokeGrenade"
				};

				get_user_name(idattacker, Name, iMassiveSize);	
				client_print(0, print_chat, "%c%s%s %s %s%s%c %s", '[', Name, "]:", " HIT -", " `", grenade_id[deploy - 1], '`', "O_o!");
				
#endif		

				set_pev(ent, pev_dmgtime, 0.0);
				dllfunc(DLLFunc_Think, ent);
				
				g_iClientGrenade[IndexFix(idattacker)] = 0;
			}
		}
#endif
	}
}

#if defined zBot_on_server
public zBot_change_data(id, zBot_alive, zBot_in_game)
{
	if(id > 0 && 1 << (id - 1) & zBot_alive)
	{
		On_Client_Spawn(id);
	}
}
#endif

#if defined ARMOURY_ENTITY_RANDOMIZER
public Armoury_Entity_Spawn_Pre(ent)
{
	if(pev_valid(ent))	
	{
		if(_Flag_NOT_Exists(flag_Precache_OFF))
		{
			g_iArmouryEntityCounter++;
		}
	
		set_pdata_int(ent, 34, g_iWeaponsCounter ? g_iRandomWeapons_Enum[random(g_iWeaponsCounter)] : 0, _:WEAPON_IN_BOX_LINUX_OFFSET);
		set_pdata_int(ent, 35, cvar_iWeaponsCountCheck, _:WEAPON_COUNT_LINUX_OFFSET);
	}
}
#endif

#if defined BREAKABLE_REFLECT
public On_Breakable_Touch_Post(iEntity, id)
{
	static 
	
	iAgressor,
	iFlags;
	
	if(pev_valid(iEntity) && (!(iFlags = pev(iEntity, pev_spawnflags)) || iFlags & ~SF_BREAK_TRIGGER_ONLY) && (iAgressor = Get_Entity_Data(id, GET_FULL_DATA)))
	{
		if(iAgressor < 0 || iAgressor & is_Monster)
		{
			static 
		
			Float:fVelocity[3],
			Float:fVector;
		
			pev(id, pev_velocity, fVelocity);
			
			if((fVector = (vector_length(fVelocity) * g_fMultiple[2][_SpeedVectorMultiple])) > g_fMultiple[2][_SpeedVectorCheck])
			{
				ExecuteHamB(Ham_TakeDamage, iEntity, id, id, fVector * g_fMultiple[2][_DamageMultiple], DMG_GENERIC);
			
				return HAM_HANDLED;
			}
		}
	}
	
	return HAM_IGNORED;
}
#endif