<script lang="ts">
	import { goto } from '$app/navigation';
	import { User, UserCircle, Users, ArrowRight } from 'lucide-svelte';

	async function goToLogin(role: string) {
		await goto(`/login?role=${role}`);
	}
</script>

<div class="min-h-screen bg-gradient-to-br from-primary-50 via-white to-blue-50">
	<header class="max-w-7xl mx-auto px-4 py-6 flex items-center justify-between">
		<div class="flex items-center">
			<div class="w-10 h-10 bg-primary-500 rounded-xl flex items-center justify-center">
				<User class="w-6 h-6 text-white" />
			</div>
			<span class="ml-3 text-xl font-bold text-gray-900">儿童康复训练系统</span>
		</div>
		<a href="/login" class="btn btn-outline">登录</a>
	</header>

	<main class="max-w-7xl mx-auto px-4 py-12">
		<section class="text-center mb-16">
			<h1 class="text-4xl md:text-5xl font-bold text-gray-900 mb-6">
				让康复训练<br />
				<span class="text-primary-600">走进家庭</span>
			</h1>
			<p class="text-lg text-gray-600 max-w-2xl mx-auto mb-8">
				治疗师专业布置，家长轻松打卡，视频上传让康复训练科学高效
			</p>
			<a href="/login" class="btn btn-primary text-lg px-8 py-3">开始使用</a>
		</section>

		<section class="grid md:grid-cols-3 gap-6 mb-16">
			<button
				on:click={() => goToLogin('parent')}
				class="card p-8 text-left hover:shadow-md transition-shadow group"
			>
				<div class="w-14 h-14 bg-blue-100 rounded-2xl flex items-center justify-center mb-4 group-hover:bg-blue-200 transition-colors">
					<UserCircle class="w-7 h-7 text-blue-600" />
				</div>
				<h3 class="text-xl font-semibold text-gray-900 mb-2">家长端</h3>
				<p class="text-gray-600 mb-4">按步骤完成训练打卡，上传视频记录过程</p>
				<div class="flex items-center text-primary-600 font-medium">
					进入家长端 <ArrowRight class="w-5 h-5 ml-2" />
				</div>
			</button>

			<button
				on:click={() => goToLogin('therapist')}
				class="card p-8 text-left hover:shadow-md transition-shadow group"
			>
				<div class="w-14 h-14 bg-green-100 rounded-2xl flex items-center justify-center mb-4 group-hover:bg-green-200 transition-colors">
					<User class="w-7 h-7 text-green-600" />
				</div>
				<h3 class="text-xl font-semibold text-gray-900 mb-2">治疗师端</h3>
				<p class="text-gray-600 mb-4">布置训练作业，视频评审标注动作，制定调整方案</p>
				<div class="flex items-center text-primary-600 font-medium">
					进入治疗师端 <ArrowRight class="w-5 h-5 ml-2" />
				</div>
			</button>

			<button
				on:click={() => goToLogin('admin')}
				class="card p-8 text-left hover:shadow-md transition-shadow group"
			>
				<div class="w-14 h-14 bg-purple-100 rounded-2xl flex items-center justify-center mb-4 group-hover:bg-purple-200 transition-colors">
					<Users class="w-7 h-7 text-purple-600" />
				</div>
				<h3 class="text-xl font-semibold text-gray-900 mb-2">机构管理端</h3>
				<p class="text-gray-600 mb-4">管理治疗师、家长和孩子，查看机构运营数据</p>
				<div class="flex items-center text-primary-600 font-medium">
					进入管理端 <ArrowRight class="w-5 h-5 ml-2" />
				</div>
			</button>
		</section>

		<section class="grid md:grid-cols-2 gap-8 items-center">
			<div>
				<h2 class="text-2xl font-bold text-gray-900 mb-4">核心功能</h2>
				<ul class="space-y-3">
					<li class="flex items-start">
						<div class="w-6 h-6 bg-success-100 rounded-full flex items-center justify-center mr-3 mt-0.5 flex-shrink-0">
							<span class="text-success-600 text-xs">✓</span>
						</div>
						<span class="text-gray-700">三类训练：发音练习、精细动作、感统练习</span>
					</li>
					<li class="flex items-start">
						<div class="w-6 h-6 bg-success-100 rounded-full flex items-center justify-center mr-3 mt-0.5 flex-shrink-0">
							<span class="text-success-600 text-xs">✓</span>
						</div>
						<span class="text-gray-700">分步打卡引导，训练过程清晰明了</span>
					</li>
					<li class="flex items-start">
						<div class="w-6 h-6 bg-success-100 rounded-full flex items-center justify-center mr-3 mt-0.5 flex-shrink-0">
							<span class="text-success-600 text-xs">✓</span>
						</div>
						<span class="text-gray-700">短视频上传，训练记录随时回看</span>
					</li>
					<li class="flex items-start">
						<div class="w-6 h-6 bg-success-100 rounded-full flex items-center justify-center mr-3 mt-0.5 flex-shrink-0">
							<span class="text-success-600 text-xs">✓</span>
						</div>
						<span class="text-gray-700">治疗师视频标注，专业反馈精准到位</span>
					</li>
				</ul>
			</div>
			<div class="card p-6 bg-gradient-to-br from-primary-500 to-blue-600 text-white">
				<h3 class="text-lg font-semibold mb-2">训练数据统计</h3>
				<div class="grid grid-cols-2 gap-4 mt-6">
					<div>
						<div class="text-3xl font-bold">98%</div>
						<div class="text-primary-100 text-sm">家长完成率</div>
					</div>
					<div>
						<div class="text-3xl font-bold">500+</div>
						<div class="text-primary-100 text-sm">作业模板</div>
					</div>
					<div>
						<div class="text-3xl font-bold">10k+</div>
						<div class="text-primary-100 text-sm">打卡记录</div>
					</div>
					<div>
						<div class="text-3xl font-bold">95%</div>
						<div class="text-primary-100 text-sm">用户满意度</div>
					</div>
				</div>
			</div>
		</section>
	</main>

	<footer class="border-t border-gray-200 mt-20">
		<div class="max-w-7xl mx-auto px-4 py-8 text-center text-gray-500 text-sm">
			© 2024 儿童康复训练系统 · 助力每一个孩子的康复之路
		</div>
	</footer>
</div>
