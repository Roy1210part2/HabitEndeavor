import SwiftUI

// TODO: 세계 지도 — 나중에 구체화 예정 (현재 비활성화)
// 아래 주석을 해제하면 지도 기능이 복원됩니다.

struct WorldMap2DView: View {
    let ownedCodes: Set<String>
    var body: some View { EmptyView() }
}

/*
import SwiftUI
import WebKit

// MARK: - Public View

struct WorldMap2DView: View {
    let ownedCodes: Set<String>

    var body: some View {
        WorldMapWebView(ownedCodes: ownedCodes)
            .id(ownedCodes.sorted().joined())
    }
}

// MARK: - Cross-platform WebView

#if os(iOS)
struct WorldMapWebView: UIViewRepresentable {
    let ownedCodes: Set<String>

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.defaultWebpagePreferences.allowsContentJavaScript = true
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.isOpaque = false
        wv.backgroundColor = .clear
        // JS가 pan/zoom을 처리 → 네이티브 스크롤 비활성화
        wv.scrollView.isScrollEnabled = false
        wv.scrollView.bounces = false
        wv.scrollView.pinchGestureRecognizer?.isEnabled = false
        return wv
    }

    func updateUIView(_ wv: WKWebView, context: Context) {
        wv.loadHTMLString(WorldMapHTML.make(owned: ownedCodes),
                          baseURL: URL(string: "about:blank"))
    }
}
#else
// macOS: 명시적 JS 허용 + baseURL 지정이 핵심
struct WorldMapWebView: NSViewRepresentable {
    let ownedCodes: Set<String>

    func makeNSView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.defaultWebpagePreferences.allowsContentJavaScript = true
        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.setValue(false, forKey: "drawsBackground") // 투명 배경
        return wv
    }

    func updateNSView(_ wv: WKWebView, context: Context) {
        wv.loadHTMLString(WorldMapHTML.make(owned: ownedCodes),
                          baseURL: URL(string: "about:blank"))
    }
}
#endif

// MARK: - HTML + SVG + Zoom/Pan

enum WorldMapHTML {
    static func make(owned: Set<String>) -> String {
        let ownedJS = owned.map { "'\($0)'" }.joined(separator: ",")
        return """
<!DOCTYPE html>
<html>
<head>
<meta name='viewport' content='width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no'>
<style>
*{margin:0;padding:0;box-sizing:border-box;-webkit-tap-highlight-color:transparent}
html,body{width:100%;height:100%;background:#0B1826;overflow:hidden;touch-action:none}
svg{width:100%;height:100%;display:block;cursor:grab}
svg.panning{cursor:grabbing}
#controls{position:absolute;bottom:12px;right:12px;display:flex;flex-direction:column;gap:6px;z-index:10}
.btn{width:34px;height:34px;border:none;border-radius:8px;background:rgba(255,255,255,0.15);
  color:#fff;font-size:16px;cursor:pointer;display:flex;align-items:center;justify-content:center;
  backdrop-filter:blur(8px);-webkit-backdrop-filter:blur(8px);
  transition:background 0.15s}
.btn:hover{background:rgba(255,255,255,0.28)}
.btn:active{background:rgba(255,255,255,0.38)}
</style>
</head>
<body>
<svg id='map' viewBox='0 0 1000 500' preserveAspectRatio='xMidYMid meet'>
  <defs>
    <linearGradient id='ocean' x1='0' y1='0' x2='0' y2='1'>
      <stop offset='0%' stop-color='#0B1826'/>
      <stop offset='100%' stop-color='#0D2137'/>
    </linearGradient>
  </defs>
  <rect width='1000' height='500' fill='url(#ocean)'/>
  <g stroke='#1a2d40' stroke-width='0.4' fill='none'>
    <line x1='0' y1='250' x2='1000' y2='250'/>
    <line x1='500' y1='0' x2='500' y2='500'/>
    <line x1='0' y1='125' x2='1000' y2='125'/>
    <line x1='0' y1='375' x2='1000' y2='375'/>
    <line x1='250' y1='0' x2='250' y2='500'/>
    <line x1='750' y1='0' x2='750' y2='500'/>
  </g>
  <g id='countries'></g>
</svg>

<div id='controls'>
  <button class='btn' onclick='zoom(0.7)' title='확대'>+</button>
  <button class='btn' onclick='zoom(1.4)' title='축소'>−</button>
  <button class='btn' onclick='resetView()' title='초기화' style='font-size:12px'>⊙</button>
</div>

<script>
const owned = new Set([\(ownedJS)]);
const CC = {
  asia:'#FFB800',europe:'#4488FF',
  northAmerica:'#FF5544',southAmerica:'#FF8833',
  africa:'#44CC55',oceania:'#33CCCC'
};
const CM = {
  KR:'asia',JP:'asia',CN:'asia',IN:'asia',TH:'asia',VN:'asia',SG:'asia',
  MY:'asia',ID:'asia',PH:'asia',MN:'asia',NP:'asia',BT:'asia',MV:'asia',
  SA:'asia',AE:'asia',IL:'asia',TR:'asia',
  DE:'europe',FR:'europe',GB:'europe',IT:'europe',ES:'europe',NL:'europe',
  CH:'europe',SE:'europe',NO:'europe',IS:'europe',LU:'europe',MC:'europe',
  SM:'europe',VA:'europe',LI:'europe',
  US:'northAmerica',CA:'northAmerica',MX:'northAmerica',CU:'northAmerica',JM:'northAmerica',
  BR:'southAmerica',AR:'southAmerica',CL:'southAmerica',CO:'southAmerica',PE:'southAmerica',BO:'southAmerica',
  NG:'africa',ZA:'africa',EG:'africa',KE:'africa',ET:'africa',GH:'africa',SC:'africa',
  AU:'oceania',NZ:'oceania',FJ:'oceania',TV:'oceania',PW:'oceania',NR:'oceania'
};
const C = {
  KR:[[126.0,34.8],[129.0,35.0],[130.9,37.6],[129.5,38.6],[127.8,38.6],[125.1,38.0]],
  JP:[[130.5,31.2],[131.0,33.5],[134.0,34.5],[137.0,36.5],[140.5,36.5],[141.5,38.5],[141.0,41.0],[139.5,41.5],[138.0,39.0],[133.5,35.5],[130.8,33.5]],
  CN:[[73.5,39.5],[80.0,37.5],[82.0,30.0],[88.0,27.8],[97.0,24.5],[101.0,22.0],[108.5,21.5],[117.0,22.3],[120.0,25.5],[122.0,30.0],[122.5,37.5],[121.0,42.0],[119.0,47.5],[119.0,53.0],[115.0,53.5],[95.0,49.0],[87.0,48.0],[80.0,42.5]],
  IN:[[68.0,23.0],[73.0,22.0],[77.0,8.5],[80.5,9.5],[80.0,14.5],[77.5,20.5],[80.5,22.0],[86.0,22.5],[88.5,25.0],[89.0,27.5],[87.0,26.5],[84.0,27.5],[81.0,28.0],[79.5,30.0],[77.5,32.0],[75.0,34.0],[73.5,33.0],[70.5,29.5]],
  TH:[[97.5,7.0],[100.5,6.0],[103.5,6.0],[105.0,11.0],[105.6,14.0],[104.0,15.5],[103.0,18.0],[101.0,19.5],[100.0,22.0],[98.0,22.0],[97.5,18.5],[98.0,16.0],[98.5,13.5],[97.5,11.0]],
  VN:[[102.2,22.5],[104.7,22.5],[106.0,20.5],[108.5,16.0],[109.0,12.0],[108.5,10.5],[107.5,10.5],[104.8,11.5],[105.3,14.0],[103.8,15.0],[103.5,18.0],[104.0,20.0],[102.8,21.5]],
  SG:[[103.6,1.6],[104.1,1.6],[104.1,1.1],[103.6,1.1]],
  MY:[[100.0,6.5],[103.5,6.0],[104.5,3.5],[103.8,1.8],[101.5,3.0],[100.0,4.0],[99.5,5.5]],
  ID:[[95.5,5.5],[98.0,4.0],[104.5,2.5],[106.0,-6.0],[106.5,-6.5],[106.0,-7.0],[104.0,-7.5],[96.5,-5.0]],
  PH:[[118.0,18.5],[122.5,18.5],[122.5,16.0],[122.0,14.0],[120.5,12.5],[120.0,9.5],[119.5,8.0],[116.5,8.5],[118.0,14.0]],
  MN:[[87.0,48.5],[119.0,48.5],[119.0,41.5],[111.0,38.5],[95.0,39.5],[87.0,45.5]],
  NP:[[80.0,30.5],[88.5,27.5],[88.0,26.5],[80.5,28.5]],
  BT:[[88.5,28.5],[92.5,28.5],[92.0,26.8],[88.8,26.8]],
  MV:[[72.5,5.0],[74.5,5.0],[74.5,-1.5],[72.5,-1.5]],
  SA:[[36.5,29.0],[55.0,24.0],[59.0,21.5],[56.5,17.0],[45.0,12.0],[43.0,15.0],[42.5,17.5],[38.0,18.0],[36.5,22.0]],
  AE:[[51.5,26.0],[56.5,24.5],[56.0,22.0],[51.5,23.0]],
  IL:[[34.0,33.5],[36.0,33.5],[35.5,29.5],[34.0,29.5]],
  TR:[[26.0,42.0],[36.5,42.5],[44.5,39.5],[42.5,37.0],[36.0,36.5],[28.0,37.0],[26.0,38.5]],
  DE:[[6.0,55.0],[14.5,54.5],[15.0,51.0],[12.0,48.0],[8.0,47.5],[6.0,51.0]],
  FR:[[-4.5,48.5],[8.5,48.5],[7.5,43.5],[3.0,43.0],[-1.5,43.5],[-4.5,47.5]],
  GB:[[-5.5,58.5],[2.0,56.0],[2.0,51.5],[1.0,51.5],[-1.5,50.5],[-5.5,50.0],[-5.5,52.0],[-4.5,53.5],[-3.0,58.5]],
  IT:[[7.0,44.0],[14.5,44.5],[15.5,41.0],[15.8,38.0],[13.0,37.5],[15.0,40.5],[14.0,41.5],[13.0,43.5],[7.5,43.5]],
  ES:[[-9.5,44.0],[3.5,42.5],[3.0,41.5],[0.0,40.5],[-0.5,38.0],[-2.0,36.5],[-5.5,36.0],[-9.5,37.0]],
  NL:[[3.5,53.5],[7.0,53.5],[7.0,51.0],[3.5,51.0]],
  CH:[[6.0,47.8],[10.5,47.8],[10.5,45.8],[6.0,45.8]],
  SE:[[11.0,69.0],[24.0,65.5],[24.0,59.0],[16.0,56.0],[12.5,56.0],[11.0,57.5]],
  NO:[[5.0,57.0],[5.5,62.0],[14.5,70.0],[28.0,71.0],[30.0,69.5],[25.0,67.0],[17.0,68.0],[14.5,63.5],[8.0,58.0]],
  IS:[[-24.0,66.0],[-13.5,66.5],[-13.0,64.0],[-20.5,63.0],[-24.5,64.5]],
  LU:[[5.5,50.5],[6.8,50.5],[6.8,49.2],[5.5,49.2]],
  MC:[[7.2,44.0],[7.6,44.0],[7.6,43.6],[7.2,43.6]],
  SM:[[12.2,44.1],[12.7,44.1],[12.7,43.7],[12.2,43.7]],
  VA:[[12.3,42.0],[12.6,42.0],[12.6,41.8],[12.3,41.8]],
  LI:[[9.3,47.4],[9.8,47.4],[9.8,46.9],[9.3,46.9]],
  US:[[-124.5,48.5],[-67.0,47.5],[-67.0,44.5],[-71.0,41.5],[-76.0,35.0],[-80.0,31.5],[-84.0,30.0],[-90.0,29.0],[-94.5,29.0],[-99.5,26.0],[-104.0,20.0],[-109.5,23.0],[-117.0,32.5]],
  CA:[[-141.0,70.0],[-55.0,70.0],[-53.0,47.0],[-67.0,44.5],[-83.5,46.0],[-110.0,49.0],[-122.5,49.0],[-130.0,55.0],[-141.0,59.5]],
  MX:[[-117.0,32.5],[-97.0,22.5],[-90.0,18.0],[-87.5,15.5],[-89.5,15.0],[-92.5,16.0],[-90.5,18.5],[-88.5,20.0],[-90.0,21.5],[-93.5,19.5],[-96.5,19.5],[-100.0,18.0],[-105.0,21.5],[-109.5,23.0]],
  CU:[[-85.0,23.0],[-74.5,20.0],[-75.5,19.5],[-84.5,22.0]],
  JM:[[-78.5,18.5],[-76.0,18.5],[-76.2,17.8],[-78.5,17.8]],
  BR:[[-73.5,-2.0],[-52.0,4.5],[-45.0,-1.0],[-35.0,-5.0],[-35.5,-9.0],[-36.5,-14.0],[-39.0,-16.5],[-40.5,-21.5],[-44.0,-23.0],[-48.5,-28.5],[-53.5,-34.0],[-58.0,-34.0],[-62.0,-32.0],[-64.5,-27.5],[-65.5,-22.5],[-62.0,-17.0],[-57.5,-12.5],[-58.0,-7.5],[-65.0,-0.5],[-72.0,-2.5]],
  AR:[[-73.5,-38.0],[-65.0,-23.0],[-62.5,-22.5],[-60.0,-22.5],[-57.5,-28.5],[-55.5,-34.0],[-58.0,-38.5],[-63.0,-42.0],[-66.0,-46.0],[-68.5,-55.5],[-65.5,-55.5],[-60.0,-51.0],[-57.5,-41.5],[-62.5,-38.5],[-66.0,-28.5],[-69.5,-30.5]],
  CL:[[-70.5,-17.5],[-69.5,-30.5],[-72.0,-35.0],[-73.5,-42.0],[-72.5,-50.0],[-69.0,-55.5],[-68.0,-54.5],[-71.5,-50.0],[-74.5,-40.5],[-72.5,-35.0],[-71.0,-27.5]],
  CO:[[-77.0,8.0],[-67.0,7.0],[-67.0,4.0],[-69.5,1.5],[-73.5,-0.5],[-78.0,2.5],[-79.0,7.5]],
  PE:[[-81.5,-1.0],[-78.0,2.5],[-73.5,-0.5],[-70.5,-9.5],[-68.5,-17.5],[-70.5,-18.0],[-75.5,-14.5],[-77.5,-8.0]],
  BO:[[-69.5,-10.0],[-65.5,-10.0],[-62.0,-16.0],[-60.0,-22.5],[-65.0,-23.0],[-69.5,-18.0]],
  NG:[[2.5,14.0],[14.5,14.0],[14.5,10.5],[13.5,8.5],[13.0,7.5],[8.5,4.5],[3.5,5.5],[2.5,7.5]],
  ZA:[[16.5,-29.0],[27.5,-23.0],[32.5,-26.5],[32.5,-29.5],[29.5,-30.5],[28.5,-33.5],[26.5,-34.0],[18.5,-34.5],[17.0,-33.0]],
  EG:[[25.0,31.5],[35.0,31.5],[35.0,29.0],[34.0,27.0],[34.0,22.0],[25.0,22.0]],
  KE:[[34.0,4.5],[41.5,4.5],[41.5,-1.0],[34.5,-1.0],[34.5,-4.0],[35.5,-5.0],[36.5,-5.5]],
  ET:[[33.0,15.0],[41.5,15.0],[43.5,11.5],[42.5,6.5],[40.5,4.0],[37.5,5.0],[34.5,8.5],[33.0,11.0]],
  GH:[[-3.5,11.0],[1.5,11.0],[1.5,5.5],[0.0,5.5],[-3.5,7.5]],
  SC:[[54.5,-3.0],[57.0,-3.0],[57.0,-5.5],[54.5,-5.5]],
  AU:[[114.0,-22.0],[124.0,-14.5],[132.5,-12.0],[136.0,-12.5],[139.0,-15.0],[142.0,-12.0],[145.0,-14.5],[147.5,-18.5],[149.5,-22.5],[153.5,-29.0],[151.0,-34.0],[150.0,-37.5],[146.5,-39.5],[144.0,-38.5],[141.0,-38.5],[130.0,-33.5],[125.5,-34.5],[114.0,-34.0],[113.5,-26.0]],
  NZ:[[172.5,-34.5],[177.5,-37.5],[175.5,-41.5],[171.5,-40.5]],
  FJ:[[176.5,-16.0],[179.0,-16.0],[179.0,-18.5],[176.5,-18.5]],
  TV:[[177.5,-7.0],[179.5,-7.0],[179.5,-9.0],[177.5,-9.0]],
  PW:[[133.5,7.5],[135.0,7.5],[135.0,6.5],[133.5,6.5]],
  NR:[[166.3,0.7],[167.3,0.7],[167.3,-0.3],[166.3,-0.3]]
};

function proj(lon,lat){return[(lon+180)/360*1000,(90-lat)/180*500]}
function makePath(pts){return pts.map((p,i)=>{const[x,y]=proj(p[0],p[1]);return(i===0?'M':'L')+x.toFixed(1)+','+y.toFixed(1)}).join(' ')+'Z'}

const svg=document.getElementById('map');
const g=document.getElementById('countries');

for(const[code,pts] of Object.entries(C)){
  const el=document.createElementNS('http://www.w3.org/2000/svg','path');
  el.id=code;el.setAttribute('d',makePath(pts));
  if(owned.has(code)){
    const col=CC[CM[code]]||'#888';
    el.setAttribute('fill',col);el.setAttribute('stroke','#0B1826');el.setAttribute('stroke-width','0.6');
    el.style.filter='drop-shadow(0 0 4px '+col+')';
  }else{
    el.setAttribute('fill','#1E2D3D');el.setAttribute('stroke','#0B1826');el.setAttribute('stroke-width','0.6');
  }
  g.appendChild(el);
  if(owned.has(code)){
    const cx=pts.reduce((s,p)=>s+p[0],0)/pts.length;
    const cy=pts.reduce((s,p)=>s+p[1],0)/pts.length;
    const[mx,my]=proj(cx,cy);
    const dot=document.createElementNS('http://www.w3.org/2000/svg','circle');
    dot.setAttribute('cx',mx.toFixed(1));dot.setAttribute('cy',my.toFixed(1));
    dot.setAttribute('r','3');dot.setAttribute('fill','white');dot.setAttribute('opacity','0.8');
    g.appendChild(dot);
  }
}

// ── Zoom / Pan ──────────────────────────────────────────────
let vb={x:0,y:0,w:1000,h:500};
const MIN_W=100,MAX_W=2000;

function applyVB(){svg.setAttribute('viewBox',`${vb.x} ${vb.y} ${vb.w} ${vb.h}`)}

function zoom(factor,cx,cy){
  cx=cx??vb.x+vb.w/2;cy=cy??vb.y+vb.h/2;
  const nw=Math.max(MIN_W,Math.min(MAX_W,vb.w*factor));
  const nh=nw*0.5;
  vb.x=cx-(cx-vb.x)/vb.w*nw;
  vb.y=cy-(cy-vb.y)/vb.h*nh;
  vb.w=nw;vb.h=nh;applyVB();
}

function resetView(){vb={x:0,y:0,w:1000,h:500};applyVB()}

function svgPoint(e){
  const r=svg.getBoundingClientRect();
  return{x:(e.clientX-r.left)/r.width*vb.w+vb.x,
         y:(e.clientY-r.top)/r.height*vb.h+vb.y};
}

// Mouse wheel zoom
svg.addEventListener('wheel',e=>{
  e.preventDefault();
  const pt=svgPoint(e);
  zoom(e.deltaY>0?1.15:0.87,pt.x,pt.y);
},{passive:false});

// Mouse drag pan
let drag=null;
svg.addEventListener('mousedown',e=>{
  drag={sx:e.clientX,sy:e.clientY,vbx:vb.x,vby:vb.y};
  svg.classList.add('panning');
});
window.addEventListener('mousemove',e=>{
  if(!drag)return;
  const r=svg.getBoundingClientRect();
  vb.x=drag.vbx-(e.clientX-drag.sx)/r.width*vb.w;
  vb.y=drag.vby-(e.clientY-drag.sy)/r.height*vb.h;
  applyVB();
});
window.addEventListener('mouseup',()=>{drag=null;svg.classList.remove('panning')});

// Double click zoom-in
svg.addEventListener('dblclick',e=>{
  const pt=svgPoint(e);zoom(0.5,pt.x,pt.y);
});

// Touch pan
let touch1=null;
svg.addEventListener('touchstart',e=>{
  e.preventDefault();
  if(e.touches.length===1){
    touch1={x:e.touches[0].clientX,y:e.touches[0].clientY,vbx:vb.x,vby:vb.y};
  }else if(e.touches.length===2){
    touch1=null;
  }
},{passive:false});

svg.addEventListener('touchmove',e=>{
  e.preventDefault();
  if(e.touches.length===1&&touch1){
    const r=svg.getBoundingClientRect();
    vb.x=touch1.vbx-(e.touches[0].clientX-touch1.x)/r.width*vb.w;
    vb.y=touch1.vby-(e.touches[0].clientY-touch1.y)/r.height*vb.h;
    applyVB();
  }else if(e.touches.length===2){
    const dx=e.touches[0].clientX-e.touches[1].clientX;
    const dy=e.touches[0].clientY-e.touches[1].clientY;
    const dist=Math.hypot(dx,dy);
    if(touch1&&touch1.pinchDist){
      const factor=touch1.pinchDist/dist;
      const cx=(e.touches[0].clientX+e.touches[1].clientX)/2;
      const cy=(e.touches[0].clientY+e.touches[1].clientY)/2;
      const r=svg.getBoundingClientRect();
      zoom(factor,(cx-r.left)/r.width*vb.w+vb.x,(cy-r.top)/r.height*vb.h+vb.y);
    }
    touch1={pinchDist:dist};
  }
},{passive:false});

svg.addEventListener('touchend',e=>{if(e.touches.length===0)touch1=null},{passive:false});
</script>
</body>
</html>
"""
    }
}

#Preview {
    WorldMap2DView(ownedCodes: ["KR", "JP", "US", "DE", "AU", "BR"])
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 20))
}
*/
