
const { execSync } = require('child_process');

let original = () => {
    let reg = execSync(`grep -o 'MJ[0-9]\\+' ${process.argv[2]}`).toString().split("\n");
    let table = execSync("cut ../tables/mji.00601.csv -d, -f2,3,4,6,8,30 | grep MJ0[3]").toString().split("\n").filter(v=>v).slice(0).map((row,i) => {
        let cell = row.split(",");
        if (reg.indexOf(cell[1]) == -1) return;
        let c, jmj, u, uiv, ksk, dkw;
        [c, jmj, u, uiv, ksk, dkw] = cell;
        jmj = "jmj-" + jmj.slice(2);
        let p = [
            uiv && ("u" + uiv.split("U+").join("u").split("_").join("-u").toLowerCase()),
            ksk && ("koseki-" + ksk),
            u.split("U+").join("u").split("_").join("-u").toLowerCase(),
        ];
        let jmj0 = jmj.slice(4,7);
        let ref = p.filter(v => v).shift();
        if ("017" == jmj0 || "018" == jmj0) ref = p[1];
        if ("020" == jmj0) ref = p[0] || p[2];
        console.log([jmj, "[[" + ref + "]]", ref ? "#a":"#ho", "new" ].join("\t"));


    });
};

let toversion = () => {
    let reg = execSync(`grep -o 'MJ[0-9]\\+_to_[^,"]\\+' ${process.argv[2]}`).toString().split("\n")
        .map(key => {
            let jmj,ref;
            [jmj, ref] = key.split("_to_");
            jmj = jmj.split("MJ").join("jmj-");
            if (ref) ref = ref.split('"').join("");
            //if (!ref) return;
            console.log([jmj, "[[" + ref + "]]", ref ? "#a":"#ho", "new" ].join("\t"));

        })
    //console.log(reg);

};
toversion();
