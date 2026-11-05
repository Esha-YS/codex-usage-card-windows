'use strict';
const assert = require('node:assert/strict');
const {test} = require('node:test');
const {formatRateLimits, resolveCodexBin, CdpSession, parseArgs, isMainWindow, AppServerClient} = require('./agent.cjs');
test('Plus windows show remaining percentages, including unavailable data', () => {
  const result = formatRateLimits({rateLimitsByLimitId:{codex:{planType:'plus', primary:{usedPercent:20,windowDurationMins:300}, secondary:{usedPercent:45,windowDurationMins:10080}}}});
  assert.equal(result.mode,'dual');
  assert.deepEqual(result.rings.map(x=>x.percent),[80,55]);
  assert.equal(formatRateLimits({rateLimits:{planType:'plus'}}).rings[0].percent,null);
});
test('reject invalid ports and polling intervals', () => {
  assert.throws(()=>parseArgs(['--port','0']));
  assert.throws(()=>parseArgs(['--port','NaN']));
  assert.throws(()=>parseArgs(['--poll-ms','NaN']));
  assert.equal(parseArgs(['--port','39222']).port,39222);
});
test('CDP rejects remote hosts, credentials, wrong ports and schemes', async () => {
  for (const address of ['ws://example.com:39222/a','ws://127.0.0.1:9222/a','wss://127.0.0.1:39222/a','ws://user:pass@127.0.0.1:39222/a']) {
    await assert.rejects(new CdpSession({webSocketDebuggerUrl:address}).connect(),/configured loopback port/);
  }
});
test('only main app windows are eligible', () => {
  assert.equal(isMainWindow({url:'app://-/index.html'}),true);
  assert.equal(isMainWindow({url:'app://-/index.html?overlay=1'}),false);
  assert.equal(isMainWindow({url:'https://chatgpt.com'}),false);
});
test('explicit CLI path resolves without requiring an installed desktop app', () => {
  assert.equal(resolveCodexBin(process.execPath,'','win32'),process.execPath);
});

test('Windows bundled CLI fallback resolves from an isolated fixture', () => {
  const fs=require('node:fs'), path=require('node:path'), os=require('node:os');
  const root=fs.mkdtempSync(path.join(os.tmpdir(),'codex-card-cli-'));
  const previous=process.env.LOCALAPPDATA;
  const resourceRoot=path.join(root,'app','resources');
  const cli=path.join(resourceRoot,'codex.exe');
  try {
    fs.mkdirSync(resourceRoot,{recursive:true});fs.writeFileSync(cli,'fixture',{mode:0o755});
    process.env.LOCALAPPDATA=path.join(root,'local');
    assert.equal(resolveCodexBin(undefined,path.join(root,'app','ChatGPT.exe'),'win32'),cli);
    fs.unlinkSync(cli);
    assert.throws(()=>resolveCodexBin(undefined,path.join(root,'app','ChatGPT.exe'),'win32'));
  } finally {
    if(previous===undefined)delete process.env.LOCALAPPDATA;else process.env.LOCALAPPDATA=previous;
    if(fs.existsSync(cli))fs.unlinkSync(cli);
    fs.rmdirSync(resourceRoot);fs.rmdirSync(path.dirname(resourceRoot));fs.rmdirSync(root);
  }
});
test('real account rate-limit read (explicit opt-in)', {skip:!process.env.CODEX_CARD_LIVE_TEST}, async () => {
  const client=new AppServerClient({command:resolveCodexBin(undefined,'','win32'),requestTimeoutMs:30000});
  client.on('server-exit',()=>{});
  try {
    await client.start();
    assert.ok(client.rateLimits && typeof client.rateLimits==='object');
    const formatted=formatRateLimits(client.rateLimits);
    assert.ok(formatted.percent!==null || formatted.rings?.some(r=>r.percent!==null),'No usable quota returned');
    console.log('Live CLI quota read succeeded; account details omitted.');
  } finally {client.stop();}
});
