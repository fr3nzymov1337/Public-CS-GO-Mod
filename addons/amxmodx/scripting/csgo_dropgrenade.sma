
  // CS Grenade Drops on Death (a.k.a. CSNadeDrops) 0.14 by Avalanche
  //
  // When a player dies they will drop the grenades that they had
  // with them onto the ground for other players to pick up. The
  // grenades play a grenade-bouncing sound when they hit the ground
  // and they look just like the real grenades. This plugin was
  // requested by Danjal of the AMXX forums.
  //
  // mp_nadedrops <0|1> - default 1
  // mp_nadedropsounds <0|1> - default 1

  #include <amxmodx>
  #include <engine>
  #include <fun>

  #define VOL_LOW 0.5 // volume used to play nade bouncing sound
  #define NADE_OFFSET 10 // distance (vaguely) between death origin and nade origin

  // DeathMSG
  public event_damage(id) {

    // if player is still alive or plugin is disabled
    if(get_user_health(id) > 0 || get_cvar_num("mp_nadedrops") < 1) {
      return PLUGIN_CONTINUE;
    }

    // if player had HE grenade
    if(hasweapon(id,"weapon_hegrenade") > 0) {
      new grenade = create_entity("info_target"); // create grenade entity
      entity_set_string(grenade,EV_SZ_classname,"fake_hegrenade"); // change name
      entity_set_int(grenade,EV_ENT_owner,id); // set owner
      entity_set_int(grenade,EV_INT_iuser1,0); // hasn't bounced yet

      // set grenade entity's size
      new Float:minbox[3] = { -2.5, -2.5, -2.5 }
      new Float:maxbox[3] = { 2.5, 2.5, 2.5 };
      entity_set_vector(grenade,EV_VEC_mins,minbox);
      entity_set_vector(grenade,EV_VEC_maxs,maxbox);

      // set grenade's overall being of a whole
      entity_set_int(grenade,EV_INT_solid,SOLID_TRIGGER);
      entity_set_int(grenade,EV_INT_movetype,MOVETYPE_TOSS);

      // set a random angle
      new Float:angles[3] = { 0.0, 0.0, 0.0 };
      angles[1] = float(random_num(0,180));
      entity_set_vector(grenade,EV_VEC_angles,angles);

      // get player's origin
      new Float:origin[3];
      entity_get_vector(id,EV_VEC_origin,origin);
      origin[0] += NADE_OFFSET; // offset

      // set model and origin
      entity_set_model(grenade,"models/w_hegrenade.mdl");
      entity_set_vector(grenade,EV_VEC_origin,origin);
    }

    // if player had smoke grenade
    if(hasweapon(id,"weapon_smokegrenade") > 0) {
      new grenade = create_entity("info_target"); // create grenade entity
      entity_set_string(grenade,EV_SZ_classname,"fake_smokegrenade"); // change name
      entity_set_int(grenade,EV_ENT_owner,id); // set owner
      entity_set_int(grenade,EV_INT_iuser1,0); // hasn't bounced yet

      // set grenade entity's size
      new Float:minbox[3] = { -2.5, -2.5, -2.5 }
      new Float:maxbox[3] = { 2.5, 2.5, 2.5 };
      entity_set_vector(grenade,EV_VEC_mins,minbox);
      entity_set_vector(grenade,EV_VEC_maxs,maxbox);

      // set grenade's overall being of a whole
      entity_set_int(grenade,EV_INT_solid,SOLID_TRIGGER);
      entity_set_int(grenade,EV_INT_movetype,MOVETYPE_TOSS);

      // set a random angle
      new Float:angles[3] = { 0.0, 0.0, 0.0 };
      angles[1] = float(random_num(0,180));
      entity_set_vector(grenade,EV_VEC_angles,angles);

      // get player's origin
      new Float:origin[3];
      entity_get_vector(id,EV_VEC_origin,origin);
      origin[0] -= NADE_OFFSET; // offset

      // set model and origin
      entity_set_model(grenade,"models/w_smokegrenade.mdl");
      entity_set_vector(grenade,EV_VEC_origin,origin);
    }

    // if player had at least one flashbang
    if(hasweapon(id,"weapon_flashbang") > 0) {
      new grenade = create_entity("info_target"); // create grenade entity
      entity_set_string(grenade,EV_SZ_classname,"fake_flashbang"); // change name
      entity_set_int(grenade,EV_ENT_owner,id); // set owner
      entity_set_int(grenade,EV_INT_iuser1,0); // hasn't bounced yet

      // set grenade entity's size
      new Float:minbox[3] = { -2.5, -2.5, -2.5 }
      new Float:maxbox[3] = { 2.5, 2.5, 2.5 };
      entity_set_vector(grenade,EV_VEC_mins,minbox);
      entity_set_vector(grenade,EV_VEC_maxs,maxbox);

      // set grenade's overall being of a whole
      entity_set_int(grenade,EV_INT_solid,SOLID_TRIGGER);
      entity_set_int(grenade,EV_INT_movetype,MOVETYPE_TOSS);

      // set a random angle
      new Float:angles[3] = { 0.0, 0.0, 0.0 };
      angles[1] = float(random_num(0,180));
      entity_set_vector(grenade,EV_VEC_angles,angles);

      // get player's origin
      new Float:origin[3];
      entity_get_vector(id,EV_VEC_origin,origin);
      origin[1] += NADE_OFFSET; // offset

      // set model and origin
      entity_set_model(grenade,"models/w_flashbang.mdl");
      entity_set_vector(grenade,EV_VEC_origin,origin);
    }

    // if player had two flashbangs, drop another
    if(hasweapon(id,"weapon_flashbang") > 1) {
      new grenade = create_entity("info_target"); // create grenade entity
      entity_set_string(grenade,EV_SZ_classname,"fake_flashbang"); // change name
      entity_set_int(grenade,EV_ENT_owner,id); // set owner
      entity_set_int(grenade,EV_INT_iuser1,0); // hasn't bounced yet

      // set grenade entity's size
      new Float:minbox[3] = { -2.5, -2.5, -2.5 }
      new Float:maxbox[3] = { 2.5, 2.5, 2.5 };
      entity_set_vector(grenade,EV_VEC_mins,minbox);
      entity_set_vector(grenade,EV_VEC_maxs,maxbox);

      // set grenade's overall being of a whole
      entity_set_int(grenade,EV_INT_solid,SOLID_TRIGGER);
      entity_set_int(grenade,EV_INT_movetype,MOVETYPE_TOSS);

      // set a random angle
      new Float:angles[3] = { 0.0, 0.0, 0.0 };
      angles[1] = float(random_num(0,180));
      entity_set_vector(grenade,EV_VEC_angles,angles);

      // get player's origin
      new Float:origin[3];
      entity_get_vector(id,EV_VEC_origin,origin);
      origin[1] -= NADE_OFFSET; // offset

      // set model and origin
      entity_set_model(grenade,"models/w_flashbang.mdl");
      entity_set_vector(grenade,EV_VEC_origin,origin);
    }

    return PLUGIN_CONTINUE;
  }

  // ResetHUD
  public event_resethud(id) {
    if(is_user_connected(id) == 1 && get_user_team(id) < 3) {
      set_task(0.5,"checkalive",id); // delay, because client is technically dead on ResetHUD
    }
  }

  // check if user is alive
  public checkalive(id) {
    if(is_user_alive(id) == 1) { // if so
      clear_nades(id); // clear nades (they just spawned)
    }
  }

  // entity touching
  public pfn_touch(ptr,ptd) {
    if(!is_valid_ent(ptd)) { // invalid toucher
      return PLUGIN_CONTINUE;
    }

    new classname[32];
    entity_get_string(ptd,EV_SZ_classname,classname,31); // get name of toucher

    new bounced = entity_get_int(ptd,EV_INT_iuser1); // bounced yet?

    // check if one of our fake grenades is colliding with world and mp_nadedropsounds is positive
    if((equal(classname,"fake_hegrenade") || equal(classname,"fake_flashbang") || equal(classname,"fake_smokegrenade")) && ptr == 0 && bounced == 0 && get_cvar_num("mp_nadedropsounds") > 0) {
      emit_sound(ptd,CHAN_ITEM,"weapons/he_bounce-1.wav",VOL_LOW,ATTN_NORM,0,PITCH_LOW); // play sound
      entity_set_int(ptd,EV_INT_iuser1,1); // has bounced
      return PLUGIN_CONTINUE;
    }

    // now check for more invalid entities or players
    if(!is_valid_ent(ptr) || !is_valid_ent(ptd) || !is_user_connected(ptd)) {
      return PLUGIN_CONTINUE;
    }

    entity_get_string(ptr,EV_SZ_classname,classname,31); // get name of touched

    // if player is touching hegrenade and doesn't have one
    if(equal(classname,"fake_hegrenade") && hasweapon(ptd,"weapon_hegrenade") == 0) {
      give_item(ptd,"weapon_hegrenade");
      remove_entity(ptr);
      return PLUGIN_CONTINUE;
    }

    // if player is touching smokegrenade and doesn't have one
    if(equal(classname,"fake_smokegrenade") && hasweapon(ptd,"weapon_smokegrenade") == 0) {
      give_item(ptd,"weapon_smokegrenade");
      remove_entity(ptr);
      return PLUGIN_CONTINUE;
    }

    // if player is touching flashbang and has room for another
    if(equal(classname,"fake_flashbang") && hasweapon(ptd,"weapon_flashbang") < 2) {
      give_item(ptd,"weapon_flashbang");
      remove_entity(ptr);
      return PLUGIN_CONTINUE;
    }

    return PLUGIN_CONTINUE;
  }

  // client disconnection
  public client_disconnect(id) {
    clear_nades(id);
  }

  // function to check if player has a specific weapon.
  // returns the amount of ammo for that weapon in backpack.
  // we use this so we can check for multiple flashbangs as well
  public hasweapon(id,weaponname[32]) {
    if(is_user_connected(id) == 0 || get_user_team(id) > 2) {
      return 0;
    }

    new weapons[32], num;
    get_user_weapons(id,weapons,num); // get weapons

    new foundweapon; // if we found the weapon yet (and if we did how much ammo for it)

    // loop through weapons
    for(new i=0;i<num;i++) {
      new checkweaponname[32];
      get_weaponname(weapons[i],checkweaponname,31);

      if(equal(weaponname,checkweaponname)) { // compare names
        new clip, ammo; // clip and ammo
        get_user_ammo(id,weapons[i],clip,ammo); // get clip and ammo
        foundweapon = ammo; // return amount in clip (for multiple FBs)
        break;
      }
    }

    return foundweapon;
  }

  // clear user's grenades
  public clear_nades(id) {
    new currnade;

    // go through fake HE grenades
    currnade = -1;
    while((currnade = find_ent_by_class(currnade,"fake_hegrenade")) > 0) {
      if(entity_get_int(currnade,EV_ENT_owner) == id) {
        remove_entity(currnade);
      }
    }

    // go through fake smoke grenades
    currnade = -1;
    while((currnade = find_ent_by_class(currnade,"fake_smokegrenade")) > 0) {
      if(entity_get_int(currnade,EV_ENT_owner) == id) {
        remove_entity(currnade);
      }
    }

    // go through fake flashbangs
    currnade = -1;
    while((currnade = find_ent_by_class(currnade,"fake_flashbang")) > 0) {
      if(entity_get_int(currnade,EV_ENT_owner) == id) {
        remove_entity(currnade);
      }
    }
  }

  // plugin precache
  public plugin_precache() {
    precache_model("models/w_hegrenade.mdl");
    precache_model("models/w_flashbang.mdl");
    precache_model("models/w_smokegrenade.mdl");
    precache_sound("weapons/he_bounce-1.wav");
  }

  // plugin initiation
  public plugin_init() {
    register_plugin("[CS:GO MOD] Drop Grenade","0.14","Avalanche");

    register_event("Damage","event_damage","b","2!0"); // damage event
    register_event("ResetHUD","event_resethud","b"); // reset HUD event

    register_cvar("mp_nadedrops","1",FCVAR_PRINTABLEONLY); // cvar to disable/enable plugin
    register_cvar("mp_nadedropsounds","1",FCVAR_PRINTABLEONLY); // cvar to disable/enable nade drop sounds

    // get the mod's name
    new modname[32];
    get_modname(modname,31);

    // if this isn't Counter-Strike
    if(!equal(modname,"cstrike")) {
      pause("ae"); // lock the plugin
    }
  }
