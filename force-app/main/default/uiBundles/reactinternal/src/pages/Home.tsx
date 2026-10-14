import { Phone } from "lucide-react";
import ashishBanner from "@assets/images/ashish-banner.png";
import communityMembers from "@assets/images/community-members.png";

const EXPLORE_URL = "https://academy.asagarwal.com/c/blog-posts/";
const SCHEDULE_URL = "https://academy.asagarwal.com/contact#schedule-discussion";

// Exact hero background from academy.asagarwal.com (layered radial + linear gradients).
const HERO_BG =
	"radial-gradient(900px 600px at 50% 40%, rgba(87, 99, 255, 0.2), rgba(0, 0, 0, 0) 60%)," +
	"radial-gradient(700px 500px at 30% 70%, rgba(120, 72, 255, 0.18), rgba(0, 0, 0, 0) 60%)," +
	"radial-gradient(900px 700px at 75% 65%, rgba(32, 199, 255, 0.1), rgba(0, 0, 0, 0) 55%)," +
	"linear-gradient(rgb(10, 16, 48) 0%, rgb(7, 10, 26) 100%)";

// Three concentric rings + orbiting dots. Each dot leads the next by 120deg via a
// negative animation-delay (a third of the loop), so they never align.
const RING_CSS = `
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
`;

export default function HomePage() {
	return (
		<section className="relative overflow-hidden text-white" style={{ background: HERO_BG }}>
			<style>{RING_CSS}</style>

			{/* Animated concentric rings + orbiting dots (exact academy markup) */}
			<svg
				className="hero-rings pointer-events-none absolute inset-0 h-full w-full"
				viewBox="0 0 1400 900"
				preserveAspectRatio="xMidYMid meet"
				aria-hidden="true"
			>
				<g className="rings">
					<circle cx="980" cy="420" r="180" />
					<circle cx="980" cy="420" r="260" />
					<circle cx="980" cy="420" r="340" />
				</g>
				<g className="orbit">
					<circle className="orbit-glow" cx="1320" cy="420" r="18" />
					<circle className="orbit-dot" cx="1320" cy="420" r="4" />
				</g>
				<g className="orbit-inner">
					<circle className="orbit-glow-inner" cx="1240" cy="420" r="14" />
					<circle className="orbit-dot-inner" cx="1240" cy="420" r="3" />
				</g>
				<g className="orbit-small">
					<circle className="orbit-glow-small" cx="1160" cy="420" r="11" />
					<circle className="orbit-dot-small" cx="1160" cy="420" r="2.5" />
				</g>
			</svg>

			{/* 1400px container with a left copy column and a 630px photo column,
			    matching the academy layout so the rings sit behind the ear/shoulder. */}
			<div className="relative mx-auto max-w-[1400px] px-6 lg:px-7 lg:pt-12">
				<div className="lg:grid lg:grid-cols-[1fr_630px] lg:items-stretch">
					{/* Left: copy */}
					<div className="flex max-w-2xl flex-col justify-center py-16 lg:py-0">
						<p className="inline-flex w-fit items-center rounded-full border border-white/25 bg-white/5 px-4 py-1.5 text-sm font-medium text-blue-100">
							Agentforce Training · Advisory · Implementation
						</p>

						<h1 className="mt-6 text-4xl font-extrabold leading-[1.1] tracking-tight sm:text-5xl lg:text-6xl">
							Master Agentforce &amp; Agentic AI in Salesforce — The Right Way
						</h1>

						<p className="mt-6 max-w-xl text-lg leading-relaxed text-blue-100/85">
							Step-by-step guidance, hands-on training, and real-world
							implementation support for Salesforce professionals and teams.
						</p>

						<div className="mt-8 flex flex-wrap gap-4">
							<a
								href={EXPLORE_URL}
								target="_blank"
								rel="noreferrer noopener"
								className="inline-flex items-center justify-center rounded-lg bg-[#0077d4] px-7 py-3.5 text-base font-semibold text-white shadow-lg shadow-[#0077d4]/25 transition-colors hover:bg-[#0066ba] focus:outline-none focus-visible:ring-2 focus-visible:ring-white/70"
							>
								Explore the Academy
							</a>
							<a
								href={SCHEDULE_URL}
								target="_blank"
								rel="noreferrer noopener"
								className="inline-flex items-center justify-center gap-2 rounded-lg bg-white px-7 py-3.5 text-base font-semibold text-gray-900 shadow-lg transition-colors hover:bg-gray-100 focus:outline-none focus-visible:ring-2 focus-visible:ring-white/70"
							>
								<Phone className="size-4" />
								Schedule a Discussion
							</a>
						</div>

						{/* Social proof */}
						<div className="mt-12 flex gap-4">
							<span className="w-1 shrink-0 rounded-full bg-[#0077d4]" />
							<div>
								<p className="text-2xl font-bold text-white">
									7.5K+ Subscribers/Members
								</p>
								<div className="mt-3 flex items-center gap-3">
									<img
										src={communityMembers}
										alt="Community members"
										className="h-10 w-auto"
									/>
									<span className="max-w-xs text-sm leading-snug text-blue-100/70">
										Trusted by thousands of Salesforce professionals across
										roles, industries, and regions
									</span>
								</div>
							</div>
						</div>
					</div>

					{/* Right: hero photo — 620px square, bottom-flush, right-aligned */}
					<div className="hidden lg:flex lg:items-end lg:justify-center">
						<img
							src={ashishBanner}
							alt="Ashish Agarwal"
							className="pointer-events-none h-[620px] w-[620px] max-w-full select-none object-contain object-bottom"
						/>
					</div>
				</div>
			</div>
		</section>
	);
}
