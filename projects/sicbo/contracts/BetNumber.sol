// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BetNumber is Ownable {

    event PatternUpdated(uint256 format, bool active);

    mapping(uint256 => bool) public patterns;

    constructor() {
        // Big
        patterns[452312848583266388373324160190187140051835877600158453279131187530910662656] = true;

        // Small
        patterns[904625697166532776746648320380374280103671755200316906558262375061821325312] = true;

        // Any triple
        patterns[1356938545749799165119972480570561420155507632800475359837393562592731987968] = true;

        // Specific triple
        patterns[1811018241397843937822879938261491478723170994297509432074646356324935270400] = true;
        patterns[1812785088462622322152463235762234397238998478194385051032767962526227890176] = true;
        patterns[1814551935527400706482046533262977315754825962091260669990889568727520509952] = true;
        patterns[1816318782592179090811629830763720234270653445988136288949011174928813129728] = true;
        patterns[1818085629656957475141213128264463152786480929885011907907132781130105749504] = true;
        patterns[1819852476721735859470796425765206071302308413781887526865254387331398369280] = true;

        // Double
        patterns[2263331089981110326196204098451678618775006871897667885353777543855845933056] = true;
        patterns[2265097937045888710525787395952421537290834355794543504311899150057138552832] = true;
        patterns[2266864784110667094855370693453164455806661839691419123270020756258431172608] = true;
        patterns[2268631631175445479184953990953907374322489323588294742228142362459723792384] = true;
        patterns[2270398478240223863514537288454650292838316807485170361186263968661016412160] = true;
        patterns[2272165325305002247844120585955393211354144291382045980144385574862309031936] = true;

        // Total number 4, 17
        patterns[2720944479758711867558278151144094514374325201188453195507273549990634455040] = true;
        patterns[2743913491600830863842861018653752455080082491847836241962854430607438512128] = true;

        // Total number 5, 16
        patterns[3175024175406756640261185608835024572941988562685487267744526343722837737472] = true;
        patterns[3194459493119318867886601881343196676616090885551119076283864011937056555008] = true;

        // Total number 6, 15
        patterns[3629103871054801412964093066525954631509651924182521339981779137455041019904] = true;
        patterns[3645005494637806871930342744032640898152099279254401910604873593266674597888] = true;

        // Total number 7, 14
        patterns[4083183566702846185667000524216884690077315285679555412219031931187244302336] = true;
        patterns[4095551496156294875974083606722085119688107672957684744925883174596292640768] = true;

        // Total number 8, 13
        patterns[4537263262350890958369907981907814748644978647176589484456284724919447584768] = true;
        patterns[4546097497674782880017824469411529341224116066660967579246892755925910683648] = true;

        // Total number 9, 12
        patterns[4991342957998935731072815439598744807212642008673623556693537518651650867200] = true;
        patterns[4996643499193270884061565332100973562760124460364250413567902337255528726528] = true;

        // Total number 10, 11
        patterns[5445422653646980503775722897289674865780305370170657628930790312383854149632] = true;
        patterns[5447189500711758888105306194790417784296132854067533247888911918585146769408] = true;

        // Combination
        patterns[5881847682139935014310372249484900293240598794916879852359937369151578832896] = true;
        patterns[5881854583886281804874159684240762570266051246025852022746492531675802632192] = true;
        patterns[5881861485632628595437947118996624847291503697134824193133047694200026431488] = true;
        patterns[5881868387378975386001734553752487124316956148243796363519602856724250230784] = true;
        patterns[5881875289125322176565521988508349401342408599352768533906158019248474030080] = true;
        patterns[5883621430951060189203742981741505488781878729922727641704614137877095251968] = true;
        patterns[5883628332697406979767530416497367765807331181031699812091169300401319051264] = true;
        patterns[5883635234443753770331317851253230042832783632140671982477724462925542850560] = true;
        patterns[5883642136190100560895105286009092319858236083249644152864279625449766649856] = true;
        patterns[5885395179762185364097113713998110684323158664928575431049290906602611671040] = true;
        patterns[5885402081508532154660901148753972961348611116037547601435846069126835470336] = true;
        patterns[5885408983254878945224688583509835238374063567146519771822401231651059269632] = true;
        patterns[5887168928573310538990484446254715879864438599934423220393967675328128090112] = true;
        patterns[5887175830319657329554271881010578156889891051043395390780522837852351889408] = true;
        patterns[5888942677384435713883855178511321075405718534940271009738644444053644509184] = true;

        // Single
        patterns[6334146727230507821556121540163362879241529770299093964865958231634041896960] = true;
        patterns[6335913574295286205885704837664105797757357254195969583824079837835334516736] = true;
        patterns[6337680421360064590215288135164848716273184738092845202782201444036627136512] = true;
        patterns[6339447268424842974544871432665591634789012221989720821740323050237919756288] = true;
        patterns[6341214115489621358874454730166334553304839705886596440698444656439212376064] = true;
        patterns[6342980962554399743204038027667077471820667189783472059656566262640504995840] = true;

        // Odd
        patterns[6784692728748995825599862402852807100777538164002376799186967812963659939840] = true;

        // Even
        patterns[7237005577332262213973186563042994240829374041602535252466099000494570602496] = true;
    }

    function setPattern(uint256 format, bool active)
        public
        onlyOwner
    {
        patterns[format] = active;

        emit PatternUpdated(format, active);
    }
}