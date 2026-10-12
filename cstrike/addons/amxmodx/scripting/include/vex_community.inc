// v4.2.0: natives carry the vx42_ prefix so item plugins always bind to the 4.2 core,
// never to an old vexmira_zombie.amxx copy that registered the old vex_* names first.
native vx42_is_zombie(id);
native vx42_is_extra_weapon(id);
native vx42_knife_allowed(id);
native vx42_restore_appearance(id);
native vx42_has_jetpack(id);
native vx42_prepare_jetpack(id);
native vx42_register_component(component);
native vx42_is_survivor(id);

#define vex_is_zombie vx42_is_zombie
#define vex_is_extra_weapon vx42_is_extra_weapon
#define vex_knife_allowed vx42_knife_allowed
#define vex_restore_appearance vx42_restore_appearance
#define vex_has_jetpack vx42_has_jetpack
#define vex_prepare_jetpack vx42_prepare_jetpack
#define vex_register_component vx42_register_component
#define vex_is_survivor vx42_is_survivor
