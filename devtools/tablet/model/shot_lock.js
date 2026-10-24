const { chromium } = require('playwright');
const P = 'l=tr&n=Vexmira&lv=60&xp=900&xn=1000&ap=4673&vc=82128&on=18&mx=32&mp=zm_vexmira&rd=1%2F30&dy=5~1~5230&pg=home';
(async () => { const b = await chromium.launch(); const pg = await (await b.newContext({ viewport: { width: 920, height: 600 } })).newPage();
 await pg.goto('file:///home/user/claude/cstrike/vexmira_web/ipad.html#' + P); await pg.waitForTimeout(900);
 await pg.evaluate(() => { document.getElementById('lockNote').textContent = ''; document.getElementById('lockTime').textContent = '21:40'; });
 const el = await pg.$('#screen'); await el.screenshot({ path: process.argv[2] }); await b.close(); })();
