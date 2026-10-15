import{j as t,r as f,u as sn,L as Z,O as rn,c as ln,d as de,e as ce,f as on,g as dn,h as cn}from"./react-vendor-BcHDuzUM.js";import{$ as un,P as mn,W as nt,t as xn,c as pn,a as ue,S as me,R as fn,C as hn,b as gn,d as jn,e as vn,f as bn,g as yn,h as Nn,i as W,j as wn,k as Sn,l as Cn,m as kn,n as In,o as Pn,p as xe,q as Ln,r as _n,s as Dn,u as An,v as zn,T as Fn,w as $n,x as Rn,y as Vn,z as En,A as pe,D as Tn,B as fe,E as lt,F as he,G as xt,H as On,X as ge,I as Bn,J as Mn,K as ft,L as je,M as qn,N as ve,O as Un,Q as Gn,U as Wn,V as be,Y as Yn,Z as Hn,_ as Kn,a0 as Qn,a1 as Zn,a2 as Xn,a3 as Ut}from"./vendor-DQacS2b6.js";(function(){const n=document.createElement("link").relList;if(n&&n.supports&&n.supports("modulepreload"))return;for(const s of document.querySelectorAll('link[rel="modulepreload"]'))r(s);new MutationObserver(s=>{for(const l of s)if(l.type==="childList")for(const i of l.addedNodes)i.tagName==="LINK"&&i.rel==="modulepreload"&&r(i)}).observe(document,{childList:!0,subtree:!0});function a(s){const l={};return s.integrity&&(l.integrity=s.integrity),s.referrerPolicy&&(l.referrerPolicy=s.referrerPolicy),s.crossOrigin==="use-credentials"?l.credentials="include":s.crossOrigin==="anonymous"?l.credentials="omit":l.credentials="same-origin",l}function r(s){if(s.ep)return;s.ep=!0;const l=a(s);fetch(s.href,l)}})();const ye=(e,n="")=>{let a;e.index?a=n||"/":e.path?e.path.startsWith("/")?a=e.path:a=n==="/"?`/${e.path}`:`${n}/${e.path}`:a=n;const r={...e,fullPath:a},s=e.children?.flatMap(l=>ye(l,a))||[];return[r,...s]},Jn=()=>Je.flatMap(e=>ye(e)),ta=""+new URL("asagarwal-logo-BqFXz-4A.png",import.meta.url).href;function ea(){return t.jsx(un,{position:"top-right",richColors:!0})}function na(){const[e,n]=f.useState(!1),a=sn(),r=i=>a.pathname===i,s=()=>n(!e),l=Jn().filter(i=>i.handle?.showInNavigation===!0&&i.fullPath!==void 0&&i.handle?.label!==void 0).map(i=>({path:i.fullPath,label:i.handle?.label}));return t.jsxs(t.Fragment,{children:[t.jsx("nav",{className:"bg-white border-b border-gray-200",children:t.jsxs("div",{className:"max-w-7xl mx-auto px-4 sm:px-6 lg:px-8",children:[t.jsxs("div",{className:"flex justify-between items-center h-16",children:[t.jsx(Z,{to:"/",className:"flex items-center","aria-label":"asagarwal.com home",children:t.jsx("img",{src:ta,alt:"asagarwal.com",className:"h-8 w-auto"})}),t.jsx("button",{onClick:s,className:"p-2 rounded-md text-gray-700 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500","aria-label":"Toggle menu",children:t.jsxs("div",{className:"w-6 h-6 flex flex-col justify-center space-y-1.5",children:[t.jsx("span",{className:`block h-0.5 w-6 bg-current transition-all ${e?"rotate-45 translate-y-2":""}`}),t.jsx("span",{className:`block h-0.5 w-6 bg-current transition-all ${e?"opacity-0":""}`}),t.jsx("span",{className:`block h-0.5 w-6 bg-current transition-all ${e?"-rotate-45 -translate-y-2":""}`})]})})]}),e&&t.jsx("div",{className:"pb-4",children:t.jsx("div",{className:"flex flex-col space-y-2",children:l.map(i=>t.jsx(Z,{to:i.path,onClick:()=>n(!1),className:`px-3 py-2 rounded-md text-sm font-medium transition-colors ${r(i.path)?"bg-blue-100 text-blue-700":"text-gray-700 hover:bg-gray-100"}`,children:i.label},i.path))})})]})}),t.jsx(rn,{}),t.jsx(ea,{})]})}const aa=""+new URL("ashish-banner-DdynQFaE.png",import.meta.url).href,sa=""+new URL("community-members-C0D0lgCs.png",import.meta.url).href,ra="https://academy.asagarwal.com/c/blog-posts/",la="https://academy.asagarwal.com/contact#schedule-discussion",ia="radial-gradient(900px 600px at 50% 40%, rgba(87, 99, 255, 0.2), rgba(0, 0, 0, 0) 60%),radial-gradient(700px 500px at 30% 70%, rgba(120, 72, 255, 0.18), rgba(0, 0, 0, 0) 60%),radial-gradient(900px 700px at 75% 65%, rgba(32, 199, 255, 0.1), rgba(0, 0, 0, 0) 55%),linear-gradient(rgb(10, 16, 48) 0%, rgb(7, 10, 26) 100%)",oa=`
.hero-rings { opacity: 0.9; filter: drop-shadow(rgba(80,120,255,0.12) 0 0 24px); }
.hero-rings .rings circle { fill: none; stroke: rgba(255,255,255,0.09); stroke-width: 1.25; }
.hero-rings .orbit { transform-origin: 980px 420px; animation: orbit 15s linear 0s infinite; }
.hero-rings .orbit-inner { transform-origin: 980px 420px; animation: orbit 15s linear -5s infinite; }
.hero-rings .orbit-small { transform-origin: 980px 420px; animation: orbit 15s linear -10s infinite; }
.hero-rings .orbit-dot { fill: rgba(140,180,255,0.95); }
.hero-rings .orbit-glow { fill: rgba(140,180,255,0.1); }
.hero-rings .orbit-dot-inner { fill: rgba(100,160,255,0.85); }
.hero-rings .orbit-glow-inner { fill: rgba(100,160,255,0.08); }
.hero-rings .orbit-dot-small { fill: rgba(170,200,255,0.95); }
.hero-rings .orbit-glow-small { fill: rgba(170,200,255,0.1); }
@keyframes orbit { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
@media (prefers-reduced-motion: reduce) {
  .hero-rings .orbit, .hero-rings .orbit-inner, .hero-rings .orbit-small { animation: none; }
}
`;function da(){return t.jsxs("section",{className:"relative overflow-hidden text-white",style:{background:ia},children:[t.jsx("style",{children:oa}),t.jsxs("svg",{className:"hero-rings pointer-events-none absolute inset-0 h-full w-full",viewBox:"0 0 1400 900",preserveAspectRatio:"xMidYMid meet","aria-hidden":"true",children:[t.jsxs("g",{className:"rings",children:[t.jsx("circle",{cx:"980",cy:"420",r:"180"}),t.jsx("circle",{cx:"980",cy:"420",r:"260"}),t.jsx("circle",{cx:"980",cy:"420",r:"340"})]}),t.jsxs("g",{className:"orbit",children:[t.jsx("circle",{className:"orbit-glow",cx:"1320",cy:"420",r:"18"}),t.jsx("circle",{className:"orbit-dot",cx:"1320",cy:"420",r:"4"})]}),t.jsxs("g",{className:"orbit-inner",children:[t.jsx("circle",{className:"orbit-glow-inner",cx:"1240",cy:"420",r:"14"}),t.jsx("circle",{className:"orbit-dot-inner",cx:"1240",cy:"420",r:"3"})]}),t.jsxs("g",{className:"orbit-small",children:[t.jsx("circle",{className:"orbit-glow-small",cx:"1160",cy:"420",r:"11"}),t.jsx("circle",{className:"orbit-dot-small",cx:"1160",cy:"420",r:"2.5"})]})]}),t.jsx("div",{className:"relative mx-auto max-w-[1400px] px-6 lg:px-7 lg:pt-12",children:t.jsxs("div",{className:"lg:grid lg:grid-cols-[1fr_630px] lg:items-stretch",children:[t.jsxs("div",{className:"flex max-w-2xl flex-col justify-center py-16 lg:py-0",children:[t.jsx("p",{className:"inline-flex w-fit items-center rounded-full border border-white/25 bg-white/5 px-4 py-1.5 text-sm font-medium text-blue-100",children:"Agentforce Training · Advisory · Implementation"}),t.jsx("h1",{className:"mt-6 text-4xl font-extrabold leading-[1.1] tracking-tight sm:text-5xl lg:text-6xl",children:"Master Agentforce & Agentic AI in Salesforce — The Right Way"}),t.jsx("p",{className:"mt-6 max-w-xl text-lg leading-relaxed text-blue-100/85",children:"Step-by-step guidance, hands-on training, and real-world implementation support for Salesforce professionals and teams."}),t.jsxs("div",{className:"mt-8 flex flex-wrap gap-4",children:[t.jsx("a",{href:ra,target:"_blank",rel:"noreferrer noopener",className:"inline-flex items-center justify-center rounded-lg bg-[#0077d4] px-7 py-3.5 text-base font-semibold text-white shadow-lg shadow-[#0077d4]/25 transition-colors hover:bg-[#0066ba] focus:outline-none focus-visible:ring-2 focus-visible:ring-white/70",children:"Explore the Academy"}),t.jsxs("a",{href:la,target:"_blank",rel:"noreferrer noopener",className:"inline-flex items-center justify-center gap-2 rounded-lg bg-white px-7 py-3.5 text-base font-semibold text-gray-900 shadow-lg transition-colors hover:bg-gray-100 focus:outline-none focus-visible:ring-2 focus-visible:ring-white/70",children:[t.jsx(mn,{className:"size-4"}),"Schedule a Discussion"]})]}),t.jsxs("div",{className:"mt-12 flex gap-4",children:[t.jsx("span",{className:"w-1 shrink-0 rounded-full bg-[#0077d4]"}),t.jsxs("div",{children:[t.jsx("p",{className:"text-2xl font-bold text-white",children:"7.5K+ Subscribers/Members"}),t.jsxs("div",{className:"mt-3 flex items-center gap-3",children:[t.jsx("img",{src:sa,alt:"Community members",className:"h-10 w-auto"}),t.jsx("span",{className:"max-w-xs text-sm leading-snug text-blue-100/70",children:"Trusted by thousands of Salesforce professionals across roles, industries, and regions"})]})]})]})]}),t.jsx("div",{className:"hidden lg:flex lg:items-end lg:justify-center",children:t.jsx("img",{src:aa,alt:"Ashish Agarwal",className:"pointer-events-none h-[620px] w-[620px] max-w-full select-none object-contain object-bottom"})})]})})]})}function ca(){return t.jsx("div",{className:"max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12",children:t.jsxs("div",{className:"text-center",children:[t.jsx("h1",{className:"text-4xl font-bold text-gray-900 mb-4",children:"404"}),t.jsx("p",{className:"text-lg text-gray-600 mb-8",children:"Page not found"}),t.jsx(Z,{to:"/",className:"inline-block px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors",children:"Go to Home"})]})})}const ua=`query SearchAccounts(
	$first: Int
	$after: String
	$where: Account_Filter
	$orderBy: Account_OrderBy
) {
	uiapi {
		query {
			Account(first: $first, after: $after, where: $where, orderBy: $orderBy) {
				edges {
					node {
						Id
						Name @optional {
							value
							displayValue
						}
						Industry @optional {
							value
							displayValue
						}
						Type @optional {
							value
							displayValue
						}
						Phone @optional {
							value
							displayValue
						}
						Owner @optional {
							Name @optional {
								value
								displayValue
							}
						}
						AnnualRevenue @optional {
							value
							displayValue
						}
					}
				}
				pageInfo {
					hasNextPage
					hasPreviousPage
					endCursor
					startCursor
				}
				totalCount
			}
		}
	}
}
`,ma=`query DistinctAccountIndustries {
	uiapi {
		aggregate {
			Account(groupBy: { Industry: { group: true } }) {
				edges {
					node {
						aggregate @optional {
							Industry @optional {
								value
								displayValue
								label
							}
						}
					}
				}
			}
		}
	}
}
`,xa=`query DistinctAccountTypes {
	uiapi {
		aggregate {
			Account(groupBy: { Type: { group: true } }) {
				edges {
					node {
						aggregate @optional {
							Type @optional {
								value
								displayValue
								label
							}
						}
					}
				}
			}
		}
	}
}
`;async function Ne(e,n,a={}){const{where:r,orderBy:s,first:l=20,after:i}=a,o=await nt(),u={first:l,after:i,where:r,orderBy:s},d=await o.graphql.query({query:e,variables:u});if(d.errors?.length)throw new Error(d.errors.map(h=>h.message).join("; "));const m=d.data?.uiapi?.query?.[n];if(!m)throw new Error(`No ${n} data returned`);return m}async function ht(e,n,a){const s=await(await nt()).graphql.query({query:e});if(s.errors?.length)throw new Error(s.errors.map(u=>u.message).join("; "));return(s.data?.uiapi?.aggregate?.[n]?.edges??[]).map(u=>{const d=u?.node?.aggregate?.[a],x=d?.value;return x?{value:x,label:d.label??d.displayValue??x}:null}).filter(u=>u!==null)}async function pa(e={}){return Ne(ua,"Account",e)}async function fa(){return ht(ma,"Account","Industry")}async function ha(){return ht(xa,"Account","Type")}function M(e,n){const[a,r]=f.useState(null),[s,l]=f.useState(!0),[i,o]=f.useState(null),[u,d]=f.useState(0),x=f.useRef(e);f.useEffect(()=>{x.current=e});const[m,h]=f.useState(n);(n.length!==m.length||n.some((v,g)=>v!==m[g]))&&(h(n),d(v=>v+1),s||l(!0),i!==null&&o(null)),f.useEffect(()=>{let v=!1;return x.current().then(g=>{v||r(g)}).catch(g=>{console.error(g),v||o(g instanceof Error?g.message:"An error occurred")}).finally(()=>{v||l(!1)}),()=>{v=!0}},[u]);const j=f.useCallback(()=>{o(null),l(!0),d(v=>v+1)},[]);return{data:a,loading:s,error:i,reload:j}}function p(e){return e?.displayValue!=null?e.displayValue:e?.value!=null?String(e.value):null}function Gt(e){const a=[[e.city,e.state].filter(Boolean).join(", "),e.postalCode].filter(Boolean).join(" "),r=[e.street,a,e.country].filter(Boolean);return r.length===0?null:r}function pt(e,...n){return e?new Date(e).toLocaleString(...n):null}const et="f.",we="q",Se="sort",Ce="dir",ke="ps",Ie="page";function ga(e,n,a,r){const s=new URLSearchParams;for(const l of e){if(l.type==="search"){l.value&&s.set(we,l.value);continue}l.value!==void 0&&l.value!==""&&s.set(`${et}${l.field}`,l.value),l.min!==void 0&&l.min!==""&&s.set(`${et}${l.field}.min`,l.min),l.max!==void 0&&l.max!==""&&s.set(`${et}${l.field}.max`,l.max)}return n&&(s.set(Se,n.field),s.set(Ce,n.direction)),a!==void 0&&s.set(ke,String(a)),r!==void 0&&r>0&&s.set(Ie,String(r+1)),s}function ja(e,n){const a=[];for(const m of n){const{field:h,label:j,type:v}=m;if(v==="search"){const D=e.get(we);D&&a.push({field:h,label:j,type:"search",value:D});continue}const g=e.get(`${et}${h}`)??void 0,S=e.get(`${et}${h}.min`)??void 0,y=e.get(`${et}${h}.max`)??void 0;(g!==void 0&&g!==""||(S!==void 0&&S!==""||y!==void 0&&y!==""))&&a.push({field:h,label:j,type:v,value:g,min:S,max:y})}let r=null;const s=e.get(Se),l=e.get(Ce);s&&(r={field:s,direction:l==="DESC"?"DESC":"ASC"});const i=e.get(ke),o=i?parseInt(i,10):void 0,u=e.get(Ie),d=u?parseInt(u,10):1,x=!isNaN(d)&&d>1?d-1:0;return{filters:a,sort:r,pageSize:o&&!isNaN(o)?o:void 0,pageIndex:x}}function va(e,n){const a=new Map(n.map(s=>[s.field,s])),r=[];for(const s of e){const l=ba(s,a.get(s.field));l&&r.push(l)}if(r.length!==0)return r.length===1?r[0]:{and:r}}function Wt(e){return`${e}T00:00:00.000Z`}function Yt(e){return`${e}T23:59:59.999Z`}function ba(e,n){const{field:a,type:r,value:s,min:l,max:i}=e;switch(r){case"text":return s?{[a]:{like:`%${s}%`}}:null;case"picklist":return s?{[a]:{eq:s}}:null;case"numeric":{if(!l&&!i)return null;const o={};return l&&(o.gte=Number(l)),i&&(o.lte=Number(i)),{[a]:o}}case"boolean":return s===void 0||s===""?null:{[a]:{eq:s==="true"}};case"multipicklist":{if(!s)return null;const o=s.split(",");return o.length===1?{[a]:{eq:o[0]}}:{[a]:{in:o}}}case"date":{if(!l&&!i)return null;const o=s??(l?"gte":"lte"),u=l??i;return{[a]:{[o]:{value:u}}}}case"daterange":{if(!l&&!i)return null;const o=[];return l&&o.push({[a]:{gte:{value:l}}}),i&&o.push({[a]:{lte:{value:i}}}),o.length===1?o[0]:{and:o}}case"datetime":{if(!l&&!i)return null;const o=s??(l?"gte":"lte"),u=l??i,d=o==="gte"||o==="gt"?Wt(u):Yt(u);return{[a]:{[o]:{value:d}}}}case"datetimerange":{if(!l&&!i)return null;const o=[];return l&&o.push({[a]:{gte:{value:Wt(l)}}}),i&&o.push({[a]:{lte:{value:Yt(i)}}}),o.length===1?o[0]:{and:o}}case"search":{if(!s)return null;const o=n?.searchFields??[];if(o.length===0)return null;const u=o.map(d=>{const x=d.split(".");let m={like:`%${s}%`};for(let h=x.length-1;h>=0;h--)m={[x[h]]:m};return m});return u.length===1?u[0]:{or:u}}default:return null}}var Pe=(e=>(e.First="FIRST",e.Last="LAST",e))(Pe||{}),zt=(e=>(e.Asc="ASC",e.Desc="DESC",e))(zt||{});function ya(e){if(e)return{[e.field]:{order:e.direction==="ASC"?zt.Asc:zt.Desc,nulls:Pe.Last}}}const Na=300;function Ft(e,n){let a;return(...r)=>{clearTimeout(a),a=setTimeout(()=>e(...r),n)}}const Ht=300;function Le(e,n,a){const r=a?.defaultPageSize??10,s=f.useMemo(()=>a?.validPageSizes??[r],[a?.validPageSizes,r]),[l,i]=ln(),o=f.useMemo(()=>ja(l,e),[]),[u,d]=f.useState(o.filters),[x,m]=f.useState(o.sort),h=f.useCallback(P=>s.includes(P)?P:r,[s,r]),[j,v]=f.useState(h(o.pageSize??r)),[g,S]=f.useState(o.pageIndex),[y,w]=f.useState(void 0),C=f.useRef([]),D=f.useCallback((P,I,A,R)=>{const O=ga(P,I,A,R);i(O,{replace:!0})},[i]),E=f.useRef(Ft(D,Ht));f.useEffect(()=>{E.current=Ft(D,Ht)},[D]);const T=f.useRef({filters:u,sort:x,pageSize:j,pageIndex:g});f.useEffect(()=>{T.current={filters:u,sort:x,pageSize:j,pageIndex:g}});const F=f.useCallback(()=>{S(0),w(void 0),C.current=[]},[]),at=f.useCallback((P,I)=>{const{sort:A,pageSize:R}=T.current;d(O=>{const B=O.filter(Ct=>Ct.field!==P);return I&&B.push(I),E.current(B,A,R),B}),F()},[F]),st=f.useCallback(P=>{const{sort:I,pageSize:A}=T.current;d(R=>{const O=R.filter(B=>B.field!==P);return E.current(O,I,A),O}),F()},[F]),ut=f.useCallback(P=>{const{filters:I,pageSize:A}=T.current;m(P),E.current(I,P,A),F()},[F]),$=f.useCallback(()=>{d([]),m(null),F(),D([],null,r,0),v(r)},[D,F,r]),L=f.useCallback(P=>{C.current=[...C.current,P],w(P),S(I=>{const A=I+1,{filters:R,sort:O,pageSize:B}=T.current;return E.current(R,O,B,A),A})},[]),q=f.useCallback(()=>{const I=C.current.slice(0,-1);C.current=I,w(I.length>0?I[I.length-1]:void 0),S(A=>{const R=Math.max(0,A-1),{filters:O,sort:B,pageSize:Ct}=T.current;return E.current(O,B,Ct,R),R})},[]),U=f.useCallback(P=>{const I=h(P),{filters:A,sort:R}=T.current;v(I),F(),E.current(A,R,I)},[F,h]),Mt=f.useMemo(()=>va(u,e),[u,e]),qt=f.useMemo(()=>ya(x),[x]),tn=f.useMemo(()=>({active:u,set:at,remove:st}),[u,at,st]),en=f.useMemo(()=>({current:x,set:ut}),[x,ut]),nn=f.useMemo(()=>({where:Mt,orderBy:qt}),[Mt,qt]),an=f.useMemo(()=>({pageSize:j,pageIndex:g,afterCursor:y,setPageSize:U,goToNextPage:L,goToPreviousPage:q}),[j,g,y,U,L,q]);return{filters:tn,sort:en,query:nn,pagination:an,resetAll:$}}function c(...e){return xn(pn(e))}const wa=ue("grid gap-0.5 rounded-lg border px-2.5 py-2 text-left text-sm has-data-[slot=alert-action]:relative has-data-[slot=alert-action]:pr-18 has-[>svg]:grid-cols-[auto_1fr] has-[>svg]:gap-x-2 *:[svg]:row-span-2 *:[svg]:translate-y-0.5 *:[svg]:text-current *:[svg:not([class*='size-'])]:size-4 w-full relative group/alert",{variants:{variant:{default:"bg-card text-card-foreground",destructive:"text-destructive bg-card *:data-[slot=alert-description]:text-destructive/90 *:[svg]:text-current"}},defaultVariants:{variant:"default"}});function gt({className:e,variant:n,...a}){return t.jsx("div",{"data-slot":"alert",role:"alert",className:c(wa({variant:n}),e),...a})}function jt({className:e,...n}){return t.jsx("div",{"data-slot":"alert-title",className:c("font-medium group-has-[>svg]/alert:col-start-2 [&_a]:hover:text-foreground [&_a]:underline [&_a]:underline-offset-3",e),...n})}function vt({className:e,...n}){return t.jsx("div",{"data-slot":"alert-description",className:c("text-muted-foreground text-sm text-balance md:text-pretty [&_p:not(:last-child)]:mb-4 [&_a]:hover:text-foreground [&_a]:underline [&_a]:underline-offset-3",e),...n})}function Y({className:e,size:n="default",...a}){return t.jsx("div",{"data-slot":"card","data-size":n,className:c("ring-foreground/10 bg-card text-card-foreground gap-4 overflow-hidden rounded-xl py-4 text-sm ring-1 has-data-[slot=card-footer]:pb-0 has-[>img:first-child]:pt-0 data-[size=sm]:gap-3 data-[size=sm]:py-3 data-[size=sm]:has-data-[slot=card-footer]:pb-0 *:[img:first-child]:rounded-t-xl *:[img:last-child]:rounded-b-xl group/card flex flex-col",e),...a})}function _e({className:e,...n}){return t.jsx("div",{"data-slot":"card-header",className:c("gap-1 rounded-t-xl px-4 group-data-[size=sm]/card:px-3 [.border-b]:pb-4 group-data-[size=sm]/card:[.border-b]:pb-3 group/card-header @container/card-header grid auto-rows-min items-start has-data-[slot=card-action]:grid-cols-[1fr_auto] has-data-[slot=card-description]:grid-rows-[auto_auto]",e),...n})}function De({className:e,...n}){return t.jsx("div",{"data-slot":"card-title",className:c("text-base leading-snug font-medium group-data-[size=sm]/card:text-sm",e),...n})}function H({className:e,...n}){return t.jsx("div",{"data-slot":"card-content",className:c("px-4 group-data-[size=sm]/card:px-3",e),...n})}const $t=ue("focus-visible:border-ring focus-visible:ring-ring/50 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive dark:aria-invalid:border-destructive/50 rounded-lg border border-transparent bg-clip-padding text-sm font-medium focus-visible:ring-3 aria-invalid:ring-3 [&_svg:not([class*='size-'])]:size-4 inline-flex items-center justify-center whitespace-nowrap transition-all disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none shrink-0 [&_svg]:shrink-0 outline-none group/button select-none",{variants:{variant:{default:"bg-primary text-primary-foreground [a]:hover:bg-primary/80",outline:"border-border bg-background hover:bg-muted hover:text-foreground dark:bg-input/30 dark:border-input dark:hover:bg-input/50 aria-expanded:bg-muted aria-expanded:text-foreground",secondary:"bg-secondary text-secondary-foreground hover:bg-secondary/80 aria-expanded:bg-secondary aria-expanded:text-secondary-foreground",ghost:"hover:bg-muted hover:text-foreground dark:hover:bg-muted/50 aria-expanded:bg-muted aria-expanded:text-foreground",destructive:"bg-destructive/10 hover:bg-destructive/20 focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40 dark:bg-destructive/20 text-destructive focus-visible:border-destructive/40 dark:hover:bg-destructive/30",link:"text-primary underline-offset-4 hover:underline"},size:{default:"h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2",xs:"h-6 gap-1 rounded-[min(var(--radius-md),10px)] px-2 text-xs in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3",sm:"h-7 gap-1 rounded-[min(var(--radius-md),12px)] px-2.5 text-[0.8rem] in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5",lg:"h-9 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-3 has-data-[icon=inline-start]:pl-3",icon:"size-8","icon-xs":"size-6 rounded-[min(var(--radius-md),10px)] in-data-[slot=button-group]:rounded-lg [&_svg:not([class*='size-'])]:size-3","icon-sm":"size-7 rounded-[min(var(--radius-md),12px)] in-data-[slot=button-group]:rounded-lg","icon-lg":"size-9"}},defaultVariants:{variant:"default",size:"default"}});function k({className:e,variant:n="default",size:a="default",asChild:r=!1,...s}){const l=r?me:"button";return t.jsx(l,{"data-slot":"button","data-variant":n,"data-size":a,className:c($t({variant:n,size:a,className:e})),...s})}function bt({...e}){return t.jsx(fn,{"data-slot":"collapsible",...e})}function yt({...e}){return t.jsx(hn,{"data-slot":"collapsible-trigger",...e})}function Nt({...e}){return t.jsx(gn,{"data-slot":"collapsible-content",...e})}function b({className:e,...n}){return t.jsx("div",{"data-slot":"skeleton",className:c("bg-accent animate-pulse rounded-md",e),...n})}const Ae=f.createContext(null);function ze({filters:e,onFilterChange:n,onFilterRemove:a,onReset:r,children:s}){return t.jsx(Ae.Provider,{value:{filters:e,onFilterChange:n,onFilterRemove:a,onReset:r},children:s})}function Fe(){const e=f.useContext(Ae);if(!e)throw new Error("useFilterField must be used within a FilterProvider");return e}function X(e){const{filters:n,onFilterChange:a,onFilterRemove:r}=Fe(),s=n.find(i=>i.field===e),l=f.useCallback(i=>{i?a(e,i):r(e)},[e,a,r]);return{value:s,onChange:l}}function Sa(){const{filters:e,onReset:n}=Fe();return{hasActiveFilters:e.length>0,resetAll:n}}function $e({children:e,...n}){const{hasActiveFilters:a,resetAll:r}=Sa();return a?t.jsx(k,{onClick:r,"aria-label":"Reset filters",variant:"destructive",...n,children:e??"Reset"}):null}function rt({className:e,type:n,...a}){return t.jsx("input",{type:n,"data-slot":"input",className:c("dark:bg-input/30 border-input focus-visible:border-ring focus-visible:ring-ring/50 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive dark:aria-invalid:border-destructive/50 disabled:bg-input/50 dark:disabled:bg-input/80 h-8 rounded-lg border bg-transparent px-2.5 py-1 text-base transition-colors file:h-6 file:text-sm file:font-medium focus-visible:ring-3 aria-invalid:ring-3 md:text-sm file:text-foreground placeholder:text-muted-foreground/70 placeholder:italic w-full min-w-0 outline-none file:inline-flex file:border-0 file:bg-transparent disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50",e),...a})}function Ca({value:e,handleChange:n,placeholder:a,className:r,iconProps:s,inputProps:l,...i}){return t.jsxs("div",{className:c("relative flex-1",r),title:a,...i,children:[t.jsx(jn,{...s,className:c("absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground",s?.className)}),t.jsx(rt,{type:"text",value:e,onChange:o=>n(o.target.value),placeholder:a,...l,className:c("pl-9",l?.className)})]})}function wt({className:e,...n}){return t.jsx(vn,{"data-slot":"label",className:c("gap-2 text-sm leading-none font-medium group-data-[disabled=true]:opacity-50 peer-disabled:opacity-50 flex items-center select-none group-data-[disabled=true]:pointer-events-none peer-disabled:cursor-not-allowed",e),...n})}function J({label:e,htmlFor:n,helpText:a,error:r,className:s,children:l,...i}){return t.jsxs("div",{className:c("space-y-1",s),...i,children:[t.jsx(wt,{htmlFor:n,children:e}),l,t.jsx("div",{className:"min-h-4",children:r?t.jsx("p",{className:"text-xs text-destructive",children:r}):a&&t.jsx("p",{className:"text-xs text-muted-foreground",children:a})})]})}function Tt(e,n=Na){const a=f.useRef(e),r=f.useRef(null);return f.useEffect(()=>{a.current=e}),f.useEffect(()=>{r.current=Ft((...s)=>{a.current(...s)},n)},[n]),f.useCallback((...s)=>{r.current?.(...s)},[])}function Re({field:e,label:n,placeholder:a,className:r,...s}){const{value:l,onChange:i}=X(e),[o,u]=f.useState(l?.value??""),d=l?.value??"",[x,m]=f.useState(d);x!==d&&(m(d),u(d));const h=Tt(j=>{i(j?{field:e,label:n,type:"search",value:j}:void 0)});return t.jsx(J,{label:n,htmlFor:`filter-${e}`,className:r,...s,children:t.jsx(Ca,{value:o,handleChange:j=>{u(j),h(j)},placeholder:a,inputProps:{id:`filter-${e}`}})})}function Rt({field:e,label:n,placeholder:a,helpText:r,className:s,...l}){const{value:i,onChange:o}=X(e);return t.jsx(J,{label:n,htmlFor:`filter-${e}`,helpText:r,className:s,...l,children:t.jsx(ka,{field:e,label:n,placeholder:a,value:i,onChange:o})})}function ka({field:e,label:n,value:a,onChange:r,className:s,...l}){const[i,o]=f.useState(a?.value??""),u=a?.value??"",[d,x]=f.useState(u);d!==u&&(x(u),o(u));const m=Tt(h=>{r(h?{field:e,label:n,type:"text",value:h}:void 0)});return t.jsx(rt,{id:`filter-${e}`,type:"text",placeholder:l.placeholder??`Filter by ${n.toLowerCase()}...`,value:i,onChange:h=>{o(h.target.value),m(h.target.value)},className:c(s),...l})}function it({...e}){return t.jsx(bn,{"data-slot":"select",...e})}function ot({...e}){return t.jsx(wn,{"data-slot":"select-value",...e})}function dt({className:e,size:n="default",children:a,...r}){return t.jsxs(yn,{"data-slot":"select-trigger","data-size":n,className:c("border-input data-placeholder:text-muted-foreground dark:bg-input/30 dark:hover:bg-input/50 focus-visible:border-ring focus-visible:ring-ring/50 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive dark:aria-invalid:border-destructive/50 gap-1.5 rounded-lg border bg-transparent py-2 pr-2 pl-2.5 text-sm transition-colors select-none focus-visible:ring-3 aria-invalid:ring-3 data-[size=default]:h-8 data-[size=sm]:h-7 data-[size=sm]:rounded-[min(var(--radius-md),10px)] *:data-[slot=select-value]:gap-1.5 [&_svg:not([class*='size-'])]:size-4 flex w-fit items-center justify-between whitespace-nowrap outline-none disabled:cursor-not-allowed disabled:opacity-50 *:data-[slot=select-value]:line-clamp-1 *:data-[slot=select-value]:flex *:data-[slot=select-value]:items-center [&_svg]:pointer-events-none [&_svg]:shrink-0",e),...r,children:[a,t.jsx(Nn,{asChild:!0,children:t.jsx(W,{className:"text-muted-foreground size-4 pointer-events-none"})})]})}function ct({className:e,children:n,position:a="item-aligned",align:r="center",...s}){return t.jsx(Sn,{children:t.jsxs(Cn,{"data-slot":"select-content","data-align-trigger":a==="item-aligned",className:c("bg-popover text-popover-foreground data-open:animate-in data-closed:animate-out data-closed:fade-out-0 data-open:fade-in-0 data-closed:zoom-out-95 data-open:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 ring-foreground/10 min-w-36 rounded-lg shadow-md ring-1 duration-100 relative z-50 max-h-(--radix-select-content-available-height) origin-(--radix-select-content-transform-origin) overflow-x-hidden overflow-y-auto data-[align-trigger=true]:animate-none",a==="popper"&&"data-[side=bottom]:translate-y-1 data-[side=left]:-translate-x-1 data-[side=right]:translate-x-1 data-[side=top]:-translate-y-1",e),position:a,align:r,...s,children:[t.jsx(Ia,{}),t.jsx(kn,{"data-position":a,className:c("data-[position=popper]:h-(--radix-select-trigger-height) data-[position=popper]:w-full data-[position=popper]:min-w-(--radix-select-trigger-width)",a==="popper"&&""),children:n}),t.jsx(Pa,{})]})})}function G({className:e,children:n,...a}){return t.jsxs(In,{"data-slot":"select-item",className:c("focus:bg-accent focus:text-accent-foreground not-data-[variant=destructive]:focus:**:text-accent-foreground gap-1.5 rounded-md py-1 pr-8 pl-1.5 text-sm [&_svg:not([class*='size-'])]:size-4 *:[span]:last:flex *:[span]:last:items-center *:[span]:last:gap-2 relative flex w-full cursor-default items-center outline-hidden select-none data-disabled:pointer-events-none data-disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:shrink-0",e),...a,children:[t.jsx("span",{className:"pointer-events-none absolute right-2 flex size-4 items-center justify-center",children:t.jsx(Pn,{children:t.jsx(xe,{className:"pointer-events-none"})})}),t.jsx(Ln,{children:n})]})}function Ia({className:e,...n}){return t.jsx(_n,{"data-slot":"select-scroll-up-button",className:c("bg-popover z-10 flex cursor-default items-center justify-center py-1 [&_svg:not([class*='size-'])]:size-4",e),...n,children:t.jsx(Dn,{})})}function Pa({className:e,...n}){return t.jsx(An,{"data-slot":"select-scroll-down-button",className:c("bg-popover z-10 flex cursor-default items-center justify-center py-1 [&_svg:not([class*='size-'])]:size-4",e),...n,children:t.jsx(W,{})})}const kt="__all__";function Ve({field:e,label:n,options:a,helpText:r,className:s,...l}){const{value:i,onChange:o}=X(e);return t.jsx(J,{label:n,htmlFor:`filter-${e}`,helpText:r,className:s,...l,children:t.jsx(La,{field:e,label:n,options:a,value:i,onChange:o})})}function La({field:e,label:n,options:a,value:r,onChange:s,triggerProps:l,contentProps:i}){return t.jsxs(it,{value:r?.value??kt,onValueChange:o=>{s(o===kt?void 0:{field:e,label:n,type:"picklist",value:o})},children:[t.jsx(dt,{id:`filter-${e}`,...l,className:c("w-full",l?.className),children:t.jsx(ot,{placeholder:`Select ${n.toLowerCase()}`})}),t.jsxs(ct,{...i,children:[t.jsx(G,{value:kt,children:"All"}),a.map(o=>t.jsx(G,{value:o.value,children:o.label},o.value))]})]})}function Ee({...e}){return t.jsx(zn,{"data-slot":"popover",...e})}function Ot({...e}){return t.jsx(Fn,{"data-slot":"popover-trigger",...e})}function Te({className:e,align:n="center",sideOffset:a=4,...r}){return t.jsx($n,{children:t.jsx(Rn,{"data-slot":"popover-content",align:n,sideOffset:a,className:c("bg-popover text-popover-foreground data-open:animate-in data-closed:animate-out data-closed:fade-out-0 data-open:fade-in-0 data-closed:zoom-out-95 data-open:zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2 ring-foreground/10 flex flex-col gap-2.5 rounded-lg p-2.5 text-sm shadow-md ring-1 duration-100 z-50 w-72 origin-(--radix-popover-content-transform-origin) outline-hidden",e),...r})})}function _a({className:e,...n}){return t.jsx(Vn,{"data-slot":"checkbox",className:c("border-input dark:bg-input/30 data-checked:bg-primary data-checked:text-primary-foreground dark:data-checked:bg-primary data-checked:border-primary aria-invalid:aria-checked:border-primary aria-invalid:border-destructive dark:aria-invalid:border-destructive/50 focus-visible:border-ring focus-visible:ring-ring/50 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 flex size-4 items-center justify-center rounded-[4px] border transition-colors group-has-disabled/field:opacity-50 focus-visible:ring-3 aria-invalid:ring-3 peer relative shrink-0 outline-none after:absolute after:-inset-x-3 after:-inset-y-2 disabled:cursor-not-allowed disabled:opacity-50",e),...n,children:t.jsx(En,{"data-slot":"checkbox-indicator",className:"[&>svg]:size-3.5 grid place-content-center text-current transition-none",children:t.jsx(xe,{})})})}function Oe({field:e,label:n,options:a,helpText:r,className:s,...l}){const{value:i,onChange:o}=X(e),u=i?.value?i.value.split(","):[],d=u.length===0?`Select ${n.toLowerCase()}`:u.length===1?a.find(m=>m.value===u[0])?.label??u[0]:`${u.length} selected`;function x(m){const h=u.includes(m)?u.filter(j=>j!==m):[...u,m];h.length===0?o(void 0):o({field:e,label:n,type:"multipicklist",value:h.join(",")})}return t.jsx(J,{label:n,helpText:r,className:s,...l,children:t.jsxs(Ee,{children:[t.jsx(Ot,{asChild:!0,children:t.jsxs(k,{variant:"outline",role:"combobox",className:c("w-full justify-between font-normal",u.length===0&&"text-muted-foreground"),children:[t.jsx("span",{className:"truncate",children:d}),t.jsx(W,{className:"ml-2 h-4 w-4 shrink-0 opacity-50"})]})}),t.jsx(Te,{className:"p-2",align:"start",children:t.jsx("div",{className:"max-h-48 overflow-y-auto space-y-1",children:a.map(m=>{const h=`filter-${e}-${m.value}`;return t.jsxs("div",{className:"flex items-center gap-2 rounded px-1 py-0.5 hover:bg-accent",children:[t.jsx(_a,{id:h,checked:u.includes(m.value),onCheckedChange:()=>x(m.value)}),t.jsx(wt,{htmlFor:h,className:"text-sm font-normal cursor-pointer w-full",children:m.label})]},m.value)})})})]})})}function Be({field:e,label:n,helpText:a,min:r,max:s,className:l,...i}){const{value:o,onChange:u}=X(e);return t.jsx(Da,{field:e,label:n,helpText:a,value:o,onChange:u,min:r,max:s,className:l,...i})}function Da({field:e,label:n,helpText:a,value:r,onChange:s,min:l,max:i,className:o,...u}){const[d,x]=f.useState(r?.min??""),[m,h]=f.useState(r?.max??""),j=r?.min??"",v=r?.max??"",[g,S]=f.useState(j),[y,w]=f.useState(v);g!==j&&(S(j),x(j)),y!==v&&(w(v),h(v));const C=$=>{if($==="")return!1;const L=Number($);return l!=null&&L<l||i!=null&&L>i},D=C(d),E=C(m),T=d!==""&&m!==""&&Number(d)>Number(m),F=D||E||T,at=Tt(($,L)=>{if(!$&&!L){s(void 0);return}const q=$!==""?Number($):null,U=L!==""?Number(L):null;q!=null&&U!=null&&q>U||q!=null&&(l!=null&&q<l||i!=null&&q>i)||U!=null&&(l!=null&&U<l||i!=null&&U>i)||s({field:e,label:n,type:"numeric",min:$,max:L})}),st=l!=null&&i!=null?`${l}–${i}`:l!=null?`${l} or more`:i!=null?`${i} or less`:null,ut=T?"Min must not exceed max":(D||E)&&st?`Value must be between ${st}`:void 0;return t.jsx(J,{label:n,helpText:a,error:ut,className:o,...u,children:t.jsxs("div",{className:"flex gap-2",children:[t.jsx(rt,{type:"number",placeholder:"Min",value:d,min:l,max:i,onChange:$=>{const L=$.target.value;x(L),at(L,m)},"aria-label":`${n} minimum`,"aria-invalid":F||void 0}),t.jsx(rt,{type:"number",placeholder:"Max",value:m,min:l,max:i,onChange:$=>{const L=$.target.value;h(L),at(d,L)},"aria-label":`${n} maximum`,"aria-invalid":F||void 0})]})})}function Aa({className:e,classNames:n,showOutsideDays:a=!0,captionLayout:r="label",buttonVariant:s="ghost",locale:l,formatters:i,components:o,...u}){const d=pe();return t.jsx(Tn,{showOutsideDays:a,className:c("p-2 [--cell-radius:var(--radius-md)] [--cell-size:--spacing(7)] group/calendar bg-background in-data-[slot=card-content]:bg-transparent in-data-[slot=popover-content]:bg-transparent",String.raw`rtl:**:[.rdp-button\_next>svg]:rotate-180`,String.raw`rtl:**:[.rdp-button\_previous>svg]:rotate-180`,e),captionLayout:r,locale:l,formatters:{formatMonthDropdown:x=>x.toLocaleString(l?.code,{month:"short"}),...i},classNames:{root:c("w-fit",d.root),months:c("relative flex flex-col gap-4 md:flex-row",d.months),month:c("flex w-full flex-col gap-4",d.month),nav:c("absolute inset-x-0 top-0 flex w-full items-center justify-between gap-1",d.nav),button_previous:c($t({variant:s}),"size-(--cell-size) p-0 select-none aria-disabled:opacity-50",d.button_previous),button_next:c($t({variant:s}),"size-(--cell-size) p-0 select-none aria-disabled:opacity-50",d.button_next),month_caption:c("flex h-(--cell-size) w-full items-center justify-center px-(--cell-size)",d.month_caption),dropdowns:c("flex h-(--cell-size) w-full items-center justify-center gap-1.5 text-sm font-medium",d.dropdowns),dropdown_root:c("cn-calendar-dropdown-root relative rounded-(--cell-radius)",d.dropdown_root),dropdown:c("absolute inset-0 bg-popover opacity-0",d.dropdown),caption_label:c("font-medium select-none",r==="label"?"text-sm":"cn-calendar-caption-label flex items-center gap-1 rounded-(--cell-radius) text-sm [&>svg]:size-3.5 [&>svg]:text-muted-foreground",d.caption_label),table:"w-full border-collapse",weekdays:c("flex",d.weekdays),weekday:c("flex-1 rounded-(--cell-radius) text-[0.8rem] font-normal text-muted-foreground select-none",d.weekday),week:c("mt-2 flex w-full",d.week),week_number_header:c("w-(--cell-size) select-none",d.week_number_header),week_number:c("text-[0.8rem] text-muted-foreground select-none",d.week_number),day:c("group/day relative aspect-square h-full w-full rounded-(--cell-radius) p-0 text-center select-none [&:last-child[data-selected=true]_button]:rounded-r-(--cell-radius)",u.showWeekNumber?"[&:nth-child(2)[data-selected=true]_button]:rounded-l-(--cell-radius)":"[&:first-child[data-selected=true]_button]:rounded-l-(--cell-radius)",d.day),range_start:c("relative isolate z-0 rounded-l-(--cell-radius) bg-muted after:absolute after:inset-y-0 after:right-0 after:w-4 after:bg-muted",d.range_start),range_middle:c("rounded-none",d.range_middle),range_end:c("relative isolate z-0 rounded-r-(--cell-radius) bg-muted after:absolute after:inset-y-0 after:left-0 after:w-4 after:bg-muted",d.range_end),today:c("rounded-(--cell-radius) bg-muted text-foreground data-[selected=true]:rounded-none",d.today),outside:c("text-muted-foreground aria-selected:text-muted-foreground",d.outside),disabled:c("text-muted-foreground opacity-50",d.disabled),hidden:c("invisible",d.hidden),...n},components:{Root:({className:x,rootRef:m,...h})=>t.jsx("div",{"data-slot":"calendar",ref:m,className:c(x),...h}),Chevron:({className:x,orientation:m,...h})=>m==="left"?t.jsx(fe,{className:c("cn-rtl-flip size-4",x),...h}):m==="right"?t.jsx(lt,{className:c("cn-rtl-flip size-4",x),...h}):t.jsx(W,{className:c("size-4",x),...h}),DayButton:({...x})=>t.jsx(za,{locale:l,...x}),WeekNumber:({children:x,...m})=>t.jsx("td",{...m,children:t.jsx("div",{className:"flex size-(--cell-size) items-center justify-center text-center",children:x})}),...o},...u})}function za({className:e,day:n,modifiers:a,locale:r,...s}){const l=pe(),i=f.useRef(null);return f.useEffect(()=>{a.focused&&i.current?.focus()},[a.focused]),t.jsx(k,{ref:i,variant:"ghost",size:"icon","data-day":n.date.toLocaleDateString(r?.code),"data-selected-single":a.selected&&!a.range_start&&!a.range_end&&!a.range_middle,"data-range-start":a.range_start,"data-range-end":a.range_end,"data-range-middle":a.range_middle,className:c("relative isolate z-10 flex aspect-square size-auto w-full min-w-(--cell-size) flex-col gap-1 border-0 leading-none font-normal group-data-[focused=true]/day:relative group-data-[focused=true]/day:z-10 group-data-[focused=true]/day:border-ring group-data-[focused=true]/day:ring-[3px] group-data-[focused=true]/day:ring-ring/50 data-[range-end=true]:rounded-(--cell-radius) data-[range-end=true]:rounded-r-(--cell-radius) data-[range-end=true]:bg-primary data-[range-end=true]:text-primary-foreground data-[range-middle=true]:rounded-none data-[range-middle=true]:bg-muted data-[range-middle=true]:text-foreground data-[range-start=true]:rounded-(--cell-radius) data-[range-start=true]:rounded-l-(--cell-radius) data-[range-start=true]:bg-primary data-[range-start=true]:text-primary-foreground data-[selected-single=true]:bg-primary data-[selected-single=true]:text-primary-foreground dark:hover:text-foreground [&>span]:text-xs [&>span]:opacity-70",l.day,e),...s})}function Me({...e}){return t.jsx(Ee,{"data-slot":"date-picker",...e})}function Fa({className:e,children:n,date:a,placeholder:r="Pick a date",dateFormat:s="PPP",...l}){return t.jsx(Ot,{asChild:!0,children:t.jsx(k,{variant:"outline","data-slot":"date-picker-trigger","data-empty":!a,className:c("w-[280px] justify-start text-left font-normal data-[empty=true]:text-muted-foreground",e),...l,children:n??t.jsxs(t.Fragment,{children:[t.jsx(he,{}),a?xt(a,s):t.jsx("span",{children:r})]})})})}function qe({className:e,...n}){return t.jsx(Te,{"data-slot":"date-picker-content",className:c("w-auto p-0",e),...n})}function $a({className:e,children:n,dateRange:a,placeholder:r="Pick a date",dateFormat:s="LLL dd, y",...l}){const i=a?.from!=null;return t.jsx(Ot,{asChild:!0,children:t.jsx(k,{variant:"outline","data-slot":"date-picker-range-trigger","data-empty":!i,className:c("justify-start text-left font-normal data-[empty=true]:text-muted-foreground",e),...l,children:n??t.jsxs(t.Fragment,{children:[t.jsx(he,{}),a?.from?a.to?t.jsxs(t.Fragment,{children:[xt(a.from,s)," –"," ",xt(a.to,s)]}):xt(a.from,s):t.jsx("span",{children:r})]})})})}function Ue(e){return t.jsx(Aa,{"data-slot":"date-picker-calendar",...e})}const Ra=[{value:"gt",label:"After"},{value:"lt",label:"Before"}];function Va(e){return e==="gt"?"min":"max"}function Ge({field:e,label:n,helpText:a,filterType:r="date",className:s,...l}){const{value:i,onChange:o}=X(e),u=i?.min?"gt":"lt",[d,x]=f.useState(u),m=Vt(i?.min??i?.max);function h(g){x(g),m&&v(g,m)}function j(g){g?v(d,g):o(void 0)}function v(g,S){const y=Et(S),w=Va(g);o({field:e,label:n,type:r,value:g,min:w==="min"?y:void 0,max:w==="max"?y:void 0})}return t.jsx(J,{label:n,helpText:a,className:s,...l,children:t.jsxs("div",{className:"flex gap-2",children:[t.jsxs(it,{value:d,onValueChange:g=>h(g),children:[t.jsx(dt,{className:"w-full flex-1",children:t.jsx(ot,{})}),t.jsx(ct,{children:Ra.map(g=>t.jsx(G,{value:g.value,children:g.label},g.value))})]}),t.jsxs(Me,{children:[t.jsx(Fa,{className:"w-full flex-2",date:m,dateFormat:"MMM do, yyyy",placeholder:"Pick a date","aria-label":n}),t.jsx(qe,{children:t.jsx(Ue,{mode:"single",captionLayout:"dropdown",selected:m,onSelect:j})})]})]})})}function Vt(e){if(!e)return;const n=On(e);return isNaN(n.getTime())?void 0:n}function Et(e){return e?e.toISOString().split("T")[0]:""}function We({field:e,label:n,helpText:a,filterType:r="daterange",className:s,...l}){const{value:i,onChange:o}=X(e),u=i?.min||i?.max?{from:Vt(i?.min),to:Vt(i?.max)}:void 0;function d(x){!x?.from&&!x?.to?o(void 0):o({field:e,label:n,type:r,min:Et(x?.from),max:Et(x?.to)})}return t.jsx(J,{label:n,helpText:a,className:s,...l,children:t.jsxs(Me,{children:[t.jsx($a,{className:"w-full",dateRange:u,placeholder:"Pick a date range","aria-label":n}),t.jsx(qe,{align:"start",children:t.jsx(Ue,{mode:"range",captionLayout:"dropdown",defaultMonth:u?.from,selected:u,onSelect:d,numberOfMonths:2})})]})})}function Ea(e){const{label:n,type:a,value:r,min:s,max:l}=e;switch(a){case"search":return`Search: ${r}`;case"text":case"picklist":return`${n}: ${r}`;case"multipicklist":{const i=r?r.split(","):[];return i.length<=2?`${n}: ${i.join(", ")}`:`${n}: ${i.length} selected`}case"boolean":return`${n}: ${r==="true"?"Yes":"No"}`;case"numeric":return s&&l?`${n}: ${s} - ${l}`:s?`${n}: >= ${s}`:`${n}: <= ${l}`;case"date":return s&&l?`${n}: ${s} to ${l}`:s?`${n}: from ${s}`:`${n}: until ${l}`;default:return n}}function Ye({filters:e,onRemove:n,className:a,buttonProps:r,...s}){return e.length===0?null:t.jsx("div",{className:c("flex flex-wrap gap-2",a),...s,children:e.map(l=>t.jsx(Ta,{filter:l,onRemove:n,...r},l.field))})}function Ta({filter:e,onRemove:n,className:a,...r}){return t.jsxs(k,{variant:"outline",size:"sm",className:c("gap-1 h-7 text-xs",a),onClick:()=>n(e.field),...r,children:[Ea(e),t.jsx(ge,{className:"h-3 w-3"})]})}const It="__none__";function He({configs:e,sort:n,onSortChange:a,className:r,labelProps:s,selectProps:l,directionButtonProps:i,...o}){return t.jsxs("div",{className:c("flex items-center gap-2",r),...o,children:[t.jsx("span",{...s,className:c("text-sm text-muted-foreground whitespace-nowrap",s?.className),children:s?.children??"Sort by"}),t.jsx(Oa,{configs:e,sort:n,onSortChange:a,...l}),n&&t.jsx(Ba,{sort:n,onSortChange:a,...i})]})}function Oa({configs:e,sort:n,onSortChange:a,triggerProps:r,contentProps:s,selectValueProps:l,selectItemProps:i}){return t.jsxs(it,{value:n?.field??It,onValueChange:o=>{a(o===It?null:{field:o,direction:n?.direction??"ASC"})},children:[t.jsx(dt,{size:"sm",...r,className:c("w-[160px]",r?.className),children:t.jsx(ot,{placeholder:"Default",...l})}),t.jsxs(ct,{...s,children:[t.jsx(G,{value:It,...i,children:"Default"}),e.map(o=>t.jsx(G,{value:o.field,...i,children:o.label},o.field))]})]})}function Ba({sort:e,onSortChange:n,className:a,...r}){return t.jsx(k,{variant:"ghost",size:"icon-sm",className:c(a),onClick:()=>n({...e,direction:e.direction==="ASC"?"DESC":"ASC"}),"aria-label":`Sort ${e.direction==="ASC"?"descending":"ascending"}`,...r,children:e.direction==="ASC"?t.jsx(Bn,{}):t.jsx(Mn,{})})}function Ma({...e}){return t.jsx("nav",{"aria-label":"breadcrumb","data-slot":"breadcrumb",...e})}function qa({className:e,...n}){return t.jsx("ol",{"data-slot":"breadcrumb-list",className:c("flex flex-wrap items-center gap-1.5 text-sm break-words text-muted-foreground sm:gap-2.5",e),...n})}function mt({className:e,...n}){return t.jsx("li",{"data-slot":"breadcrumb-item",className:c("inline-flex items-center gap-1.5",e),...n})}function Kt({asChild:e,className:n,...a}){const r=e?me:"a";return t.jsx(r,{"data-slot":"breadcrumb-link",className:c("transition-colors hover:text-foreground",n),...a})}function Qt({className:e,...n}){return t.jsx("span",{"data-slot":"breadcrumb-page",role:"link","aria-disabled":"true","aria-current":"page",className:c("font-normal text-foreground",e),...n})}function Zt({children:e,className:n,...a}){return t.jsx("li",{"data-slot":"breadcrumb-separator",role:"presentation","aria-hidden":"true",className:c("[&>svg]:size-3.5",n),...a,children:e??t.jsx(lt,{})})}function St({listPath:e,listLabel:n,recordName:a,loading:r,includeHome:s=!0,homeLabel:l="Home"}){const i=r||a;return t.jsx(Ma,{className:"mb-3",children:t.jsxs(qa,{children:[s&&t.jsx(mt,{children:t.jsx(Kt,{asChild:!0,children:t.jsx(Z,{to:"/",children:l})})}),t.jsx(Zt,{}),i?t.jsxs(t.Fragment,{children:[t.jsx(mt,{children:t.jsx(Kt,{asChild:!0,children:t.jsx(Z,{to:e,children:n})})}),t.jsx(Zt,{}),t.jsx(mt,{children:r&&!a?t.jsx(b,{className:"h-4 w-32"}):t.jsx(Qt,{children:a})})]}):t.jsx(mt,{children:t.jsx(Qt,{children:n})})]})})}function Ua({className:e,...n}){return t.jsx("nav",{role:"navigation","aria-label":"pagination","data-slot":"pagination",className:c("mx-auto flex w-full justify-center",e),...n})}function Ga({className:e,...n}){return t.jsx("ul",{"data-slot":"pagination-content",className:c("gap-0.5 flex items-center",e),...n})}function Pt({...e}){return t.jsx("li",{"data-slot":"pagination-item",...e})}function Ke({className:e,isActive:n,size:a="icon",children:r,...s}){return t.jsx(k,{asChild:!0,variant:n?"outline":"ghost",size:a,className:c(e),children:t.jsx("a",{"aria-current":n?"page":void 0,"data-slot":"pagination-link","data-active":n,...s,children:r})})}function Wa({className:e,text:n="Previous",...a}){return t.jsxs(Ke,{"aria-label":"Go to previous page",size:"default",className:c("pl-1.5!",e),...a,children:[t.jsx(fe,{"data-icon":"inline-start",className:"cn-rtl-flip"}),t.jsx("span",{className:"hidden sm:block",children:n})]})}function Ya({className:e,text:n="Next",...a}){return t.jsxs(Ke,{"aria-label":"Go to next page",size:"default",className:c("pr-1.5!",e),...a,children:[t.jsx("span",{className:"hidden sm:block",children:n}),t.jsx(lt,{"data-icon":"inline-end",className:"cn-rtl-flip"})]})}function Qe({pageIndex:e,hasNextPage:n,hasPreviousPage:a,pageSize:r,pageSizeOptions:s,onNextPage:l,onPreviousPage:i,onPageSizeChange:o,disabled:u=!1}){const d=j=>{const v=parseInt(j,10);!isNaN(v)&&v!==r&&o(v)},x=e+1,m=u||!a,h=u||!n;return t.jsxs("div",{className:"w-full grid grid-cols-1 sm:grid-cols-2 items-center justify-center gap-4 py-2",children:[t.jsxs("div",{className:"flex justify-center sm:justify-start items-center gap-2 shrink-0 row-2 sm:row-1",role:"group","aria-label":"Page size selector",children:[t.jsx(wt,{htmlFor:"page-size-select",className:"text-sm font-normal whitespace-nowrap",children:"Results per page:"}),t.jsxs(it,{value:r.toString(),onValueChange:d,disabled:u,children:[t.jsx(dt,{id:"page-size-select",className:"w-16","aria-label":"Select number of results per page",children:t.jsx(ot,{})}),t.jsx(ct,{children:s.map(j=>t.jsx(G,{value:j.toString(),children:j},j))})]})]}),t.jsx(Ua,{className:"w-full mx-0 sm:justify-end",children:t.jsxs(Ga,{children:[t.jsx(Pt,{children:t.jsx(Wa,{onClick:m?void 0:i,"aria-disabled":m,className:m?"pointer-events-none opacity-50":"cursor-pointer"})}),t.jsx(Pt,{children:t.jsxs("span",{className:"min-w-16 text-center text-sm text-muted-foreground px-2","aria-current":"page",children:["Page ",x]})}),t.jsx(Pt,{children:t.jsx(Ya,{onClick:h?void 0:l,"aria-disabled":h,className:h?"pointer-events-none opacity-50":"cursor-pointer"})})]})})]})}const Xt={defaultPageSize:7,validPageSizes:[7,14,28,42]},Ha=[{field:"search",label:"Search",type:"search",searchFields:["Name","Phone","Industry"],placeholder:"Search by name, phone, or industry..."},{field:"Name",label:"Account Name",type:"text",placeholder:"Search by name..."},{field:"Industry",label:"Industry",type:"picklist"},{field:"Type",label:"Type",type:"multipicklist"},{field:"AnnualRevenue",label:"Annual Revenue",type:"numeric"},{field:"CreatedDate",label:"Created Date",type:"datetime"},{field:"LastModifiedDate",label:"Last Modified Date",type:"datetimerange"}],Jt=[{field:"Name",label:"Name"},{field:"AnnualRevenue",label:"Annual Revenue"},{field:"Industry",label:"Industry"},{field:"CreatedDate",label:"Created Date"}];function Ka(){const[e,n]=f.useState(!0),{data:a}=M(fa,[]),{data:r}=M(ha,[]),{filters:s,sort:l,query:i,pagination:o,resetAll:u}=Le(Ha,Jt,Xt),{data:d,loading:x,error:m}=M(()=>pa({where:i.where,orderBy:i.orderBy,first:o.pageSize,after:o.afterCursor}),[i.where,i.orderBy,o.pageSize,o.afterCursor]),h=d?.pageInfo,j=d?.totalCount,v=h?.hasNextPage??!1,g=o.pageIndex>0,S=f.useMemo(()=>(d?.edges??[]).reduce((y,w)=>(w?.node&&y.push(w.node),y),[]),[d?.edges]);return t.jsxs("div",{className:"max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-6",children:[t.jsx(St,{listPath:"/accounts",listLabel:"Accounts"}),t.jsx("h1",{className:"text-2xl font-bold mb-4",children:"Search Accounts"}),t.jsxs("div",{className:"flex flex-col lg:flex-row gap-6",children:[t.jsx("aside",{className:"w-full lg:w-80 shrink-0",children:t.jsx(ze,{filters:s.active,onFilterChange:s.set,onFilterRemove:s.remove,onReset:u,children:t.jsx(Y,{children:t.jsxs(bt,{open:e,onOpenChange:n,children:[t.jsxs(_e,{className:"flex flex-row items-center justify-between space-y-0 pb-2",children:[t.jsx(De,{className:"text-base font-semibold",children:t.jsx("h2",{children:"Filters"})}),t.jsxs("div",{className:"flex items-center gap-1",children:[t.jsx($e,{variant:"destructive",size:"sm"}),t.jsx(yt,{asChild:!0,children:t.jsxs(k,{variant:"ghost",size:"icon",children:[t.jsx(W,{className:`h-4 w-4 transition-transform ${e?"":"-rotate-90"}`}),t.jsx("span",{className:"sr-only",children:"Toggle filters"})]})})]})]}),t.jsx(Nt,{children:t.jsxs(H,{className:"space-y-1 pt-0",children:[t.jsx(Re,{field:"search",label:"Search",placeholder:"Search by name, phone, or industry..."}),t.jsx(Rt,{field:"Name",label:"Account Name",placeholder:"Search by name..."}),t.jsx(Ve,{field:"Industry",label:"Industry",options:a??[]}),t.jsx(Oe,{field:"Type",label:"Type",options:r??[]}),t.jsx(Be,{field:"AnnualRevenue",label:"Annual Revenue"}),t.jsx(Ge,{field:"CreatedDate",label:"Created Date",filterType:"datetime"}),t.jsx(We,{field:"LastModifiedDate",label:"Last Modified Date",filterType:"datetimerange"})]})})]})})})}),t.jsxs("div",{className:"flex-1 min-w-0",children:[t.jsxs("div",{className:"flex flex-wrap items-center gap-2 mb-4",children:[t.jsx(He,{configs:Jt,sort:l.current,onSortChange:l.set}),t.jsx(Ye,{filters:s.active,onRemove:s.remove})]}),t.jsxs("div",{className:"min-h-132",children:[x&&t.jsxs(t.Fragment,{children:[t.jsx(b,{className:"h-5 w-30 mb-3"}),t.jsx("div",{className:"divide-y",children:Array.from({length:o.pageSize},(y,w)=>t.jsxs("div",{className:"flex items-center justify-between py-3",children:[t.jsxs("div",{className:"space-y-2",children:[t.jsx(b,{className:"h-5 w-40"}),t.jsx(b,{className:"h-4 w-28"})]}),t.jsxs("div",{className:"space-y-2 flex flex-col items-end",children:[t.jsx(b,{className:"h-4 w-24"}),t.jsx(b,{className:"h-4 w-20"})]})]},w))})]}),m&&t.jsxs(t.Fragment,{children:[t.jsx("p",{className:"text-sm text-muted-foreground mb-3",children:"0 accounts found"}),t.jsxs(gt,{variant:"destructive",role:"alert",children:[t.jsx(ft,{}),t.jsx(jt,{children:"Failed to load accounts"}),t.jsx(vt,{children:"Something went wrong while loading accounts. Please try again later."})]})]}),!x&&!m&&S.length>0&&t.jsxs(t.Fragment,{children:[t.jsx("p",{className:"text-sm text-muted-foreground mb-3",children:j!=null&&(v||g)?`${j} account${j!==1?"s":""} found`:`Showing ${S.length} account${S.length!==1?"s":""}`}),t.jsx(Qa,{nodes:S})]}),!x&&!m&&S.length===0&&t.jsxs("div",{className:"flex flex-col items-center justify-center py-16 text-center",children:[t.jsx(je,{className:"size-12 text-muted-foreground mb-4"}),t.jsx("h2",{className:"text-lg font-semibold mb-1",children:"No accounts found"}),t.jsx("p",{className:"text-sm text-muted-foreground",children:"Try adjusting your filters or search criteria."})]})]}),t.jsx(Qe,{pageIndex:o.pageIndex,hasNextPage:v,hasPreviousPage:g,pageSize:o.pageSize,pageSizeOptions:Xt.validPageSizes,onNextPage:()=>{h?.endCursor&&o.goToNextPage(h.endCursor)},onPreviousPage:o.goToPreviousPage,onPageSizeChange:o.setPageSize,disabled:x||!!m})]})]})]})}function Qa({nodes:e}){return t.jsx("ul",{className:"divide-y",children:e.map(n=>t.jsx(Za,{node:n},n.Id))})}function Za({node:e}){return t.jsx("li",{children:t.jsxs(Z,{to:`/accounts/${e.Id}`,className:"flex items-center justify-between py-3 px-3 -mx-3 rounded-md transition-colors hover:bg-accent",children:[t.jsxs("div",{children:[t.jsx("span",{className:"font-medium",children:p(e.Name)??"—"}),t.jsx("p",{className:"text-sm text-muted-foreground",children:[p(e.Industry),p(e.Type)].filter(Boolean).join(" · ")||"—"})]}),t.jsxs("div",{className:"text-right text-sm",children:[t.jsx("p",{children:p(e.Phone)??""}),t.jsx("p",{className:"text-muted-foreground",children:p(e.Owner?.Name)??""})]})]})})}const Xa=`query GetAccountDetail($id: ID!) {
	uiapi {
		query {
			Account(where: { Id: { eq: $id } }) {
				edges {
					node {
						Id
						Name @optional {
							value
							displayValue
						}
						Owner @optional {
							Name @optional {
								value
								displayValue
							}
						}
						Phone @optional {
							value
							displayValue
						}
						Fax @optional {
							value
							displayValue
						}
						Parent @optional {
							Name @optional {
								value
								displayValue
							}
						}
						Website @optional {
							value
							displayValue
						}
						Type @optional {
							value
							displayValue
						}
						NumberOfEmployees @optional {
							value
							displayValue
						}
						Industry @optional {
							value
							displayValue
						}
						AnnualRevenue @optional {
							value
							displayValue
						}
						Description @optional {
							value
							displayValue
						}
						BillingStreet @optional {
							value
							displayValue
						}
						BillingCity @optional {
							value
							displayValue
						}
						BillingState @optional {
							value
							displayValue
						}
						BillingPostalCode @optional {
							value
							displayValue
						}
						BillingCountry @optional {
							value
							displayValue
						}
						ShippingStreet @optional {
							value
							displayValue
						}
						ShippingCity @optional {
							value
							displayValue
						}
						ShippingState @optional {
							value
							displayValue
						}
						ShippingPostalCode @optional {
							value
							displayValue
						}
						ShippingCountry @optional {
							value
							displayValue
						}
						CreatedBy @optional {
							Name @optional {
								value
								displayValue
							}
						}
						CreatedDate @optional {
							value
							displayValue
						}
						LastModifiedBy @optional {
							Name @optional {
								value
								displayValue
							}
						}
						LastModifiedDate @optional {
							value
							displayValue
						}
					}
				}
			}
		}
	}
}
`;function V({className:e,orientation:n="horizontal",decorative:a=!0,...r}){return t.jsx(qn,{"data-slot":"separator",decorative:a,orientation:n,className:c("bg-border shrink-0 data-horizontal:h-px data-horizontal:w-full data-vertical:w-px data-vertical:self-stretch",e),...r})}async function Ja(e){const a=await(await nt()).graphql.query({query:Xa,variables:{id:e}});if(a.errors?.length)throw new Error(a.errors.map(r=>r.message).join("; "));return a.data?.uiapi?.query?.Account?.edges?.[0]?.node}function ts(){const{recordId:e}=de(),n=ce(),{data:a,loading:r,error:s}=M(()=>Ja(e),[e]);return t.jsxs("div",{className:"max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-6",children:[t.jsx(St,{listPath:"/accounts",listLabel:"Accounts",loading:r,recordName:a?p(a.Name)??"":s?"Error":r?void 0:"Not Found"}),r&&t.jsx(ss,{}),s&&t.jsx(ns,{onBack:()=>n(-1)}),!r&&!s&&!a&&t.jsx(as,{onBack:()=>n(-1)}),a&&t.jsx(es,{account:a})]})}function es({account:e}){const n=Gt({street:p(e.BillingStreet),city:p(e.BillingCity),state:p(e.BillingState),postalCode:p(e.BillingPostalCode),country:p(e.BillingCountry)}),a=Gt({street:p(e.ShippingStreet),city:p(e.ShippingCity),state:p(e.ShippingState),postalCode:p(e.ShippingPostalCode),country:p(e.ShippingCountry)}),r={dateStyle:"medium",timeStyle:"short"},s=pt(p(e.CreatedDate),void 0,r),l=pt(p(e.LastModifiedDate),void 0,r);return t.jsxs(t.Fragment,{children:[t.jsxs("h1",{className:"text-2xl font-bold mb-4",children:["Account: ",p(e.Name)]}),t.jsx(Y,{children:t.jsxs(H,{className:"space-y-8 pt-6",children:[t.jsx("div",{children:t.jsxs("div",{className:"space-y-4",children:[t.jsxs(K,{children:[t.jsx(_,{label:"Account Owner",children:p(e.Owner?.Name)}),t.jsx(_,{label:"Phone",children:t.jsx(te,{value:p(e.Phone)})})]}),t.jsxs(K,{children:[t.jsx(_,{label:"Account Name",children:p(e.Name)}),t.jsx(_,{label:"Fax",children:t.jsx(te,{value:p(e.Fax)})})]}),t.jsxs(K,{children:[t.jsx(_,{label:"Parent Account",children:p(e.Parent?.Name)}),t.jsx(_,{label:"Website",children:p(e.Website)})]})]})}),t.jsx(V,{}),t.jsxs(Lt,{title:"Additional Information",children:[t.jsxs(K,{children:[t.jsx(_,{label:"Type",children:p(e.Type)}),t.jsx(_,{label:"Employees",children:p(e.NumberOfEmployees)})]}),t.jsxs(K,{children:[t.jsx(_,{label:"Industry",children:p(e.Industry)}),t.jsx(_,{label:"Annual Revenue",children:p(e.AnnualRevenue)})]}),t.jsx(_,{label:"Description",children:p(e.Description)})]}),t.jsx(V,{}),t.jsx(Lt,{title:"Address Information",children:t.jsxs(K,{children:[t.jsx(_,{label:"Billing Address",children:n?n.map((i,o)=>t.jsx("div",{children:i},o)):null}),t.jsx(_,{label:"Shipping Address",children:a?a.map((i,o)=>t.jsx("div",{children:i},o)):null})]})}),t.jsx(V,{}),t.jsx(Lt,{title:"System Information",children:t.jsxs(K,{children:[t.jsx(_,{label:"Created By",children:[p(e.CreatedBy?.Name),s].filter(Boolean).join(" ")||null}),t.jsx(_,{label:"Last Modified By",children:[p(e.LastModifiedBy?.Name),l].filter(Boolean).join(" ")||null})]})})]})})]})}function te({value:e}){return e?t.jsx("a",{href:`tel:${e}`,className:"underline",children:e}):null}function _({label:e,children:n}){return t.jsxs("div",{children:[t.jsx("dt",{className:"text-sm text-muted-foreground",children:e}),t.jsx("dd",{className:"mt-0.5",children:n??"—"})]})}function K({children:e}){return t.jsx("div",{className:"grid grid-cols-2 gap-x-8 gap-y-4",children:e})}function Lt({title:e,children:n}){const[a,r]=f.useState(!0);return t.jsxs(bt,{open:a,onOpenChange:r,children:[t.jsxs(yt,{className:"flex items-center gap-2 cursor-pointer text-lg font-semibold py-2",children:[a?t.jsx(W,{className:"size-5"}):t.jsx(lt,{className:"size-5"}),e]}),t.jsx(Nt,{children:t.jsx("div",{className:"mt-2 space-y-4",children:n})})]})}function ns({onBack:e}){return t.jsxs(t.Fragment,{children:[t.jsxs(gt,{variant:"destructive",role:"alert",children:[t.jsx(ft,{}),t.jsx(jt,{children:t.jsx("h2",{children:"Failed to load account"})}),t.jsx(vt,{children:"Something went wrong while loading this account. Please try again later."})]}),t.jsxs("div",{className:"mt-4 flex gap-3",children:[t.jsx(k,{variant:"outline",onClick:e,children:"← Back"}),t.jsx(k,{variant:"outline",onClick:()=>window.location.reload(),children:"Retry"})]})]})}function as({onBack:e}){return t.jsx(Y,{children:t.jsxs(H,{className:"flex flex-col items-center justify-center py-16 text-center",children:[t.jsx(ve,{className:"size-12 text-muted-foreground mb-4"}),t.jsx("h2",{className:"text-lg font-semibold mb-1",children:"Account not found"}),t.jsx("p",{className:"text-sm text-muted-foreground mb-6",children:"The account you’re looking for doesn’t exist or may have been deleted."}),t.jsx(k,{variant:"outline",onClick:e,children:"← Go back"})]})})}function ss(){return t.jsxs(t.Fragment,{children:[t.jsx(b,{className:"h-8 w-56 mb-4"}),t.jsx(Y,{children:t.jsxs(H,{className:"space-y-8 pt-6",children:[t.jsx("div",{children:t.jsxs("div",{className:"space-y-4",children:[t.jsx(tt,{}),t.jsx(tt,{}),t.jsx(tt,{})]})}),t.jsx(V,{}),t.jsx(rs,{}),t.jsx(V,{}),t.jsxs("div",{className:"space-y-4",children:[t.jsx(b,{className:"h-7 w-48 py-2"}),t.jsxs("div",{className:"grid grid-cols-2 gap-x-8 gap-y-4",children:[t.jsxs("div",{children:[t.jsx(b,{className:"h-4 w-28 mb-1.5"}),t.jsx(b,{className:"h-5 w-44 mb-1"}),t.jsx(b,{className:"h-5 w-36 mb-1"}),t.jsx(b,{className:"h-5 w-28"})]}),t.jsxs("div",{children:[t.jsx(b,{className:"h-4 w-32 mb-1.5"}),t.jsx(b,{className:"h-5 w-44 mb-1"}),t.jsx(b,{className:"h-5 w-36 mb-1"}),t.jsx(b,{className:"h-5 w-28"})]})]})]}),t.jsx(V,{}),t.jsxs("div",{className:"space-y-4",children:[t.jsx(b,{className:"h-7 w-48 py-2"}),t.jsx(tt,{})]})]})})]})}function ee(){return t.jsxs("div",{children:[t.jsx(b,{className:"h-4 w-24 mb-1.5"}),t.jsx(b,{className:"h-5 w-40"})]})}function tt(){return t.jsxs("div",{className:"grid grid-cols-2 gap-x-8 gap-y-4",children:[t.jsx(ee,{}),t.jsx(ee,{})]})}function rs(){return t.jsxs("div",{className:"space-y-4",children:[t.jsx(b,{className:"h-7 w-48 py-2"}),t.jsx(tt,{}),t.jsx(tt,{})]})}const ls=`query SearchLeads($first: Int, $after: String, $where: Lead_Filter, $orderBy: Lead_OrderBy) {
	uiapi {
		query {
			Lead(first: $first, after: $after, where: $where, orderBy: $orderBy) {
				edges {
					node {
						Id
						Name @optional {
							value
							displayValue
						}
						Company @optional {
							value
							displayValue
						}
						Status @optional {
							value
							displayValue
						}
						Industry @optional {
							value
							displayValue
						}
						Phone @optional {
							value
							displayValue
						}
						Email @optional {
							value
							displayValue
						}
						Owner @optional {
							... on User {
								Name @optional {
									value
									displayValue
								}
							}
							... on Group {
								Name @optional {
									value
									displayValue
								}
							}
						}
						AnnualRevenue @optional {
							value
							displayValue
						}
					}
				}
				pageInfo {
					hasNextPage
					hasPreviousPage
					endCursor
					startCursor
				}
				totalCount
			}
		}
	}
}
`,is=`query DistinctLeadIndustries {
	uiapi {
		aggregate {
			Lead(groupBy: { Industry: { group: true } }) {
				edges {
					node {
						aggregate @optional {
							Industry @optional {
								value
								displayValue
								label
							}
						}
					}
				}
			}
		}
	}
}
`,os=`query DistinctLeadStatuses {
	uiapi {
		aggregate {
			Lead(groupBy: { Status: { group: true } }) {
				edges {
					node {
						aggregate @optional {
							Status @optional {
								value
								displayValue
								label
							}
						}
					}
				}
			}
		}
	}
}
`,ds=`mutation UpdateLead($input: LeadUpdateInput!) {
	uiapi {
		LeadUpdate(input: $input) {
			success
			Record {
				Id
				FirstName @optional {
					value
					displayValue
				}
				LastName @optional {
					value
					displayValue
				}
				Company @optional {
					value
					displayValue
				}
				Title @optional {
					value
					displayValue
				}
				Phone @optional {
					value
					displayValue
				}
				Email @optional {
					value
					displayValue
				}
				Website @optional {
					value
					displayValue
				}
				Status @optional {
					value
					displayValue
				}
				LeadSource @optional {
					value
					displayValue
				}
				Industry @optional {
					value
					displayValue
				}
				Rating @optional {
					value
					displayValue
				}
				NumberOfEmployees @optional {
					value
					displayValue
				}
				AnnualRevenue @optional {
					value
					displayValue
				}
				Description @optional {
					value
					displayValue
				}
			}
		}
	}
}
`,cs=`query GetLeadFieldInfo {
	uiapi {
		objectInfos(apiNames: ["Lead"]) {
			ApiName
			defaultRecordTypeId
			fields {
				ApiName
				label
				updateable
			}
		}
	}
}
`,us=`query GetLeadPicklistValues($inputs: [ObjectInfoInput!]) {
	uiapi {
		objectInfos(objectInfoInputs: $inputs) {
			fields {
				ApiName
				... on PicklistField {
					picklistValuesByRecordTypeIDs {
						recordTypeID
						picklistValues {
							value
							label
						}
					}
				}
			}
		}
	}
}
`;async function ms(e={}){return Ne(ls,"Lead",e)}async function xs(){return ht(is,"Lead","Industry")}async function ps(){return ht(os,"Lead","Status")}async function fs(e,n){const r=await(await nt()).graphql.mutate({mutation:ds,variables:{input:{Id:e,Lead:n}}});if(r.errors?.length)throw new Error(r.errors.map(l=>l.message).join("; "));const s=r.data?.uiapi?.LeadUpdate;if(!s?.success||!s.Record)throw new Error("Lead update did not complete successfully");return s.Record}async function hs(){const e=await nt(),n=await e.graphql.query({query:cs});if(n.errors?.length)throw new Error(n.errors.map(i=>i.message).join("; "));const a=n.data?.uiapi?.objectInfos?.[0],r=a?.defaultRecordTypeId??void 0,s={};for(const i of a?.fields??[])i&&(s[i.ApiName]={label:i.label??null,updateable:i.updateable,options:[]});if(!r)return s;const l=await e.graphql.query({query:us,variables:{inputs:[{apiName:"Lead",recordTypeIDs:[r]}]}});if(l.errors?.length)throw new Error(l.errors.map(i=>i.message).join("; "));for(const i of l.data?.uiapi?.objectInfos?.[0]?.fields??[]){if(!i||!("picklistValuesByRecordTypeIDs"in i))continue;const o=i.picklistValuesByRecordTypeIDs;if(!o?.length)continue;const d=((o.find(x=>x?.recordTypeID===r)??o[0])?.picklistValues??[]).map(x=>({value:x?.value??"",label:x?.label??x?.value??""})).filter(x=>x.value!=="");s[i.ApiName]?s[i.ApiName].options=d:s[i.ApiName]={label:null,updateable:!0,options:d}}return s}const ne={defaultPageSize:7,validPageSizes:[7,14,28,42]},gs=[{field:"search",label:"Search",type:"search",searchFields:["Name","Company","Email"],placeholder:"Search by name, company, or email..."},{field:"Name",label:"Lead Name",type:"text",placeholder:"Search by name..."},{field:"Company",label:"Company",type:"text",placeholder:"Search by company..."},{field:"Industry",label:"Industry",type:"picklist"},{field:"Status",label:"Status",type:"multipicklist"},{field:"AnnualRevenue",label:"Annual Revenue",type:"numeric"},{field:"CreatedDate",label:"Created Date",type:"datetime"},{field:"LastModifiedDate",label:"Last Modified Date",type:"datetimerange"}],ae=[{field:"Name",label:"Name"},{field:"Company",label:"Company"},{field:"AnnualRevenue",label:"Annual Revenue"},{field:"CreatedDate",label:"Created Date"}];function js(){const[e,n]=f.useState(!0),{data:a}=M(xs,[]),{data:r}=M(ps,[]),{filters:s,sort:l,query:i,pagination:o,resetAll:u}=Le(gs,ae,ne),{data:d,loading:x,error:m}=M(()=>ms({where:i.where,orderBy:i.orderBy,first:o.pageSize,after:o.afterCursor}),[i.where,i.orderBy,o.pageSize,o.afterCursor]),h=d?.pageInfo,j=d?.totalCount,v=h?.hasNextPage??!1,g=o.pageIndex>0,S=f.useMemo(()=>(d?.edges??[]).reduce((y,w)=>(w?.node&&y.push(w.node),y),[]),[d?.edges]);return t.jsxs("div",{className:"max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-6",children:[t.jsx(St,{listPath:"/leads",listLabel:"Leads"}),t.jsx("h1",{className:"text-2xl font-bold mb-4",children:"Search Leads"}),t.jsxs("div",{className:"flex flex-col lg:flex-row gap-6",children:[t.jsx("aside",{className:"w-full lg:w-80 shrink-0",children:t.jsx(ze,{filters:s.active,onFilterChange:s.set,onFilterRemove:s.remove,onReset:u,children:t.jsx(Y,{children:t.jsxs(bt,{open:e,onOpenChange:n,children:[t.jsxs(_e,{className:"flex flex-row items-center justify-between space-y-0 pb-2",children:[t.jsx(De,{className:"text-base font-semibold",children:t.jsx("h2",{children:"Filters"})}),t.jsxs("div",{className:"flex items-center gap-1",children:[t.jsx($e,{variant:"destructive",size:"sm"}),t.jsx(yt,{asChild:!0,children:t.jsxs(k,{variant:"ghost",size:"icon",children:[t.jsx(W,{className:`h-4 w-4 transition-transform ${e?"":"-rotate-90"}`}),t.jsx("span",{className:"sr-only",children:"Toggle filters"})]})})]})]}),t.jsx(Nt,{children:t.jsxs(H,{className:"space-y-1 pt-0",children:[t.jsx(Re,{field:"search",label:"Search",placeholder:"Search by name, company, or email..."}),t.jsx(Rt,{field:"Name",label:"Lead Name",placeholder:"Search by name..."}),t.jsx(Rt,{field:"Company",label:"Company",placeholder:"Search by company..."}),t.jsx(Ve,{field:"Industry",label:"Industry",options:a??[]}),t.jsx(Oe,{field:"Status",label:"Status",options:r??[]}),t.jsx(Be,{field:"AnnualRevenue",label:"Annual Revenue"}),t.jsx(Ge,{field:"CreatedDate",label:"Created Date",filterType:"datetime"}),t.jsx(We,{field:"LastModifiedDate",label:"Last Modified Date",filterType:"datetimerange"})]})})]})})})}),t.jsxs("div",{className:"flex-1 min-w-0",children:[t.jsxs("div",{className:"flex flex-wrap items-center gap-2 mb-4",children:[t.jsx(He,{configs:ae,sort:l.current,onSortChange:l.set}),t.jsx(Ye,{filters:s.active,onRemove:s.remove})]}),t.jsxs("div",{className:"min-h-132",children:[x&&t.jsxs(t.Fragment,{children:[t.jsx(b,{className:"h-5 w-30 mb-3"}),t.jsx("div",{className:"divide-y",children:Array.from({length:o.pageSize},(y,w)=>t.jsxs("div",{className:"flex items-center justify-between py-3",children:[t.jsxs("div",{className:"space-y-2",children:[t.jsx(b,{className:"h-5 w-40"}),t.jsx(b,{className:"h-4 w-28"})]}),t.jsxs("div",{className:"space-y-2 flex flex-col items-end",children:[t.jsx(b,{className:"h-4 w-24"}),t.jsx(b,{className:"h-4 w-20"})]})]},w))})]}),m&&t.jsxs(t.Fragment,{children:[t.jsx("p",{className:"text-sm text-muted-foreground mb-3",children:"0 leads found"}),t.jsxs(gt,{variant:"destructive",role:"alert",children:[t.jsx(ft,{}),t.jsx(jt,{children:"Failed to load leads"}),t.jsx(vt,{children:"Something went wrong while loading leads. Please try again later."})]})]}),!x&&!m&&S.length>0&&t.jsxs(t.Fragment,{children:[t.jsx("p",{className:"text-sm text-muted-foreground mb-3",children:j!=null&&(v||g)?`${j} lead${j!==1?"s":""} found`:`Showing ${S.length} lead${S.length!==1?"s":""}`}),t.jsx(vs,{nodes:S})]}),!x&&!m&&S.length===0&&t.jsxs("div",{className:"flex flex-col items-center justify-center py-16 text-center",children:[t.jsx(je,{className:"size-12 text-muted-foreground mb-4"}),t.jsx("h2",{className:"text-lg font-semibold mb-1",children:"No leads found"}),t.jsx("p",{className:"text-sm text-muted-foreground",children:"Try adjusting your filters or search criteria."})]})]}),t.jsx(Qe,{pageIndex:o.pageIndex,hasNextPage:v,hasPreviousPage:g,pageSize:o.pageSize,pageSizeOptions:ne.validPageSizes,onNextPage:()=>{h?.endCursor&&o.goToNextPage(h.endCursor)},onPreviousPage:o.goToPreviousPage,onPageSizeChange:o.setPageSize,disabled:x||!!m})]})]})]})}function vs({nodes:e}){return t.jsx("ul",{className:"divide-y",children:e.map(n=>t.jsx(bs,{node:n},n.Id))})}function bs({node:e}){return t.jsx("li",{children:t.jsxs(Z,{to:`/leads/${e.Id}`,className:"flex items-center justify-between py-3 px-3 -mx-3 rounded-md transition-colors hover:bg-accent",children:[t.jsxs("div",{children:[t.jsx("span",{className:"font-medium",children:p(e.Name)??"—"}),t.jsx("p",{className:"text-sm text-muted-foreground",children:[p(e.Company),p(e.Status)].filter(Boolean).join(" · ")||"—"})]}),t.jsxs("div",{className:"text-right text-sm",children:[t.jsx("p",{children:p(e.Phone)??""}),t.jsx("p",{className:"text-muted-foreground",children:p(e.Owner?.Name)??""})]})]})})}const ys=`query GetLeadDetail($id: ID!) {
	uiapi {
		query {
			Lead(where: { Id: { eq: $id } }) {
				edges {
					node {
						Id
						Name @optional {
							value
							displayValue
						}
						Salutation @optional {
							value
							displayValue
						}
						FirstName @optional {
							value
							displayValue
						}
						LastName @optional {
							value
							displayValue
						}
						Owner @optional {
							... on User {
								Name @optional {
									value
									displayValue
								}
							}
							... on Group {
								Name @optional {
									value
									displayValue
								}
							}
						}
						Company @optional {
							value
							displayValue
						}
						Title @optional {
							value
							displayValue
						}
						Phone @optional {
							value
							displayValue
						}
						MobilePhone @optional {
							value
							displayValue
						}
						Fax @optional {
							value
							displayValue
						}
						Email @optional {
							value
							displayValue
						}
						Website @optional {
							value
							displayValue
						}
						Status @optional {
							value
							displayValue
						}
						LeadSource @optional {
							value
							displayValue
						}
						Industry @optional {
							value
							displayValue
						}
						Rating @optional {
							value
							displayValue
						}
						NumberOfEmployees @optional {
							value
							displayValue
						}
						AnnualRevenue @optional {
							value
							displayValue
						}
						Description @optional {
							value
							displayValue
						}
						ProductInterest__c @optional {
							value
							displayValue
						}
						SICCode__c @optional {
							value
							displayValue
						}
						NumberofLocations__c @optional {
							value
							displayValue
						}
						CurrentGenerators__c @optional {
							value
							displayValue
						}
						Primary__c @optional {
							value
							displayValue
						}
						Street @optional {
							value
							displayValue
						}
						City @optional {
							value
							displayValue
						}
						State @optional {
							value
							displayValue
						}
						PostalCode @optional {
							value
							displayValue
						}
						Country @optional {
							value
							displayValue
						}
						CreatedBy @optional {
							Name @optional {
								value
								displayValue
							}
						}
						CreatedDate @optional {
							value
							displayValue
						}
						LastModifiedBy @optional {
							Name @optional {
								value
								displayValue
							}
						}
						LastModifiedDate @optional {
							value
							displayValue
						}
					}
				}
			}
		}
	}
}
`;function Ns({...e}){return t.jsx(Un,{"data-slot":"dialog",...e})}function ws({...e}){return t.jsx(Gn,{"data-slot":"dialog-trigger",...e})}function Ss({...e}){return t.jsx(Kn,{"data-slot":"dialog-portal",...e})}function Cs({className:e,...n}){return t.jsx(Qn,{"data-slot":"dialog-overlay",className:c("data-open:animate-in data-closed:animate-out data-closed:fade-out-0 data-open:fade-in-0 bg-black/10 duration-100 supports-backdrop-filter:backdrop-blur-xs fixed inset-0 isolate z-50",e),...n})}function ks({className:e,children:n,showCloseButton:a=!0,...r}){return t.jsxs(Ss,{children:[t.jsx(Cs,{}),t.jsxs(Wn,{"data-slot":"dialog-content",className:c("bg-background data-open:animate-in data-closed:animate-out data-closed:fade-out-0 data-open:fade-in-0 data-closed:zoom-out-95 data-open:zoom-in-95 ring-foreground/10 grid max-w-[calc(100%-2rem)] gap-4 rounded-xl p-4 text-sm ring-1 duration-100 sm:max-w-sm fixed top-1/2 left-1/2 z-50 w-full -translate-x-1/2 -translate-y-1/2 outline-none",e),...r,children:[n,a&&t.jsx(be,{"data-slot":"dialog-close",asChild:!0,children:t.jsxs(k,{variant:"ghost",className:"absolute top-2 right-2",size:"icon-sm",children:[t.jsx(ge,{}),t.jsx("span",{className:"sr-only",children:"Close"})]})})]})]})}function Is({className:e,...n}){return t.jsx("div",{"data-slot":"dialog-header",className:c("gap-2 flex flex-col",e),...n})}function Ps({className:e,showCloseButton:n=!1,children:a,...r}){return t.jsxs("div",{"data-slot":"dialog-footer",className:c("bg-muted/50 rounded-b-xl border-t p-4 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end",e),...r,children:[a,n&&t.jsx(be,{asChild:!0,children:t.jsx(k,{variant:"outline",children:"Close"})})]})}function Ls({className:e,...n}){return t.jsx(Yn,{"data-slot":"dialog-title",className:c("text-base leading-none font-medium",e),...n})}function _s({className:e,...n}){return t.jsx(Hn,{"data-slot":"dialog-description",className:c("text-muted-foreground *:[a]:hover:text-foreground text-sm *:[a]:underline *:[a]:underline-offset-3",e),...n})}const Ze=[{fields:[{name:"Salutation",label:"Salutation",kind:"picklist"},{name:"FirstName",label:"First Name",kind:"text"},{name:"LastName",label:"Last Name",kind:"text",required:!0},{name:"Company",label:"Company",kind:"text",required:!0},{name:"Title",label:"Title",kind:"text"},{name:"Phone",label:"Phone",kind:"text"},{name:"MobilePhone",label:"Mobile",kind:"text"},{name:"Fax",label:"Fax",kind:"text"},{name:"Email",label:"Email",kind:"email"},{name:"Website",label:"Website",kind:"url"},{name:"LeadSource",label:"Lead Source",kind:"picklist"},{name:"Industry",label:"Industry",kind:"picklist"},{name:"Status",label:"Lead Status",kind:"picklist",required:!0},{name:"Rating",label:"Rating",kind:"picklist"},{name:"AnnualRevenue",label:"Annual Revenue",kind:"number"},{name:"NumberOfEmployees",label:"No. of Employees",kind:"number"},{name:"ProductInterest__c",label:"Product Interest",kind:"picklist"},{name:"Primary__c",label:"Primary",kind:"picklist"},{name:"SICCode__c",label:"SIC Code",kind:"text"},{name:"NumberofLocations__c",label:"Number of Locations",kind:"number"},{name:"CurrentGenerators__c",label:"Current Generator(s)",kind:"text"}]},{title:"Address",fields:[{name:"Country",label:"Country",kind:"picklist"},{name:"State",label:"State/Province",kind:"picklist"},{name:"City",label:"City",kind:"text"},{name:"PostalCode",label:"Zip/Postal Code",kind:"text"},{name:"Street",label:"Street",kind:"textarea",fullWidth:!0}]},{fields:[{name:"Description",label:"Description",kind:"textarea",fullWidth:!0}]}],Bt=Ze.flatMap(e=>e.fields),Ds=new Set(["number"]),_t="__none__";function Xe(e,n){return e[n]}function se(e){const n={};for(const a of Bt){const r=Xe(e,a.name);if(a.kind==="number"){const s=r?.value;n[a.name]=s==null?"":String(s)}else if(a.kind==="picklist"){const s=r?.value;n[a.name]=s==null?"":String(s)}else n[a.name]=p(r)??""}return n}function As(e){const n={};for(const a of Bt){const r=(e[a.name]??"").trim();if(r===""){n[a.name]=void 0;continue}if(Ds.has(a.kind)){const s=Number(r);n[a.name]=Number.isFinite(s)?s:void 0}else n[a.name]=r}return n}function zs(e){const n=e.Owner;return p(n?.Name)}function re(e,n,a){const r=e[n],s=p(r?.Name),l=p(Xe(e,a)),i=[s,l].filter(Boolean);return i.length?i.join(", "):null}function Fs({lead:e,fieldInfo:n,onUpdated:a}){const[r,s]=f.useState(!1),[l,i]=f.useState(()=>se(e)),[o,u]=f.useState(!1),[d,x]=f.useState(null);function m(y){y&&(i(se(e)),x(null)),s(y)}function h(y,w){i(C=>({...C,[y]:w}))}async function j(y){y.preventDefault();const w=Bt.filter(C=>C.required&&(l[C.name]??"").trim()==="");if(w.length){x(`${w.map(C=>C.label).join(", ")} ${w.length>1?"are":"is"} required.`);return}u(!0),x(null);try{const C=await fs(e.Id,As(l));Ut.success("Lead updated"),s(!1),a?.(C)}catch(C){const D=C instanceof Error?C.message:"Failed to update lead";x(D),Ut.error(D)}finally{u(!1)}}const v=zs(e),g=re(e,"CreatedBy","CreatedDate"),S=re(e,"LastModifiedBy","LastModifiedDate");return t.jsxs(Ns,{open:r,onOpenChange:m,children:[t.jsx(ws,{asChild:!0,children:t.jsxs(k,{variant:"outline",size:"sm",children:[t.jsx(Zn,{className:"size-4"}),"Edit"]})}),t.jsx(ks,{className:"sm:max-w-3xl max-h-[90vh] overflow-y-auto",children:t.jsxs("form",{onSubmit:j,children:[t.jsxs(Is,{children:[t.jsx(Ls,{children:"Edit Lead"}),t.jsxs(_s,{children:[t.jsx("span",{className:"text-destructive",children:"*"})," = Required Information"]})]}),t.jsxs("div",{className:"space-y-6 py-4",children:[v&&t.jsx(Dt,{label:"Lead Owner",value:v}),Ze.map((y,w)=>t.jsxs("div",{className:"space-y-4",children:[y.title&&t.jsx("h3",{className:"text-sm font-semibold border-b pb-1",children:y.title}),t.jsx("div",{className:"grid grid-cols-1 sm:grid-cols-2 gap-4",children:y.fields.map(C=>t.jsx($s,{config:C,value:l[C.name]??"",options:n?.[C.name]?.options??[],onChange:h},C.name))})]},y.title??w)),t.jsxs("div",{className:"grid grid-cols-1 sm:grid-cols-2 gap-4 border-t pt-4",children:[g&&t.jsx(Dt,{label:"Created By",value:g}),S&&t.jsx(Dt,{label:"Last Modified By",value:S})]})]}),d&&t.jsx("p",{role:"alert",className:"text-sm text-destructive mb-2",children:d}),t.jsxs(Ps,{children:[t.jsx(k,{type:"button",variant:"outline",onClick:()=>s(!1),disabled:o,children:"Cancel"}),t.jsxs(k,{type:"submit",disabled:o,children:[o&&t.jsx(Xn,{className:"size-4 animate-spin"}),o?"Saving…":"Save changes"]})]})]})})]})}function $s({config:e,value:n,options:a,onChange:r}){const{name:s,label:l,kind:i,required:o,fullWidth:u}=e,d=t.jsxs(wt,{htmlFor:s,children:[l,o&&t.jsx("span",{className:"text-destructive",children:" *"})]});if(i==="picklist"&&a.length>0)return t.jsxs("div",{className:u?"sm:col-span-2 flex flex-col gap-1.5":"flex flex-col gap-1.5",children:[d,t.jsxs(it,{value:n===""?_t:n,onValueChange:m=>r(s,m===_t?"":m),children:[t.jsx(dt,{id:s,className:"w-full","aria-label":l,children:t.jsx(ot,{placeholder:"--None--"})}),t.jsxs(ct,{children:[!o&&t.jsx(G,{value:_t,children:"--None--"}),a.map(m=>t.jsx(G,{value:m.value,children:m.label},m.value))]})]})]});if(i==="textarea")return t.jsxs("div",{className:u?"sm:col-span-2 flex flex-col gap-1.5":"flex flex-col gap-1.5",children:[d,t.jsx("textarea",{id:s,name:s,className:"border-input focus-visible:border-ring focus-visible:ring-ring/50 min-h-20 w-full rounded-lg border bg-transparent px-2.5 py-1.5 text-sm outline-none focus-visible:ring-3",value:n,onChange:m=>r(s,m.target.value)})]});const x=i==="number"?"number":i==="email"?"email":i==="url"?"url":"text";return t.jsxs("div",{className:u?"sm:col-span-2 flex flex-col gap-1.5":"flex flex-col gap-1.5",children:[d,t.jsx(rt,{id:s,name:s,type:x,value:n,onChange:m=>r(s,m.target.value)})]})}function Dt({label:e,value:n}){return t.jsxs("div",{className:"flex flex-col gap-1",children:[t.jsx("span",{className:"text-sm text-muted-foreground",children:e}),t.jsx("span",{className:"text-sm",children:n})]})}async function Rs(e){const a=await(await nt()).graphql.query({query:ys,variables:{id:e},cacheControl:"no-cache"});if(a.errors?.length)throw new Error(a.errors.map(r=>r.message).join("; "));return a.data?.uiapi?.query?.Lead?.edges?.[0]?.node}function Vs(){const{recordId:e}=de(),n=ce(),{data:a,loading:r,error:s,reload:l}=M(()=>Rs(e),[e]),{data:i}=M(()=>hs(),[]);return t.jsxs("div",{className:"max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-6",children:[t.jsx(St,{listPath:"/leads",listLabel:"Leads",loading:r,recordName:a?p(a.Name)??"":s?"Error":r?void 0:"Not Found"}),r&&t.jsx(Ms,{}),s&&t.jsx(Os,{onBack:()=>n(-1)}),!r&&!s&&!a&&t.jsx(Bs,{onBack:()=>n(-1)}),a&&t.jsx(Es,{lead:a,fieldInfo:i,onUpdated:l})]})}function Es({lead:e,fieldInfo:n,onUpdated:a}){const r={dateStyle:"medium",timeStyle:"short"},s=pt(e.CreatedDate?.value,void 0,r),l=pt(e.LastModifiedDate?.value,void 0,r);return t.jsxs(t.Fragment,{children:[t.jsxs("div",{className:"flex items-center justify-between mb-4 gap-4",children:[t.jsxs("h1",{className:"text-2xl font-bold",children:["Lead: ",p(e.Name)]}),t.jsx(Fs,{lead:e,fieldInfo:n,onUpdated:a})]}),t.jsx(Y,{children:t.jsxs(H,{className:"space-y-8 pt-6",children:[t.jsx("div",{children:t.jsxs("div",{className:"space-y-4",children:[t.jsxs(z,{children:[t.jsx(N,{label:"Lead Owner",children:p(e.Owner?.Name)}),t.jsx(N,{label:"Phone",children:t.jsx(le,{value:p(e.Phone)})})]}),t.jsxs(z,{children:[t.jsx(N,{label:"Salutation",children:p(e.Salutation)}),t.jsx(N,{label:"Mobile",children:t.jsx(le,{value:p(e.MobilePhone)})})]}),t.jsxs(z,{children:[t.jsx(N,{label:"Name",children:p(e.Name)}),t.jsx(N,{label:"Fax",children:p(e.Fax)})]}),t.jsxs(z,{children:[t.jsx(N,{label:"Company",children:p(e.Company)}),t.jsx(N,{label:"Email",children:t.jsx(Ts,{value:p(e.Email)})})]}),t.jsxs(z,{children:[t.jsx(N,{label:"Title",children:p(e.Title)}),t.jsx(N,{label:"Website",children:p(e.Website)})]}),t.jsxs(z,{children:[t.jsx(N,{label:"Lead Status",children:p(e.Status)}),t.jsx(N,{label:"Rating",children:p(e.Rating)})]})]})}),t.jsx(V,{}),t.jsxs(At,{title:"Additional Information",children:[t.jsxs(z,{children:[t.jsx(N,{label:"Lead Source",children:p(e.LeadSource)}),t.jsx(N,{label:"Industry",children:p(e.Industry)})]}),t.jsxs(z,{children:[t.jsx(N,{label:"Annual Revenue",children:p(e.AnnualRevenue)}),t.jsx(N,{label:"No. of Employees",children:p(e.NumberOfEmployees)})]}),t.jsxs(z,{children:[t.jsx(N,{label:"Product Interest",children:p(e.ProductInterest__c)}),t.jsx(N,{label:"Primary",children:p(e.Primary__c)})]}),t.jsxs(z,{children:[t.jsx(N,{label:"SIC Code",children:p(e.SICCode__c)}),t.jsx(N,{label:"Number of Locations",children:p(e.NumberofLocations__c)})]}),t.jsx(z,{children:t.jsx(N,{label:"Current Generator(s)",children:p(e.CurrentGenerators__c)})}),t.jsx(N,{label:"Description",children:p(e.Description)})]}),t.jsx(V,{}),t.jsxs(At,{title:"Address Information",children:[t.jsxs(z,{children:[t.jsx(N,{label:"Country",children:p(e.Country)}),t.jsx(N,{label:"State/Province",children:p(e.State)})]}),t.jsxs(z,{children:[t.jsx(N,{label:"City",children:p(e.City)}),t.jsx(N,{label:"Zip/Postal Code",children:p(e.PostalCode)})]}),t.jsx(N,{label:"Street",children:p(e.Street)})]}),t.jsx(V,{}),t.jsx(At,{title:"System Information",children:t.jsxs(z,{children:[t.jsx(N,{label:"Created By",children:[p(e.CreatedBy?.Name),s].filter(Boolean).join(" ")||null}),t.jsx(N,{label:"Last Modified By",children:[p(e.LastModifiedBy?.Name),l].filter(Boolean).join(" ")||null})]})})]})})]})}function le({value:e}){return e?t.jsx("a",{href:`tel:${e}`,className:"underline",children:e}):null}function Ts({value:e}){return e?t.jsx("a",{href:`mailto:${e}`,className:"underline",children:e}):null}function N({label:e,children:n}){return t.jsxs("div",{children:[t.jsx("dt",{className:"text-sm text-muted-foreground",children:e}),t.jsx("dd",{className:"mt-0.5",children:n??"—"})]})}function z({children:e}){return t.jsx("div",{className:"grid grid-cols-2 gap-x-8 gap-y-4",children:e})}function At({title:e,children:n}){const[a,r]=f.useState(!0);return t.jsxs(bt,{open:a,onOpenChange:r,children:[t.jsxs(yt,{className:"flex items-center gap-2 cursor-pointer text-lg font-semibold py-2",children:[a?t.jsx(W,{className:"size-5"}):t.jsx(lt,{className:"size-5"}),e]}),t.jsx(Nt,{children:t.jsx("div",{className:"mt-2 space-y-4",children:n})})]})}function Os({onBack:e}){return t.jsxs(t.Fragment,{children:[t.jsxs(gt,{variant:"destructive",role:"alert",children:[t.jsx(ft,{}),t.jsx(jt,{children:t.jsx("h2",{children:"Failed to load lead"})}),t.jsx(vt,{children:"Something went wrong while loading this lead. Please try again later."})]}),t.jsxs("div",{className:"mt-4 flex gap-3",children:[t.jsx(k,{variant:"outline",onClick:e,children:"← Back"}),t.jsx(k,{variant:"outline",onClick:()=>window.location.reload(),children:"Retry"})]})]})}function Bs({onBack:e}){return t.jsx(Y,{children:t.jsxs(H,{className:"flex flex-col items-center justify-center py-16 text-center",children:[t.jsx(ve,{className:"size-12 text-muted-foreground mb-4"}),t.jsx("h2",{className:"text-lg font-semibold mb-1",children:"Lead not found"}),t.jsx("p",{className:"text-sm text-muted-foreground mb-6",children:"The lead you’re looking for doesn’t exist or may have been deleted."}),t.jsx(k,{variant:"outline",onClick:e,children:"← Go back"})]})})}function Ms(){return t.jsxs(t.Fragment,{children:[t.jsx(b,{className:"h-8 w-56 mb-4"}),t.jsx(Y,{children:t.jsxs(H,{className:"space-y-8 pt-6",children:[t.jsx("div",{children:t.jsxs("div",{className:"space-y-4",children:[t.jsx(Q,{}),t.jsx(Q,{}),t.jsx(Q,{}),t.jsx(Q,{})]})}),t.jsx(V,{}),t.jsx(qs,{}),t.jsx(V,{}),t.jsxs("div",{className:"space-y-4",children:[t.jsx(b,{className:"h-7 w-48 py-2"}),t.jsxs("div",{children:[t.jsx(b,{className:"h-4 w-28 mb-1.5"}),t.jsx(b,{className:"h-5 w-44 mb-1"}),t.jsx(b,{className:"h-5 w-36 mb-1"}),t.jsx(b,{className:"h-5 w-28"})]})]}),t.jsx(V,{}),t.jsxs("div",{className:"space-y-4",children:[t.jsx(b,{className:"h-7 w-48 py-2"}),t.jsx(Q,{})]})]})})]})}function ie(){return t.jsxs("div",{children:[t.jsx(b,{className:"h-4 w-24 mb-1.5"}),t.jsx(b,{className:"h-5 w-40"})]})}function Q(){return t.jsxs("div",{className:"grid grid-cols-2 gap-x-8 gap-y-4",children:[t.jsx(ie,{}),t.jsx(ie,{})]})}function qs(){return t.jsxs("div",{className:"space-y-4",children:[t.jsx(b,{className:"h-7 w-48 py-2"}),t.jsx(Q,{}),t.jsx(Q,{})]})}const Je=[{path:"/",element:t.jsx(na,{}),children:[{index:!0,element:t.jsx(da,{}),handle:{showInNavigation:!0,label:"Home"}},{path:"*",element:t.jsx(ca,{})},{path:"accounts/:recordId",element:t.jsx(ts,{})},{path:"accounts",element:t.jsx(Ka,{}),handle:{showInNavigation:!0,label:"Accounts"}},{path:"leads/:recordId",element:t.jsx(Vs,{})},{path:"leads",element:t.jsx(js,{}),handle:{showInNavigation:!0,label:"Leads"}}]}],oe=globalThis.SFDC_ENV?.basePath,Us=typeof oe=="string"?oe.replace(/\/+$/,""):void 0,Gs=on(Je,{basename:Us});dn.createRoot(document.getElementById("root")).render(t.jsx(f.StrictMode,{children:t.jsx(cn,{router:Gs})}));
