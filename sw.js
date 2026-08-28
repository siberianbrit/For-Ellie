const CACHE="ellie-v8-4";
self.addEventListener("install",e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(["./","index.html","manifest.json","icon.png"]))));
self.addEventListener("activate",e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k))))));
self.addEventListener("fetch",e=>e.respondWith(caches.match(e.request).then(r=>r||fetch(e.request))));
self.addEventListener("push",e=>{
  let data={title:"Ellie",body:"Напоминание о лекарстве",icon:"icon.png"};
  try{ data=Object.assign(data,e.data?e.data.json():{}); }catch(_){}
  e.waitUntil(self.registration.showNotification(data.title,{body:data.body,icon:data.icon||"icon.png",badge:data.badge||"icon.png",data:data.data||{}}));
});
self.addEventListener("notificationclick",e=>{e.notification.close();e.waitUntil(clients.matchAll({type:"window",includeUncontrolled:true}).then(cs=>cs.length?cs[0].focus():clients.openWindow("./")))});