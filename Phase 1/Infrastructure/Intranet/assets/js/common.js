(function (window, document) {
"use strict";
var GM = window.GrandMachinato = window.GrandMachinato || {};
GM.Data = GM.Data || {};
GM.Util = {
 byId:function(id){return document.getElementById(id);},
 clear:function(node){while(node && node.firstChild){node.removeChild(node.firstChild);}},
 text:function(tag,value,className){var el=document.createElement(tag); if(className){el.className=className;} el.appendChild(document.createTextNode(value===null||typeof value==="undefined"?"":String(value))); return el;},
 addEvent:function(el,name,fn){if(!el){return;} if(el.addEventListener){el.addEventListener(name,fn,false);}else if(el.attachEvent){el.attachEvent("on"+name,fn);}},
 hasClass:function(el,name){return (" "+el.className+" ").indexOf(" "+name+" ")>-1;},
 addClass:function(el,name){if(!GM.Util.hasClass(el,name)){el.className+=(el.className?" ":"")+name;}},
 removeClass:function(el,name){el.className=(" "+el.className+" ").replace(" "+name+" "," ").replace(/^\s+|\s+$/g,"");},
 getQuery:function(name){var q=window.location.search.substring(1).split("&"),i,p; for(i=0;i<q.length;i+=1){p=q[i].split("=");if(decodeURIComponent(p[0])===name){return decodeURIComponent((p[1]||"").replace(/\+/g," "));}} return "";},
 lower:function(value){return String(value||"").toLowerCase();},
 option:function(value,label){var o=document.createElement("option");o.value=value;o.appendChild(document.createTextNode(label));return o;},
 unique:function(items,key){var seen={},out=[],i,v;for(i=0;i<items.length;i+=1){v=items[i][key];if(!seen[v]){seen[v]=true;out.push(v);}}out.sort();return out;},
 print:function(){window.print();},
 ready:function(fn){if(document.readyState==="loading"){GM.Util.addEvent(document,"DOMContentLoaded",fn);}else{fn();}}
};
GM.Util.ready(function(){var d=GM.Util.byId("current-date"),buttons,i;if(d){try{d.innerHTML="";d.appendChild(document.createTextNode(new Date().toLocaleDateString(undefined,{weekday:"long",year:"numeric",month:"long",day:"numeric"})));}catch(e){d.innerHTML="";d.appendChild(document.createTextNode(new Date().toDateString()));}}
buttons=document.getElementsByTagName("button");for(i=0;i<buttons.length;i+=1){if((" "+buttons[i].className+" ").indexOf(" print-button ")>-1){GM.Util.addEvent(buttons[i],"click",GM.Util.print);}}
});
}(window, document));