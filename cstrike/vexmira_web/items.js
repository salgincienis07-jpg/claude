/* VEXMIRA tablet item names - SAMPLE.
 * The server plugin overwrites this file at every map start (see CONTRACT.md).
 * index 0 = item 1. r = rarity 0..4 (Common, Rare, Epic, Legendary, Mythic), vc = price in VexCoin.
 * cases[].loot = [itemCode, rarity, chance%].
 * Optional extra keys the tablet understands (all optional, may be omitted):
 *   cmd:{case:"/kasa",trade:"/takas <isim>",daily:"/gunluk",inv:"/envanter",zup:"/gelisim",tablet:"/tablet"}
 *   daily:[{tr:"50 AP",en:"50 AP"}, ... 7 entries], zcost:[1,2,3,4,5], ip:"1.2.3.4:27015", discord:"discord.gg/xyz"
 */
window.VXITEMS = {
  k: [
    {tr:"Balrog-9 / Ates Yumrugu", en:"Balrog-9", r:2, vc:600},
    {tr:"Janus-9", en:"Janus-9", r:2, vc:750},
    {tr:"Rune Blade / Run Kilici", en:"Rune Blade", r:3, vc:1200},
    {tr:"Holy Sword Divine Order", en:"Holy Sword Divine Order", r:3, vc:1600},
    {tr:"Miracle Prism Sword", en:"Miracle Prism Sword", r:4, vc:2500}
  ],
  c: [
    {tr:"Ozel Harekat", en:"Spec Ops", r:0, vc:200},
    {tr:"Kan Lejyonu", en:"Blood Legion", r:1, vc:400},
    {tr:"Biyotehlike Ekibi", en:"Hazmat Squad", r:2, vc:700},
    {tr:"Gece Avcisi", en:"Night Stalker", r:3, vc:1100}
  ],
  w: [
    {tr:"Kullu Melek", en:"Ashen Angel", r:1, vc:450},
    {tr:"Kara Hasatci", en:"Black Reaper", r:2, vc:800},
    {tr:"Kelebek Muhafiz", en:"Butterfly Guard", r:1, vc:500},
    {tr:"Iblis Kanadi", en:"Demon Wings", r:3, vc:1300},
    {tr:"Anka Kanadi", en:"Phoenix Wings", r:3, vc:1500},
    {tr:"Seraf Kanadi", en:"Seraph Wings", r:4, vc:2200}
  ],
  p: [
    {tr:"Kirby", en:"Kirby", r:1, vc:400},
    {tr:"FTurtle", en:"FTurtle", r:0, vc:250},
    {tr:"Padrigo", en:"Padrigo", r:2, vc:650},
    {tr:"Gizemli Kedi", en:"Mystic Cat", r:3, vc:1000},
    {tr:"Kardan Adam", en:"Snowman", r:1, vc:450}
  ],
  f: [
    {tr:"Yildirim", en:"Lightning", r:1, vc:350},
    {tr:"Altin Patlama", en:"Gold Burst", r:2, vc:600},
    {tr:"Kan Cesmesi", en:"Blood Fountain", r:2, vc:650},
    {tr:"Buz Kirilmasi", en:"Ice Shatter", r:1, vc:400},
    {tr:"Bosluk Cokusu", en:"Void Collapse", r:4, vc:2000},
    {tr:"Havai Fisek", en:"Fireworks", r:0, vc:200}
  ],
  z: [
    {tr:"Plazma", en:"Plasma", r:1, vc:300},
    {tr:"Kan", en:"Blood", r:0, vc:200},
    {tr:"Toksik", en:"Toxic", r:2, vc:500},
    {tr:"Gokkusagi", en:"Rainbow", r:3, vc:900}
  ],
  cases: [
    {tr:"Bronz Kasa", en:"Bronze Case", vc:150, loot:[
      ["a200",0,24.0],["$50",0,20.0],["z2",0,12.0],["f6",0,10.0],["p2",0,9.0],["c1",0,8.0],
      ["z1",1,6.0],["f1",1,4.5],["v1",1,3.5],["w1",1,2.0],["p1",1,1.0]]},
    {tr:"Gumus Kasa", en:"Silver Case", vc:350, loot:[
      ["a500",0,18.0],["$150",1,14.0],["c2",1,12.0],["w3",1,11.0],["p5",1,10.0],["f4",1,9.0],
      ["v3",1,7.0],["k1",2,6.0],["w2",2,5.0],["f2",2,4.0],["z3",2,3.0],["p3",2,1.0]]},
    {tr:"Altin Kasa", en:"Gold Case", vc:700, loot:[
      ["$500",1,16.0],["v7",2,12.0],["k2",2,12.0],["c3",2,12.0],["f3",2,11.0],["k1",2,10.0],
      ["w4",3,7.0],["p4",3,6.0],["k3",3,5.0],["c4",3,4.0],["z4",3,3.0],["k4",3,2.0]]},
    {tr:"Kabus Kasasi", en:"Nightmare Case", vc:1200, loot:[
      ["v7",2,15.0],["$500",2,14.0],["k2",2,12.0],["w5",3,11.0],["k4",3,10.0],["k3",3,9.0],
      ["p4",3,8.0],["z4",3,7.0],["w6",4,5.0],["f5",4,5.0],["k5",4,4.0]]}
  ]
};
