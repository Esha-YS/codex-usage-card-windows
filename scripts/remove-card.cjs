'use strict';
const {CdpSession,isMainWindow}=require('./agent.cjs');
(async()=>{
  try {
    const response=await fetch('http://127.0.0.1:39222/json/list',{signal:AbortSignal.timeout(2000)});
    const targets=(await response.json()).filter(t=>t.type==='page'&&isMainWindow(t));
    await Promise.all(targets.map(async target=>{
      const session=new CdpSession(target);
      try { await session.connect();await session.evaluate('window.__codexUsageBadge?.destroy()'); }
      finally { session.close(); }
    }));
  } catch {}
})();

