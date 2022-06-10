import 'package:flutter/cupertino.dart';

// -------------------------------------------
// -          InfluxData color palet         -
// -            For more info see            -
// - https://github.com/influxdata/clockface -
// -------------------------------------------

// Grey
const grey5 = Color(0xFF07070e);
const grey15 = Color(0xFF1a1a2a);
const grey25 = Color(0xFF333346);
const grey35 = Color(0xFF4d4d60);
const grey45 = Color(0xFF68687b);
const grey55 = Color(0xFF828294);
const grey65 = Color(0xFF9e9ead);
const grey75 = Color(0xFFb9b9c5);
const grey85 = Color(0xFFd5d5dd);
const grey95 = Color(0xFFf1f1f3);
const white = Color(0xFFffffff);

// Neutrals
const obsidian = Color(0xFF07070e); // Grey5
const raven = Color(0xFF07070e); // Grey5
const kevlar = Color(0xFF07070e); // Grey5
const castle = Color(0xFF1a1a2a); // Grey15
const onyx = Color(0xFF1a1a2a); // Grey15
const pepper = Color(0xFF333346); // Grey25
const smoke = Color(0xFF333346); // Grey25
const graphite = Color(0xFF4d4d60); // Grey35
const storm = Color(0xFF68687b); // Grey45
const mountain = Color(0xFF68687b); // Grey45
const wolf = Color(0xFF828294); // Grey55
const sidewalk = Color(0xFF9e9ead); // Grey65
const forge = Color(0xFF9e9ead); // Grey65
const mist = Color(0xFFb9b9c5); // Grey75
const chromium = Color(0xFFb9b9c5); // Grey75
const platinum = Color(0xFFd5d5dd); // Grey85
const pearl = Color(0xFFd5d5dd); // Grey85
const whisper = Color(0xFFf1f1f3); // Grey95
const cloud = Color(0xFFf1f1f3); // Grey95
const ghost = Color(0xFFf1f1f3); // Grey95

// Blues
const abyss = Color(0xFF120653);
const sapphire = Color(0xFF0b3a8d);
const ocean = Color(0xFF066fc5);
const pool = Color(0xFF00a3ff);
const laser = Color(0xFF00C9FF);
const hydrogen = Color(0xFF6BDFFF);
const neutrino = Color(0xFFBEF0FF);
const yeti = Color(0xFFF0FCFF);

// Purples
const shadow = Color(0xFF2b007e);
const voidColor = Color(0xFF5c10a0);
const amethyst = Color(0xFF8e1fc3);
const star = Color(0xFFbe2ee4);
const comet = Color(0xFFce58eb);
const potassium = Color(0xFFdd84f1);
const moonstone = Color(0xFFebadf8);
const twilight = Color(0xFFfad9ff);

// Greens
const gypsy = Color(0xFF003e34);
const emerald = Color(0xFF006f49);
const viridian = Color(0xFF009f5f);
const rainforest = Color(0xFF34bb55);
const honeydew = Color(0xFF67d74e);
const krypton = Color(0xFF9bf445);
const wasabi = Color(0xFFc6f98e);
const mint = Color(0xFFf3ffd6);

// Yellows
const oak = Color(0xFF3F241F);
const topaz = Color(0xFFE85B1C);
const tiger = Color(0xFFF48D38);
const pineapple = Color(0xFFFFB94A);
const thunder = Color(0xFFFFD255);
const sulfur = Color(0xFFFFE480);
const daisy = Color(0xFFFFF6B8);
const banana = Color(0xFFFFFDDE);

// Reds
const basalt = Color(0xFF2F1F29);
const ruby = Color(0xFFBF3D5E);
const fire = Color(0xFFDC4E58);
const curacao = Color(0xFFF95F53);
const dreamsicle = Color(0xFFFF8564);
const tungsten = Color(0xFFFFB6A0);
const marmelade = Color(0xFFFFDCCF);
const flan = Color(0xFFFFF7F4);

// Brand Colors
const chartreuse = Color(0xFFD6F622);
const deeppurple = Color(0xFF13002D);
const magenta = Color(0xFFBF2FE5);
const galaxy = Color(0xFF9394FF);
const pulsar = Color(0xFF513CC6);

const beijingEclipse = [basalt, shadow];
const distantNebula = [shadow, abyss];
const spirulinaSmoothie = [abyss, gypsy];
const lASunset = [ruby, voidColor];
const polarExpress = [voidColor, sapphire];
const rebelAlliance = [sapphire, emerald];
const docScott = [fire, amethyst];
const gundamPilot = [amethyst, ocean];
const tropicalTourist = [ocean, viridian];
const desertFestival = [curacao, star];
const miyazakiSky = [star, pool];
const garageBand = [pool, rainforest];
const brooklynCowboy = [dreamsicle, comet];
const pastelGothic = [comet, laser];
const lowDifficulty = [laser, honeydew];
const synthPop = [tungsten, potassium];
const cottonCandy = [potassium, hydrogen];
const hotelBreakfast = [hydrogen, krypton];
const magicCarpet = [marmelade, moonstone];
const cruisingAltitude = [moonstone, neutrino];
const coconutLime = [neutrino, wasabi];
const pastryCafe = [flan, twilight];
const kawaiiDesu = [twilight, yeti];
const robotLogic = [yeti, mint];
const cephalopodInk = [gypsy, oak];
const jungleDusk = [emerald, topaz];
const jalapenoTaco = [viridian, tiger];
const mangoGrove = [rainforest, pineapple];
const citrusSodapop = [honeydew, thunder];
const candyApple = [krypton, sulfur];
const millennialAvocado = [wasabi, daisy];
const mintyFresh = [mint, banana];
const darkChocolate = [oak, basalt];
const savannaHeat = [topaz, ruby];
const fuyuPersimmon = [tiger, fire];
const scotchBonnet = [pineapple, curacao];
const californiaCampfire = [thunder, dreamsicle];
const justPeachy = [sulfur, tungsten];
const goldenHour = [daisy, marmelade];
const simpleCream = [banana, flan];
// Brand Gradients
const warpSpeed = [deeppurple, voidColor];
const powerStone = [voidColor, magenta];
const ominousFog = [pulsar, galaxy];
const milkyWay = [magenta, galaxy];
const lazyAfternoon = [pool, galaxy];
const nineteenEightyFour = [pool, magenta];
const radioactiveWarning = [pool, chartreuse];
const lostGalaxy = [deeppurple, pulsar];
const grapeSoda = [deeppurple, amethyst];
const lavenderLatte = [deeppurple, star];
// Single Hue Gradients
const defaultDark = [castle, smoke];
const defaultGradient = [wolf, mist];
const defaultLight = [mist, cloud];
const primaryDark = [sapphire, ocean];
const primary = [pool, laser];
const primaryLight = [laser, hydrogen];
const secondaryDark = [voidColor, amethyst];
const secondary = [star, comet];
const secondaryLight = [comet, moonstone];
const successDark = [emerald, viridian];
const success = [rainforest, pool];
const successLight = [honeydew, krypton];
const warningDark = [topaz, tiger];
const warning = [pineapple, thunder];
const warningLight = [thunder, sulfur];
const dangerDark = [ruby, fire];
const danger = [ruby, topaz];
const dangerLight = [dreamsicle, tungsten];
const info = [pool, pulsar];
